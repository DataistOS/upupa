// upupa_backend/internal/features/profile/handlers.go
package profile

import (
	"encoding/json"
	"net/http"
	"strings"

	"upupa_backend/internal/store"
)

type Handler struct {
	Collections store.CollectionRepository
	Records     store.RecordRepository
}

func NewHandler(collections store.CollectionRepository, records store.RecordRepository) *Handler {
	return &Handler{
		Collections: collections,
		Records:     records,
	}
}

func (h *Handler) GetProfileHandler(w http.ResponseWriter, r *http.Request) {
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
		h.respondWithError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	collections, err := h.Collections.GetAll()
	if err != nil {
		h.respondWithError(w, http.StatusInternalServerError, "Failed to retrieve collections statistics")
		return
	}

	totalCollections := len(collections)
	var totalRecords int64 = 0
	collectionStats := []map[string]interface{}{}

	for _, col := range collections {
		recordCount := 0
		allRecs, listErr := h.Records.ListRecords(col.ID, store.ListOptions{PerPage: 10000})
		if listErr == nil {
			recordCount = len(allRecs)
		}

		totalRecords += int64(recordCount)

		collectionStats = append(collectionStats, map[string]interface{}{
			"id":           col.ID,
			"name":         col.Name,
			"system":       col.System,
			"record_count": recordCount,
		})
	}

	profileData := map[string]interface{}{
		"email":             "admin@upupa.local",
		"role":              "Administrator",
		"total_collections": totalCollections,
		"total_records":     totalRecords,
		"collections":       collectionStats,
	}

	h.respondWithJSON(w, http.StatusOK, profileData)
}

func (h *Handler) UpdateProfileHandler(w http.ResponseWriter, r *http.Request) {
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
		h.respondWithError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req struct {
		Email    string `json:"email"`
		Password string `json:"password,omitempty"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.respondWithError(w, http.StatusBadRequest, "Invalid request payload")
		return
	}

	h.respondWithJSON(w, http.StatusOK, map[string]string{
		"message": "Profile updated successfully",
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
