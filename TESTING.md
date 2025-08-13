# Testing Documentation

## Overview

This project uses **Vitest** as the testing framework with **React Testing Library** for component testing. The testing setup provides comprehensive coverage for components, utilities, and integration tests.

## Testing Stack

- **Vitest**: Fast unit testing framework
- **React Testing Library**: Component testing utilities
- **jsdom**: DOM environment for testing
- **@testing-library/user-event**: User interaction simulation
- **@vitest/coverage-v8**: Code coverage reporting

## Test Structure

```
src/
├── test/
│   ├── setup.ts          # Global test configuration
│   ├── utils.tsx         # Test utilities and helpers
│   └── basic.test.ts     # Basic test examples
├── components/
│   └── *.test.tsx        # Component tests
└── lib/
    └── *.test.ts         # Utility function tests
```

## Running Tests

### Development Mode
```bash
npm run test
```
Runs tests in watch mode with UI interface.

### Single Run
```bash
npm run test:run
```
Runs all tests once and exits.

### Coverage Report
```bash
npm run test:coverage
```
Generates detailed coverage report.

### CI Mode
```bash
npm run test:ci
```
Runs tests with coverage and verbose output for CI/CD.

## Test Categories

### 1. Unit Tests
- **Utility Functions**: Test individual functions in isolation
- **Helper Functions**: Test data transformation and validation
- **Pure Functions**: Test functions with no side effects

### 2. Component Tests
- **Rendering**: Verify components render correctly
- **User Interactions**: Test user interactions and state changes
- **Props**: Test component behavior with different props
- **Accessibility**: Ensure components are accessible

### 3. Integration Tests
- **API Integration**: Test Supabase interactions
- **Routing**: Test navigation and routing behavior
- **State Management**: Test complex state interactions

## Test Utilities

### Mock Data Factories
```typescript
import { createMockPin, createMockBed, createMockPlantDetails } from '../test/utils';

const mockPin = createMockPin({ name: 'Custom Plant' });
const mockBed = createMockBed({ name: 'Custom Bed' });
```

### Custom Render Function
```typescript
import { render, screen } from '../test/utils';

// Automatically includes Router and other providers
render(<MyComponent />);
```

### User Event Simulation
```typescript
import userEvent from '@testing-library/user-event';

const user = userEvent.setup();
await user.click(screen.getByText('Submit'));
await user.type(screen.getByLabelText('Name'), 'Test Plant');
```

## Mocking Strategy

### External Dependencies
- **Supabase**: Mocked to avoid real database calls
- **React Router**: Mocked for isolated component testing
- **Environment Variables**: Mocked for consistent test environment

### Browser APIs
- **fetch**: Mocked for API testing
- **File API**: Mocked for file upload testing
- **IntersectionObserver**: Mocked for scroll-based components

## Coverage Goals

- **Statements**: 70%
- **Branches**: 70%
- **Functions**: 70%
- **Lines**: 70%

## Best Practices

### 1. Test Structure
```typescript
describe('ComponentName', () => {
  it('should render correctly', () => {
    // Test implementation
  });

  it('should handle user interactions', async () => {
    // Test implementation
  });
});
```

### 2. Test Naming
- Use descriptive test names
- Follow the pattern: "should [expected behavior] when [condition]"
- Group related tests in describe blocks

### 3. Assertions
- Test behavior, not implementation
- Use semantic queries (getByRole, getByLabelText)
- Avoid testing implementation details

### 4. Async Testing
```typescript
it('should handle async operations', async () => {
  await waitFor(() => {
    expect(screen.getByText('Loaded')).toBeInTheDocument();
  });
});
```

## Common Patterns

### Testing Components with Props
```typescript
it('should render with different props', () => {
  const { rerender } = render(<Component name="Test" />);
  expect(screen.getByText('Test')).toBeInTheDocument();

  rerender(<Component name="Updated" />);
  expect(screen.getByText('Updated')).toBeInTheDocument();
});
```

### Testing User Interactions
```typescript
it('should handle form submission', async () => {
  const user = userEvent.setup();
  const onSubmit = vi.fn();

  render(<Form onSubmit={onSubmit} />);
  
  await user.type(screen.getByLabelText('Name'), 'Test Plant');
  await user.click(screen.getByText('Submit'));

  expect(onSubmit).toHaveBeenCalledWith({ name: 'Test Plant' });
});
```

### Testing API Calls
```typescript
it('should fetch data on mount', async () => {
  const mockData = [{ id: 1, name: 'Test' }];
  vi.mocked(fetch).mockResolvedValueOnce({
    ok: true,
    json: () => Promise.resolve(mockData)
  } as Response);

  render(<DataComponent />);

  await waitFor(() => {
    expect(screen.getByText('Test')).toBeInTheDocument();
  });
});
```

## Debugging Tests

### 1. Debug Output
```typescript
screen.debug(); // Print current DOM
screen.debug(element); // Print specific element
```

### 2. Test Isolation
```typescript
beforeEach(() => {
  vi.clearAllMocks();
  // Reset any global state
});
```

### 3. Async Debugging
```typescript
await waitFor(() => {
  expect(screen.getByText('Expected')).toBeInTheDocument();
}, { timeout: 5000 });
```

## CI/CD Integration

The project includes GitHub Actions workflow that:
- Runs tests on multiple Node.js versions
- Generates coverage reports
- Performs security audits
- Deploys to Vercel on successful tests

## Troubleshooting

### Common Issues

1. **Test Environment**: Ensure jsdom is properly configured
2. **Async Operations**: Use waitFor for async state changes
3. **Mocking**: Verify mocks are properly set up
4. **Timing**: Add appropriate timeouts for slow operations

### Performance Tips

1. **Mock Heavy Dependencies**: Mock external APIs and databases
2. **Test Isolation**: Avoid shared state between tests
3. **Selective Testing**: Use test patterns to run specific tests
4. **Parallel Execution**: Vitest runs tests in parallel by default

## Future Improvements

- [ ] Add E2E tests with Playwright
- [ ] Implement visual regression testing
- [ ] Add performance testing
- [ ] Expand accessibility testing
- [ ] Add mutation testing



