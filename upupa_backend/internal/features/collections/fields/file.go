// upupa_backend/internal/features/collections/fields/file.go
package fields

import (
	"fmt"
)

type FileFieldValidator struct {
	Field SchemaField
}

func (v *FileFieldValidator) Validate(value any) error {
	if value == nil {
		if v.Field.Required {
			return fmt.Errorf("فیلد فایل %s الزامی است", v.Field.Name)
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
			return fmt.Errorf("فیلد %s باید شامل چند فایل باشد", v.Field.Name)
		}
	case []any:
		if float64(len(val)) > maxSelect {
			return fmt.Errorf("تعداد فایل‌های آپلود شده در فیلد %s بیشتر از حد مجاز است", v.Field.Name)
		}
	default:
		return fmt.Errorf("مقدار فیلد فایل %s نامعتبر است", v.Field.Name)
	}

	return nil
}
