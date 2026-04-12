package main

import (
	"bufio"
	"errors"
	"fmt"
	"os"
	"time"
)

func (l *TaskListLocal) AddTask(title string, completed bool, duration int) error {
	if title == "" {
		return errors.New("空")
	}
	l.mu.Lock()
	defer l.mu.Unlock()

	id := len(l.tasks) + 1
	l.tasks = append(l.tasks, Task{ID: id, Title: title, Completed: completed, Duration: duration})
	return nil
}

func saveToCloudLocal(t Task, ch chan<- string) {
	time.Sleep(time.Duration(t.Duration) * time.Second)
	ch <- fmt.Sprintf("Task %d %s (所要時間: %d秒)のタスクをクラウドに同期しました。", t.ID, t.Title, t.Duration)
}

func mainLocal() {
	myTasks := TaskListLocal{
		tasks: []Task{
			{ID: 1, Title: "Goの基礎を学ぶの設計図を書くよ", Completed: true, Duration: 5},
			{ID: 2, Title: "テストを実施します", Completed: false, Duration: 2},
			{ID: 3, Title: "テストをしているよ", Completed: true, Duration: 15},
			{ID: 4, Title: "テスト完了したらデプロイするよ", Completed: true, Duration: 7},
			{ID: 5, Title: "デプロイ中・・", Completed: true, Duration: 10},
		},
	}

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
		var comp bool
		fmt.Scanln(&comp)

		if err := myTasks.AddTask(title, comp, sec); err != nil {
			fmt.Println("エラー：", err)
		}

		fmt.Printf("「%s」を仮登録しました。\n", title)
	}

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
			go saveToCloudLocal(t, msgChan)
		}
	}
	fmt.Printf("\n%d 件の同期処理を実施する\n", completedCount)
	fmt.Printf("\n%d件の完了済みタスクを同期中\n", completedCount)

	for i := 0; i < completedCount; i++ {
		msg := <-msgChan
		fmt.Println("通知", msg)
	}

	finishTime := time.Since(startTime)
	fmt.Printf("全て完了（合計時間:%v）\n", finishTime)

}
