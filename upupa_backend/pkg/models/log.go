// upupa_backend/pkg/models/log.go
package models

import "time"

type RequestLog struct {
	ID        int64     `json:"id"`
	Method    string    `json:"method"`
	URL       string    `json:"url"`
	Status    int       `json:"status"`
	IP        string    `json:"ip"`
	Referer   string    `json:"referer"`
	CreatedAt time.Time `json:"created_at"`
}
