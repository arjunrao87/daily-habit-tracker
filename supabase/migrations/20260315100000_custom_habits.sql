-- Create habits table for user-defined habits
CREATE TABLE IF NOT EXISTS habits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    icon TEXT NOT NULL DEFAULT 'star.fill',
    color TEXT NOT NULL DEFAULT 'blue',
    is_inverse BOOLEAN NOT NULL DEFAULT false,
    sort_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_habits_user_id ON habits (user_id);

-- Enable RLS
ALTER TABLE habits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own habits"
    ON habits FOR SELECT
    USING (auth.uid()::text = user_id);

CREATE POLICY "Users can insert own habits"
    ON habits FOR INSERT
    WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own habits"
    ON habits FOR UPDATE
    USING (auth.uid()::text = user_id)
    WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own habits"
    ON habits FOR DELETE
    USING (auth.uid()::text = user_id);

-- Migrate habit_logs: add habit_id column, populate from existing data
ALTER TABLE habit_logs ADD COLUMN IF NOT EXISTS habit_id UUID REFERENCES habits(id) ON DELETE CASCADE;

-- Drop the old CHECK constraint on habit_type
ALTER TABLE habit_logs DROP CONSTRAINT IF EXISTS habit_logs_habit_type_check;

-- Update the unique constraint to use habit_id instead of habit_type
-- (We keep the old constraint for now and add a new one; old data uses habit_type, new data uses habit_id)
ALTER TABLE habit_logs ADD CONSTRAINT unique_user_habit_id_date UNIQUE (user_id, habit_id, date);
