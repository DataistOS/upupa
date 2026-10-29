// upupa_backend/internal/api/handlers.go
package api

import (
    "database/sql"
    "encoding/json"
    "fmt"
    "log"
    "net/http"
    "strconv"
    "strings"
    "time"

    "upupa_backend/internal/store"
    "upupa_backend/pkg/models"

    "github.com/go-chi/chi/v5"
)

type API struct {
    Collections store.CollectionRepository
    Records     store.RecordRepository
    Users       store.UserRepository
}

func NewAPI(collections store.CollectionRepository, records store.RecordRepository, users store.UserRepository) *API {
    return &API{
       Collections: collections,
       Records:     records,
       Users:       users,
    }
}

func (a *API) respondWithError(w http.ResponseWriter, code int, message string) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(code)
    json.NewEncoder(w).Encode(map[string]string{"error": message})
}

func (a *API) respondWithJSON(w http.ResponseWriter, code int, payload interface{}) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(code)
    if payload != nil {
       json.NewEncoder(w).Encode(payload)
    }
}

func (a *API) HealthCheck(w http.ResponseWriter, r *http.Request) {
    a.respondWithJSON(w, http.StatusOK, map[string]string{"status": "ok", "version": "v1.0.0"})
}

func (a *API) CreateCollectionHandler(w http.ResponseWriter, r *http.Request) {
    var req models.Collection
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
       a.respondWithError(w, http.StatusBadRequest, "Invalid request payload")
       return
    }

    if req.Name == "" {
       a.respondWithError(w, http.StatusBadRequest, "Collection name is required")
       return
    }

    req.ID = models.NewID()
    req.Name = models.Slugify(req.Name)
    req.Created = time.Now()
    req.Updated = time.Now()
    req.System = false

    if req.Schema == nil {
       req.Schema = []models.Field{}
    }
    if req.Rules == nil {
       req.Rules = []models.Rule{}
    }

    collection, err := a.Collections.CreateCollection(req)
    if err != nil {
       if strings.Contains(err.Error(), "UNIQUE constraint failed") {
          a.respondWithError(w, http.StatusConflict, fmt.Sprintf("Collection with name '%s' already exists", req.Name))
          return
       }
       log.Printf("Error creating collection: %v", err)
       a.respondWithError(w, http.StatusInternalServerError, "Failed to create collection")
       return
    }

    a.respondWithJSON(w, http.StatusCreated, collection)
}

func (a *API) ListCollectionsHandler(w http.ResponseWriter, r *http.Request) {
    collections, err := a.Collections.GetAll()
    if err != nil {
       log.Printf("Error listing collections: %v", err)
       a.respondWithError(w, http.StatusInternalServerError, "Failed to retrieve collections")
       return
    }

    a.respondWithJSON(w, http.StatusOK, collections)
}

func (a *API) GetCollectionHandler(w http.ResponseWriter, r *http.Request) {
    name := chi.URLParam(r, "name")

    col, err := a.Collections.GetByName(name)
    if err != nil {
       if err == sql.ErrNoRows {
          a.respondWithError(w, http.StatusNotFound, "Collection not found")
          return
       }
       a.respondWithError(w, http.StatusInternalServerError, "Failed to retrieve collection")
       return
    }

    a.respondWithJSON(w, http.StatusOK, col)
}

func (a *API) UpdateCollectionHandler(w http.ResponseWriter, r *http.Request) {
    name := chi.URLParam(r, "name")

    col, err := a.Collections.GetByName(name)
    if err != nil {
       if err == sql.ErrNoRows {
          a.respondWithError(w, http.StatusNotFound, "Collection not found")
          return
       }
       a.respondWithError(w, http.StatusInternalServerError, "Failed to retrieve collection")
       return
    }

    if col.System {
       a.respondWithError(w, http.StatusForbidden, "Cannot modify system collection")
       return
    }

    var req models.Collection
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
       a.respondWithError(w, http.StatusBadRequest, "Invalid request payload")
       return
    }

    if req.Schema != nil {
       col.Schema = req.Schema
    }
    if req.Rules != nil {
       col.Rules = req.Rules
    }

    if _, err := a.Collections.UpdateCollection(*col); err != nil {
       if err == sql.ErrNoRows {
          a.respondWithError(w, http.StatusNotFound, "Collection not found during update")
          return
       }
       log.Printf("Error updating collection: %v", err)
       a.respondWithError(w, http.StatusInternalServerError, "Failed to update collection")
       return
    }

    updatedCol, _ := a.Collections.GetByName(name)
    a.respondWithJSON(w, http.StatusOK, updatedCol)
}

func (a *API) DeleteCollectionHandler(w http.ResponseWriter, r *http.Request) {
    name := chi.URLParam(r, "name")

    col, err := a.Collections.GetByName(name)
    if err != nil {
       if err == sql.ErrNoRows {
          a.respondWithError(w, http.StatusNotFound, "Collection not found")
          return
       }
       a.respondWithError(w, http.StatusInternalServerError, "Failed to retrieve collection")
       return
    }

    if col.System {
       a.respondWithError(w, http.StatusForbidden, "Cannot delete system collection")
       return
    }

    err = a.Collections.DeleteCollection(name)
    if err != nil {
       if err == sql.ErrNoRows {
          a.respondWithError(w, http.StatusNotFound, "Collection not found for deletion")
          return
       }
       log.Printf("Error deleting collection: %v", err)
       a.respondWithError(w, http.StatusInternalServerError, "Failed to delete collection")
       return
    }

    a.respondWithJSON(w, http.StatusNoContent, nil)
}

func (a *API) CreateRecordHandler(w http.ResponseWriter, r *http.Request) {
    collectionName := chi.URLParam(r, "name")

    col, err := a.Collections.GetByName(collectionName)
    if err != nil {
       if err == sql.ErrNoRows {
          a.respondWithError(w, http.StatusNotFound, "Collection not found")
          return
       }
       a.respondWithError(w, http.StatusInternalServerError, "Failed to retrieve collection")
       return
    }

    authHeader := r.Header.Get("Authorization")
    isAuthenticated := authHeader != "" && strings.HasPrefix(authHeader, "Bearer ")
    if ruleErr := CheckCollectionRule(*col, "create", isAuthenticated); ruleErr != nil {
       a.respondWithError(w, http.StatusForbidden, ruleErr.Error())
       return
    }

    var data map[string]interface{}
    if err := json.NewDecoder(r.Body).Decode(&data); err != nil {
       a.respondWithError(w, http.StatusBadRequest, "Invalid record payload")
       return
    }

    record := models.Record{
       ID:           models.NewID(),
       CollectionID: col.ID,
       Created:      time.Now(),
       Updated:      time.Now(),
       Data:         data,
    }

    createdRecord, err := a.Records.CreateRecord(record)
    if err != nil {
       log.Printf("Error creating record: %v", err)
       a.respondWithError(w, http.StatusInternalServerError, "Failed to create record")
       return
    }

    a.respondWithJSON(w, http.StatusCreated, createdRecord)
}

func (a *API) ListRecordsHandler(w http.ResponseWriter, r *http.Request) {
    collectionName := chi.URLParam(r, "name")

    col, err := a.Collections.GetByName(collectionName)
    if err != nil {
       if err == sql.ErrNoRows {
          a.respondWithError(w, http.StatusNotFound, "Collection not found")
          return
       }
       a.respondWithError(w, http.StatusInternalServerError, "Failed to retrieve collection")
       return
    }

    authHeader := r.Header.Get("Authorization")
    isAuthenticated := authHeader != "" && strings.HasPrefix(authHeader, "Bearer ")
    if ruleErr := CheckCollectionRule(*col, "list", isAuthenticated); ruleErr != nil {
       a.respondWithError(w, http.StatusForbidden, ruleErr.Error())
       return
    }

    page, err := strconv.Atoi(r.URL.Query().Get("page"))
    if err != nil || page < 1 {
       page = 1
    }

    perPage, err := strconv.Atoi(r.URL.Query().Get("perPage"))
    if err != nil || perPage < 1 {
       perPage = 30
    }

    sort := r.URL.Query().Get("sort")
    if sort == "" {
       sort = "-created"
    }

    filter := r.URL.Query().Get("filter")

    opts := store.ListOptions{
       Page:    page,
       PerPage: perPage,
       Sort:    sort,
       Filter:  filter,
    }

    records, err := a.Records.ListRecords(col.ID, opts)
    if err != nil {
       log.Printf("Error listing records: %v", err)
       a.respondWithError(w, http.StatusInternalServerError, fmt.Sprintf("Failed to retrieve records: %v", err))
       return
    }

    if records == nil {
       records = []models.Record{}
    }

    a.respondWithJSON(w, http.StatusOK, records)
}

func (a *API) GetRecordHandler(w http.ResponseWriter, r *http.Request) {
    collectionName := chi.URLParam(r, "name")
    recordID := chi.URLParam(r, "id")

    col, err := a.Collections.GetByName(collectionName)
    if err != nil {
       if err == sql.ErrNoRows {
          a.respondWithError(w, http.StatusNotFound, "Collection not found")
          return
       }
       a.respondWithError(w, http.StatusInternalServerError, "Failed to retrieve collection")
       return
    }

    authHeader := r.Header.Get("Authorization")
    isAuthenticated := authHeader != "" && strings.HasPrefix(authHeader, "Bearer ")
    if ruleErr := CheckCollectionRule(*col, "view", isAuthenticated); ruleErr != nil {
       a.respondWithError(w, http.StatusForbidden, ruleErr.Error())
       return
    }

    record, err := a.Records.GetByID(col.ID, recordID)
    if err != nil {
       if err == sql.ErrNoRows {
          a.respondWithError(w, http.StatusNotFound, "Record not found")
          return
       }
       log.Printf("Error retrieving record: %v", err)
       a.respondWithError(w, http.StatusInternalServerError, "Failed to retrieve record")
       return
    }

    a.respondWithJSON(w, http.StatusOK, record)
}

func (a *API) UpdateRecordHandler(w http.ResponseWriter, r *http.Request) {
    collectionName := chi.URLParam(r, "name")
    recordID := chi.URLParam(r, "id")

    col, err := a.Collections.GetByName(collectionName)
    if err != nil {
       if err == sql.ErrNoRows {
          a.respondWithError(w, http.StatusNotFound, "Collection not found")
          return
       }
       a.respondWithError(w, http.StatusInternalServerError, "Failed to retrieve collection")
       return
    }

    authHeader := r.Header.Get("Authorization")
    isAuthenticated := authHeader != "" && strings.HasPrefix(authHeader, "Bearer ")
    if ruleErr := CheckCollectionRule(*col, "update", isAuthenticated); ruleErr != nil {
       a.respondWithError(w, http.StatusForbidden, ruleErr.Error())
       return
    }

    record, err := a.Records.GetByID(col.ID, recordID)
    if err != nil {
       if err == sql.ErrNoRows {
          a.respondWithError(w, http.StatusNotFound, "Record not found")
          return
       }
       log.Printf("Error retrieving record for update: %v", err)
       a.respondWithError(w, http.StatusInternalServerError, "Failed to retrieve record")
       return
    }

    var req struct {
       Data map[string]interface{} `json:"data"`
    }
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
       a.respondWithError(w, http.StatusBadRequest, "Invalid request payload")
       return
    }

    updateData := req.Data

    for k, v := range updateData {
       record.Data[k] = v
    }

    record.Updated = time.Now()

    if err := a.Records.Update(*record); err != nil {
       if err == sql.ErrNoRows {
          a.respondWithError(w, http.StatusNotFound, "Record not found during update")
          return
       }
       log.Printf("Error updating record: %v", err)
       a.respondWithError(w, http.StatusInternalServerError, "Failed to update record")
       return
    }

    updatedRecord, _ := a.Records.GetByID(col.ID, recordID)
    a.respondWithJSON(w, http.StatusOK, updatedRecord)
}

func (a *API) DeleteRecordHandler(w http.ResponseWriter, r *http.Request) {
    collectionName := chi.URLParam(r, "name")
    recordID := chi.URLParam(r, "id")

    col, err := a.Collections.GetByName(collectionName)
    if err != nil {
       if err == sql.ErrNoRows {
          a.respondWithError(w, http.StatusNotFound, "Collection not found")
          return
       }
       a.respondWithError(w, http.StatusInternalServerError, "Failed to retrieve collection")
       return
    }

    authHeader := r.Header.Get("Authorization")
    isAuthenticated := authHeader != "" && strings.HasPrefix(authHeader, "Bearer ")
    if ruleErr := CheckCollectionRule(*col, "delete", isAuthenticated); ruleErr != nil {
       a.respondWithError(w, http.StatusForbidden, ruleErr.Error())
       return
    }

    err = a.Records.DeleteRecord(col.ID, recordID)
    if err != nil {
       if err == sql.ErrNoRows {
          a.respondWithError(w, http.StatusNotFound, "Record not found")
          return
       }
       log.Printf("Error deleting record: %v", err)
       a.respondWithError(w, http.StatusInternalServerError, "Failed to delete record")
       return
    }

    a.respondWithJSON(w, http.StatusNoContent, nil)
}