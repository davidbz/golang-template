---
applyTo: "**/*.go"
---

## Go Coding Conventions

### Return Early (Circuit Breaker Pattern)

Early returns help reduce nesting and improve code readability by handling edge cases first.

**Do:**
```go
func ProcessUserData(ctx context.Context, user *User) (*ProcessedData, error) {
	if user == nil {
		return nil, errors.New("user is nil")
	}
	if !user.IsActive {
		return nil, errors.New("user is inactive")
	}
	if user.Role != "admin" && user.AccessLevel < 3 {
		return nil, errors.New("insufficient permissions")
	}

	// Main logic here after all validations pass
	return performProcessing(ctx, user)
}
```

**Don't:**
```go
func ProcessUserData(ctx context.Context, user *User) (*ProcessedData, error) {
	if user != nil {
		if user.IsActive {
			if user.Role == "admin" || user.AccessLevel >= 3 {
				// Main logic deeply nested
				return performProcessing(ctx, user)
			} else {
				return nil, errors.New("insufficient permissions")
			}
		} else {
			return nil, errors.New("user is inactive")
		}
	} else {
		return nil, errors.New("user is nil")
	}
}
```

### Avoid Using Else & Use Default Values

Minimizing `else` statements improves readability and reduces complexity. Use default values and early returns to handle common cases.

**Do:**
```go
func GetUserStatus(ctx context.Context, user *User) UserStatus {
	// Default value
	status := UserStatus{
		State:    "offline",
		LastSeen: nil,
	}

	if user == nil {
		return status
	}

	if user.Online {
		return UserStatus{
			State:    "online",
			LastSeen: time.Now(),
		}
	}

	if user.LastActivity != nil {
		return UserStatus{
			State:    "away",
			LastSeen: user.LastActivity,
		}
	}

	return status
}
```

**Don't:**
```go
func GetUserStatus(ctx context.Context, user *User) UserStatus {
	if user != nil {
		if user.Online {
			return UserStatus{
				State:    "online",
				LastSeen: time.Now(),
			}
		} else {
			if user.LastActivity != nil {
				return UserStatus{
					State:    "away",
					LastSeen: user.LastActivity,
				}
			} else {
				return UserStatus{
					State:    "offline",
					LastSeen: nil,
				}
			}
		}
	} else {
		return UserStatus{
			State:    "offline",
			LastSeen: nil,
		}
	}
}
```

### Avoid Using Named Return Values

Named return values can make code harder to read and understand, especially in longer functions. Use explicit returns for clarity.

**Do:**
```go
func ProcessData(ctx context.Context, data []byte) (*Result, error) {
	if len(data) == 0 {
		return nil, errors.New("empty data")
	}

	result, err := parseData(data)
	if err != nil {
		return nil, fmt.Errorf("failed to parse data: %w", err)
	}

	return result, nil
}
```

**Don't:**
```go
func ProcessData(ctx context.Context, data []byte) (result *Result, err error) {
	if len(data) == 0 {
		err = errors.New("empty data")
		return
	}

	result, err = parseData(data)
	if err != nil {
		err = fmt.Errorf("failed to parse data: %w", err)
		return
	}

	return
}
```

### Interface Methods Should Include Context as First Argument

All interface methods should include a context parameter as the first argument to support timeout, cancellation, and request-scoped values.

**Do:**
```go
// UserRepository defines methods for user data access
type UserRepository interface {
	GetByID(ctx context.Context, id string) (*User, error)
	Save(ctx context.Context, user *User) error
	Delete(ctx context.Context, id string) error
}

// Implementation
type SQLUserRepository struct {
	db *sql.DB
}

func (r *SQLUserRepository) GetByID(ctx context.Context, id string) (*User, error) {
	// Use ctx for query timeouts, cancellation
	row := r.db.QueryRowContext(ctx, "SELECT * FROM users WHERE id = ?", id)
	// ... rest of implementation
}
```
