-- Create habit_logs table for tracking daily habit counts
CREATE TABLE IF NOT EXISTS habit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    habit_type TEXT NOT NULL CHECK (habit_type IN ('reading', 'meditation', 'gym', 'cholesterol')),
    date DATE NOT NULL,
    count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- One row per user per habit per day
    CONSTRAINT unique_user_habit_date UNIQUE (user_id, habit_type, date)
);

-- Index for fast lookups by user
CREATE INDEX IF NOT EXISTS idx_habit_logs_user_id ON habit_logs (user_id);

-- Index for date-range queries (streak calculation)
CREATE INDEX IF NOT EXISTS idx_habit_logs_user_date ON habit_logs (user_id, date DESC);

-- Enable Row Level Security
ALTER TABLE habit_logs ENABLE ROW LEVEL SECURITY;

-- Policy: users can only SELECT their own rows
CREATE POLICY "Users can view own habit logs"
    ON habit_logs
    FOR SELECT
    USING (auth.uid()::text = user_id);

-- Policy: users can only INSERT their own rows
CREATE POLICY "Users can insert own habit logs"
    ON habit_logs
    FOR INSERT
    WITH CHECK (auth.uid()::text = user_id);

-- Policy: users can only UPDATE their own rows
CREATE POLICY "Users can update own habit logs"
    ON habit_logs
    FOR UPDATE
    USING (auth.uid()::text = user_id)
    WITH CHECK (auth.uid()::text = user_id);

-- Policy: users can only DELETE their own rows
CREATE POLICY "Users can delete own habit logs"
    ON habit_logs
    FOR DELETE
    USING (auth.uid()::text = user_id);

-- Trigger to auto-update updated_at on row changes
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON habit_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
