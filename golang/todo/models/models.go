package models

import (
	"context"
	"crypto/rand"
	"database/sql"
	"encoding/hex"
	"errors"
	"fmt"
	"log"
	"strconv"
	"time"

	"github.com/lib/pq"
	"github.com/redis/go-redis/v9"
	"golang.org/x/crypto/bcrypt"
)

// Taskの構造体を作成
type Task struct {
	ID         int
	Title      string
	Completed  bool
	Duration   int
	Created_at time.Time
}

// TaskListの構造体を作成、DBへデータ管理
type TaskList struct {
	DB    *sql.DB
	Redis *redis.Client
}

// HTMLへ渡すデータ構造体
type TemplateData struct {
	TotalCount     int
	CompletedCount int
	PendingCount   int
	Tasks          []Task
	Created_at     time.Time
	CurrentPage    int
	PrevPage       int
	NextPage       int
}

// 関数外で重複エラーの定義
var ErrUserAlreadyExists = errors.New("このユーザー名は既に使用されています")

// CRUD...C:CREATE/R:READ/U:UPDATE/D:DELETE
// タスク追加処理
func (l *TaskList) AddTask(user_id int, title string, completed bool, duration int, created_at time.Time) error {
	if title == "" {
		return errors.New("タイトルが空です")
	}
	query := `INSERT INTO tasks (user_id, title, completed, duration, created_at) VALUES ($1, $2, $3, $4, $5)`
	_, err := l.DB.Exec(query, user_id, title, completed, duration, created_at)
	return err
}

// タスク読み取り処理
// 返り値が2つ設定しており、[]Taskとerror
func (l *TaskList) ReadTask(user_id int, keyword string, status string, limit int, offset int) ([]Task, error) {
	query := `SELECT id, title, completed, duration, created_at FROM tasks WHERE user_id = $1`

	// anyで箱を用意
	var args []any
	// user_idをargsという箱に入れる。現在user_idは$1、箱に1つしか値がない
	args = append(args, user_id)

	// 検索キーワードがある場合の処理
	if keyword != "" {
		// キーワードをargsという箱に入れる
		// 現在argsという箱は2個入っているため、ここでは$2となる
		args = append(args, "%"+keyword+"%")
		query += fmt.Sprintf(" AND title LIKE $%d", len(args))
	}

	// フィルター機能
	if status == "true" || status == "false" {
		// statusをargsという箱に入れる
		args = append(args, status)
		query += fmt.Sprintf(" AND completed = $%d", len(args))
	}

	// ソート機能
	query += " ORDER BY id"

	// ページネーション設定
	// limitとoffsetをそれぞれargsという箱に入れる
	args = append(args, limit, offset)
	query += fmt.Sprintf(" LIMIT $%d OFFSET $%d", len(args)-1, len(args))

	// データベース問い合わせ
	rows, err := l.DB.Query(query, args...)
	if err != nil {
		return nil, err
	}
	// DB接続しているので、終了の合図
	defer rows.Close()

	// 受け取ったデータを構造体へ入れる
	var tasks []Task

	// 次のデータがないかループで確認
	for rows.Next() {
		var t Task
		// ポインタ & を使って直接書き込み
		if err := rows.Scan(&t.ID, &t.Title, &t.Completed, &t.Duration, &t.Created_at); err != nil {
			// 返り値としてtasksが空の場合は、errを返す
			return nil, err
		}
		// データが入った小箱を、tasksに返す
		tasks = append(tasks, t)
	}
	return tasks, nil
}

// タスク更新処理
func (l *TaskList) UpdateTask(user_id int, id int, title string, completed bool, duration int) error {
	if id <= 0 || title == "" {
		return errors.New("不正なIDまたはタイトルが空です。")
	}
	query := `UPDATE tasks SET title = $1, completed = $2, duration = $3 WHERE id = $4 AND user_id = $5`
	_, err := l.DB.Exec(query, title, completed, duration, id, user_id)
	return err
}

// タスク削除処理
func (l *TaskList) DelTask(user_id int, taskID int) error {
	// まずは空チェック
	if user_id <= 0 || taskID <= 0 {
		return errors.New("不正なIDを入力しています。")
	}

	query := `DELETE FROM tasks WHERE id = $1 AND user_id =$2`
	_, err := l.DB.Exec(query, taskID, user_id)
	return err
}

// サインアップ処理
func (l *TaskList) SignupUser(username string, password string) error {
	// 同様に空チェック
	if username == "" || password == "" {
		return errors.New("ユーザー名、もしくはパスワードが空です。")
	}

	// パスワードをstringからバイト列に変換
	// パスワードをどれくらい複雑に、時間をかけてかき混ぜるか（コスト）を計算
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	query := `INSERT INTO users (username, password_hash) VALUES ($1, $2)`
	// errの箱があり、2回目の登場なので、上書きを実施
	_, err = l.DB.Exec(query, username, string(hashedPassword))
	if err != nil {
		if pqErr, ok := err.(*pq.Error); ok && pqErr.Code == "23505" {
			return ErrUserAlreadyExists
		}
		return err
	}
	return nil
}

// ユーザー名からID取得処理
func (l *TaskList) GetUserId(username string) (int, error) {
	var user_id int
	query := `SELECT id FROM users WHERE username = $1`
	err := l.DB.QueryRow(query, username).Scan(&user_id)
	if err != nil {
		log.Println(err)
		return 0, err
	}
	return user_id, err
}

// ランダムで推測不可能なセッショントークンを生成する関数（ヒント）
func GenerateSessionToken() (string, error) {
	// 64バイトの空の箱（配列）を用意します
	b := make([]byte, 64)

	// crypto/rand を使って、安全な乱数を箱に詰めます
	_, err := rand.Read(b)
	if err != nil {
		return "", err
	}

	// バイト列（コンピュータ語）そのままだとCookieに入れられないので、
	// 16進数の文字列（a-f, 0-9のみの安全な文字列）に変換して返します
	return hex.EncodeToString(b), nil
}

// セッションをDBに保存
func (l *TaskList) CreateSession(user_id int, token string) error {
	// 下記はRedisに保存のケース
	ctx := context.Background()
	return l.Redis.Set(ctx, token, user_id, 24*time.Hour).Err()
	// 下記についてはDBへの保存のケース
	/*
		expiresAt := time.Now().Add(24 * time.Hour)
		query := `INSERT INTO sessions (user_id, session_token, expires_at) VALUES ($1, $2, $3)`
		_, err := l.DB.Exec(query, user_id, token, expiresAt)
		return err
	*/
}

// トークンからユーザーIDを特定
func (l *TaskList) GetUserIdToken(token string) (int, error) {
	// 下記はRedisに保存のケース
	ctx := context.Background()

	val, err := l.Redis.Get(ctx, token).Result()
	if err != nil {
		log.Println(err)
		return 0, err
	}

	user_id, _ := strconv.Atoi(val)
	return user_id, nil
	// 下記についてはDBへの保存のケース
	/*
		var user_id int
		// 有効期限内のもののみ取得
		query := `SELECT user_id FROM sessions WHERE session_token = $1 AND expires_at > NOW()`
		err := l.DB.QueryRow(query, token).Scan(&user_id)
		return user_id, err
	*/
}
