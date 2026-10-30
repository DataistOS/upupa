// upupa_backend/internal/store/query.go
package store

import (
	"fmt"
	"strings"
)

type ListOptions struct {
	Page    int
	PerPage int
	Sort    string
	Filter  string
}

func DefaultListOptions() ListOptions {
	return ListOptions{
		Page:    1,
		PerPage: 30,
		Sort:    "-created",
		Filter:  "",
	}
}

func (o ListOptions) GetLimitAndOffset() (int, int) {
	page := o.Page
	if page < 1 {
		page = 1
	}

	perPage := o.PerPage
	if perPage < 1 {
		perPage = 30
	} else if perPage > 500 {
		perPage = 500
	}

	limit := perPage
	offset := (page - 1) * perPage

	return limit, offset
}

func (o ListOptions) ParseSort() string {
	if o.Sort == "" {
		return "created DESC"
	}

	var clauses []string
	parts := strings.Split(o.Sort, ",")

	for _, part := range parts {
		part = strings.TrimSpace(part)
		if part == "" {
			continue
		}

		direction := "ASC"
		field := part

		if strings.HasPrefix(part, "-") {
			direction = "DESC"
			field = strings.TrimPrefix(part, "-")
		} else if strings.HasPrefix(part, "+") {
			field = strings.TrimPrefix(part, "+")
		}

		field = sanitizeIdentifier(field)

		if field != "" {
			var sortCol string
			if field == "id" || field == "created" || field == "updated" || field == "collection_id" {
				sortCol = field
			} else {
				sortCol = fmt.Sprintf("json_extract(data, '$.%s')", field)
			}
			clauses = append(clauses, fmt.Sprintf("%s %s", sortCol, direction))
		}
	}

	if len(clauses) == 0 {
		return "created DESC"
	}

	return strings.Join(clauses, ", ")
}

func (o ListOptions) ParseFilter() (string, []interface{}, error) {
	if strings.TrimSpace(o.Filter) == "" {
		return "", nil, nil
	}

	conditions := strings.Split(o.Filter, "&&")
	var whereClauses []string
	var args []interface{}

	operators := []string{"!=", ">=", "<=", "=", ">", "<", "~"}

	for _, cond := range conditions {
		cond = strings.TrimSpace(cond)
		if cond == "" {
			continue
		}

		var op string
		foundOp := false
		for _, candidate := range operators {
			if strings.Contains(cond, candidate) {
				op = candidate
				foundOp = true
				break
			}
		}

		if !foundOp {
			return "", nil, fmt.Errorf("عبارت فیلتر نامعتبر است: %s", cond)
		}

		parts := strings.SplitN(cond, op, 2)
		if len(parts) != 2 {
			return "", nil, fmt.Errorf("ساختار عبارت فیلتر نادرست است: %s", cond)
		}

		field := sanitizeIdentifier(strings.TrimSpace(parts[0]))
		val := strings.TrimSpace(parts[1])

		if (strings.HasPrefix(val, "'") && strings.HasSuffix(val, "'")) ||
			(strings.HasPrefix(val, "\"") && strings.HasSuffix(val, "\"")) {
			if len(val) >= 2 {
				val = val[1 : len(val)-1]
			}
		}

		var columnExpr string
		if field == "id" || field == "created" || field == "updated" || field == "collection_id" {
			columnExpr = field
		} else {
			columnExpr = fmt.Sprintf("json_extract(data, '$.%s')", field)
		}

		switch op {
		case "=":
			whereClauses = append(whereClauses, fmt.Sprintf("%s = ?", columnExpr))
			args = append(args, val)
		case "!=":
			whereClauses = append(whereClauses, fmt.Sprintf("%s != ?", columnExpr))
			args = append(args, val)
		case ">":
			whereClauses = append(whereClauses, fmt.Sprintf("%s > ?", columnExpr))
			args = append(args, val)
		case ">=":
			whereClauses = append(whereClauses, fmt.Sprintf("%s >= ?", columnExpr))
			args = append(args, val)
		case "<":
			whereClauses = append(whereClauses, fmt.Sprintf("%s < ?", columnExpr))
			args = append(args, val)
		case "<=":
			whereClauses = append(whereClauses, fmt.Sprintf("%s <= ?", columnExpr))
			args = append(args, val)
		case "~":
			whereClauses = append(whereClauses, fmt.Sprintf("%s LIKE ?", columnExpr))
			args = append(args, "%"+val+"%")
		}
	}

	if len(whereClauses) == 0 {
		return "", nil, nil
	}

	return strings.Join(whereClauses, " AND "), args, nil
}

func sanitizeIdentifier(ident string) string {
	return strings.Map(func(r rune) rune {
		if (r >= 'a' && r <= 'z') || (r >= 'A' && r <= 'Z') || (r >= '0' && r <= '9') || r == '_' || r == '.' {
			return r
		}
		return -1
	}, ident)
}
