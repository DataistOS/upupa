// upupa_backend/internal/features/auth/handlers.go
package auth

import (
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"strings"

	"upupa_backend/internal/store"
	"upupa_backend/pkg/auth"
	"upupa_backend/pkg/models"

	"golang.org/x/crypto/bcrypt"
)

type registerRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type loginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type authResponse struct {
	Token string      `json:"token"`
	User  models.User `json:"user"`
}

type Handler struct {
	Users store.UserRepository
}

func NewHandler(users store.UserRepository) *Handler {
	return &Handler{
		Users: users,
	}
}

func (h *Handler) RegisterHandler(w http.ResponseWriter, r *http.Request) {
	var req registerRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondWithError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if req.Email == "" || req.Password == "" {
		h.respondWithError(w, http.StatusBadRequest, "Email and password are required")
		return
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		log.Printf("Error hashing password: %v", err)
		h.respondWithError(w, http.StatusInternalServerError, "Failed to process request")
		return
	}

	createdUser, err := h.Users.Register(req.Email, string(hashedPassword))
	if err != nil {
		if strings.Contains(err.Error(), "already exists") {
			h.respondWithError(w, http.StatusConflict, err.Error())
			return
		}
		log.Printf("Error registering user: %v", err)
		h.respondWithError(w, http.StatusInternalServerError, "Failed to register user")
		return
	}

	if createdUser != nil {
		createdUser.PasswordHash = ""
	}

	token, err := auth.GenerateJWT(createdUser.ID)
	if err != nil {
		log.Printf("Error generating JWT: %v", err)
		h.respondWithError(w, http.StatusInternalServerError, "Failed to generate token")
		return
	}

	h.respondWithJSON(w, http.StatusCreated, authResponse{
		Token: token,
		User:  *createdUser,
	})
}

func (h *Handler) LoginHandler(w http.ResponseWriter, r *http.Request) {
	var req loginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondWithError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	user, err := h.Users.GetByEmail(req.Email)
	if err != nil {
		if err == sql.ErrNoRows {
			h.respondWithError(w, http.StatusUnauthorized, "Invalid email or password")
			return
		}
		log.Printf("Error retrieving user: %v", err)
		h.respondWithError(w, http.StatusInternalServerError, "Server error during login")
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		h.respondWithError(w, http.StatusUnauthorized, "Invalid email or password")
		return
	}

	user.PasswordHash = ""

	token, err := auth.GenerateJWT(user.ID)
	if err != nil {
		log.Printf("Error generating JWT: %v", err)
		h.respondWithError(w, http.StatusInternalServerError, "Failed to generate token")
		return
	}

	h.respondWithJSON(w, http.StatusOK, authResponse{
		Token: token,
		User:  *user,
	})
}

func (h *Handler) respondWithError(w http.ResponseWriter, code int, message string) {
	h.respondWithJSON(w, code, map[string]string{"error": message})
}

func (h *Handler) respondWithJSON(w http.ResponseWriter, code int, payload interface{}) {
	response, _ := json.Marshal(payload)
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	w.Write(response)
}
