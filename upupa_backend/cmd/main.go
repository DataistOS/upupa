// upupa_backend/cmd/main.go
package main

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"time"

	"upupa_backend/internal/features/auth"
	"upupa_backend/internal/features/collections"
	"upupa_backend/internal/features/logs"
	"upupa_backend/internal/features/profile"
	"upupa_backend/internal/features/storage"
	"upupa_backend/internal/store"
	"upupa_backend/pkg/models"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/spf13/cobra"
)

const DB_FILE = "storage/upupa_backend.db"

var Version = "(untracked)"

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

	if err := dbStore.InitLogTable(); err != nil {
		log.Fatalf("Failed to initialize log table: %v", err)
	}
	log.Println("Log table initialized successfully.")

	if err := dbStore.InitPasswordResetTable(); err != nil {
		log.Fatalf("Failed to initialize password reset table: %v", err)
	}
	log.Println("Password reset table initialized successfully.")

	if err := createSystemCollections(dbStore); err != nil {
		log.Fatalf("Failed to create system collections: %v", err)
	}
	log.Println("System collections created successfully.")

	if err := createProductCollection(dbStore, dbStore); err != nil {
		log.Fatalf("Failed to create product records: %v", err)
	}
	log.Println("Product collection and test record initialized successfully.")

	authHandler := auth.NewHandler(dbStore)
	passwordResetHandler := auth.NewPasswordResetHandler(dbStore, dbStore)

	profileHandler := profile.NewHandler(dbStore, dbStore)
	storageHandler := storage.NewHandler(dbStore)
	collectionHandler := collections.NewHandler(dbStore, dbStore, dbStore)

	router := chi.NewRouter()

	router.Use(middleware.Logger)
	router.Use(middleware.Recoverer)

	router.Use(logs.RequestLoggerMiddleware(dbStore))

	router.Get("/health", collectionHandler.HealthCheck)

	router.Route("/api/v1", func(r chi.Router) {
		r.Post("/register", authHandler.RegisterHandler)
		r.Post("/login", authHandler.LoginHandler)

		r.Post("/auth/password-reset", passwordResetHandler.RequestPasswordResetHandler)
		r.Post("/auth/password-reset-confirm", passwordResetHandler.ConfirmPasswordResetHandler)

		r.Get("/profile", profileHandler.GetProfileHandler)
		r.Put("/profile", profileHandler.UpdateProfileHandler)

		r.Get("/logs", logs.GetLogsHandler(dbStore))

		r.Post("/files", storageHandler.UploadFileHandler)
		r.Get("/files/{filename}", storageHandler.ServeFileHandler)

		r.Post("/collections", collectionHandler.CreateCollectionHandler)
		r.Get("/collections", collectionHandler.ListCollectionsHandler)

		r.Route("/collections/{name}", func(r chi.Router) {
			r.Get("/", collectionHandler.GetCollectionHandler)
			r.Patch("/", collectionHandler.UpdateCollectionHandler)
			r.Delete("/", collectionHandler.DeleteCollectionHandler)

			r.Post("/records", collectionHandler.CreateRecordHandler)
			r.Get("/records", collectionHandler.ListRecordsHandler)

			r.Route("/records/{id}", func(r chi.Router) {
				r.Get("/", collectionHandler.GetRecordHandler)
				r.Patch("/", collectionHandler.UpdateRecordHandler)
				r.Put("/", collectionHandler.UpdateRecordHandler)
				r.Delete("/", collectionHandler.DeleteRecordHandler)
			})
		})
	})

	var showVersion bool
	var rootCmd = &cobra.Command{
		Use:   "upupa",
		Short: "Upupa backend CLI management tool",
		Run: func(cmd *cobra.Command, args []string) {
			if showVersion {
				fmt.Printf("Upupa Backend Version: %s\n", Version)
				return
			}
			cmd.Help()
		},
	}

	rootCmd.PersistentFlags().BoolVarP(
		&showVersion,
		"version",
		"v",
		false,
		"Print the version of Upupa backend",
	)

	rootCmd.AddCommand(NewServeCommand(router, Version))

	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
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
			ID:     productCollectionID,
			Name:   "products",
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
		"name":        "Upupa Test Product",
		"price":       49.99,
		"stock":       100,
		"releaseDate": time.Now().Format("2006-01-02"),
		"is_active":   true,
	}

	testRecord := models.Record{
		ID:           productID,
		CollectionID: productCollectionID,
		Created:      time.Now(),
		Updated:      time.Now(),
		Data:         productData,
	}

	log.Println("Creating test product record...")
	if _, err := recRepo.CreateRecord(testRecord); err != nil {
		return fmt.Errorf("failed to create test product record: %w", err)
	}

	log.Println("Product collection and test record initialized successfully.")
	return nil
}
