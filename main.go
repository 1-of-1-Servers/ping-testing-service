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
	// The CORS header is already set by the middleware

	if err := json.NewEncoder(w).Encode(response); err != nil {
		http.Error(w, "Failed to encode response", http.StatusInternalServerError)
		return
	}
}

// withCORS is a middleware that alows all CORS requests.
func withCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Allow all origins
		w.Header().Set("Access-Control-Allow-Origin", "*")
		// Handle preflight requests
		if r.Method == http.MethodOptions {
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type")
			w.WriteHeader(http.StatusOK)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func main() {
	http.Handle("/ping", withCORS(http.HandlerFunc(pingHandler)))

	port := "{{APP_PORT}}"
	if port == "{{APP_PORT}}" {
		port = "8080"
	}

	log.Printf("Server is running on port %s...", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
