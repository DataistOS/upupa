// upupa_backend/internal/store/sqlite.go
package store

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"time"

	"upupa_backend/pkg/models"

	_ "github.com/mattn/go-sqlite3"
)

type SQLiteStore struct {
	db *sql.DB
}

func NewSQLiteStore(dbPath string) (*SQLiteStore, error) {
	db, err := sql.Open("sqlite3", dbPath)
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	db.SetMaxOpenConns(1)

	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	return &SQLiteStore{db: db}, nil
}

func (s *SQLiteStore) InitSchema() error {
	const collectionsSchema = `
    CREATE TABLE IF NOT EXISTS collections (
       id TEXT PRIMARY KEY,
       name TEXT UNIQUE NOT NULL,
       system BOOLEAN NOT NULL,
       schema TEXT NOT NULL,
       rules TEXT NOT NULL,
       created DATETIME NOT NULL,
       updated DATETIME NOT NULL
    );`

	const recordsSchema = `
    CREATE TABLE IF NOT EXISTS records (
       id TEXT NOT NULL,
       collection_id TEXT NOT NULL,
       data TEXT NOT NULL,
       created DATETIME NOT NULL,
       updated DATETIME NOT NULL,
       PRIMARY KEY (id, collection_id)
    );`

	if _, err := s.db.Exec(collectionsSchema); err != nil {
		return fmt.Errorf("failed to create collections table: %w", err)
	}
	if _, err := s.db.Exec(recordsSchema); err != nil {
		return fmt.Errorf("failed to create records table: %w", err)
	}

	return nil
}

// =========================================================================
// CollectionRepository Implementation
// =========================================================================

func (s *SQLiteStore) CreateCollection(col models.Collection) (*models.Collection, error) {
	schemaJSON, _ := json.Marshal(col.Schema)
	rulesJSON, _ := json.Marshal(col.Rules)

	query := `INSERT INTO collections (id, name, system, schema, rules, created, updated) VALUES (?, ?, ?, ?, ?, ?, ?)`
	_, err := s.db.Exec(query, col.ID, col.Name, col.System, schemaJSON, rulesJSON, col.Created.Format(time.RFC3339), col.Updated.Format(time.RFC3339))
	if err != nil {
		return nil, err
	}

	return &col, nil
}

func (s *SQLiteStore) GetByName(name string) (*models.Collection, error) {
	query := `SELECT id, name, system, schema, rules, created, updated FROM collections WHERE name = ?`
	row := s.db.QueryRow(query, name)

	var col models.Collection
	var schemaJSON []byte
	var rulesJSON []byte
	var created, updated string

	err := row.Scan(&col.ID, &col.Name, &col.System, &schemaJSON, &rulesJSON, &created, &updated)
	if err != nil {
		return nil, err
	}

	if err := json.Unmarshal(schemaJSON, &col.Schema); err != nil {
		return nil, fmt.Errorf("failed to unmarshal schema: %w", err)
	}
	if err := json.Unmarshal(rulesJSON, &col.Rules); err != nil {
		return nil, fmt.Errorf("failed to unmarshal rules: %w", err)
	}

	col.Created, _ = time.Parse(time.RFC3339, created)
	col.Updated, _ = time.Parse(time.RFC3339, updated)

	return &col, nil
}

func (s *SQLiteStore) GetAll() ([]models.Collection, error) {
	query := `SELECT id, name, system, schema, rules, created, updated FROM collections ORDER BY created ASC`
	rows, err := s.db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var collections []models.Collection
	for rows.Next() {
		var col models.Collection
		var schemaJSON []byte
		var rulesJSON []byte
		var created, updated string

		if err := rows.Scan(&col.ID, &col.Name, &col.System, &schemaJSON, &rulesJSON, &created, &updated); err != nil {
			return nil, err
		}

		if err := json.Unmarshal(schemaJSON, &col.Schema); err != nil {
			return nil, fmt.Errorf("failed to unmarshal schema: %w", err)
		}
		if err := json.Unmarshal(rulesJSON, &col.Rules); err != nil {
			return nil, fmt.Errorf("failed to unmarshal rules: %w", err)
		}

		col.Created, _ = time.Parse(time.RFC3339, created)
		col.Updated, _ = time.Parse(time.RFC3339, updated)

		collections = append(collections, col)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return collections, nil
}

func (s *SQLiteStore) UpdateCollection(col models.Collection) (*models.Collection, error) {
	col.Updated = time.Now()
	schemaJSON, _ := json.Marshal(col.Schema)
	rulesJSON, _ := json.Marshal(col.Rules)

	query := `UPDATE collections SET schema = ?, rules = ?, updated = ? WHERE name = ?`
	res, err := s.db.Exec(query, schemaJSON, rulesJSON, col.Updated.Format(time.RFC3339), col.Name)
	if err != nil {
		return nil, err
	}

	rowsAffected, _ := res.RowsAffected()
	if rowsAffected == 0 {
		return nil, sql.ErrNoRows
	}

	return &col, nil
}

func (s *SQLiteStore) DeleteCollection(name string) error {
	query := `DELETE FROM collections WHERE name = ?`
	res, err := s.db.Exec(query, name)
	if err != nil {
		return err
	}
	rowsAffected, _ := res.RowsAffected()
	if rowsAffected == 0 {
		return sql.ErrNoRows
	}

	col, err := s.GetByName(name)
	if err == nil {
		recordDeleteQuery := `DELETE FROM records WHERE collection_id = ?`
		if _, err := s.db.Exec(recordDeleteQuery, col.ID); err != nil {
			fmt.Printf("Warning: Failed to delete records for collection %s: %v\n", name, err)
		}
	}

	return nil
}

// =========================================================================
// RecordRepository Implementation
// =========================================================================

func (s *SQLiteStore) CreateRecord(record models.Record) (*models.Record, error) {
	dataJSON, _ := json.Marshal(record.Data)

	query := `INSERT INTO records (id, collection_id, data, created, updated) VALUES (?, ?, ?, ?, ?)`
	_, err := s.db.Exec(query, record.ID, record.CollectionID, dataJSON, record.Created.Format(time.RFC3339), record.Updated.Format(time.RFC3339))
	if err != nil {
		return nil, err
	}

	return &record, nil
}

func (s *SQLiteStore) scanRecord(row *sql.Row, recordID string, collectionID string) (*models.Record, error) {
	var dataJSON []byte
	var created, updated string

	err := row.Scan(&dataJSON, &created, &updated)
	if err != nil {
		return nil, err
	}

	var data map[string]interface{}
	if err := json.Unmarshal(dataJSON, &data); err != nil {
		return nil, fmt.Errorf("failed to unmarshal record data: %w", err)
	}

	record := &models.Record{
		ID:           recordID,
		CollectionID: collectionID,
		Created:      time.Time{},
		Updated:      time.Time{},
		Data:         data,
	}

	record.Created, _ = time.Parse(time.RFC3339, created)
	record.Updated, _ = time.Parse(time.RFC3339, updated)

	return record, nil
}

func (s *SQLiteStore) GetByID(collectionID, recordID string) (*models.Record, error) {
	query := `SELECT data, created, updated FROM records WHERE collection_id = ? AND id = ?`
	row := s.db.QueryRow(query, collectionID, recordID)
	return s.scanRecord(row, recordID, collectionID)
}

func (s *SQLiteStore) Update(record models.Record) error {
	record.Updated = time.Now()
	dataJSON, _ := json.Marshal(record.Data)

	query := `UPDATE records SET data = ?, updated = ? WHERE id = ? AND collection_id = ?`
	res, err := s.db.Exec(query, dataJSON, record.Updated.Format(time.RFC3339), record.ID, record.CollectionID)
	if err != nil {
		return err
	}

	rowsAffected, _ := res.RowsAffected()
	if rowsAffected == 0 {
		return sql.ErrNoRows
	}
	return nil
}

func (s *SQLiteStore) DeleteRecord(collectionID, recordID string) error {
	query := `DELETE FROM records WHERE collection_id = ? AND id = ?`
	res, err := s.db.Exec(query, collectionID, recordID)
	if err != nil {
		return err
	}

	rowsAffected, _ := res.RowsAffected()
	if rowsAffected == 0 {
		return sql.ErrNoRows
	}
	return nil
}

func (s *SQLiteStore) ListRecords(collectionID string, opts ListOptions) ([]models.Record, error) {
	limit, offset := opts.GetLimitAndOffset()
	sortClause := opts.ParseSort()
	whereClause, filterArgs, err := opts.ParseFilter()
	if err != nil {
		return nil, fmt.Errorf("failed to parse filter: %w", err)
	}

	query := fmt.Sprintf(`SELECT id, data, created, updated FROM records WHERE collection_id = ?`)
	args := []interface{}{collectionID}

	if whereClause != "" {
		query += fmt.Sprintf(` AND (%s)`, whereClause)
		args = append(args, filterArgs...)
	}

	query += fmt.Sprintf(` ORDER BY %s LIMIT ? OFFSET ?`, sortClause)
	args = append(args, limit, offset)

	rows, err := s.db.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var records []models.Record
	for rows.Next() {
		var record models.Record
		var dataJSON []byte
		var created, updated string

		if err := rows.Scan(&record.ID, &dataJSON, &created, &updated); err != nil {
			return nil, err
		}

		record.CollectionID = collectionID
		record.Created, _ = time.Parse(time.RFC3339, created)
		record.Updated, _ = time.Parse(time.RFC3339, updated)

		var data map[string]interface{}
		if err := json.Unmarshal(dataJSON, &data); err != nil {
			return nil, fmt.Errorf("failed to unmarshal record data: %w", err)
		}
		record.Data = data

		records = append(records, record)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return records, nil
}

// =========================================================================
// UserRepository Implementation
// =========================================================================

func (s *SQLiteStore) CreateUser(user models.User) (*models.User, error) {
	data := map[string]interface{}{
		"email":        user.Email,
		"passwordHash": user.PasswordHash,
		"is_admin":     user.IsAdmin,
	}

	checkQuery := `
    SELECT r.id
    FROM records r
    JOIN collections c ON r.collection_id = c.id
    WHERE c.name = 'users' AND json_extract(r.data, '$.email') = ?
    LIMIT 1`
	var existingID string
	err := s.db.QueryRow(checkQuery, user.Email).Scan(&existingID)
	if err != nil && err != sql.ErrNoRows {
		return nil, fmt.Errorf("error checking for existing user: %w", err)
	}
	if err == nil {
		return nil, fmt.Errorf("user with email '%s' already exists", user.Email)
	}

	userCol, err := s.GetByName("users")
	if err != nil {
		return nil, fmt.Errorf("users collection not found: %w", err)
	}

	record := models.Record{
		ID:           user.ID,
		CollectionID: userCol.ID,
		Created:      user.Created,
		Updated:      user.Updated,
		Data:         data,
	}

	_, err = s.CreateRecord(record)
	if err != nil {
		return nil, err
	}

	return &user, nil
}

func (s *SQLiteStore) Register(email, hashedPassword string) (*models.User, error) {
	user := models.User{
		ID:           models.NewID(),
		Email:        email,
		PasswordHash: hashedPassword,
		Created:      time.Now(),
		Updated:      time.Now(),
		IsAdmin:      false,
	}

	createdUser, err := s.CreateUser(user)
	if err != nil {
		return nil, err
	}

	createdUser.PasswordHash = ""
	return createdUser, nil
}

func (s *SQLiteStore) GetByEmail(email string) (*models.User, error) {
	userCol, err := s.GetByName("users")
	if err != nil {
		return nil, sql.ErrNoRows
	}

	query := `
    SELECT r.id, r.data, r.created, r.updated
    FROM records r
    WHERE r.collection_id = ?
    AND json_extract(r.data, '$.email') = ?
    LIMIT 1
    `
	row := s.db.QueryRow(query, userCol.ID, email)

	var recordID string
	var dataJSON []byte
	var created, updated string

	err = row.Scan(&recordID, &dataJSON, &created, &updated)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, sql.ErrNoRows
		}
		return nil, fmt.Errorf("error scanning user record: %w", err)
	}

	var userData map[string]interface{}
	if err := json.Unmarshal(dataJSON, &userData); err != nil {
		return nil, fmt.Errorf("failed to unmarshal user data: %w", err)
	}

	var isAdmin bool
	if is, ok := userData["is_admin"].(bool); ok {
		isAdmin = is
	} else if f, ok := userData["is_admin"].(float64); ok {
		isAdmin = f != 0
	} else {
		isAdmin = false
	}

	user := models.User{
		ID:           recordID,
		Email:        email,
		PasswordHash: userData["passwordHash"].(string),
		Created:      time.Time{},
		Updated:      time.Time{},
		IsAdmin:      isAdmin,
	}

	user.Created, _ = time.Parse(time.RFC3339, created)
	user.Updated, _ = time.Parse(time.RFC3339, updated)

	return &user, nil
}

func (s *SQLiteStore) GetUserByID(userID string) (*models.User, error) {
	userCol, err := s.GetByName("users")
	if err != nil {
		return nil, sql.ErrNoRows
	}

	query := `
    SELECT r.data, r.created, r.updated
    FROM records r
    WHERE r.collection_id = ?
    AND r.id = ?
    LIMIT 1
    `
	row := s.db.QueryRow(query, userCol.ID, userID)

	var dataJSON []byte
	var created, updated string

	err = row.Scan(&dataJSON, &created, &updated)
	if err != nil {
		return nil, err
	}

	var userData map[string]interface{}
	if err := json.Unmarshal(dataJSON, &userData); err != nil {
		return nil, fmt.Errorf("failed to unmarshal user data: %w", err)
	}

	var isAdmin bool
	if is, ok := userData["is_admin"].(bool); ok {
		isAdmin = is
	} else if f, ok := userData["is_admin"].(float64); ok {
		isAdmin = f != 0
	} else {
		isAdmin = false
	}

	user := models.User{
		ID:           userID,
		Email:        userData["email"].(string),
		PasswordHash: userData["passwordHash"].(string),
		Created:      time.Time{},
		Updated:      time.Time{},
		IsAdmin:      isAdmin,
	}

	user.Created, _ = time.Parse(time.RFC3339, created)
	user.Updated, _ = time.Parse(time.RFC3339, updated)

	return &user, nil
}
