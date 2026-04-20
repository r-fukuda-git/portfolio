package main

import (
	"log"
	"net/http"
	"strconv"
	"text/template"
	"time"
	"todo/common"
	"todo/models"
)

// タスク追加ハンドラー(POST処理)
func (l *models.TaskList) AddHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodPost {
		// フォームからタイトルの値を取得
		title := r.FormValue("title")

		// string型からbool型へ変換
		completed, err := common.GetFormBool(r, "completed")
		if err != nil {
			log.Println(err)
			http.Error(w, "無効なステータスです", http.StatusBadRequest)
			return
		}

		// string型からint型へ変換
		duration, err := common.GetFormInt(r, "duration")
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

// タスク読み取りハンドラー(GET)
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
		log.Printf("DB取得エラー:%v", err)
		http.Error(w, "データ取得失敗", http.StatusInternalServerError)
		return
	}

	// HTMLに渡すデータの準備
	var totalCount, completedCount int
	// CASE文を使って、「全部の数」と「完了した数」を同時に計算
	query := `SELECT COUNT(id),COALESE(SUM(CASE WHEN completed = true THEN 1 ELSE 0 END),0) FROM tasks WHERE user_id = $1`
	_, err = l.DB.QueryRow(query, user_id).Scan(&totalCount, &completedCount)
	if err != nil {
		log.Printf("データ取得失敗:%v", err)
	}

	var created_at_time time.Time
	_, err = l.DB.QueryRow(`SELECT created_at FROM tasks WHERE user_id = $1`).Scan(&created_at_time)
	if err != nil {
		log.Printf("データ取得失敗:%v", err)
	}

	pendingCount := totalCount - completedCount

	Data := models.TemplateData{
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
		log.Printf("テンプレート読み込みエラー:%v", err)
		http.Error(w, "システムエラーが発生", http.StatusInternalServerError)
		return
	}

	err = tmpl.Execute(w, Data)
	if err != nil {
		log.Printf("実行エラー:%v", err)
		http.Error(w, "システムエラー", http.StatusInternalServerError)
		return
	}
}

// タスク更新ハンドラー
func (l *models.TaskList) UpdateHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodPost {
		user_id := r.Context().Value("user_id").(int)
		title := r.FormValue("title")

		completed, err := common.GetFormBool(r, "completed")
		if err != nil {
			log.Println(err)
			http.Error(w, "無効な判定です", http.StatusInternalServerError)
			return
		}

		duration, err := common.GetFormInt(r, "duration")
		if err != nil {
			log.Println(err)
			http.Error(w, "無効な数字です", http.StatusInternalServerError)
			return
		}
	}
}
