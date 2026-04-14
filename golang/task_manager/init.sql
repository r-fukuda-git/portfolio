CREATE TABLE IF NOT EXISTS tasks (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    completed BOOLEAN NOT NULL DEFAULT false,
    duration INTEGER NOT NULL DEFAULT 1
);

INSERT INTO tasks (title, completed, duration)
SELECT 
    '大量処理タスク #' || i, 
    (random() > 0.5), 
    (random() * 5 + 1)::int
FROM generate_series(1, 100000) AS i
ON CONFLICT DO NOTHING;