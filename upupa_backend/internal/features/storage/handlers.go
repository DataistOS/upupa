// upupa_backend/internal/features/storage/handlers.go
package storage

import (
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"upupa_backend/internal/store"

	"github.com/go-chi/chi/v5"
)

const uploadDir = "./storage/uploads"

type Handler struct {
	dbStore *store.SQLiteStore
}

func NewHandler(dbStore *store.SQLiteStore) *Handler {
	return &Handler{
		dbStore: dbStore,
	}
}

func (h *Handler) UploadFileHandler(w http.ResponseWriter, r *http.Request) {
	if err := r.ParseMultipartForm(10 << 20); err != nil {
		h.respondWithError(w, http.StatusBadRequest, "File size exceeds limit or invalid form")
		return
	}

	file, header, err := r.FormFile("file")
	if err != nil {
		h.respondWithError(w, http.StatusBadRequest, "No file uploaded or invalid file field")
		return
	}
	defer file.Close()

	if err := os.MkdirAll(uploadDir, os.ModePerm); err != nil {
		h.respondWithError(w, http.StatusInternalServerError, "Failed to create storage directory")
		return
	}

	randBytes := make([]byte, 6)
	rand.Read(randBytes)
	fileHash := hex.EncodeToString(randBytes)
	safeFilename := fileHash + "_" + filepath.Base(header.Filename)
	filePath := filepath.Join(uploadDir, safeFilename)

	dst, err := os.Create(filePath)
	if err != nil {
		h.respondWithError(w, http.StatusInternalServerError, "Failed to save file on server")
		return
	}
	defer dst.Close()

	if _, err := io.Copy(dst, file); err != nil {
		h.respondWithError(w, http.StatusInternalServerError, "Failed to write file contents")
		return
	}

	h.respondWithJSON(w, http.StatusCreated, map[string]string{
		"filename": safeFilename,
		"original": header.Filename,
		"url":      "/api/v1/files/" + safeFilename,
	})
}

func (h *Handler) ServeFileHandler(w http.ResponseWriter, r *http.Request) {
	filename := chi.URLParam(r, "filename")
	if filename == "" || strings.Contains(filename, "..") {
		h.respondWithError(w, http.StatusBadRequest, "Invalid filename")
		return
	}

	filePath := filepath.Join(uploadDir, filename)
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		h.respondWithError(w, http.StatusNotFound, "File not found")
		return
	}

	http.ServeFile(w, r, filePath)
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
