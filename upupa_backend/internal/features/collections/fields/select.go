// upupa_backend/internal/features/collections/fields/select.go
package fields

import (
	"fmt"
)

type SelectFieldValidator struct {
	Field SchemaField
}

func (v *SelectFieldValidator) Validate(value any) error {
	if value == nil {
		if v.Field.Required {
			return fmt.Errorf("فیلد انتخابی %s الزامی است", v.Field.Name)
		}
		return nil
	}

	options := v.Field.Options
	maxSelect, _ := options["maxSelect"].(float64)
	if maxSelect <= 0 {
		maxSelect = 1
	}

	allowedValues, _ := options["values"].([]any)

	switch val := value.(type) {
	case string:
		if maxSelect > 1 {
			return fmt.Errorf("فیلد %s باید شامل چند گزینه باشد", v.Field.Name)
		}
		if !isValAllowed(val, allowedValues) {
			return fmt.Errorf("مقدار انتخابی برای فیلد %s نامعتبر است", v.Field.Name)
		}
	case []any:
		if float64(len(val)) > maxSelect {
			return fmt.Errorf("تعداد گزینه‌های انتخاب شده برای فیلد %s بیشتر از حد مجاز است", v.Field.Name)
		}
		for _, item := range val {
			strItem, ok := item.(string)
			if !ok || !isValAllowed(strItem, allowedValues) {
				return fmt.Errorf("یکی از گزینه‌های انتخاب شده برای فیلد %s نامعتبر است", v.Field.Name)
			}
		}
	default:
		return fmt.Errorf("نوع داده ورودی برای فیلد انتخابی %s نامعتبر است", v.Field.Name)
	}

	return nil
}

func isValAllowed(val string, allowed []any) bool {
	if len(allowed) == 0 {
		return true
	}
	for _, a := range allowed {
		if strA, ok := a.(string); ok && strA == val {
			return true
		}
	}
	return false
}
