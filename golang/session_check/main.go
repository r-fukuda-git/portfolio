package main

import (
	"fmt"
	"net/http"
	"net/http/cookiejar"
	"net/url"
	"sync"
)

func CreateSessions(userId int, wg *sync.WaitGroup) {
	defer wg.Done()

	jar, _ := cookiejar.New(nil)
	client := &http.Client{
		Jar: jar,
	}

	baseurl := "http://localhost:8082"
	username := fmt.Sprintf("testuser%d", userId)
	password := "password123"

	// テストユーザーのサインアップ処理
	signUpVal := url.Values{"username": {username}, "password": {password}}
	client.PostForm(baseurl+"/signup", signUpVal)

	// テストユーザーのログイン処理
	loginVal := url.Values{"username": {username}, "password": {password}}
	resp, err := client.PostForm(baseurl+"/login", loginVal)
	if err != nil {
		fmt.Printf("User %d: Login request failed: %v\n", userId, err)
		return
	}
	defer resp.Body.Close()

	// クッキーにセッションIDが付与されているか確認
	u, _ := url.Parse(baseurl)
	cookies := jar.Cookies(u)
	sessionToken := ""
	for _, c := range cookies {
		if c.Name == "session_id" {
			sessionToken = c.Value
			break
		}
	}

	if sessionToken == "" {
		fmt.Printf("User %d: Failed to get session cookie. (Login failed)\n", userId)
		return
	}
	fmt.Printf("User %d: Logged in. Token=%s...\n", userId, sessionToken[:8])

	// 初回アクセス発行
	resp, err = client.Get(baseurl + "/login")
	if err != nil {
		fmt.Printf("User %d: Error %v\n", userId, err)
		return
	}
	defer resp.Body.Close()

	fmt.Printf("User %d: Status %s: (Session Created)\n", userId, resp.Status)

	// 2回目以降のアクセス
	resp2, _ := client.Get(baseurl + "/login")
	defer resp2.Body.Close()
	fmt.Printf("User %d: Retry Access Success\n", userId)
}

func main() {
	var wg sync.WaitGroup
	numUsers := 100

	fmt.Printf("Start %d sessions...\n", numUsers)

	for i := 1; i <= numUsers; i++ {
		wg.Add(1)
		go CreateSessions(i, &wg)
	}
	wg.Wait()
	fmt.Println("All session test completed")
}
