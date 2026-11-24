// upupa_backend/internal/features/storage/media_sync.go
package storage

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"upupa_backend/internal/store"
)

const defaultHuMaNagerUploadEndpoint = "http://127.0.0.1:8081/api/upload"

type CollectionProfile struct {
	DefaultPathField  string
	ForceFileName     string
	DefaultCollection string
}

type MediaSyncHandler struct {
	Records       store.RecordRepository
	HuMaNagerURL  string
	TempUploadDir string
	HTTPClient    *http.Client
	Profiles      map[string]CollectionProfile
}

func NewMediaSyncHandler(records store.RecordRepository) *MediaSyncHandler {
	return &MediaSyncHandler{
		Records:       records,
		HuMaNagerURL:  defaultHuMaNagerUploadEndpoint,
		TempUploadDir: uploadDir,
		HTTPClient:    &http.Client{Timeout: 30 * time.Second},
		Profiles: map[string]CollectionProfile{
			"daftarche": {
				DefaultPathField: "avatarpath",
				ForceFileName:    "avatar.jpg",
			},
			"_default": {
				DefaultPathField: "path",
				ForceFileName:    "",
			},
		},
	}
}

func (h *MediaSyncHandler) getProfile(collection string) CollectionProfile {
	key := strings.ToLower(strings.TrimSpace(collection))
	if p, ok := h.Profiles[key]; ok {
		return p
	}
	return h.Profiles["_default"]
}

func (h *MediaSyncHandler) SyncFileHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		h.respondError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	if err := r.ParseMultipartForm(25 << 20); err != nil {
		h.respondError(w, http.StatusBadRequest, "Invalid multipart form data")
		return
	}

	collectionName := strings.TrimSpace(r.FormValue("collection"))
	if collectionName == "" {
		collectionName = "daftarche"
	}
	profile := h.getProfile(collectionName)

	collectionID := strings.TrimSpace(r.FormValue("collection_id"))
	recordID := strings.TrimSpace(r.FormValue("record_id"))
	slug := strings.TrimSpace(r.FormValue("slug"))
	if slug == "" {
		slug = strings.TrimSpace(r.FormValue("finglish"))
	}

	targetField := strings.TrimSpace(r.FormValue("target_field"))
	if targetField == "" {
		targetField = profile.DefaultPathField
	}

	forcedName := strings.TrimSpace(r.FormValue("target_filename"))
	if forcedName == "" {
		forcedName = profile.ForceFileName
	}

	var tempFilePath string
	var originalName string
	var fileBytes []byte

	file, header, err := r.FormFile("file")
	if err == nil {
		defer file.Close()
		originalName = header.Filename

		if err := os.MkdirAll(h.TempUploadDir, os.ModePerm); err != nil {
			h.respondError(w, http.StatusInternalServerError, "Failed to prepare temp directory")
			return
		}

		tempFilePath = filepath.Join(h.TempUploadDir, fmt.Sprintf("tmp_%d_%s", time.Now().UnixNano(), filepath.Base(originalName)))
		tmpFile, err := os.Create(tempFilePath)
		if err != nil {
			h.respondError(w, http.StatusInternalServerError, "Failed to create temp file")
			return
		}

		fileBytes, err = io.ReadAll(file)
		if err != nil {
			tmpFile.Close()
			_ = os.Remove(tempFilePath)
			h.respondError(w, http.StatusInternalServerError, "Failed to read uploaded file")
			return
		}

		if _, err := tmpFile.Write(fileBytes); err != nil {
			tmpFile.Close()
			_ = os.Remove(tempFilePath)
			h.respondError(w, http.StatusInternalServerError, "Failed to write temp file")
			return
		}
		_ = tmpFile.Close()
	} else {
		existingName := filepath.Base(strings.TrimSpace(r.FormValue("temp_filename")))
		if existingName == "" || existingName == "." {
			h.respondError(w, http.StatusBadRequest, "No file or temp_filename provided")
			return
		}
		tempFilePath = filepath.Join(h.TempUploadDir, existingName)
		data, readErr := os.ReadFile(tempFilePath)
		if readErr != nil {
			h.respondError(w, http.StatusNotFound, "Temporary file not found")
			return
		}
		fileBytes = data
		originalName = existingName
	}

	defer func() {
		if tempFilePath != "" {
			_ = os.Remove(tempFilePath)
		}
	}()

	if slug == "" && collectionID != "" && recordID != "" && h.Records != nil {
		if rec, recErr := h.Records.GetByID(collectionID, recordID); recErr == nil && rec != nil {
			if s, ok := rec.Data["slug"].(string); ok && s != "" {
				slug = s
			} else if f, ok := rec.Data["finglish"].(string); ok && f != "" {
				slug = f
			}
		}
	}

	sendName := originalName
	if forcedName != "" {
		sendName = forcedName
	}

	var body bytes.Buffer
	writer := multipart.NewWriter(&body)

	part, err := writer.CreateFormFile("file", sendName)
	if err != nil {
		h.respondError(w, http.StatusInternalServerError, "Failed to build multipart file")
		return
	}
	if _, err := part.Write(fileBytes); err != nil {
		h.respondError(w, http.StatusInternalServerError, "Failed to write multipart file")
		return
	}

	_ = writer.WriteField("collection", collectionName)
	if slug != "" {
		_ = writer.WriteField("slug", slug)
	}
	if recordID != "" {
		_ = writer.WriteField("record_id", recordID)
	}
	if err := writer.Close(); err != nil {
		h.respondError(w, http.StatusInternalServerError, "Failed to finalize multipart body")
		return
	}

	req, err := http.NewRequestWithContext(r.Context(), http.MethodPost, h.HuMaNagerURL, &body)
	if err != nil {
		h.respondError(w, http.StatusInternalServerError, "Failed to create HuMaNager request")
		return
	}
	req.Header.Set("Content-Type", writer.FormDataContentType())

	resp, err := h.HTTPClient.Do(req)
	if err != nil {
		h.respondError(w, http.StatusBadGateway, "Failed to reach HuMaNager daemon: "+err.Error())
		return
	}
	defer resp.Body.Close()

	respBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		h.respondError(w, http.StatusBadGateway, "Failed to read HuMaNager response")
		return
	}

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		h.respondError(w, http.StatusBadGateway, fmt.Sprintf("HuMaNager returned status %d: %s", resp.StatusCode, string(respBytes)))
		return
	}

	var hmResp struct {
		Success      bool   `json:"success"`
		RelativePath string `json:"relative_path"`
		AssignedPath string `json:"assigned_path"`
		FileName     string `json:"file_name"`
	}
	if err := json.Unmarshal(respBytes, &hmResp); err != nil || hmResp.RelativePath == "" {
		h.respondError(w, http.StatusBadGateway, "Invalid response or missing relative_path from HuMaNager")
		return
	}

	if collectionID != "" && recordID != "" && targetField != "" && h.Records != nil {
		if rec, recErr := h.Records.GetByID(collectionID, recordID); recErr == nil && rec != nil {
			if rec.Data == nil {
				rec.Data = make(map[string]interface{})
			}
			rec.Data[targetField] = hmResp.RelativePath
			rec.Updated = time.Now()
			if updErr := h.Records.Update(*rec); updErr != nil {
				h.respondError(w, http.StatusInternalServerError, "Failed to update record path field: "+updErr.Error())
				return
			}
		}
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(map[string]any{
		"success":       true,
		"collection":    collectionName,
		"record_id":     recordID,
		"target_field":  targetField,
		"relative_path": hmResp.RelativePath,
		"file_name":     hmResp.FileName,
	})
}

func (h *MediaSyncHandler) respondError(w http.ResponseWriter, code int, msg string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	_ = json.NewEncoder(w).Encode(map[string]string{"error": msg})
}
