// upupa_backend/internal/features/collections/fields/bool.go
package fields

import (
	"fmt"
)

type BoolFieldValidator struct {
	Field SchemaField
}

func (v *BoolFieldValidator) Validate(value any) error {
	if value == nil {
		if v.Field.Required {
			return fmt.Errorf("فیلد بولین %s الزامی است", v.Field.Name)
		}
		return nil
	}

	_, ok := value.(bool)
	if !ok {
		return fmt.Errorf("مقدار فیلد بولین %s باید از نوع صحیح/غلط (True/False) باشد", v.Field.Name)
	}

	return nil
}
