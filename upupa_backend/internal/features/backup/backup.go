// upupa_backend/internal/features/backup/backup.go
package backup

import (
	"fmt"
	"net/http"
	"os"
	"time"
)

type BackupHandler struct {
	dbPath string
}

func NewHandler(dbPath string) *BackupHandler {
	return &BackupHandler{dbPath: dbPath}
}

func (h *BackupHandler) DownloadBackup(w http.ResponseWriter, r *http.Request) {
	if _, err := os.Stat(h.dbPath); os.IsNotExist(err) {
		http.Error(w, `{"error": "Database file not found"}`, http.StatusNotFound)
		return
	}

	filename := fmt.Sprintf("upupa_backup_%s.db", time.Now().Format("20060102_150405"))

	w.Header().Set("Content-Type", "application/octet-stream")
	w.Header().Set("Content-Disposition", fmt.Sprintf(`attachment; filename="%s"`, filename))

	http.ServeFile(w, r, h.dbPath)
}
