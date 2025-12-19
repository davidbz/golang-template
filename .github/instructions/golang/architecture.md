---
applyTo: "**/*.go"
---

## Go Architecture Conventions

### Separate Logic and Data

Keeping logic and data separate makes code more maintainable and testable. In Go, this often means separating into different packages.

**Do:**
```go
// models/roles.go
package models

// RolePermissions defines what actions a role can perform
type RolePermissions struct {
	CanEdit   bool
	CanDelete bool
	CanInvite bool
}

// RoleMap defines available roles and their permissions
var RoleMap = map[string]RolePermissions{
	"admin":  {CanEdit: true, CanDelete: true, CanInvite: true},
	"editor": {CanEdit: true, CanDelete: false, CanInvite: false},
	"viewer": {CanEdit: false, CanDelete: false, CanInvite: false},
}

// services/permissions.go
package services

import (
	"context"
	"myapp/models"
)

// PermissionChecker handles permission verification
type PermissionChecker struct {
	// Dependencies injected via constructor
}

// CheckPermission verifies if a user can perform an action
func (p *PermissionChecker) CheckPermission(ctx context.Context, user *models.User, action string) bool {
	if user == nil || user.Role == "" {
		return false
	}

	permissions, exists := models.RoleMap[user.Role]
	if !exists {
		// Default to viewer permissions if role not found
		permissions = models.RoleMap["viewer"]
	}

	switch action {
	case "edit":
		return permissions.CanEdit
	case "delete":
		return permissions.CanDelete
	case "invite":
		return permissions.CanInvite
	default:
		return false
	}
}
```

### Avoid Technology Names in Main Business Flow

If you spot technology names or specific component names in your main business flow, it's not the way to go. Business logic should be abstracted and not coupled to specific technologies.

**Do:**
```go
// Main business flow - no technology names visible
func ProcessUserRegistration(ctx context.Context, userData UserRegistrationData) error {
	// Validate user data
	if err := validateRegistrationData(userData); err != nil {
		return err
	}

	// Create user account
	user, err := createUserAccount(ctx, userData)
	if err != nil {
		return err
	}

	// Send welcome notification
	if err := sendWelcomeMessage(ctx, user); err != nil {
		// Log error but don't fail the registration
		log.Error("failed to send welcome message", "user_id", user.ID, "error", err)
	}

	// Provision access
	return provisionUserAccess(ctx, user)
}

// Technology-specific implementations are abstracted away
type NotificationService interface {
	SendWelcome(ctx context.Context, user *User) error
}

type AccessProvisionService interface {
	ProvisionAccess(ctx context.Context, user *User) error
}
```

**Don't:**
```go
// Bad - technology names leak into business logic
func ProcessUserRegistration(ctx context.Context, userData UserRegistrationData) error {
	// Validate user data
	if err := validateRegistrationData(userData); err != nil {
		return err
	}

	// Create user account
	user, err := createUserAccount(ctx, userData)
	if err != nil {
		return err
	}

	// Send email via SendGrid - technology name in business flow!
	if err := sendGridClient.SendWelcomeEmail(ctx, user.Email); err != nil {
		log.Error("SendGrid failed", "error", err)
	}

	// Provision in Active Directory - technology name in business flow!
	if err := activeDirectoryClient.CreateUser(ctx, user); err != nil {
		return fmt.Errorf("AD provisioning failed: %w", err)
	}

	// Update Salesforce - technology name in business flow!
	return salesforceClient.CreateContact(ctx, user)
}
```

### Don't Mix Standard Logic and Technical Integrations

Separate core business logic from technical integrations like SailPoint. Use the observer pattern to keep these concerns decoupled.

**Do:**
```go
// domain/user_service.go
package domain

import "context"

// UserService handles core user business logic
type UserService struct {
	repo           UserRepository
	eventPublisher EventPublisher
}

func NewUserService(repo UserRepository, publisher EventPublisher) *UserService {
	return &UserService{
		repo:           repo,
		eventPublisher: publisher,
	}
}

func (s *UserService) CreateUser(ctx context.Context, user *User) error {
	// Core business logic
	if err := validateUser(user); err != nil {
		return err
	}

	// Save to database
	if err := s.repo.Save(ctx, user); err != nil {
		return err
	}

	// Publish event for observers (like SailPoint) to react to
	s.eventPublisher.Publish(ctx, "user.created", user)

	return nil
}

// integrations/sailpoint/observer.go
package sailpoint

import "context"

// SailPointObserver implements the Observer interface
type SailPointObserver struct {
	client SailPointClient
}

func (o *SailPointObserver) OnEvent(ctx context.Context, eventType string, data interface{}) {
	switch eventType {
	case "user.created":
		user, ok := data.(*User)
		if ok {
			o.client.SyncUser(ctx, user)
		}
	// Handle other events
	}
}
```

### Everything Goes Through IoC (Dependency Injection) Using Dig

We use [go-dig](https://github.com/uber-go/dig) for dependency injection in Go projects.

**Do:**
```go
import (
	"go.uber.org/dig"
)

// Services with constructor-based dependency injection
type UserController struct {
	userService UserService
	authService AuthService
}

func NewUserController(userService UserService, authService AuthService) *UserController {
	return &UserController{
		userService: userService,
		authService: authService,
	}
}

// In main.go or setup.go
func BuildContainer() *dig.Container {
	container := dig.New()

	// Register dependencies
	container.Provide(initDatabase)
	container.Provide(NewEventBus)
	container.Provide(NewSQLUserRepository)
	container.Provide(NewAuthService)
	container.Provide(NewUserService)
	container.Provide(NewUserController)

	return container
}

func StartApp() {
	container := BuildContainer()

	// Invoke the application entry point
	err := container.Invoke(func(controller *UserController) {
		// Start using the controller
		server := NewServer(controller)
		server.Start()
	})

	if err != nil {
		panic(err)
	}
}
```

### Configuration with godotenv and Dependency Injection

Use `godotenv` to load environment files and `caarlos0/env` to parse configuration. Load once at startup and distribute via DI.

**Do:**
```go
// config/config.go
type Config struct {
	Server ServerConfig
	Auth   AuthConfig
}

type ServerConfig struct {
	Port int `env:"SERVER_PORT" envDefault:"8080"`
}

type AuthConfig struct {
	ClientID string `env:"AUTH_CLIENT_ID"`
	Secret   string `env:"AUTH_CLIENT_SECRET"`
}

// DepConfig for dependency injection
type DepConfig struct {
	dig.Out
	*ServerConfig
	*AuthConfig
}

func Load() *Config {
	for _, file := range []string{".env", ".env.defaults", ".env.secrets"} {
		_ = godotenv.Load(file)
	}
	var cfg Config
	env.Parse(&cfg)
	return &cfg
}

func ParseDependenciesConfig(cfg *Config) DepConfig {
	return DepConfig{dig.Out{}, &cfg.Server, &cfg.Auth}
}

// main.go
container.Provide(config.Load)
container.Provide(config.ParseDependenciesConfig)
container.Provide(func(cfg *config.AuthConfig) *auth.Service {
	return auth.NewService(cfg)
})
```

**Don't:**
```go
// Bad - reading env vars directly in business logic
host := os.Getenv("HOST")

// Bad - global config accessed everywhere
var GlobalConfig *Config
```
