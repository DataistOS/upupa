// upupa_backend/internal/features/collections/fields/factory.go
package fields

import "fmt"

func NewValidator(field SchemaField) (Validator, error) {
	switch field.Type {
	case FieldTypeText, FieldTypeEditor, FieldTypeEmail, FieldTypeUrl:
		return &TextFieldValidator{Field: field}, nil
	case FieldTypeNumber:
		return &NumberFieldValidator{Field: field}, nil
	case FieldTypeBool:
		return &BoolFieldValidator{Field: field}, nil
	case FieldTypeDate, FieldTypeAutodate:
		return &DateFieldValidator{Field: field}, nil
	case FieldTypeSelect:
		return &SelectFieldValidator{Field: field}, nil
	case FieldTypeFile:
		return &FileFieldValidator{Field: field}, nil
	case FieldTypeRelation:
		return &RelationFieldValidator{Field: field}, nil
	case FieldTypeJson:
		return &JsonFieldValidator{Field: field}, nil
	case FieldTypeGeoPoint:
		return &GeoPointFieldValidator{Field: field}, nil
	default:
		return nil, fmt.Errorf("نوع فیلد نامعتبر یا پشتیبانی نشده است: %s", field.Type)
	}
}
