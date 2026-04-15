package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"
	"os"
	"runtime"
	"time"

	"github.com/joho/godotenv"
	_ "github.com/lib/pq"
)

var db *sql.DB

func setup(dbDriver string, dsn string) (*sql.DB, error) {
	conn, err := sql.Open(dbDriver, dsn)
	if err != nil {
		return nil, err
	}
	return conn, err
}

func latencyLogger(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()

		next.ServeHTTP(w, r)

		elapsed := time.Since(start)
		log.Printf("[latency] %s %s took %s\n", r.Method, r.URL.RequestURI(), elapsed)
	})
}

func handleRoot(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.NotFound(w, r)
		return
	}
	reqType := r.URL.Query().Get("type")
	if reqType == "old" {
		executeOldWay(w, r)
	} else {
		executeNewway(w, r)
	}
}

func executeNewway(w http.ResponseWriter, r *http.Request) {
	startMem := getMemUsage()
	queryStart := time.Now()

	var count int
	err := db.QueryRowContext(r.Context(), "SELECT COUNT(id) FROM tasks").Scan(&count)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	queryElapsed := time.Since(queryStart)
	log.Printf("DB Query - NEW] SELECT COUNT took %s", queryElapsed)

	html := fmt.Sprintf("[New Way] Total count: %d", count)
	w.Write([]byte(html))

	endMem := getMemUsage()
	log.Printf("[Memory Footprint - NEW] Allocation: %v KB", (endMem-startMem)/1024)
}

func executeOldWay(w http.ResponseWriter, r *http.Request) {
	startMem := getMemUsage()
	queryStart := time.Now()

	rows, err := db.QueryContext(r.Context(), "SELECT id FROM tasks LIMIT 100000")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	type Record struct {
		ID int
	}
	var records []Record
	for rows.Next() {
		var rec Record
		if err := rows.Scan(&rec.ID); err != nil {
			continue
		}
		records = append(records, rec)
	}
	count := len(records)

	queryElapsed := time.Since(queryStart)
	log.Printf("DB Query - OLD] SELECT COUNT took %s", queryElapsed)

	html := fmt.Sprintf("[OLD Way] Total count: %d", count)
	w.Write([]byte(html))

	endMem := getMemUsage()
	log.Printf("[Memory Footprint - OLD] Allocation: %v KB", (endMem-startMem)/1024)
}

func getMemUsage() uint64 {
	runtime.GC()
	var m runtime.MemStats
	runtime.ReadMemStats(&m)
	return m.Alloc
}

func main() {
	_ = godotenv.Load()

	host := os.Getenv("DB_HOST")
	port := os.Getenv("DB_PORT")
	user := os.Getenv("DB_USER")
	pass := os.Getenv("DB_PASSWORD")
	dbname := os.Getenv("DB_NAME")

	dbDriver := "postgres"
	dsn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable", host, port, user, pass, dbname)

	var err error
	db, err = setup(dbDriver, dsn)
	if err != nil {
		log.Fatalln(err)
	}
	defer db.Close()

	mux := http.NewServeMux()
	mux.HandleFunc("/", handleRoot)

	loggedMux := latencyLogger(mux)
	log.Println("Server starting on :8080...")
	log.Fatal(http.ListenAndServe(":8080", loggedMux))

}
