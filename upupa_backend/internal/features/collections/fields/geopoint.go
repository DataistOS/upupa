// upupa_backend/internal/features/collections/fields/geopoint.go
package fields

import (
	"fmt"
)

type GeoPointFieldValidator struct {
	Field SchemaField
}

func (v *GeoPointFieldValidator) Validate(value any) error {
	if value == nil {
		if v.Field.Required {
			return fmt.Errorf("فیلد مختصات جغرافیایی %s الزامی است", v.Field.Name)
		}
		return nil
	}

	m, ok := value.(map[string]any)
	if !ok {
		return fmt.Errorf("فیلد مختصات جغرافیایی %s باید شامل طول و عرض جغرافیایی باشد", v.Field.Name)
	}

	lat, okLat := m["lat"].(float64)
	lng, okLng := m["lng"].(float64)

	if !okLat || !okLng {
		return fmt.Errorf("مقادیر lat و lng در فیلد %s باید از نوع عدد باشند", v.Field.Name)
	}

	if lat < -90 || lat > 90 {
		return fmt.Errorf("مقدار عرض جغرافیایی (lat) در فیلد %s باید بین -90 و 90 باشد", v.Field.Name)
	}

	if lng < -180 || lng > 180 {
		return fmt.Errorf("مقدار طول جغرافیایی (lng) در فیلد %s باید بین -180 و 180 باشد", v.Field.Name)
	}

	return nil
}
