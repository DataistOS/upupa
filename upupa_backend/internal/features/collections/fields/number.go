// upupa_backend/internal/features/collections/fields/number.go
package fields

import (
	"fmt"
)

type NumberFieldValidator struct {
	Field SchemaField
}

func (v *NumberFieldValidator) Validate(value any) error {
	if value == nil {
		if v.Field.Required {
			return fmt.Errorf("فیلد عددی %s الزامی است", v.Field.Name)
		}
		return nil
	}

	var numVal float64
	switch val := value.(type) {
	case float64:
		numVal = val
	case int:
		numVal = float64(val)
	case int64:
		numVal = float64(val)
	default:
		return fmt.Errorf("مقدار فیلد %s باید از نوع عدد باشد", v.Field.Name)
	}

	options := v.Field.Options

	if minVal, ok := options["min"].(float64); ok && numVal < minVal {
		return fmt.Errorf("مقدار فیلد %s نباید کمتر از %f باشد", v.Field.Name, minVal)
	}

	if maxVal, ok := options["max"].(float64); ok && numVal > maxVal {
		return fmt.Errorf("مقدار فیلد %s نباید بیشتر از %f باشد", v.Field.Name, maxVal)
	}

	return nil
}
