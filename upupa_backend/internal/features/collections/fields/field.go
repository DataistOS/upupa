// upupa_backend/internal/features/collections/fields/field.go
package fields

type FieldType string

const (
	FieldTypeText     FieldType = "text"
	FieldTypeEditor   FieldType = "editor"
	FieldTypeNumber   FieldType = "number"
	FieldTypeBool     FieldType = "bool"
	FieldTypeEmail    FieldType = "email"
	FieldTypeUrl      FieldType = "url"
	FieldTypeDate     FieldType = "date"
	FieldTypeAutodate FieldType = "autodate"
	FieldTypeSelect   FieldType = "select"
	FieldTypeFile     FieldType = "file"
	FieldTypeRelation FieldType = "relation"
	FieldTypeJson     FieldType = "json"
	FieldTypeGeoPoint FieldType = "geoPoint"
)

type SchemaField struct {
	ID       string         `json:"id"`
	Name     string         `json:"name"`
	Type     FieldType      `json:"type"`
	Required bool           `json:"required"`
	Options  map[string]any `json:"options"`
}

type Validator interface {
	Validate(value any) error
}
