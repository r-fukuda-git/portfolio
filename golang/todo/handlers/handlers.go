package main

import (
	"encoding/json"
	"log"
	"net/http"
	"strconv"
	"text/template"
	"time"
	"todo/common"
	"todo/models"

	"github.com/lib/pq"
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

		id, err := common.GetFormInt(r, "int")
		if err != nil {
			log.Println(err)
			http.Error(w, "無効な数字です", http.StatusInternalServerError)
			return
		}

		err = l.models.UpdateTask(user_id, id, title, completed, duration)
		if err != nil {
			http.Error(w, "更新処理失敗", http.StatusInternalServerError)
			return
		}
	}
	http.Redirect(w, r, "/", http.StatusSeeOther)
}

// タスク削除ハンドラー
func (l *models.TaskList) DelHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodPost {
		user_id := r.Context().Value("user_id").(int)

		id, err := common.GetFormInt(w, "int")
		if err != nil {
			log.Println(err)
			http.Error(w, "無効な数字です", http.StatusInternalServerError)
			return
		}

		err = l.models.DelTask(user_id, id)
		if err != nil {
			log.Println(err)
			http.Error(w, "削除失敗", http.StatusInternalServerError)
			return
		}
	}
	http.Redirect(w, r, "/", http.StatusSeeOther)
}

// 追加処理
// 一括処理タスクハンドラー
func (l *models.TaskList) BulkDelHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodPost {

		// フォーム解析
		r.ParseForm()
		idStr := r.Form["ids"]

		//　フォームから入力された値のチェック
		if len(idStr) == 0 {
			http.Redirect(w, r, "/", http.StatusSeeOther)
			return
		}

		// 数字を入れる用の配列を用意
		var ids int

		for _, idText := range idStr {
			id, err := strconv.Atoi(idText)
			if err != nil {
				log.Println(err)
				return
			}
			ids = append(ids, id)
		}

		query := `DELETE FROM tasks WHERE user_id = $1 AND id = ANY($2)`
		_, err := l.DB.Exec(query, user_id, pq.Array(ids))
		if err != nil {
			log.Println(err)
			http.Error(w, "一括削除失敗", http.StatusInternalServerError)
			return
		}
	}
	http.Redirect(w, r, "/", http.StatusSeeOther)
}

// API用ハンドラー
func (l *models.TaskList) ApiTasksHandlers(w http.ResponseWriter, r *http.Request) {
	// APIで表示するのは全件
	user_id := r.Context().Value("user_id").(int)
	tasks, err := l.models.ReadTask(user_id, "", "", 100, 0)
	if err != nil {
		log.Println(err)
		http.Error(w, "APIデータ取得失敗", http.StatusInternalServerError)
		return
	}
	// ブラウザにJSONデータを送る内容を明示的に記載
	w.Header().Set("Content-Type", "application/json")

	// tasksをJSONに変換して、wに書き込み
	err = json.NewEncoder(w).Encode(tasks)
	if err != nil {
		log.Println(err)
		http.Error(w, "JSON変換エラー", http.StatusInternalServerError)
		return
	}
}

// サインアップ用ハンドラ-
func (l *models.TaskList) SignUpHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodGet {
		tmpl, err := template.ParseFiles("templates/signup.html")
		if err != nil {
			log.Println(err)
			http.Error(w, "データ読み込み失敗", http.StatusInternalServerError)
			return
		}
		err = tmpl.Execute(w, nil)

		if err != nil {
			log.Println(err)
			http.Error(w, "データ表示エラー", http.StatusInternalServerError)
			return
		}
		return
	}

	if r.Method == http.MethodPost {
		username := r.FormValue("username")
		password := r.FormValue("password")

		err := l.models.SignupUser(username, password)
		log.Printf("サインアップ完了:%v", username)
		if err != nil {
			log.Println(err)
			http.Error(w, "サインアップに失敗しました", http.StatusInternalServerError)
			return
		}
		http.Redirect(w, r, "/", http.StatusSeeOther)
	}
}

// ログイン時のクッキー処理用ハンドラー
func (l *models.TaskList) AuthCookie(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {

		// クッキーの確認

	}
}
