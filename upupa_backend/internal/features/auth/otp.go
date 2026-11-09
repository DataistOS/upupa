// upupa_backend/internal/features/auth/otp.go
package auth

import (
	"crypto/rand"
	"encoding/json"
	"fmt"
	"net/http"
	"sync"
	"time"
)

var otpStorage = struct {
	sync.Mutex
	codes map[string]otpRecord
}{codes: make(map[string]otpRecord)}

type otpRecord struct {
	Code      string
	ExpiresAt time.Time
}

type OTPRequest struct {
	Email string `json:"email"`
}

type OTPLoginRequest struct {
	Email string `json:"email"`
	Code  string `json:"code"`
}

func generateOTPCode() string {
	var b [3]byte
	rand.Read(b[:])
	return fmt.Sprintf("%06d", int(b[0])<<16|int(b[1])<<8|int(b[2])%1000000)
}

func RequestOTPHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req OTPRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Email == "" {
		http.Error(w, "Invalid request body or email", http.StatusBadRequest)
		return
	}

	code := generateOTPCode()

	otpStorage.Lock()
	otpStorage.codes[req.Email] = otpRecord{
		Code:      code,
		ExpiresAt: time.Now().Add(5 * time.Minute),
	}
	otpStorage.Unlock()

	fmt.Printf("[OTP Service] Code for %s is: %s\n", req.Email, code)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"message": "OTP code sent successfully",
	})
}

func LoginOTPHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req OTPLoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	otpStorage.Lock()
	record, exists := otpStorage.codes[req.Email]
	if exists {
		delete(otpStorage.codes, req.Email)
	}
	otpStorage.Unlock()

	if !exists || record.Code != req.Code || time.Now().After(record.ExpiresAt) {
		http.Error(w, "Invalid or expired OTP code", http.StatusUnauthorized)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"token":         "mock-upupa-jwt-token-for-otp",
		"refresh_token": "mock-upupa-refresh-token-for-otp",
		"record": map[string]interface{}{
			"email": req.Email,
		},
	})
}
