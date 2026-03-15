#!/usr/bin/env python3
"""
Test script to verify Supabase habit_logs table connectivity.

Usage:
    export SUPABASE_URL="https://your-project.supabase.co"
    export SUPABASE_ANON_KEY="your-anon-key"
    python3 scripts/test_supabase.py

Requires: pip install supabase
"""

import os
import sys
import uuid
from datetime import date


def main():
    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_ANON_KEY")

    if not url or not key:
        print("ERROR: Set SUPABASE_URL and SUPABASE_ANON_KEY environment variables.")
        sys.exit(1)

    try:
        from supabase import create_client
    except ImportError:
        print("ERROR: Install supabase-py first: pip install supabase")
        sys.exit(1)

    client = create_client(url, key)
    test_user_id = f"test-user-{uuid.uuid4().hex[:8]}"
    today = date.today().isoformat()

    print(f"Testing with user_id={test_user_id}, date={today}")
    print()

    # --- Test 1: Insert a habit log ---
    print("1. INSERT a habit log...")
    result = (
        client.table("habit_logs")
        .insert({
            "user_id": test_user_id,
            "habit_type": "reading",
            "date": today,
            "count": 1,
        })
        .execute()
    )
    assert len(result.data) == 1, "Insert should return one row"
    row = result.data[0]
    assert row["user_id"] == test_user_id
    assert row["habit_type"] == "reading"
    assert row["count"] == 1
    print(f"   OK - inserted id={row['id']}")

    # --- Test 2: Read it back ---
    print("2. SELECT the habit log...")
    result = (
        client.table("habit_logs")
        .select("*")
        .eq("user_id", test_user_id)
        .eq("date", today)
        .execute()
    )
    assert len(result.data) == 1, "Should find exactly one row"
    assert result.data[0]["count"] == 1
    print("   OK - read back successfully")

    # --- Test 3: Upsert (update count) ---
    print("3. UPSERT to increment count...")
    result = (
        client.table("habit_logs")
        .upsert(
            {
                "user_id": test_user_id,
                "habit_type": "reading",
                "date": today,
                "count": 2,
            },
            on_conflict="user_id,habit_type,date",
        )
        .execute()
    )
    assert len(result.data) == 1
    assert result.data[0]["count"] == 2
    print("   OK - count updated to 2")

    # --- Test 4: Unique constraint ---
    print("4. Verify unique constraint (user_id, habit_type, date)...")
    try:
        client.table("habit_logs").insert({
            "user_id": test_user_id,
            "habit_type": "reading",
            "date": today,
            "count": 99,
        }).execute()
        print("   FAIL - duplicate insert should have raised an error")
        sys.exit(1)
    except Exception:
        print("   OK - duplicate insert correctly rejected")

    # --- Test 5: Insert another habit type ---
    print("5. INSERT a different habit type for same user/date...")
    result = (
        client.table("habit_logs")
        .insert({
            "user_id": test_user_id,
            "habit_type": "gym",
            "date": today,
            "count": 1,
        })
        .execute()
    )
    assert len(result.data) == 1
    print("   OK - different habit_type allowed")

    # --- Test 6: Verify column schema ---
    print("6. Verify all expected columns exist...")
    result = (
        client.table("habit_logs")
        .select("id, user_id, habit_type, date, count, created_at, updated_at")
        .eq("user_id", test_user_id)
        .execute()
    )
    assert len(result.data) == 2, f"Expected 2 rows, got {len(result.data)}"
    row = result.data[0]
    for col in ["id", "user_id", "habit_type", "date", "count", "created_at", "updated_at"]:
        assert col in row, f"Missing column: {col}"
    print("   OK - all columns present")

    # --- Cleanup ---
    print("\nCleaning up test data...")
    client.table("habit_logs").delete().eq("user_id", test_user_id).execute()
    print("   Done.")

    print("\n=== ALL TESTS PASSED ===")


if __name__ == "__main__":
    main()
