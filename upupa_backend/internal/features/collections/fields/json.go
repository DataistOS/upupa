// upupa_backend/internal/features/collections/fields/json.go
package fields

import (
	"encoding/json"
	"fmt"
)

type JsonFieldValidator struct {
	Field SchemaField
}

func (v *JsonFieldValidator) Validate(value any) error {
	if value == nil {
		if v.Field.Required {
			return fmt.Errorf("فیلد JSON برای %s الزامی است", v.Field.Name)
		}
		return nil
	}

	_, err := json.Marshal(value)
	if err != nil {
		return fmt.Errorf("ساختار داده برای فیلد JSON در %s نامعتبر است", v.Field.Name)
	}

	return nil
}
