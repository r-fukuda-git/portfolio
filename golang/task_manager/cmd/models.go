package main

import (
	"database/sql"
	"fmt"
	"time"
)

// ToStringのインターフェースを作成
type Stringer interface {
	ToString() string
}

// Taskの構造体を作成
type Task struct {
	ID         int
	Title      string
	Completed  bool
	Duration   int
	Created_at time.Time
}

// Taskをtとして読み込み、statusの確認を関数で実施
func (t *Task) ToString() string {
	status := "未完了"
	if t.Completed {
		status = "完了"
	}
	return fmt.Sprintf("[%d] %s (%s)", t.ID, t.Title, status)
}

// TaskListの構造体を作成、Taskを配列にとる
type TaskList struct {
	tasks []Task
	db    *sql.DB
}
