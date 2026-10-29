// upupa_backend/pkg/models/models.go
package models

import (
    "crypto/rand"
    "encoding/hex"
    "fmt"
    "strings"
    "time"
)

type Field struct {
    Name         string      `json:"name"`
    Type         string      `json:"type"`
    Required     bool        `json:"required"`
    DefaultValue interface{} `json:"defaultValue,omitempty"`
    CollectionId string      `json:"collectionId,omitempty"`
}

type Rule struct {
    Name      string `json:"name"`
    Type      string `json:"type"`
    Condition string `json:"condition"`
    Action    string `json:"action"`
    Enabled   bool   `json:"enabled"`
}

type Collection struct {
    ID          string    `json:"id"`
    Name        string    `json:"name"`
    System      bool      `json:"system"`
    Created     time.Time `json:"created"`
    Updated     time.Time `json:"updated"`
    Schema      []Field   `json:"schema"`
    Rules       []Rule    `json:"rules"`
    RecordCount int       `json:"recordCount"`
}

type Record struct {
    ID           string                 `json:"id"`
    CollectionID string                 `json:"collectionId"`
    Created      time.Time              `json:"created"`
    Updated      time.Time              `json:"updated"`
    Data         map[string]interface{} `json:"data"`
    Expand       map[string]interface{} `json:"expand,omitempty"`
}

type User struct {
    ID           string    `json:"id"`
    Email        string    `json:"email"`
    PasswordHash string    `json:"-"`
    IsAdmin      bool      `json:"is_admin"`
    Created      time.Time `json:"created"`
    Updated      time.Time `json:"updated"`
}

func (u *User) SafeUser() *User {
    safeUser := *u
    safeUser.PasswordHash = ""
    return &safeUser
}

func NewID() string {
    b := make([]byte, 6)
    if _, err := rand.Read(b); err != nil {
       return fmt.Sprintf("%x", time.Now().UnixNano())
    }
    return hex.EncodeToString(b)
}

func Slugify(s string) string {
    s = strings.ToLower(s)
    s = strings.ReplaceAll(s, " ", "-")
    return s
}