// upupa_backend/internal/features/collections/fields/text.go
package fields

import (
	"fmt"
	"regexp"
	"strings"
)

type TextFieldValidator struct {
	Field SchemaField
}

func (v *TextFieldValidator) Validate(value any) error {
	if value == nil || value == "" {
		if v.Field.Required {
			return fmt.Errorf("فیلد %s الزامی است", v.Field.Name)
		}
		return nil
	}

	strVal, ok := value.(string)
	if !ok {
		return fmt.Errorf("مقدار فیلد %s باید از نوع متنی باشد", v.Field.Name)
	}

	options := v.Field.Options

	if minLen, ok := options["min"].(float64); ok && len(strVal) < int(minLen) {
		return fmt.Errorf("تعداد کاراکترهای فیلد %s نباید کمتر از %d باشد", v.Field.Name, int(minLen))
	}

	if maxLen, ok := options["max"].(float64); ok && len(strVal) > int(maxLen) {
		return fmt.Errorf("تعداد کاراکترهای فیلد %s نباید بیشتر از %d باشد", v.Field.Name, int(maxLen))
	}

	if pattern, ok := options["pattern"].(string); ok && pattern != "" {
		matched, err := regexp.MatchString(pattern, strVal)
		if err != nil || !matched {
			return fmt.Errorf("فرمت وارد شده برای فیلد %s معتبر نیست", v.Field.Name)
		}
	}

	if v.Field.Type == FieldTypeEmail && !strings.Contains(strVal, "@") {
		return fmt.Errorf("فرمت ایمیل در فیلد %s نامعتبر است", v.Field.Name)
	}

	return nil
}
