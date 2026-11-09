// upupa_backend/internal/features/auth/impersonate.go
package auth

import (
	"encoding/json"
	"net/http"
)

type ImpersonateRequest struct {
	UserID string `json:"user_id"`
}

func ImpersonateHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req ImpersonateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.UserID == "" {
		http.Error(w, "Invalid request body or user_id", http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"token":         "mock_impersonation_jwt_token",
		"refresh_token": "mock_impersonation_refresh_token",
		"record": map[string]interface{}{
			"id":    req.UserID,
			"email": "impersonated_user@example.com",
		},
	})
}
