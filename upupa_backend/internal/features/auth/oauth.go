// upupa_backend/internal/features/auth/oauth.go
package auth

import (
	"encoding/json"
	"net/http"
)

type OAuthUrlResponse struct {
	URL string `json:"url"`
}

type OAuthAuthRequest struct {
	Provider string `json:"provider"`
	Code     string `json:"code"`
}

func GetOAuthURLHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	provider := r.URL.Query().Get("provider")
	if provider == "" {
		http.Error(w, "Provider is required", http.StatusBadRequest)
		return
	}

	var authURL string
	switch provider {
	case "google":
		authURL = "https://accounts.google.com/o/oauth2/v2/auth?response_type=code&client_id=YOUR_GOOGLE_CLIENT_ID&redirect_uri=http://localhost:8090/api/auth/oauth2/callback&scope=email%20profile"
	case "github":
		authURL = "https://github.com/login/oauth/authorize?client_id=YOUR_GITHUB_CLIENT_ID&redirect_uri=http://localhost:8090/api/auth/oauth2/callback&scope=user:email"
	default:
		http.Error(w, "Unsupported provider", http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(OAuthUrlResponse{URL: authURL})
}

func OAuthAuthHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req OAuthAuthRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"token":         "mock-upupa-jwt-token-for-oauth",
		"refresh_token": "mock-upupa-refresh-token-for-oauth",
		"record": map[string]interface{}{
			"email":    "user@example.com",
			"provider": req.Provider,
		},
	})
}
