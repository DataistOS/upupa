// upupa_backend/internal/api/storage_handlers.go
package api

import (
	"crypto/rand"
	"encoding/hex"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"github.com/go-chi/chi/v5"
)

const uploadDir = "./storage"

func (a *API) UploadFileHandler(w http.ResponseWriter, r *http.Request) {
	if err := r.ParseMultipartForm(10 << 20); err != nil {
		a.respondWithError(w, http.StatusBadRequest, "File size exceeds limit or invalid form")
		return
	}

	file, header, err := r.FormFile("file")
	if err != nil {
		a.respondWithError(w, http.StatusBadRequest, "No file uploaded or invalid file field")
		return
	}
	defer file.Close()

	if err := os.MkdirAll(uploadDir, os.ModePerm); err != nil {
		a.respondWithError(w, http.StatusInternalServerError, "Failed to create storage directory")
		return
	}

	randBytes := make([]byte, 6)
	rand.Read(randBytes)
	fileHash := hex.EncodeToString(randBytes)
	safeFilename := fileHash + "_" + filepath.Base(header.Filename)
	filePath := filepath.Join(uploadDir, safeFilename)

	dst, err := os.Create(filePath)
	if err != nil {
		a.respondWithError(w, http.StatusInternalServerError, "Failed to save file on server")
		return
	}
	defer dst.Close()

	if _, err := io.Copy(dst, file); err != nil {
		a.respondWithError(w, http.StatusInternalServerError, "Failed to write file contents")
		return
	}

	a.respondWithJSON(w, http.StatusCreated, map[string]string{
		"filename": safeFilename,
		"original": header.Filename,
		"url":      "/api/v1/files/" + safeFilename,
	})
}

func (a *API) ServeFileHandler(w http.ResponseWriter, r *http.Request) {
	filename := chi.URLParam(r, "filename")
	if filename == "" || strings.Contains(filename, "..") {
		a.respondWithError(w, http.StatusBadRequest, "Invalid filename")
		return
	}

	filePath := filepath.Join(uploadDir, filename)
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		a.respondWithError(w, http.StatusNotFound, "File not found")
		return
	}

	http.ServeFile(w, r, filePath)
}
