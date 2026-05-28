package main

import (
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"time"
)

type healthResponse struct {
	Status    string `json:"status"`
	Service   string `json:"service"`
	Version   string `json:"version"`
	Timestamp string `json:"timestamp"`
}

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	slog.SetDefault(logger)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	version := os.Getenv("APP_VERSION")
	if version == "" {
		version = "dev"
	}

	mux := http.NewServeMux()

	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/" {
			http.NotFound(w, r)
			return
		}
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		fmt.Fprintf(w, `<!DOCTYPE html>
<html lang="ja">
<head><meta charset="utf-8"><title>CI/CD Demo</title></head>
<body>
  <h1>Portfolio CI/CD Demo</h1>
  <p>Go sample app deployed via ECRからECSへ変更. %s</p>
  <ul>
    <li>Version: %s</li>
    <li>Time: %s</li>
  </ul>
</body>
</html>`, version, time.Now().UTC().Format(time.RFC3339))
	})

	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(healthResponse{
			Status:    "ok",
			Service:   "cicd-demo",
			Version:   version,
			Timestamp: time.Now().UTC().Format(time.RFC3339),
		})
	})

	addr := ":" + port
	slog.Info("server starting", slog.String("addr", addr), slog.String("version", version))
	if err := http.ListenAndServe(addr, mux); err != nil {
		slog.Error("server stopped", slog.Any("error", err))
		os.Exit(1)
	}
}
