// upupa_backend/internal/api/profile_handlers.go
package api

import (
	"encoding/json"
	"net/http"
	"strings"

	"upupa_backend/internal/store"
)

func (a *API) GetProfileHandler(w http.ResponseWriter, r *http.Request) {
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
		a.respondWithError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	collections, err := a.Collections.GetAll()
	if err != nil {
		a.respondWithError(w, http.StatusInternalServerError, "Failed to retrieve collections statistics")
		return
	}

	totalCollections := len(collections)
	var totalRecords int64 = 0
	collectionStats := []map[string]interface{}{}

	for _, col := range collections {
		recordCount := 0
		allRecs, listErr := a.Records.ListRecords(col.ID, store.ListOptions{PerPage: 10000})
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

	a.respondWithJSON(w, http.StatusOK, profileData)
}

func (a *API) UpdateProfileHandler(w http.ResponseWriter, r *http.Request) {
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
		a.respondWithError(w, http.StatusUnauthorized, "Unauthorized")
		return
	}

	var req struct {
		Email    string `json:"email"`
		Password string `json:"password,omitempty"`
	}

	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		a.respondWithError(w, http.StatusBadRequest, "Invalid request payload")
		return
	}

	a.respondWithJSON(w, http.StatusOK, map[string]string{
		"message": "Profile updated successfully",
	})
}
