package main

import (
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"text/template"
	"time"

	"github.com/joho/godotenv"
	_ "github.com/lib/pq"
	"golang.org/x/crypto/bcrypt"
)

// サインアップ処理
func (l *TaskList) signupUser(username string, password string) error {
	// 2回に分けるよりOR条件で繋いだ方がいい
	if username == "" || password == "" {
		return errors.New("空")
	}

	// パスワード
	// 平文のパスワードをハッシュに変更する
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	// 入力された情報をDBに保存
	query := `INSERT INTO users (username, password_hash) VALUES ($1, $2)`

	_, err = l.db.Exec(query, username, string(hashedPassword))
	if err != nil {
		return err
	}

	return nil
}

// ログイン処理
func (l *TaskList) authMiddleware(next http.HandleFunc) http.HandleFunc {
	return func(w http.ResponseWriter, r *http.Request) {

		// リクエストからsession_idを探す
		cookie, err := r.Cookie("session_id")
		if err != nil {
			http.Redirect(w, r, "/login", http.StatusSeeOther)
			return //return しないと、勝手に中に入られる
		}

		// ログインしていれば、クッキーの中身を取り出す
		userID := cookie.Value
		log.Println("アクセスしたユーザーID:", userID)

		// 会員証の確認が取れたために、本来の処理へ
		next(w, r)
	}
}

func (l *TaskList)


// タスク追加処理
func (l *TaskList) AddTask(title string, completed bool, duration int, created_at time.Time) error {
	if title == "" {
		return errors.New("空")
	}

	query := `INSERT INTO tasks (title, completed, duration, created_at) VALUES ($1, $2, $3, $4)`
	_, err := l.db.Exec(query, title, completed, duration, created_at)
	return err
}

// タスク削除処理
func (l *TaskList) DelTask(ID int) error {
	if ID <= 0 {
		return errors.New("不正なID")
	}

	query := `DELETE FROM tasks WHERE id = $1`
	_, err := l.db.Exec(query, ID)
	return err
}

// タスク更新処理
func (l *TaskList) UpdateTask(id int, title string, completed bool, duraion int) error {
	if id <= 0 {
		return errors.New("不正なID")
	}
	if title == "" {
		return errors.New("タイトル空です")
	}

	query := `UPDATE tasks SET title = $1, completed = $2, duration = $3 WHERE id = $4`
	_, err := l.db.Exec(query, title, completed, duraion, id)
	return err
}

// DBから情報を取得
func (l *TaskList) GetAllTasks(keyword string, status string, limit int, offset int) ([]Task, error) {
	query := `SELECT id, title, completed, duration, created_at FROM tasks WHERE 1=1`
	var args []any

	if keyword != "" {
		args = append(args, "%"+keyword+"%")
		query += fmt.Sprintf(" AND title LIKE $%d", len(args))
	}

	if status == "true" || status == "false" {
		args = append(args, status)
		query += fmt.Sprintf(" AND completed = %d", len(args))
	}

	query += " ORDER BY id"

	args = append(args, limit, offset)
	query += fmt.Sprintf(" LIMIT $%d OFFSET $%d", len(args)-1, len(args))

	rows, err := l.db.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tasks []Task
	for rows.Next() {
		var t Task
		if err := rows.Scan(&t.ID, &t.Title, &t.Completed, &t.Duration, &t.Created_at); err != nil {
			return nil, err
		}
		tasks = append(tasks, t)
	}
	return tasks, nil
}

// GET処理
func (l *TaskList) indexHandler(w http.ResponseWriter, r *http.Request) {
	// ページネーション設定
	pageStr := r.URL.Query().Get("page")
	page := 1
	if pageStr != "" {
		p, err := strconv.Atoi(pageStr)
		if err == nil && p > 0 {
			page = p
		}
	}

	limit := 10
	offset := (page - 1) * limit

	// 検索・フィルター設定
	keyword := r.URL.Query().Get("q")
	statusStr := r.URL.Query().Get("status")

	tasks, err := l.GetAllTasks(keyword, statusStr, limit, offset)
	if err != nil {
		log.Println("DBエラー", err)
		http.Error(w, "データ取得失敗", http.StatusInternalServerError)
		return
	}

	var totalCount int
	err = l.db.QueryRow("SELECT COUNT(*) FROM tasks").Scan(&totalCount)
	if err != nil {
		fmt.Println(err)
	}

	var completedCount int
	err = l.db.QueryRow("SELECT COUNT(*) FROM tasks WHERE completed = true").Scan(&completedCount)
	if err != nil {
		fmt.Println(err)
	}

	var created_at_time time.Time
	err = l.db.QueryRow("SELECT created_at FROM tasks").Scan(&created_at_time)
	if err != nil {
		fmt.Println(err)
	}

	pendingCount := totalCount - completedCount

	// HTMLに渡すデータの準備
	data := struct {
		TotalCount     int
		CompletedCount int
		PendingCount   int
		Tasks          []Task
		Created_at     time.Time
		CurrentPage    int
		PrevPage       int
		NextPage       int
	}{
		TotalCount:     len(tasks),
		CompletedCount: completedCount,
		PendingCount:   pendingCount,
		Tasks:          tasks,
		Created_at:     created_at_time,
		CurrentPage:    page,
		PrevPage:       page - 1,
		NextPage:       page + 1,
	}

	tmpl, err := template.ParseFiles("templates/index.html")
	if err != nil {
		log.Printf("テンプレート読み込みエラー: %v", err)
		http.Error(w, "systemエラーが発生", http.StatusInternalServerError)
		return
	}

	// リクエストを送信
	err = tmpl.Execute(w, data)
	if err != nil {
		log.Printf("実行エラー: %v", err)
		http.Error(w, "systemerr", http.StatusInternalServerError)
		return
	}
}

// POST処理
func (l *TaskList) addHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodPost {
		// フォームから値を取得
		title := r.FormValue("title")

		// string型からbool型へ変換
		compStr := r.FormValue("completed")
		completed, err := strconv.ParseBool(compStr)
		if err != nil {
			log.Println(err)
			http.Error(w, "無効なステータスです", http.StatusBadRequest)
			return
		}

		// string型からint型へ変換
		durStr := r.FormValue("duration")
		duration, err := strconv.Atoi(durStr)
		if err != nil {
			log.Println(err)
			http.Error(w, "無効なステータスです", http.StatusBadRequest)
			return
		}

		// 作成日時を定義
		now := time.Now()

		// DBへ保存
		err = l.AddTask(title, completed, duration, now)
		if err != nil {
			http.Error(w, "保存失敗", http.StatusInternalServerError)
			return
		}
	}
	http.Redirect(w, r, "/", http.StatusSeeOther)
}

// DELETE処理
// HTMLはGETとPOSTしかない
func (l *TaskList) delHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodPost {

		// string型からint型へ変更
		intStr := r.FormValue("id")
		id, err := strconv.Atoi(intStr)
		if err != nil {
			log.Println(err)
			http.Error(w, "無効なステータス", http.StatusBadRequest)
			return
		}

		err = l.DelTask(id)
		if err != nil {
			http.Error(w, "削除失敗", http.StatusInternalServerError)
			return
		}
	}
	http.Redirect(w, r, "/", http.StatusSeeOther)
}

// UPDATE処理
func (l *TaskList) updateHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodPost {

		title := r.FormValue("title")

		compStr := r.FormValue("completed")
		completed, err := strconv.ParseBool(compStr)
		if err != nil {
			log.Println(err)
			http.Error(w, "無効な文字", http.StatusInternalServerError)
			return
		}

		durStr := r.FormValue("duration")
		duration, err := strconv.Atoi(durStr)
		if err != nil {
			log.Println(err)
			http.Error(w, "無効ですよ", http.StatusInternalServerError)
			return
		}

		intStr := r.FormValue("id")
		id, err := strconv.Atoi(intStr)
		if err != nil {
			log.Println(err)
			http.Error(w, "更新失敗", http.StatusInternalServerError)
			return
		}

		err = l.UpdateTask(id, title, completed, duration)
		if err != nil {
			http.Error(w, "更新失敗", http.StatusInternalServerError)
			return
		}
	}
	http.Redirect(w, r, "/", http.StatusSeeOther)
}

// 一括処理
func (l *TaskList) bulkDelHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodPost {

		// フォーム解析
		r.ParseForm()
		idStr := r.Form["ids"]

		// 空チェック
		if len(idStr) == 0 {
			http.Redirect(w, r, "/", http.StatusSeeOther)
			return
		}

		// DBに渡す箱を用意
		var args []any
		var placeholders []string

		for i, idText := range idStr {
			id, err := strconv.Atoi(idText)
			if err != nil {
				log.Println(err)
				return
			}
			args = append(args, id)

			placeholders = append(placeholders, fmt.Sprintf("$%d", i+1))
		}
		query := fmt.Sprintf("DELETE FROM tasks WHERE id IN (%s)", strings.Join(placeholders, ","))
		_, err := l.db.Exec(query, args...)
		if err != nil {
			log.Println(err)
			http.Error(w, "削除失敗", http.StatusInternalServerError)
			return
		}
	}
	http.Redirect(w, r, "/", http.StatusSeeOther)
}

// API用のハンドラー
func (l *TaskList) apiTasksHandler(w http.ResponseWriter, r *http.Request) {
	// 全件取得
	tasks, err := l.GetAllTasks("", "", 100, 0)
	if err != nil {
		http.Error(w, "データ取得失敗", http.StatusInternalServerError)
		return
	}

	// ブラウザにJSONデータを送る内容を明示的に記載
	w.Header().Set("Content-Type", "application/json")

	// tasksをJSONに変換し、wに書き込み
	err = json.NewEncoder(w).Encode(tasks)
	if err != nil {
		http.Error(w, "JSON変換エラー", http.StatusInternalServerError)
		return
	}
}

func main() {
	_ = godotenv.Load()

	host := os.Getenv("DB_HOST")
	port := os.Getenv("DB_PORT")
	user := os.Getenv("DB_USER")
	pass := os.Getenv("DB_PASSWORD")
	dbname := os.Getenv("DB_NAME")

	connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable", host, port, user, pass, dbname)

	var db *sql.DB
	var err error
	for i := 0; i < 10; i++ {
		db, err = sql.Open("postgres", connStr)
		if err == nil && db.Ping() == nil {
			break
		}
		fmt.Println("DB接続中")
		time.Sleep(2 * time.Second)
	}

	if err != nil {
		log.Fatal("DB接続失敗", err)
	}
	defer db.Close()

	if err := db.Ping(); err != nil {
		fmt.Printf("応答なし:%v", err)
		return
	}
	myTasks := TaskList{db: db}

	http.HandleFunc("/", myTasks.indexHandler)
	http.HandleFunc("/add", myTasks.addHandler)
	http.HandleFunc("/del", myTasks.delHandler)
	http.HandleFunc("/update", myTasks.updateHandler)
	http.HandleFunc("/bulk-del", myTasks.bulkDelHandler)
	http.HandleFunc("/api/tasks", myTasks.apiTasksHandler)

	fmt.Println("Server started at :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
