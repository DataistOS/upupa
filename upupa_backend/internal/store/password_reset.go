// upupa_backend/internal/store/password_reset.go
package store

import (
	"database/sql"
	"fmt"
	"time"
)

type PasswordResetStore interface {
	CreatePasswordResetToken(email, token string, expiresAt time.Time) error
	GetEmailByToken(token string) (string, error)
	DeletePasswordResetToken(token string) error
	UpdateUserPassword(email, newPasswordHash string) error
}

func (s *SQLiteStore) InitPasswordResetTable() error {
	query := `
	CREATE TABLE IF NOT EXISTS password_resets (
		token TEXT PRIMARY KEY,
		email TEXT NOT NULL,
		expires_at DATETIME NOT NULL,
		created_at DATETIME NOT NULL
	);`
	_, err := s.db.Exec(query)
	if err != nil {
		return fmt.Errorf("failed to create password_resets table: %w", err)
	}
	return nil
}

func (s *SQLiteStore) CreatePasswordResetToken(email, token string, expiresAt time.Time) error {
	_, _ = s.db.Exec("DELETE FROM password_resets WHERE email = ?", email)

	query := `INSERT INTO password_resets (token, email, expires_at, created_at) VALUES (?, ?, ?, ?)`
	_, err := s.db.Exec(query, token, email, expiresAt.Format(time.RFC3339), time.Now().Format(time.RFC3339))
	return err
}

func (s *SQLiteStore) GetEmailByToken(token string) (string, error) {
	query := `SELECT email, expires_at FROM password_resets WHERE token = ?`
	row := s.db.QueryRow(query, token)

	var email string
	var expiresAtStr string
	if err := row.Scan(&email, &expiresAtStr); err != nil {
		if err == sql.ErrNoRows {
			return "", fmt.Errorf("invalid or expired token")
		}
		return "", err
	}

	expiresAt, err := time.Parse(time.RFC3339, expiresAtStr)
	if err != nil || time.Now().After(expiresAt) {
		return "", fmt.Errorf("token has expired")
	}

	return email, nil
}

func (s *SQLiteStore) DeletePasswordResetToken(token string) error {
	_, err := s.db.Exec("DELETE FROM password_resets WHERE token = ?", token)
	return err
}

func (s *SQLiteStore) UpdateUserPassword(email, newPasswordHash string) error {
	userCol, err := s.GetByName("users")
	if err != nil {
		return fmt.Errorf("users collection not found: %w", err)
	}

	query := `
	UPDATE records
	SET data = json_set(data, '$.passwordHash', ?), updated = ?
	WHERE collection_id = ? AND json_extract(data, '$.email') = ?
	`
	_, err = s.db.Exec(query, newPasswordHash, time.Now().Format(time.RFC3339), userCol.ID, email)
	return err
}
