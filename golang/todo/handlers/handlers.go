package handlers

import (
	"context"
	"database/sql"
	"encoding/json"
	"log/slog"
	"net/http"
	"strconv"
	"text/template"
	"time"

	"todo/common"
	"todo/models"

	"github.com/lib/pq"
	"golang.org/x/crypto/bcrypt"
)

// ハンドラー用構造体
type TaskHandler struct {
	Models *models.TaskList
}

// タスク追加ハンドラー(POST処理)
func (h *TaskHandler) AddHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodPost {
		// フォームからタイトルの値を取得
		title := r.FormValue("title")

		// string型からbool型へ変換
		completed, err := common.GetFormBool(r, "completed")
		if err != nil {
			slog.Error("無効なステータスです",
				slog.Bool("action", false),
				slog.Any("error_detail", err))

			http.Error(w, "無効なリクエストです", http.StatusBadRequest)
			return
		}

		// string型からint型へ変換
		duration, err := common.GetFormInt(r, "duration")
		if err != nil {
			slog.Error("無効なステータスです",
				slog.Int("action", 0),
				slog.Any("error_detail", err))

			http.Error(w, "無効なリクエストです", http.StatusBadRequest)
			return
		}

		// contextからuser_idを取得
		user_id := r.Context().Value("user_id").(int)

		// 作成日時を定義
		now := time.Now()

		// DBへ保存
		err = h.Models.AddTask(user_id, title, completed, duration, now)
		if err != nil {
			slog.Error("タスクの保存に失敗しました",
				slog.Int("user_id", user_id),
				slog.Any("error_detail", err),
				slog.String("handler", "AddHandler"))
		}
	}
	http.Redirect(w, r, "/", http.StatusSeeOther)
}

// タスク読み取りハンドラー(GET)
func (h *TaskHandler) ReadHandler(w http.ResponseWriter, r *http.Request) {
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

	tasks, err := h.Models.ReadTask(user_id, keyword, statusStr, limit, offset)
	if err != nil {
		slog.Error("データ取得に失敗しました",
			slog.Any("error_detail", err),
			slog.Int("user_id", user_id),
			slog.String("handler", "ReadHandler"))

		http.Error(w, "データ取得失敗", http.StatusInternalServerError)
		return
	}

	// HTMLに渡すデータの準備
	var totalCount, completedCount int
	// CASE文を使って、「全部の数」と「完了した数」を同時に計算
	query := `SELECT COUNT(id),COALESCE(SUM(CASE WHEN completed = true THEN 1 ELSE 0 END),0) FROM tasks WHERE user_id = $1`
	err = h.Models.DB.QueryRow(query, user_id).Scan(&totalCount, &completedCount)
	if err != nil {
		slog.Error("データ取得に失敗しました",
			slog.Any("error_detail", err),
			slog.Int("user_id", user_id),
			slog.String("handler", "ReadHandler"))
	}

	var created_at_time time.Time
	err = h.Models.DB.QueryRow(`SELECT created_at FROM tasks WHERE user_id = $1`, user_id).Scan(&created_at_time)
	if err != nil {
		if err == sql.ErrNoRows {
			slog.Error("データ0件です",
				slog.Any("error_detail", err),
				slog.Int("user_id", user_id),
				slog.String("handler", "ReadHandler"))
		} else {
			slog.Error("データ取得に失敗しました",
				slog.Any("error_detail", err),
				slog.Int("user_id", user_id),
				slog.String("handler", "ReadHandler"))
		}
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
		slog.Error("テンプレート読み込みエラー",
			slog.Any("error_detail", err),
			slog.Int("user_id", user_id),
			slog.String("handler", "ReadHandler"))

		http.Error(w, "システムエラーが発生", http.StatusInternalServerError)
		return
	}

	err = tmpl.Execute(w, Data)
	if err != nil {
		slog.Error("システム実行エラー",
			slog.Any("error_detail", err),
			slog.Int("user_id", user_id),
			slog.String("handler", "ReadHandler"))

		http.Error(w, "システムエラー", http.StatusInternalServerError)
		return
	}
}

// タスク更新ハンドラー
func (h *TaskHandler) UpdateHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodPost {
		user_id := r.Context().Value("user_id").(int)
		title := r.FormValue("title")

		completed, err := common.GetFormBool(r, "completed")
		if err != nil {
			slog.Error("無効な判定です",
				slog.Any("error_detail", err),
				slog.Int("user_id", user_id),
				slog.String("handler", "UpdateHandler"))

			http.Error(w, "無効な判定です", http.StatusInternalServerError)
			return
		}

		duration, err := common.GetFormInt(r, "duration")
		if err != nil {
			slog.Error("無効な判定です",
				slog.Any("error_detail", err),
				slog.Int("user_id", user_id),
				slog.String("handler", "UpdateHandler"))

			http.Error(w, "無効な数字です", http.StatusInternalServerError)
			return
		}

		id, err := common.GetFormInt(r, "id")
		if err != nil {
			slog.Error("無効な判定です",
				slog.Any("error_detail", err),
				slog.Int("user_id", user_id),
				slog.String("handler", "UpdateHandler"))

			http.Error(w, "無効な数字です", http.StatusInternalServerError)
			return
		}

		err = h.Models.UpdateTask(user_id, id, title, completed, duration)
		if err != nil {
			slog.Error("タスクの更新に失敗しました",
				slog.Any("error_detail", err),
				slog.Int("user_id", user_id),
				slog.String("handler", "UpdateHandler"))

			http.Error(w, "更新処理失敗", http.StatusInternalServerError)
			return
		}
	}
	http.Redirect(w, r, "/", http.StatusSeeOther)
}

// タスク削除ハンドラー
func (h *TaskHandler) DelHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodPost {
		user_id := r.Context().Value("user_id").(int)

		id, err := common.GetFormInt(r, "int")
		if err != nil {
			slog.Error("無効なステータスです",
				slog.Any("error_detail", err),
				slog.Int("user_id", user_id),
				slog.String("handler", "DelHandler"))

			http.Error(w, "無効な数字です", http.StatusInternalServerError)
			return
		}

		err = h.Models.DelTask(user_id, id)
		if err != nil {
			slog.Error("無効なステータスです",
				slog.Any("error_detail", err),
				slog.Int("user_id", user_id),
				slog.String("handler", "DelHandler"))

			http.Error(w, "削除失敗", http.StatusInternalServerError)
			return
		}
	}
	http.Redirect(w, r, "/", http.StatusSeeOther)
}

// 追加処理
// 一括処理タスクハンドラー
func (h *TaskHandler) BulkDelHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodPost {

		user_id := r.Context().Value("user_id").(int)

		// フォーム解析
		r.ParseForm()
		idStr := r.Form["ids"]

		//　フォームから入力された値のチェック
		if len(idStr) == 0 {
			http.Redirect(w, r, "/", http.StatusSeeOther)
			return
		}

		// 数字を入れる用の配列を用意
		var ids []int

		for _, idText := range idStr {
			id, err := strconv.Atoi(idText)
			if err != nil {
				slog.Error("無効なステータスです",
					slog.Any("error_detail", err),
					slog.Int("user_id", user_id),
					slog.String("handler", "BulkDelHandler"))
				return
			}
			ids = append(ids, id)
		}

		query := `DELETE FROM tasks WHERE user_id = $1 AND id = ANY($2::int[])`
		_, err := h.Models.DB.Exec(query, user_id, pq.Array(ids))
		if err != nil {
			slog.Error("実行エラー",
				slog.Any("error_detail", err),
				slog.Int("user_id", user_id),
				slog.String("handler", "BulkDelHandler"))

			http.Error(w, "一括削除失敗", http.StatusInternalServerError)
			return
		}
	}
	http.Redirect(w, r, "/", http.StatusSeeOther)
}

// API用ハンドラー
func (h *TaskHandler) ApiTasksHandlers(w http.ResponseWriter, r *http.Request) {
	// APIで表示するのは全件
	user_id := r.Context().Value("user_id").(int)
	tasks, err := h.Models.ReadTask(user_id, "", "", 100, 0)
	if err != nil {
		slog.Error("APIデータ取得失敗",
			slog.Any("error_detail", err),
			slog.Int("user_id", user_id),
			slog.String("handler", "ApiTasksHandlers"))
		http.Error(w, "APIデータ取得失敗", http.StatusInternalServerError)
		return
	}
	// ブラウザにJSONデータを送る内容を明示的に記載
	w.Header().Set("Content-Type", "application/json")

	// tasksをJSONに変換して、wに書き込み
	err = json.NewEncoder(w).Encode(tasks)
	if err != nil {
		slog.Error("JSON変換エラー",
			slog.Any("error_detail", err),
			slog.Int("user_id", user_id),
			slog.String("handler", "ApiTasksHandlers"))
		http.Error(w, "JSON変換エラー", http.StatusInternalServerError)
		return
	}
}

// サインアップ用ハンドラ-
func (h *TaskHandler) SignUpHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodGet {
		tmpl, err := template.ParseFiles("templates/signup.html")
		if err != nil {
			slog.Error("データ読み込み失敗",
				slog.Any("error_detail", err),
				slog.String("handler", "SignUpHandler"))

			http.Error(w, "データ読み込み失敗", http.StatusInternalServerError)
			return
		}
		err = tmpl.Execute(w, nil)
		if err != nil {
			slog.Error("データ表示エラー",
				slog.Any("error_detail", err),
				slog.String("handler", "SignUpHandler"))

			http.Error(w, "データ表示エラー", http.StatusInternalServerError)
			return
		}
		return
	}

	if r.Method == http.MethodPost {
		username := r.FormValue("username")
		password := r.FormValue("password")

		err := h.Models.SignupUser(username, password)
		if err != nil {
			if err == models.ErrUserAlreadyExists {
				slog.Error("重複登録の試行がありました",
					slog.Any("error_detail", err),
					slog.String("username", username),
					slog.String("handler", "SignUpHandler"))

				http.Error(w, err.Error(), http.StatusConflict)
				return
			}
			slog.Error("サインアップに失敗しました",
				slog.Any("error_detail", err),
				slog.String("username", username),
				slog.String("handler", "SignUpHandler"))
			http.Error(w, "サインアップに失敗しました", http.StatusInternalServerError)
			return
		}
		slog.Info("サインアップ完了", slog.String("username", username))
		http.Redirect(w, r, "/", http.StatusSeeOther)
	}
}

// ログイン時のクッキー処理用ハンドラー
func (h *TaskHandler) AuthCookie(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// クッキーの確認
		cookie, err := r.Cookie("session_id")
		if err != nil {
			slog.Error("Cookieが存在しません",
				slog.Any("error_detail", err),
				slog.String("handler", "AuthCookie"))
			http.Redirect(w, r, "/login", http.StatusSeeOther)
			return
		}

		// ログインしていれば、クッキーの中身を取得
		user_id, err := h.Models.GetUserIdToken(cookie.Value)
		if err != nil {
			slog.Error("不正または期限切れのセッション",
				slog.Any("error_detail", err),
				slog.Int("user_id", user_id),
				slog.String("handler", "AuthCookie"))
			http.Redirect(w, r, "/login", http.StatusSeeOther)
			return
		}

		// 次の処理へ渡す
		ctx := context.WithValue(r.Context(), "user_id", user_id)
		next(w, r.WithContext(ctx))
	}
}

// ログイン処理ハンドラー
func (h *TaskHandler) LoginHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodGet {
		tmpl, err := template.ParseFiles("templates/login.html")
		if err != nil {
			slog.Error("データ読み込みに失敗しました",
				slog.Any("error_detail", err),
				slog.String("handler", "LoginHandler"))

			http.Error(w, "データ読み込みに失敗しました", http.StatusInternalServerError)
			return
		}
		err = tmpl.Execute(w, nil)
		if err != nil {
			slog.Error("データ表示失敗しました",
				slog.Any("error_detail", err),
				slog.String("handler", "LoginHandler"))

			http.Error(w, "データ表示失敗しました", http.StatusInternalServerError)
			return
		}
		return
	}

	if r.Method == http.MethodPost {
		username := r.FormValue("username")
		password := r.FormValue("password")

		// errという箱にDBからのパスワードを取得
		var storeHash string
		err := h.Models.DB.QueryRow(`SELECT password_hash FROM users WHERE username = $1`, username).Scan(&storeHash)
		if err != nil {
			slog.Error("ユーザーが存在しません",
				slog.Any("error_detail", err),
				slog.String("handler", "LoginHandler"))

			http.Error(w, "ユーザーが存在しません", http.StatusUnauthorized)
			return
		}

		// DBと入力パスワードの照合
		err = bcrypt.CompareHashAndPassword([]byte(storeHash), []byte(password))
		if err != nil {
			slog.Error("ユーザー名かパスワードが違います",
				slog.Any("error_detail", err),
				slog.String("handler", "LoginHandler"))

			http.Error(w, "ユーザー名かパスワードが違います", http.StatusUnauthorized)
			return
		}
		// ログイン成功した人にセッショントークンを渡す
		// user_idをユーザー名から取得する
		user_id, err := h.Models.GetUserId(username)
		if err != nil {
			slog.Error("ユーザー名の取得に失敗しました。",
				slog.Any("error_detail", err),
				slog.Int("user_id", user_id),
				slog.String("handler", "LoginHandler"))
			http.Redirect(w, r, "/login", http.StatusSeeOther)
			return
		}
		// ユーザーに渡すためのトークンを作成
		token, err := models.GenerateSessionToken()
		if err != nil {
			slog.Error("トークン作成失敗",
				slog.Any("error_detail", err),
				slog.Int("user_id", user_id),
				slog.String("handler", "LoginHandler"))
			http.Error(w, "トークン作成失敗", http.StatusInternalServerError)
			return
		}
		// DBにuser_idとtokenを記録
		err = h.Models.CreateSession(user_id, token)
		if err != nil {
			slog.Error("ユーザー名の取得に失敗しました。",
				slog.Any("error_detail", err),
				slog.Int("user_id", user_id),
				slog.String("handler", "LoginHandler"))
			http.Error(w, "DBへ登録失敗しました", http.StatusInternalServerError)
			return
		}

		// クッキーの発行
		cookie := &http.Cookie{
			Name:     "session_id",
			Value:    token,
			Path:     "/",
			HttpOnly: true,
			MaxAge:   120, // 有効期限を設定
		}
		http.SetCookie(w, cookie)
		http.Redirect(w, r, "/", http.StatusSeeOther)
	}
}

// ログアウト処理ハンドラー
// ログアウト：ブラウザが持っているsession_idを破棄して、未ログイン状態にすること
func (h *TaskHandler) LogoutHandler(w http.ResponseWriter, r *http.Request) {
	// クッキーの破棄
	cookie := &http.Cookie{
		Name:     "session_id",
		Value:    "",
		Path:     "/",
		HttpOnly: true,
		MaxAge:   -1, // 有効期限を即座に破棄する
	}
	http.SetCookie(w, cookie)
	http.Redirect(w, r, "/", http.StatusSeeOther)
}
