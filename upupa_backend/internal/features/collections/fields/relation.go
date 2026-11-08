// upupa_backend/internal/features/collections/fields/relation.go
package fields

import (
	"fmt"
)

type RelationFieldValidator struct {
	Field SchemaField
}

func (v *RelationFieldValidator) Validate(value any) error {
	if value == nil {
		if v.Field.Required {
			return fmt.Errorf("فیلد ارتباطی %s الزامی است", v.Field.Name)
		}
		return nil
	}

	options := v.Field.Options
	maxSelect, _ := options["maxSelect"].(float64)
	if maxSelect <= 0 {
		maxSelect = 1
	}

	switch val := value.(type) {
	case string:
		if maxSelect > 1 {
			return fmt.Errorf("فیلد %s باید شامل چندین شناسه ارتباطی باشد", v.Field.Name)
		}
		if val == "" && v.Field.Required {
			return fmt.Errorf("شناسه رکورد در فیلد %s نمی‌تواند خالی باشد", v.Field.Name)
		}
	case []any:
		if float64(len(val)) > maxSelect {
			return fmt.Errorf("تعداد ارجاعات فیلد %s بیشتر از حد مجاز است", v.Field.Name)
		}
		for _, item := range val {
			if _, ok := item.(string); !ok {
				return fmt.Errorf("شناسه رکورد نامعتبر در فیلد ارتباطی %s", v.Field.Name)
			}
		}
	default:
		return fmt.Errorf("نوع داده ورودی برای فیلد ارتباطی %s نامعتبر است", v.Field.Name)
	}

	return nil
}
