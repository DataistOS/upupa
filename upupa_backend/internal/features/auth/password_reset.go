// upupa_backend/internal/features/auth/password_reset.go
package auth

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"log"
	"net/http"
	"time"

	"upupa_backend/internal/store"

	"golang.org/x/crypto/bcrypt"
)

type passwordResetRequest struct {
	Email string `json:"email"`
}

type passwordResetConfirm struct {
	Token       string `json:"token"`
	NewPassword string `json:"new_password"`
}

type PasswordResetHandler struct {
	Users      store.UserRepository
	ResetStore store.PasswordResetStore
}

func NewPasswordResetHandler(users store.UserRepository, resetStore store.PasswordResetStore) *PasswordResetHandler {
	return &PasswordResetHandler{
		Users:      users,
		ResetStore: resetStore,
	}
}

func (h *PasswordResetHandler) RequestPasswordResetHandler(w http.ResponseWriter, r *http.Request) {
	var req passwordResetRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondWithError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if req.Email == "" {
		h.respondWithError(w, http.StatusBadRequest, "Email is required")
		return
	}

	user, err := h.Users.GetByEmail(req.Email)
	if err != nil || user == nil {
		h.respondWithJSON(w, http.StatusOK, map[string]string{
			"message": "If an account with this email exists, a password reset link has been generated.",
		})
		return
	}

	tokenBytes := make([]byte, 32)
	_, err = rand.Read(tokenBytes)
	if err != nil {
		log.Printf("Error generating reset token: %v", err)
		h.respondWithError(w, http.StatusInternalServerError, "Failed to process request")
		return
	}
	token := hex.EncodeToString(tokenBytes)
	expiresAt := time.Now().Add(15 * time.Minute)

	err = h.ResetStore.CreatePasswordResetToken(req.Email, token, expiresAt)
	if err != nil {
		log.Printf("Error saving reset token: %v", err)
		h.respondWithError(w, http.StatusInternalServerError, "Failed to process request")
		return
	}

	resetLink := "http://127.0.0.1:8888/api/v1/auth/password-reset-confirm?token=" + token
	log.Println("==================================================")
	log.Printf("[LOCAL EMAIL SIMULATION] Password Reset Link for %s:", req.Email)
	log.Println(resetLink)
	log.Println("==================================================")

	h.respondWithJSON(w, http.StatusOK, map[string]string{
		"message": "Password reset link generated. Check server console.",
	})
}

func (h *PasswordResetHandler) ConfirmPasswordResetHandler(w http.ResponseWriter, r *http.Request) {
	var req passwordResetConfirm
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondWithError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if req.Token == "" || req.NewPassword == "" {
		h.respondWithError(w, http.StatusBadRequest, "Token and new password are required")
		return
	}

	email, err := h.ResetStore.GetEmailByToken(req.Token)
	if err != nil {
		h.respondWithError(w, http.StatusBadRequest, "Invalid or expired password reset token")
		return
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		log.Printf("Error hashing new password: %v", err)
		h.respondWithError(w, http.StatusInternalServerError, "Failed to update password")
		return
	}

	err = h.ResetStore.UpdateUserPassword(email, string(hashedPassword))
	if err != nil {
		log.Printf("Error updating user password: %v", err)
		h.respondWithError(w, http.StatusInternalServerError, "Failed to update password")
		return
	}

	_ = h.ResetStore.DeletePasswordResetToken(req.Token)

	h.respondWithJSON(w, http.StatusOK, map[string]string{
		"message": "Password has been successfully reset.",
	})
}

func (h *PasswordResetHandler) respondWithError(w http.ResponseWriter, code int, message string) {
	h.respondWithJSON(w, code, map[string]string{"error": message})
}

func (h *PasswordResetHandler) respondWithJSON(w http.ResponseWriter, code int, payload interface{}) {
	response, _ := json.Marshal(payload)
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	w.Write(response)
}
