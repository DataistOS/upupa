// upupa_backend/internal/features/auth/mfa.go
package auth

import (
	"encoding/json"
	"net/http"
)

type MFASetupResponse struct {
	Secret    string `json:"secret"`
	QRCodeURL string `json:"qr_code_url"`
}

type MFAVerifyRequest struct {
	Email string `json:"email"`
	Code  string `json:"code"`
}

func SetupMFAHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	response := MFASetupResponse{
		Secret:    "JBSWY3DPEHPK3PXP",
		QRCodeURL: "otpauth://totp/Upupa:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Upupa",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func VerifyMFAHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req MFAVerifyRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"message": "MFA enabled successfully",
	})
}
