// upupa_backend/internal/api/auth_handlers.go
package api

import (
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"strings"

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

func (a *API) RegisterHandler(w http.ResponseWriter, r *http.Request) {
	var req registerRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		a.respondWithError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if req.Email == "" || req.Password == "" {
		a.respondWithError(w, http.StatusBadRequest, "Email and password are required")
		return
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		log.Printf("Error hashing password: %v", err)
		a.respondWithError(w, http.StatusInternalServerError, "Failed to process request")
		return
	}

	createdUser, err := a.Users.Register(req.Email, string(hashedPassword))
	if err != nil {
		if strings.Contains(err.Error(), "already exists") {
			a.respondWithError(w, http.StatusConflict, err.Error())
			return
		}
		log.Printf("Error registering user: %v", err)
		a.respondWithError(w, http.StatusInternalServerError, "Failed to register user")
		return
	}

	if createdUser != nil {
		createdUser.PasswordHash = ""
	}

	token, err := auth.GenerateJWT(createdUser.ID)
	if err != nil {
		log.Printf("Error generating JWT: %v", err)
		a.respondWithError(w, http.StatusInternalServerError, "Failed to generate token")
		return
	}

	a.respondWithJSON(w, http.StatusCreated, authResponse{
		Token: token,
		User:  *createdUser,
	})
}

func (a *API) LoginHandler(w http.ResponseWriter, r *http.Request) {
	var req loginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		a.respondWithError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	user, err := a.Users.GetByEmail(req.Email)
	if err != nil {
		if err == sql.ErrNoRows {
			a.respondWithError(w, http.StatusUnauthorized, "Invalid email or password")
			return
		}
		log.Printf("Error retrieving user: %v", err)
		a.respondWithError(w, http.StatusInternalServerError, "Server error during login")
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		a.respondWithError(w, http.StatusUnauthorized, "Invalid email or password")
		return
	}

	user.PasswordHash = ""

	token, err := auth.GenerateJWT(user.ID)
	if err != nil {
		log.Printf("Error generating JWT: %v", err)
		a.respondWithError(w, http.StatusInternalServerError, "Failed to generate token")
		return
	}

	a.respondWithJSON(w, http.StatusOK, authResponse{
		Token: token,
		User:  *user,
	})
}
