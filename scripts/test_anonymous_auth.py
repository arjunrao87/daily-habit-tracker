#!/usr/bin/env python3
"""
Integration test for US-002: Anonymous Authentication.

Tests that:
1. Anonymous sign-in creates a session
2. The session provides a valid user ID
3. The anonymous user can read/write habit_logs via RLS
4. A second anonymous sign-in creates a different user (session isolation)

Requires: pip install supabase
Environment variables: SUPABASE_URL, SUPABASE_ANON_KEY
"""

import os
import sys
from datetime import date

from supabase import create_client, Client


def get_client() -> Client:
    url = os.environ.get("SUPABASE_URL")
    key = os.environ.get("SUPABASE_ANON_KEY")
    if not url or not key:
        print("ERROR: Set SUPABASE_URL and SUPABASE_ANON_KEY environment variables")
        sys.exit(1)
    return create_client(url, key)


def test_anonymous_sign_in():
    """Test that anonymous sign-in works and returns a user ID."""
    print("=== Test: Anonymous Sign-In ===")
    client = get_client()

    # Sign in anonymously
    response = client.auth.sign_in_anonymously()
    assert response.user is not None, "Anonymous sign-in should return a user"
    assert response.user.id is not None, "User should have an ID"
    assert response.session is not None, "Should have a session"

    user_id = str(response.user.id)
    print(f"  Anonymous user ID: {user_id}")
    print(f"  Session token present: {bool(response.session.access_token)}")
    print("  PASSED")
    return client, user_id


def test_anonymous_user_can_write(client: Client, user_id: str):
    """Test that an anonymous user can insert habit_logs via RLS."""
    print("\n=== Test: Anonymous User Can Write ===")
    today = date.today().isoformat()

    result = (
        client.table("habit_logs")
        .upsert(
            {
                "user_id": user_id,
                "habit_type": "reading",
                "date": today,
                "count": 1,
            },
            on_conflict="user_id,habit_type,date",
        )
        .execute()
    )

    assert len(result.data) > 0, "Upsert should return the inserted row"
    row = result.data[0]
    assert row["user_id"] == user_id
    assert row["habit_type"] == "reading"
    assert row["count"] == 1
    print(f"  Inserted habit_log: {row['id']}")
    print("  PASSED")


def test_anonymous_user_can_read(client: Client, user_id: str):
    """Test that an anonymous user can read their own habit_logs."""
    print("\n=== Test: Anonymous User Can Read ===")
    today = date.today().isoformat()

    result = (
        client.table("habit_logs")
        .select("*")
        .eq("user_id", user_id)
        .eq("date", today)
        .execute()
    )

    assert len(result.data) > 0, "Should be able to read own habit logs"
    print(f"  Found {len(result.data)} log(s) for today")
    print("  PASSED")


def test_session_isolation():
    """Test that a second anonymous sign-in creates a different user."""
    print("\n=== Test: Session Isolation ===")
    client1 = get_client()
    client2 = get_client()

    resp1 = client1.auth.sign_in_anonymously()
    resp2 = client2.auth.sign_in_anonymously()

    user1 = str(resp1.user.id)
    user2 = str(resp2.user.id)

    assert user1 != user2, f"Two anonymous sign-ins should create different users, got {user1} both times"
    print(f"  User 1: {user1}")
    print(f"  User 2: {user2}")
    print("  PASSED")


def test_rls_prevents_cross_user_access():
    """Test that one anonymous user cannot read another's data."""
    print("\n=== Test: RLS Prevents Cross-User Access ===")
    client1 = get_client()
    client2 = get_client()

    resp1 = client1.auth.sign_in_anonymously()
    resp2 = client2.auth.sign_in_anonymously()

    user1 = str(resp1.user.id)
    user2 = str(resp2.user.id)
    today = date.today().isoformat()

    # User 1 inserts a log
    client1.table("habit_logs").upsert(
        {
            "user_id": user1,
            "habit_type": "meditation",
            "date": today,
            "count": 5,
        },
        on_conflict="user_id,habit_type,date",
    ).execute()

    # User 2 tries to read User 1's data — should get empty result due to RLS
    result = (
        client2.table("habit_logs")
        .select("*")
        .eq("user_id", user1)
        .execute()
    )

    assert len(result.data) == 0, f"User 2 should not see User 1's data, but got {len(result.data)} rows"
    print("  User 2 correctly cannot see User 1's data")
    print("  PASSED")


def cleanup(client: Client, user_id: str):
    """Clean up test data."""
    today = date.today().isoformat()
    try:
        client.table("habit_logs").delete().eq("user_id", user_id).eq("date", today).execute()
    except Exception:
        pass


if __name__ == "__main__":
    print("US-002: Anonymous Authentication Integration Tests\n")

    # Test 1: Anonymous sign-in
    client, user_id = test_anonymous_sign_in()

    try:
        # Test 2: Write with anonymous auth
        test_anonymous_user_can_write(client, user_id)

        # Test 3: Read with anonymous auth
        test_anonymous_user_can_read(client, user_id)

        # Test 4: Session isolation
        test_session_isolation()

        # Test 5: RLS enforcement
        test_rls_prevents_cross_user_access()

        print("\n=== ALL TESTS PASSED ===")
    finally:
        cleanup(client, user_id)
