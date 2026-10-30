// upupa_backend/internal/api/log_handlers.go
package api

import (
	"encoding/json"
	"log"
	"net/http"
	"time"

	"upupa_backend/pkg/models"
)

type statusResponseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (w *statusResponseWriter) WriteHeader(code int) {
	w.statusCode = code
	w.ResponseWriter.WriteHeader(code)
}

type LogRepository interface {
	SaveLog(method, url string, status int, ip, referer string, createdAt time.Time) error
	GetLogs(limit int) ([]models.RequestLog, error)
}

func RequestLoggerMiddleware(logRepo LogRepository) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			startTime := time.Now()

			wrappedWriter := &statusResponseWriter{
				ResponseWriter: w,
				statusCode:     http.StatusOK,
			}

			next.ServeHTTP(wrappedWriter, r)

			ip := r.RemoteAddr
			if forwardedIP := r.Header.Get("X-Forwarded-For"); forwardedIP != "" {
				ip = forwardedIP
			}

			referer := r.Header.Get("Referer")
			if referer == "" {
				referer = "N/A"
			}

			go func(method, url, ip, referer string, status int, createdAt time.Time) {
				err := logRepo.SaveLog(method, url, status, ip, referer, createdAt)
				if err != nil {
					log.Printf("Error saving request log: %v", err)
				}
			}(r.Method, r.URL.String(), ip, referer, wrappedWriter.statusCode, startTime)
		})
	}
}

func GetLogsHandler(logRepo LogRepository) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")

		logs, err := logRepo.GetLogs(100)
		if err != nil {
			http.Error(w, `{"error": "Failed to fetch logs"}`, http.StatusInternalServerError)
			return
		}

		json.NewEncoder(w).Encode(logs)
	}
}
