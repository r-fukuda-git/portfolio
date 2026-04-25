package main

import (
	"database/sql"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/joho/godotenv"
	_ "github.com/lib/pq"
	"github.com/redis/go-redis/v9"

	"todo/handlers"
	"todo/models"
)

func main() {
	// ロガー初期化
	// 部品(NewJSONHandler)を、本体(slog.New)の中に入れてからセット
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	slog.SetDefault(logger)

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
		slog.Info("DB接続中...", slog.Int("retry_count", i+1))
		time.Sleep(2 * time.Second)
	}

	if err != nil {
		slog.Error("DB接続失敗しました",
			slog.String("action", "db_init"),
			slog.Any("error_detail", err),
		)
		os.Exit(1)
	}
	defer db.Close()

	if err := db.Ping(); err != nil {
		slog.Error("応答なし",
			slog.String("action", "db_init"),
			slog.Any("error_detail", err),
		)
		return
	}

	// Redisクライアントの初期化を実施
	addr := os.Getenv("REDIS_ADDR")
	rpass := os.Getenv("REDIS_PASS")

	// DBについてはstring型ではなく、int型にする必要がある
	dbStr := os.Getenv("REDIS_DB")
	dbNum, err := strconv.Atoi(dbStr)
	if err != nil {
		slog.Error("RedisのDB番号変換に失敗しました",
			slog.String("action", "redis_init"),
			slog.Any("error_detail", err),
		)
		os.Exit(1)
	}

	rdb := redis.NewClient(&redis.Options{
		Addr:     addr,
		Password: rpass,
		DB:       dbNum,
	})

	// dbのポインタとして渡し、初期化する
	myTasks := &models.TaskList{
		DB:    db,
		Redis: rdb,
	}

	// Handlersパッケージのインスタンスを生成
	myHandler := &handlers.TaskHandler{Models: myTasks}

	// 誰でもみられるページ
	http.HandleFunc("/login", myHandler.LoginHandler)
	http.HandleFunc("/signup", myHandler.SignUpHandler)
	http.HandleFunc("/logout", myHandler.LogoutHandler)

	// authMiddlewareで包むことによりcookieを持つ人しか見られない
	http.HandleFunc("/", myHandler.AuthCookie(myHandler.ReadHandler))
	http.HandleFunc("/add", myHandler.AuthCookie(myHandler.AddHandler))
	http.HandleFunc("/del", myHandler.AuthCookie(myHandler.DelHandler))
	http.HandleFunc("/update", myHandler.AuthCookie(myHandler.UpdateHandler))
	http.HandleFunc("/bulk-del", myHandler.AuthCookie(myHandler.BulkDelHandler))
	http.HandleFunc("/api/tasks", myHandler.AuthCookie(myHandler.ApiTasksHandlers))

	slog.Info("サーバを起動します", slog.String("port", "8080"))
	if err := http.ListenAndServe(":8080", nil); err != nil {
		slog.Error("サーバが異常終了しました",
			slog.String("action", "server_start"),
			slog.Any("error_detail", err))
	}
	os.Exit(1)
}
