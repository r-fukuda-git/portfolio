CREATE TABLE IF NOT EXISTS tasks (
    id SERIAL PRIMARY KEY,
    title TEXT NOT NULL,
    completed BOOLEAN NOT NULL DEFAULT false,
    duration INTEGER NOT NULL DEFAULT 1
);

INSERT INTO tasks (title, completed, duration)
SELECT 
    (ARRAY['【仕事】', '【個人】', '【急ぎ】', '【検討中】'])[floor(random() * 4 + 1)] || 
    (ARRAY['プロジェクト資料', '請求書', '定例会議', '買い物リスト', 'バグ報告書', 'ランチ予約'])[floor(random() * 6 + 1)] || 
    (ARRAY['の作成', 'の確認', 'を修正', 'の送付', 'の調査'])[floor(random() * 5 + 1)] || 
    ' (ID:' || i || ')',
    (random() > 0.7),
    CASE 
        WHEN i % 10 = 0 THEN (random() * 100 + 50)::int
        ELSE (random() * 10 + 1)::int
    END
FROM generate_series(1, 10) AS i
ON CONFLICT DO NOTHING;