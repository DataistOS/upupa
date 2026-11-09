package realtime

import (
	"fmt"
	"net/http"
	"time"

	"github.com/go-chi/chi/v5"
)

func RegisterRoutes(r chi.Router) {
	r.Route("/realtime", func(r chi.Router) {
		r.Get("/", handleSSEConnection)
	})
}

func handleSSEConnection(w http.ResponseWriter, r *http.Request) {
	flusher, ok := w.(http.Flusher)
	if !ok {
		http.Error(w, "Streaming unsupported!", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	client := &Client{
		ID:     fmt.Sprintf("%d", time.Now().UnixNano()),
		Send:   make(chan []byte, 256),
		Topics: make(map[string]bool),
	}

	GlobalHub.register <- client
	defer func() {
		GlobalHub.unregister <- client
	}()

	fmt.Fprintf(w, "event: connected\ndata: {\"clientId\": \"%s\"}\n\n", client.ID)
	flusher.Flush()

	ticker := time.NewTicker(15 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-r.Context().Done():
			return

		case message, ok := <-client.Send:
			if !ok {
				return
			}
			fmt.Fprintf(w, "data: %s\n\n", message)
			flusher.Flush()

		case <-ticker.C:
			fmt.Fprintf(w, ":ping\n\n")
			flusher.Flush()
		}
	}
}