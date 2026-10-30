// upupa_backend/internal/store/log_store.go
package store

import (
	"time"
	"upupa_backend/pkg/models"
)

func (s *SQLiteStore) InitLogTable() error {
	query := `
	CREATE TABLE IF NOT EXISTS request_logs (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		method TEXT NOT NULL,
		url TEXT NOT NULL,
		status INTEGER NOT NULL,
		ip TEXT,
		referer TEXT,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);`
	_, err := s.db.Exec(query)
	return err
}

func (s *SQLiteStore) SaveLog(method, url string, status int, ip, referer string, createdAt time.Time) error {
	query := `INSERT INTO request_logs (method, url, status, ip, referer, created_at) VALUES (?, ?, ?, ?, ?, ?)`
	_, err := s.db.Exec(query, method, url, status, ip, referer, createdAt)
	return err
}

func (s *SQLiteStore) GetLogs(limit int) ([]models.RequestLog, error) {
	rows, err := s.db.Query(`SELECT id, method, url, status, ip, referer, created_at FROM request_logs ORDER BY id DESC LIMIT ?`, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var logs []models.RequestLog
	for rows.Next() {
		var l models.RequestLog
		if err := rows.Scan(&l.ID, &l.Method, &l.URL, &l.Status, &l.IP, &l.Referer, &l.CreatedAt); err != nil {
			continue
		}
		logs = append(logs, l)
	}
	return logs, nil
}
