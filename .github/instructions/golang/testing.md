---
applyTo: "**/*_test.go"
---

# Instructions for Generating Unit Tests in Golang

## Overview

This guide provides instructions for generating unit tests in Golang for the Cerberus project. We use standard Go testing tools along with testify and Mockery for assertions and mocking interfaces.

## Testing Framework

Use Go's built-in testing package (`testing`) along with the following libraries:
- `github.com/stretchr/testify/assert` for assertions
- `github.com/stretchr/testify/require` for fatal assertions
- `github.com/stretchr/testify/mock` for mocking

prefer `require` over `assert` to fail fast.

Tests should follow these principles:

1. Each test should focus on a single piece of functionality
2. Use descriptive test names with pattern `Test{FunctionName}` for the main test function
3. Use subtests with `t.Run()` to test different scenarios, with clear scenario descriptions:
   ```go
   t.Run("Scenario description", func(t *testing.T) {
        // test implementation
   })
   ```
4. Follow the Arrange-Act-Assert pattern:
   - Set up test data and mock expectations
   - Call the function being tested
   - Assert on the results
5. Aim for high code coverage, particularly for critical paths
6. Test both success and error paths

## Test Structure

1. Initialize test dependencies with helper functions:
   ```go
   func initTest(t *testing.T) (*serviceUnderTest, *mocks) {
       mocks := &mocks{
           mockDependency1: dependency1.NewMockInterface(t),
           mockDependency2: dependency2.NewMockInterface(t),
       }

       // Set up common mock expectations
       mocks.mockDependency1.EXPECT().SomeMethod().Return(expectedValue).Maybe()

       // Initialize service under test with mocks
       service := NewService(mocks.mockDependency1, mocks.mockDependency2)

       return service, mocks
   }
   ```

2. Define test variables at the beginning of each test or subtest:
   ```go
   var (
       ctx = context.Background()
       id = uuid.NewString()
       expectedResult = "expected value"
   )
   ```

3. For multiple related scenarios, use subtests with a common setup and varied test cases

## Using Mockery for Mocks

We use [Mockery](https://github.com/vektra/mockery) to generate mock implementations of interfaces. Mocks for all interfaces exist in the project.

### How to Use Mockery in Tests

1. Define a mocks struct to hold all dependencies:
   ```go
   type mocks struct {
       mockDependency1 *dependency1.MockInterface
       mockDependency2 *dependency2.MockInterface
   }
   ```

2. Create mock instances in the test setup:
   ```go
   mockObj := dependency.NewMockInterface(t)
   ```

3. Set expectations using the mock:
   ```go
   // For exact parameters
   mockObj.EXPECT().MethodName(expectedParam).Return(expectedResult, nil).Once()

   // For any parameters
   mockObj.EXPECT().MethodName(mock.Anything).Return(expectedResult, nil).Once()

   // Optional expectations
   mockObj.EXPECT().MethodName(mock.Anything).Return(expectedResult, nil).Maybe()
   ```

4. Verify expectations are automatically checked by Mockery at the end of the test

## Assertions

Use appropriate assertion functions for different situations:

```go
// For verifying success cases
assert.NoError(t, err)
assert.Equal(t, expected, actual)
assert.Contains(t, slice, element)

// For fatal assertions that should stop the test immediately
require.NoError(t, err)
require.NotNil(t, result)
```

## Running Tests

After creating tests, always run them to verify they work correctly. Use the following command to run tests in the current package:

```bash
go test -v ./...
```

To run a specific test:

```bash
go test -v -run TestFunctionName
```
Make sure all tests pass before submitting your changes.
If a test fails, debug the issue by examining the test logs and fixing either the test or the code under test as appropriate.
