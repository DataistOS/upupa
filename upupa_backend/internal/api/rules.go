// upupa_backend/internal/api/rules.go
package api

import (
	"fmt"
	"strings"

	"upupa_backend/pkg/models"
)

func CheckCollectionRule(col models.Collection, actionType string, isAuthenticated bool) error {
	var targetRule *models.Rule
	for _, rule := range col.Rules {
		if strings.EqualFold(rule.Type, actionType) {
			targetRule = &rule
			break
		}
	}

	if targetRule == nil || !targetRule.Enabled {
		return nil
	}

	cond := strings.TrimSpace(targetRule.Condition)
	if cond == "" || cond == "true" {
		return nil
	}

	if strings.Contains(cond, "@request.auth.id") {
		if !isAuthenticated {
			return fmt.Errorf("access denied: authentication required for action '%s'", actionType)
		}
	}

	return nil
}