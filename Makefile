.PHONY: build test run clean help mocks mocks-clean mocks-regen test-coverage test-coverage-html deps fmt lint lint-fix

# Build the app binary
build:
	@echo "Building..."
	@go build -o bin/app ./cmd/
	@echo "Build complete: bin/app"

# Generate mocks
mocks:
	@echo "Generating mocks..."
	@mockery --config .mockery.yaml
	@echo "Mocks generated successfully"

# Clean generated mocks
mocks-clean:
	@echo "Cleaning mocks..."
	@rm -rf internal/mocks
	@echo "Mocks cleaned"

# Regenerate mocks (clean + generate)
mocks-regen: mocks-clean mocks
	@echo "Mocks regenerated"

# Run all tests (generates mocks first)
test: mocks
	@echo "Running tests..."
	@go test -v ./...

# Run tests with coverage (for CI)
test-coverage:
	@echo "Running tests with coverage..."
	@go test ./... -race -covermode=atomic -coverprofile=coverage.out -timeout=5m
	@echo "Coverage report generated: coverage.out"

# Run tests with coverage and generate HTML report (for local development)
test-coverage-html: test-coverage
	@echo "Generating HTML coverage report..."
	@go tool cover -html=coverage.out -o coverage.html
	@echo "HTML coverage report generated: coverage.html"

# Run the app
run:
	@echo "Starting..."
	@go run ./cmd/

# Clean build artifacts
clean:
	@echo "Cleaning..."
	@rm -rf bin/
	@rm -f coverage.out coverage.html
	@echo "Clean complete"

# Install dependencies
deps:
	@echo "Installing dependencies..."
	@go mod download
	@go mod tidy

# Format code with the formatters configured in .golangci.yml (gofumpt, goimports, golines)
fmt:
	@echo "Formatting code..."
	@golangci-lint fmt

# Lint code (requires golangci-lint)
lint:
	@echo "Linting code..."
	@golangci-lint run

# Lint code and apply auto-fixes where available
lint-fix:
	@echo "Linting code with auto-fix..."
	@golangci-lint run --fix

# Help
help:
	@echo "Available targets:"
	@echo "  build              - Build the app binary"
	@echo "  test               - Run all tests (generates mocks first)"
	@echo "  test-coverage      - Run tests with coverage (for CI)"
	@echo "  test-coverage-html - Run tests with coverage and generate HTML report"
	@echo "  run                - Run the app"
	@echo "  clean              - Clean build artifacts"
	@echo "  deps               - Install dependencies"
	@echo "  fmt                - Format code (requires golangci-lint)"
	@echo "  lint               - Lint code (requires golangci-lint)"
	@echo "  lint-fix           - Lint code and apply auto-fixes"
	@echo "  mocks              - Generate mocks from interfaces"
	@echo "  mocks-clean        - Remove generated mocks"
	@echo "  mocks-regen        - Clean and regenerate all mocks"
	@echo "  help               - Show this help message"
