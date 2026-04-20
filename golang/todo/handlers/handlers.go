package main

import (
	"log"
	"net/http"
	"strconv"
	"time"
	"todo/models"
)

// タスク追加ハンドラー(POST処理)
func (l *models.TaskList) AddHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodPost {
		// フォームからタイトルの値を取得
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

		// contextからuser_idを取得
		user_id := r.Context().Value("user_id").(int)

		// 作成日時を定義
		now := time.Now()

		// DBへ保存
		err = l.models.AddTask(user_id, title, completed, duration, now)
		if err != nil {
			http.Error(w, "保存失敗", http.StatusInternalServerError)
			return
		}
	}
	http.Redirect(w, r, "/", http.StatusSeeOther)
}

// タスク読み取りハンドラー
func (l *models.TaskList) ReadHandler(w http.ResponseWriter, r *http.Request) {
	// contextからuser_idを取得
	user_id := r.Context().Value("user_id").(int)

	// ページネーションの設定
	// クエリパラメータからpageを取得するように設定
	pageStr := r.URL.Query().Get("page")
	// デフォルトを1ページ目として定義
	page := 1
	if pageStr != "" {
		p, err := strconv.Atoi(pageStr)
		// エラーがない＝変換成功、かつページが1以上だった場合、その数字をページとして採用
		if err == nil && p > 0 {
			page = p
		}
	}

	// 検索・フィルター設定
	limit := 10
	offset := (page - 1) * limit
	keyword := r.URL.Query().Get("q")
	statusStr := r.URL.Query().Get("status")

	tasks, err := l.models.ReadTask(user_id, keyword, statusStr, limit, offset)
	if err != nil {
		log.Println("DB取得エラー", err)
		http.Error(w, "データ取得失敗", http.StatusInternalServerError)
		return
	}

}
