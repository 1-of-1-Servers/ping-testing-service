package main

import (
	"encoding/json"
	"log"
	"net/http"
	"time"
)

type PingResponse struct {
	Message    string    `json:"message"`
	ServerTime time.Time `json:"server_time"`
}

func pingHandler(w http.ResponseWriter, r *http.Request) {
	response := PingResponse{
		Message:    "pong",
		ServerTime: time.Now(),
	}

	w.Header().Set("Content-Type", "application/json")

	if err := json.NewEncoder(w).Encode(response); err != nil {
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
		return
	}
}

func main() {
	http.HandleFunc("/ping", pingHandler)

	port := "{{APP_PORT}}"

	if port == "{{APP_PORT}}" {
		port = "8080"
	}

	log.Printf("Server is running on port %s...", port)

	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
