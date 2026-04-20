package main

import (
	"context"
	"database/sql"
	"encoding/json"
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

	"todo/models"
)

// サインアップハンドラー
func (l *models.TaskList) signupHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodGet {
		tmpl, err := template.ParseFiles("templates/signup.html")
		if err != nil {
			log.Printf("読み込みエラー", err)
			http.Error(w, "読み込みエラー", http.StatusInternalServerError)
			return
		}

		err = tmpl.Execute(w, nil)
		if err != nil {
			log.Printf("表示エラー", err)
			http.Error(w, "表示エラー", http.StatusInternalServerError)
			return
		}
		return
	}

	if r.Method == http.MethodPost {
		username := r.FormValue("username")
		password := r.FormValue("password")

		// 既に作ったDB処理を呼び出す
		err := l.signupUser(username, password)
		log.Printf("ログイン成功:%v", username)
		if err != nil {
			http.Error(w, "登録に失敗しました", http.StatusInternalServerError)
			return
		}
		http.Redirect(w, r, "/", http.StatusSeeOther)
	}
}

// ログイン処理
func (l *TaskList) authMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {

		// リクエストからsession_idを探す
		cookie, err := r.Cookie("session_id")
		if err != nil {
			http.Redirect(w, r, "/login", http.StatusSeeOther)
			return //return しないと、勝手に中に入られる
		}

		// ログインしていれば、ユーザーを指定して、クッキーの中身を取り出す
		username := cookie.Value
		var user_id int
		err = l.db.QueryRow(`SELECT id FROM users WHERE username = $1`, username).Scan(&user_id)
		if err != nil {
			http.Redirect(w, r, "/login", http.StatusSeeOther)
			return
		}

		// contextにuser_idという名前でuser_idを入れる
		ctx := context.WithValue(r.Context(), "user_id", user_id)

		// 会員証の確認が取れたために、新しいリクエスト(r.WithContext)と共に本来の処理へ
		next(w, r.WithContext(ctx))
	}
}

// ログイン処理
func (l *TaskList) loginHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodGet {
		tmpl, err := template.ParseFiles("templates/login.html")
		if err != nil {
			log.Printf("ログインテンプレート読み込みエラー:%v", err)
			http.Error(w, "システムエラー", http.StatusInternalServerError)
			return
		}

		err = tmpl.Execute(w, nil)
		if err != nil {
			log.Printf("表示エラー:%v", err)
			http.Error(w, "表示えらー", http.StatusInternalServerError)
			return
		}
		return
	}

	if r.Method == http.MethodPost {
		username := r.FormValue("username")
		password := r.FormValue("password")

		// DBからハッシュ化されたパスワードを取得
		var storeHash string
		err := l.db.QueryRow(`SELECT password_hash FROM users WHERE username = $1`, username).Scan(&storeHash)
		if err != nil {
			http.Error(w, "ユーザー名かパスワードが異なります。", http.StatusUnauthorized)
			return
		}

		// パスワード照合
		err = bcrypt.CompareHashAndPassword([]byte(storeHash), []byte(password))
		if err != nil {
			http.Error(w, "ユーザー名かパスワードが違います", http.StatusUnauthorized)
			return
		}

		// クッキーの発行
		cookie := &http.Cookie{
			Name:     "session_id",
			Value:    username,
			Path:     "/",
			HttpOnly: true,
			MaxAge:   120, //有効期限を設定
		}
		http.SetCookie(w, cookie)

		http.Redirect(w, r, "/", http.StatusSeeOther)
	}
}

// GET処理
func (l *TaskList) indexHandler(w http.ResponseWriter, r *http.Request) {

	// 検索・フィルター設定
	keyword := r.URL.Query().Get("q")
	statusStr := r.URL.Query().Get("status")

	tasks, err := l.GetAllTasks(user_id, keyword, statusStr, limit, offset)
	if err != nil {
		log.Println("DBエラー", err)
		http.Error(w, "データ取得失敗", http.StatusInternalServerError)
		return
	}

	var totalCount int
	err = l.db.QueryRow("SELECT COUNT(*) FROM tasks WHERE user_id = $1", user_id).Scan(&totalCount)
	if err != nil {
		fmt.Println(err)
	}

	var completedCount int
	err = l.db.QueryRow("SELECT COUNT(*) FROM tasks WHERE completed = true AND user_id = $1", user_id).Scan(&completedCount)
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

// DELETE処理
// HTMLはGETとPOSTしかない
func (l *TaskList) delHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodPost {

		user_id := r.Context().Value("user_id").(int)

		// string型からint型へ変更
		intStr := r.FormValue("id")
		id, err := strconv.Atoi(intStr)
		if err != nil {
			log.Println(err)
			http.Error(w, "無効なステータス", http.StatusBadRequest)
			return
		}

		err = l.DelTask(user_id, id)
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

		user_id := r.Context().Value("user_id").(int)
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

		err = l.UpdateTask(user_id, id, title, completed, duration)
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
		args := []any{user_id}
		var placeholders []string

		for i, idText := range idStr {
			id, err := strconv.Atoi(idText)
			if err != nil {
				log.Println(err)
				return
			}
			args = append(args, id)

			placeholders = append(placeholders, fmt.Sprintf("$%d", i+2))
		}
		// プレースホルダーの順番をずらす
		query := fmt.Sprintf("DELETE FROM tasks WHERE id IN (%s) AND user_id = $1", strings.Join(placeholders, ","))
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
	user_id := r.Context().Value("user_id").(int)
	tasks, err := l.GetAllTasks(user_id, "", "", 100, 0)
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

	// 誰でもみられるページ
	http.HandleFunc("/login", myTasks.loginHandler)
	http.HandleFunc("/signup", myTasks.signupHandler)

	// authMiddlewareで包むことによりcookieを持つ人しか見られない
	http.HandleFunc("/", myTasks.authMiddleware(myTasks.indexHandler))
	http.HandleFunc("/add", myTasks.authMiddleware(myTasks.addHandler))
	http.HandleFunc("/del", myTasks.authMiddleware(myTasks.delHandler))
	http.HandleFunc("/update", myTasks.authMiddleware(myTasks.updateHandler))
	http.HandleFunc("/bulk-del", myTasks.authMiddleware(myTasks.bulkDelHandler))
	http.HandleFunc("/api/tasks", myTasks.authMiddleware(myTasks.apiTasksHandler))

	fmt.Println("Server started at :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
