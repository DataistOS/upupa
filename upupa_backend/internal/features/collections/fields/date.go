// upupa_backend/internal/features/collections/fields/date.go
package fields

import (
	"fmt"
	"time"
)

type DateFieldValidator struct {
	Field SchemaField
}

func (v *DateFieldValidator) Validate(value any) error {
	if value == nil {
		if v.Field.Required {
			return fmt.Errorf("فیلد تاریخ %s الزامی است", v.Field.Name)
		}
		return nil
	}

	strVal, ok := value.(string)
	if !ok {
		return fmt.Errorf("مقدار فیلد تاریخ %s باید رشته‌ای باشد", v.Field.Name)
	}

	parsedTime, err := time.Parse(time.RFC3339, strVal)
	if err != nil {
		parsedTime, err = time.Parse("2006-01-02 15:04:05", strVal)
		if err != nil {
			parsedTime, err = time.Parse("2006-01-02", strVal)
			if err != nil {
				return fmt.Errorf("فرمت تاریخ فیلد %s نامعتبر است", v.Field.Name)
			}
		}
	}

	options := v.Field.Options

	if minStr, ok := options["min"].(string); ok && minStr != "" {
		minTime, err := time.Parse("2006-01-02 15:04:05", minStr)
		if err != nil {
			minTime, _ = time.Parse("2006-01-02", minStr)
		}
		if parsedTime.Before(minTime) {
			return fmt.Errorf("تاریخ فیلد %s نباید قبل از %s باشد", v.Field.Name, minStr)
		}
	}

	if maxStr, ok := options["max"].(string); ok && maxStr != "" {
		maxTime, err := time.Parse("2006-01-02 15:04:05", maxStr)
		if err != nil {
			maxTime, _ = time.Parse("2006-01-02", maxStr)
		}
		if parsedTime.After(maxTime) {
			return fmt.Errorf("تاریخ فیلد %s نباید بعد از %s باشد", v.Field.Name, maxStr)
		}
	}

	return nil
}
