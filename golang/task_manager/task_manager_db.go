package main

import (
	"bufio"
	"database/sql"
	"errors"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/joho/godotenv"
	_ "github.com/lib/pq"
)

func (l *TaskList) AddTask(title string, completed bool, duration int) error {
	if title == "" {
		return errors.New("空")
	}

	query := `INSERT INTO tasks (title, completed, duration) VALUES ($1, $2, $3)`
	_, err := l.db.Exec(query, title, completed, duration)
	return err
}

func (l *TaskList) GetAllTasks() ([]Task, error) {
	rows, err := l.db.Query("SELECT id, title, completed, duration FROM tasks ORDER by id")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var tasks []Task
	for rows.Next() {
		var t Task
		if err := rows.Scan(&t.ID, &t.Title, &t.Completed, &t.Duration); err != nil {
			return nil, err
		}
		tasks = append(tasks, t)
	}
	return tasks, nil
}

func saveToCloud(t Task, ch chan<- string) {
	time.Sleep(time.Duration(t.Duration) * time.Second)
	ch <- fmt.Sprintf("Task %d %s (所要時間: %d秒)のタスクをクラウドに同期しました。", t.ID, t.Title, t.Duration)
}

func main() {
	enverr := godotenv.Load()
	if enverr != nil {
		log.Fatal(".envの読み込みに失敗しました")
	}

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

	scanner := bufio.NewScanner(os.Stdin)
	fmt.Println("--- タスク登録モード (終了するには Enter だけ押してください) ---")

	for {
		fmt.Println("追加したいタスクは？")
		scanner.Scan()
		title := scanner.Text()

		if title == "" {
			fmt.Println("入力終了")
			break
		}

		if title == "q" {
			fmt.Println("入力終了")
			break
		}

		fmt.Println("何秒かかります？")
		var sec int
		fmt.Scanln(&sec)

		fmt.Println("タスクの完了状況は？")
		scanner.Scan()
		inputComp := scanner.Text()
		comp := inputComp == "true"

		if err := myTasks.AddTask(title, comp, sec); err != nil {
			fmt.Println("エラー：", err)
		}

		fmt.Printf("「%s」を仮登録しました。\n", title)
	}

	latestTask, err := myTasks.GetAllTasks()
	if err != nil {
		fmt.Printf("タスク取得に失敗しました.%v", err)
	}
	myTasks.tasks = latestTask

	for _, t := range myTasks.tasks {
		fmt.Println(t, t.ToString())
	}

	stats := map[string]int{
		"total": len(myTasks.tasks),
	}
	fmt.Printf("\n統計: 合計 %d 件 \n", stats["total"])

	fmt.Println("バックグラウンド処理開始")
	startTime := time.Now()
	msgChan := make(chan string)
	completedCount := 0

	for _, t := range myTasks.tasks {
		if t.Completed {
			completedCount++
			go saveToCloud(t, msgChan)
		}
	}
	fmt.Printf("\n%d 件の同期処理を実施する\n", completedCount)
	fmt.Printf("\n%d件の完了済みタスクを同期中\n", completedCount)

	for i := 0; i < completedCount; i++ {
		msg := <-msgChan
		if i%10000 == 0 {
			fmt.Printf("\r進捗: %d / %d 完了...\n", i, completedCount)
		}
		fmt.Println("通知", msg)
	}

	finishTime := time.Since(startTime)
	fmt.Printf("全て完了（合計時間:%v）\n", finishTime)

}
