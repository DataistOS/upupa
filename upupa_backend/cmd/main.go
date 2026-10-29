// upupa_backend/cmd/main.go
package main

import (
    "database/sql"
    "fmt"
    "log"
    "net/http"
    "time"

    "upupa_backend/internal/api"
    "upupa_backend/internal/store"
    "upupa_backend/pkg/models"

    "github.com/go-chi/chi/v5"
    "github.com/go-chi/chi/v5/middleware"
)

const DB_FILE = "upupa_backend.db"

func main() {
    log.Println("Initializing database...")

    dbStore, err := store.NewSQLiteStore(DB_FILE)
    if err != nil {
       log.Fatalf("Failed to connect to database: %v", err)
    }
    log.Println("Database connection successful.")

    if err := dbStore.InitSchema(); err != nil {
       log.Fatalf("Failed to initialize database schema: %v", err)
    }
    log.Println("Database schema initialized.")

    if err := createSystemCollections(dbStore); err != nil {
       log.Fatalf("Failed to create system collections: %v", err)
    }
    log.Println("System collections created successfully.")

    if err := createProductCollection(dbStore, dbStore); err != nil {
       log.Fatalf("Failed to create product records: %v", err)
    }
    log.Println("Product collection and test record initialized successfully.")

    apiService := api.NewAPI(dbStore, dbStore, dbStore)
    router := chi.NewRouter()

    router.Use(middleware.Logger)
    router.Use(middleware.Recoverer)

    router.Get("/health", apiService.HealthCheck)

    router.Route("/api/v1", func(r chi.Router) {
       r.Post("/register", apiService.RegisterHandler)
       r.Post("/login", apiService.LoginHandler)

       r.Post("/collections", apiService.CreateCollectionHandler)
       r.Get("/collections", apiService.ListCollectionsHandler)

       r.Route("/collections/{name}", func(r chi.Router) {
          r.Get("/", apiService.GetCollectionHandler)
          r.Patch("/", apiService.UpdateCollectionHandler)
          r.Delete("/", apiService.DeleteCollectionHandler)

          r.Post("/records", apiService.CreateRecordHandler)
          r.Get("/records", apiService.ListRecordsHandler)

          r.Route("/records/{id}", func(r chi.Router) {
             r.Get("/", apiService.GetRecordHandler)
             r.Patch("/", apiService.UpdateRecordHandler)
             r.Put("/", apiService.UpdateRecordHandler)
             r.Delete("/", apiService.DeleteRecordHandler)
          })
       })
    })

    const port = "8888"
    log.Printf("Server starting on :%s...", port)
    if err := http.ListenAndServe(":"+port, router); err != nil {
       log.Fatalf("Server failed to start: %v", err)
    }
}

func createSystemCollections(colRepo store.CollectionRepository) error {
    usersColName := "users"
    _, err := colRepo.GetByName(usersColName)

    if err == nil {
       log.Println("System collection 'users' already exists, skipping creation.")
       return nil
    } else if err != sql.ErrNoRows {
       return fmt.Errorf("failed to check for existing system collection: %w", err)
    }

    usersCollection := models.Collection{
       ID:     models.NewID(),
       Name:   usersColName,
       System: true,
       Schema: []models.Field{
          {Name: "email", Type: "string", Required: true},
          {Name: "passwordHash", Type: "string", Required: true},
          {Name: "is_admin", Type: "boolean", DefaultValue: false},
       },
    }

    log.Printf("Creating system collection '%s'...", usersColName)
    if _, err := colRepo.CreateCollection(usersCollection); err != nil {
       return err
    }

    return nil
}

const productCollectionID = "prod_01"
const productID = "rec_test_prod"

func createProductCollection(colRepo store.CollectionRepository, recRepo store.RecordRepository) error {
    _, err := colRepo.GetByName("products")
    if err == sql.ErrNoRows {
       productCollection := models.Collection{
          ID: productCollectionID,
          Name: "products",
          System: false,
          Schema: []models.Field{
             {Name: "name", Type: "string", Required: true},
             {Name: "price", Type: "number"},
             {Name: "stock", Type: "number"},
             {Name: "releaseDate", Type: "string"},
             {Name: "is_active", Type: "boolean", DefaultValue: true},
          },
       }

       log.Println("Creating collection 'products'...")
       if _, err := colRepo.CreateCollection(productCollection); err != nil {
          return err
       }
    } else if err != nil {
       return err
    }

    _, err = recRepo.GetByID(productCollectionID, productID)
    if err == nil {
       log.Println("Test product record already exists, skipping creation.")
       return nil
    } else if err != sql.ErrNoRows {
       return fmt.Errorf("failed to check for existing product record: %w", err)
    }

    productData := map[string]interface{}{
       "name": "Upupa Test Product",
       "price": 49.99,
       "stock": 100,
       "releaseDate": time.Now().Format("2006-01-02"),
       "is_active": true,
    }

    testRecord := models.Record{
       ID: productID,
       CollectionID: productCollectionID,
       Created: time.Now(),
       Updated: time.Now(),
       Data: productData,
    }

    log.Println("Creating test product record...")
    if _, err := recRepo.CreateRecord(testRecord); err != nil {
       return fmt.Errorf("failed to create test product record: %w", err)
    }

    log.Println("Product collection and test record initialized successfully.")
    return nil
}