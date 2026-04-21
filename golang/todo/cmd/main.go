package main

import (
	"context"
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"
	"text/template"
	"time"

	"github.com/joho/godotenv"
	_ "github.com/lib/pq"
	"golang.org/x/crypto/bcrypt"

	"todo/models"
)

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
	myTasks := models.TaskList{db: db}

	// 誰でもみられるページ
	http.HandleFunc("/login", myTasks.loginHandler)
	http.HandleFunc("/signup", myTasks.signupHandler)

	// authMiddlewareで包むことによりcookieを持つ人しか見られない
	http.HandleFunc("/", myTasks.authMiddleware(myTasks.ReadHandler))
	http.HandleFunc("/add", myTasks.authMiddleware(myTasks.AddHandler))
	http.HandleFunc("/del", myTasks.authMiddleware(myTasks.DelHandler))
	http.HandleFunc("/update", myTasks.authMiddleware(myTasks.UpdateHandler))
	http.HandleFunc("/bulk-del", myTasks.authMiddleware(myTasks.BulkDelHandler))
	http.HandleFunc("/api/tasks", myTasks.authMiddleware(myTasks.apiTasksHandler))

	fmt.Println("Server started at :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
