// upupa_backend/internal/store/repository.go
package store

import (
	"upupa_backend/pkg/models"
)

type Store interface {
	InitSchema() error
	CollectionRepository
	RecordRepository
	UserRepository
}

type CollectionRepository interface {
	CreateCollection(models.Collection) (*models.Collection, error)
	GetByName(string) (*models.Collection, error)
	GetAll() ([]models.Collection, error)
	UpdateCollection(models.Collection) (*models.Collection, error)
	DeleteCollection(string) error
}

type RecordRepository interface {
	CreateRecord(models.Record) (*models.Record, error)
	GetByID(collectionID, recordID string) (*models.Record, error)
	Update(models.Record) error
	DeleteRecord(collectionID, recordID string) error
	ListRecords(collectionID string, opts ListOptions) ([]models.Record, error)
}

type UserRepository interface {
	CreateUser(models.User) (*models.User, error)
	GetByEmail(email string) (*models.User, error)
	GetUserByID(userID string) (*models.User, error)
	Register(email, hashedPassword string) (*models.User, error)
}
