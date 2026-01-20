---
name: typescript-best-practices
description: TypeScript best practices and coding guidelines. Use when the user asks to "review TypeScript code", "check my TS code", "review this TypeScript", or when writing, reviewing, or refactoring TypeScript code. Applies to projects with tsconfig.json or .ts/.tsx files. Provides dos and don'ts for type design, naming conventions, generics, and patterns.
---

# TypeScript Best Practices

Guidelines for writing clean, type-safe, and maintainable TypeScript code.

> **Note:** If the repository has established code style conventions, follow those first. These guidelines serve as defaults.

## Core Principles

1. **Type-First Design** - Define types before implementation; minimize reliance on inference
2. **Interface for Structure** - Use `interface` for objects, `type` for unions/mapped/conditional
3. **Namespace for Type Organization** - Group related types with namespaces (types only, not runtime)
4. **Generic Const for Strictness** - Use `<const TConfig>` for strict literal inference
5. **Extract, Don't Redefine** - Get types from existing definitions instead of duplicating
6. **Strictest Config** - Use strictest tsconfig base; install `ts-reset` for saner built-in types

## Quick Reference

### interface vs type

| Use | When |
|-----|------|
| `interface` | Object structures, class contracts, extensible APIs |
| `type` | Union types, mapped types, conditional types, tuples |

### Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Interface/Type | PascalCase | `UserProfile`, `ResponseData` |
| Generic parameters | `T` prefix | `TUser`, `TConfig` (never bare `T`, `K`, `V`) |
| Acronyms | First cap only | `userId`, `ApiResponse` (NOT `userID`, `APIResponse`) |
| Constants | UPPER_SNAKE | `MAX_RETRY_COUNT` |
| Variables/Functions | camelCase | `getUserById`, `isActive` |

#### Generic Parameter Naming

The `T` prefix applies to **all** generic type parameters, not just top-level ones:

```typescript
// ✓ DO: Use T prefix everywhere
type Nullable<TValue> = TValue | null;

type MyPick<TObj, TKey extends keyof TObj> = {
  [TProp in TKey]: TObj[TProp];
};

type ArrayElement<TValue> = TValue extends Array<infer TItem> ? TItem : never;

function merge<TTarget, TSource>(target: TTarget, source: TSource): TTarget & TSource;

// ✗ DON'T: Use single letters
type Nullable<T> = T | null;

type MyPick<T, K extends keyof T> = {
  [P in K]: T[P];
};

type ArrayElement<T> = T extends Array<infer U> ? U : never;

function merge<A, B>(target: A, source: B): A & B;
```

Common patterns:
- `TValue`, `TItem`, `TElement` — for generic values
- `TKey`, `TProp` — for object keys in mapped types
- `TInput`, `TOutput`, `TResult` — for function parameters/returns
- `TConfig`, `TOptions` — for configuration objects

## Type Design Patterns

### Namespace Pattern for Type Organization

Group related types with function using namespace. Put documentation on the namespace.

```typescript
/**
 * Creates a debounced function that delays invoking `func` until after
 * `wait` milliseconds have elapsed since the last invocation.
 */
namespace debounce {
  /**
   * Configuration options for the debounced function.
   */
  export interface Options {
    /** Delay in milliseconds before the function is invoked */
    wait: number;
    /** If true, invoke on the leading edge instead of trailing */
    immediate: boolean;
  }

  export type Ret = () => void;

  export type Type = (func: (...args: unknown[]) => void, options: Options) => Ret;
}

const debounce: debounce.Type = (func, options) => {
  // implementation
};

export { debounce };
```

### Multiple Call Signatures

When a function has overloads, define separate interfaces and extend.

**Why separate interfaces?**
- Each signature can be **reused independently** in other types
- Simplifies **runtime implementation** — complex overload types in a single interface make it hard to implement without `as any` or type errors
- Better **type inference** for polymorphic components — TypeScript handles extends-based composition more predictably than inline overloads

```typescript
// ✓ DO: Extend separate interfaces
namespace myFunction {
  export interface TypeBasic {
    (options: Options): Ret;
  }
  export interface TypeWithExtra {
    (options: Options, extra: boolean): RetWithExtra;
  }
  export interface Type extends TypeBasic, TypeWithExtra {}
}

// ✗ DON'T: Define all signatures in one interface
namespace myFunction {
  export interface Type {
    (options: Options): Ret;
    (options: Options, extra: boolean): RetWithExtra;
  }
}
```

### Function with Additional Properties

For functions that also have properties (like `myFunc.defaultOptions`):

```typescript
namespace myFunction {
  export interface Options {
    wait: number;
    immediate: boolean;
  }
  export type Ret = () => void;

  export type TypeImpl = (options: Options) => Ret;

  export interface AllInOneProps {
    defaultOptions: Options;
  }

  export type Type = TypeImpl & AllInOneProps;
}

const myFunctionImpl: myFunction.TypeImpl = (options) => {
  // implementation
};

const defaultOptions: myFunction.Options = {
  wait: 300,
  immediate: false,
};

const allInOneProps: myFunction.AllInOneProps = {
  defaultOptions,
};

const myFunction: myFunction.Type = Object.assign(myFunctionImpl, allInOneProps);

export { myFunction };
```

#### Tree-Shaking Considerations

This pattern bundles everything together, which may prevent tree-shaking. Use it wisely:

| Pattern | When to Use | Example |
|---------|-------------|---------|
| All-in-one props | Features frequently used together | `Select.Option` - almost always used with Select |
| Separate exports | Independent features, not always needed | `AutoComplete` - adds bundle size, not always used |

**✓ DO: Bundle tightly coupled features**

```typescript
// Good: Option is almost always used with Select
const Select: Select.Type = Object.assign(SelectImpl, { Option });
export { Select };

// Usage: Select.Option is convenient and expected
<Select>
  <Select.Option value="1">One</Select.Option>
</Select>
```

**✗ DON'T: Bundle independent features that increase bundle size**

```typescript
// Bad: AutoComplete adds significant size and isn't always needed
const Select: Select.Type = Object.assign(SelectImpl, {
  Option,
  AutoComplete, // ← Increases bundle even when unused
});
```

**✓ DO: Export independent features separately**

```typescript
// Good: Let users import only what they need
export { Select };
export { AutoComplete };

// Users can choose:
import { Select } from 'my-lib';           // Just Select
import { Select, AutoComplete } from 'my-lib';  // Both
import * as SelectLib from 'my-lib';       // Namespace access: SelectLib.AutoComplete
```

## DO and DON'T

### Type Declarations

| DO | DON'T |
|----|-------|
| `interface User { id: string }` for objects | `type User = { id: string }` for simple objects |
| `type Status = 'active' \| 'inactive'` for unions | `interface` for union types (impossible) |
| `type NullableProps<TObj> = { [TProp in keyof TObj]: TObj[TProp] \| null }` | `interface` for mapped types (impossible) |

### Array Type Syntax

| DO | DON'T |
|----|-------|
| `Array<TItem>` | `TItem[]` |
| `ReadonlyArray<TItem>` | `readonly TItem[]` |

```typescript
// ✓ DO: Generic syntax is more explicit
type Users = Array<User>;
type ReadonlyUsers = ReadonlyArray<User>;
type Matrix = Array<Array<number>>;

function getItems(): Array<Item> { /* ... */ }

// ✗ DON'T: Bracket syntax is less visible
type Users = User[];
type ReadonlyUsers = readonly User[];
type Matrix = number[][];

function getItems(): Item[] { /* ... */ }
```

**Why prefer `Array<T>`:**
- More explicit and visible than `[]` suffix
- Consistent with other generic types (`Map<K, V>`, `Set<T>`, `Promise<T>`)
- `ReadonlyArray<T>` is cleaner than `readonly T[]`
- Nested arrays are more readable: `Array<Array<T>>` vs `T[][]`

### Object Type Syntax

Avoid `{}` as it accepts almost anything (including primitives in some contexts). Use explicit types instead:

| Use Case | DO | DON'T |
|----------|-----|-------|
| Empty object | `Record<string, never>` | `{}` |
| Any object (generic constraint) | `Record<string, unknown>` | `{}` or `object` |
| Non-primitive | `object` | `{}` |

```typescript
// ✓ DO: Empty object type
type EmptyObject = Record<string, never>;
const empty: EmptyObject = {};  // Only {} is assignable

// ✓ DO: Generic constraint for any object
function merge<TObj extends Record<string, unknown>>(target: TObj, source: TObj): TObj;

// ✓ DO: Use object when excluding primitives
function keys(obj: object): Array<string> {
  return Object.keys(obj);
}
keys({ a: 1 });     // ✓ OK
keys([1, 2, 3]);    // ✓ OK (arrays are objects)
keys('string');     // ✗ Error: string is not object

// ✗ DON'T: {} accepts almost anything
type BadEmpty = {};
const bad: BadEmpty = { unexpected: 'property' };  // No error!
```

**Key differences:**

| Type | Accepts | Use When |
|------|---------|----------|
| `Record<string, never>` | Only `{}` | Truly empty object, no properties allowed |
| `Record<string, unknown>` | Any object with string keys | Type annotations, return types, parameters |
| `Record<string, any>` | Any object with string keys | **Only for `extends` constraints** |
| `object` | Any non-primitive | Excluding `string`, `number`, `boolean`, etc. |
| `{}` | Almost anything except `null`/`undefined` | **Avoid** - too permissive |

```typescript
// ✓ DO: Record<K, any> only in extends constraints
function process<TObj extends Record<string, any>>(obj: TObj): TObj;

// ✓ DO: Record<K, unknown> for type annotations
const config: Record<string, unknown> = {};
function getConfig(): Record<string, unknown> { }

// ✗ DON'T: Record<K, any> as direct type annotation
const badConfig: Record<string, any> = {};

// ✗ DON'T: Record<K, unknown> in extends (too restrictive)
function badProcess<TObj extends Record<string, unknown>>(obj: TObj): TObj;
// ^ This won't accept objects with specific value types
```

**Custom key types:**

```typescript
// Use PropertyKey for all possible keys (string | number | symbol)
type AnyRecord = Record<PropertyKey, unknown>;

// Use specific key type when known
type StringKeyed = Record<string, unknown>;
type NumericKeyed = Record<number, unknown>;
type SymbolKeyed = Record<symbol, unknown>;
```

### any Usage

| DO | DON'T |
|----|-------|
| `function debounce<TFunc extends (...args: Array<any>) => any>` | `const data: any = response` |
| Use `unknown` for truly unknown types | Use `any` to silence errors |
| Parse with zod/arktype, then use inferred type | Cast with `as any` |

```typescript
// ✓ DO: Use any only in generic constraints
function debounce<TFunc extends (...args: Array<any>) => any>(
  func: TFunc,
  wait: number
): TFunc {
  // implementation
}

// ✓ DO: Use runtime validation for unknown data
import { z } from 'zod';
const UserSchema = z.object({ id: z.string(), name: z.string() });
type User = z.infer<typeof UserSchema>;
const user = UserSchema.parse(response); // typed as User

// ✗ DON'T: Use any to bypass type checking
const data: any = await fetch('/api/user').then(r => r.json());
```

### Avoid `as` and `!` Assertions

`as` and `!` bypass type checking and create "type lies" — telling TypeScript something is true without proving it.

| DO | DON'T |
|----|-------|
| Zod/arktype for runtime validation | `response as User` |
| `satisfies` for compile-time checks | `value as unknown as TargetType` |
| Type guards (`if ('prop' in obj)`) | `as any` to silence errors |
| `as const` for literal inference | Force types without validation |
| Explicit null checks (`if (x !== null)`) | `x!` non-null assertion |

```typescript
// ✓ DO: Runtime validation with Zod
import { z } from 'zod';
const UserSchema = z.object({ id: z.string(), name: z.string() });
type User = z.infer<typeof UserSchema>;

const response = await fetch('/api/user').then(r => r.json());
const user = UserSchema.parse(response); // Validated and typed

// ✓ DO: satisfies for compile-time type checking
const config = {
  port: 3000,
  host: 'localhost',
} satisfies ServerConfig;

// ✓ DO: Type guard for narrowing
function isUser(value: unknown): value is User {
  return (
    typeof value === 'object' &&
    value !== null &&
    'id' in value &&
    'name' in value
  );
}
if (isUser(response)) {
  console.log(response.name); // Narrowed to User
}

// ✓ DO: Explicit null check
const element = document.getElementById('app');
if (element === null) {
  throw new Error('Element not found');
}
element.textContent = 'Hello'; // element is HTMLElement

// ✗ DON'T: Type assertion without validation
const unsafeUser = response as User; // No runtime check, could be wrong

// ✗ DON'T: Double assertion to bypass type system
const unsafeValue = someData as unknown as TargetType;

// ✗ DON'T: Non-null assertion
const unsafeElement = document.getElementById('app')!; // Dangerous if null
unsafeElement.textContent = 'Hello'; // Runtime error if element is null
```

**When `as` is acceptable:**

| Context | Example | Why OK |
|---------|---------|--------|
| `as const` | `{ key: 'value' } as const satisfies BaseType` | Narrows inference to literal/readonly, not a type lie |
| Generic constraints | `(...args: Array<any>) => any` | Required for flexible function types |
| Type test files | `anyObj as Result satisfies Expected` | Testing type behavior, not runtime |
| DOM APIs with known context | `document.getElementById('app') as HTMLDivElement` | When you control the HTML |
| After exhaustive narrowing | `as never` in default case | Proves unreachable |

### Function Declarations

| DO | DON'T |
|----|-------|
| `const fn: MyType = (arg) => { }` | `const fn = (arg: ArgType): RetType => { }` |
| `const fn = ((arg) => { }) satisfies MyType` | `function fn(arg: ArgType): RetType { }` |
| Arrow functions for const declarations | Named function expressions |

```typescript
// ✓ DO: Type on the const, implementation infers params
const myFunction: myFunction.Type = (options) => {
  // options is typed from myFunction.Type
};

// ✓ DO: satisfies when namespace doesn't exist
const onClick = ((event) => {
  // implementation
}) satisfies React.ComponentProps<'button'>['onClick'];

// ✗ DON'T: Redundant inline type annotations
const badInlineTypes = (options: myFunction.Options): myFunction.Ret => {
  // implementation
};

// ✗ DON'T: Named function expression
const badNamedExpr: myFunction.Type = function badNamedExpr(options) {
  // implementation
};
```

### Type Extraction

| DO | DON'T |
|----|-------|
| `React.ComponentProps<'button'>['onClick']` | `(e: React.MouseEvent<HTMLButtonElement>) => void` |
| `NonNullable<typeof config['timeout']>` | Manually redefine the type |
| `Parameters<typeof fn>[0]` | Copy parameter types manually |

```typescript
// ✓ DO: Extract types from existing definitions
const onClick: React.ComponentProps<'button'>['onClick'] = (event) => {
  // event is correctly typed
};

// ✓ DO: NonNullable with explicit check
type TimeoutType = NonNullable<typeof config['timeout']>;
if (config.timeout === undefined) {
  throw new Error('timeout is required');
}
const timeout: TimeoutType = config.timeout; // narrowed, no ! needed

// ✗ DON'T: Redefine what already exists
const onClick = (event: React.MouseEvent<HTMLButtonElement>) => {
  // Duplicates the type definition
};
```

### Generic Constants

| DO | DON'T |
|----|-------|
| `defineConfig<const TConfig>(config: TConfig)` | Lose literal types with regular generics |
| `as const satisfies BaseConfig` | `as BaseConfig` (loses specificity) |

```typescript
// ✓ DO: Use const generic for strict inference
function defineConfig<const TConfig extends BaseConfig>(config: TConfig): TConfig {
  return config;
}

const strictConfig = defineConfig({
  routes: ['/home', '/about'], // inferred as readonly ['/home', '/about']
  debug: true,
});
```

```typescript
// ✓ DO: as const satisfies for one-off definitions
const literalConfig = {
  routes: ['/home', '/about'],
  debug: true,
} as const satisfies BaseConfig;
```

```typescript
// ✗ DON'T: Lose literal types
const looseConfig: BaseConfig = {
  routes: ['/home', '/about'], // widened to Array<string>
  debug: true,
};
```

### Namespace Usage

| DO | DON'T |
|----|-------|
| `namespace myFunc { export interface Options {} }` | `namespace Utils { export function helper() {} }` |
| Group types with their function | Use namespace for runtime code |
| Types only in namespaces | Mix types and implementation |

### Safe Array Access

With `noUncheckedIndexedAccess` enabled, array index access returns `T | undefined`. Handle this properly:

```typescript
const items: Array<string> = ['a', 'b', 'c'];

// ✗ DON'T: Index access without null check
for (let i = 0; i < items.length + 10; i++) {
  console.log(items[i].toUpperCase()); // Error: items[i] is string | undefined
}

// ✗ DON'T: Non-null assertion to bypass check
for (let i = 0; i < items.length; i++) {
  console.log(items[i]!.toUpperCase()); // Dangerous: suppresses real errors
}

// ✓ DO: Explicit undefined check
for (let i = 0; i < items.length; i++) {
  const item = items[i];
  if (item === undefined) {
    continue; // or throw new Error('Unreachable');
  }
  console.log(item.toUpperCase()); // item is narrowed to string
}

// ✓ DO: Use for-of when index is not needed
for (const item of items) {
  console.log(item.toUpperCase()); // item is string, no undefined
}

// ✓ DO: Use forEach or map
items.forEach((item) => {
  console.log(item.toUpperCase());
});
```

**Prefer iteration methods over index access** — `for-of`, `forEach`, `map`, `filter` all provide properly typed values without the `undefined` concern.

### Early Return Pattern

Use guard clauses to handle edge cases first, keeping the main logic un-nested:

```typescript
// ✓ DO: Guard clauses with early return
function processUser(user: User | null) {
  if (user === null) {
    return;
  }
  if (!user.isActive) {
    return;
  }
  if (user.role !== 'admin') {
    return;
  }
  // Main logic here, un-nested
  performAdminAction(user);
}

// ✗ DON'T: Deeply nested conditions
function processUserBad(user: User | null) {
  if (user !== null) {
    if (user.isActive) {
      if (user.role === 'admin') {
        performAdminAction(user);
      }
    }
  }
}
```

**Ternary for simple branching** — useful but avoid deep nesting:

```typescript
// ✓ DO: Ternary with simple conditions first
function getMessage(status: Status) {
  return status === 'loading' ? 'Please wait...' :
         status === 'error' ? 'Something went wrong' :
         status === 'success' ? 'Done!' :
         'Unknown status';
}

// ✓ DO: Early return ternary — simple cases first, complex last
function processRequest(request: Request) {
  return !request.isValid ? { error: 'Invalid request' } :
         request.isCached ? getCachedResponse(request) :
         executeFullRequest(request); // Most complex case last
}

// ✗ DON'T: Overly complex nested ternary
const result = a ? (b ? (c ? x : y) : z) : (d ? w : v);
```

**Guidelines:**
- Simple/quick-exit conditions first
- Complex logic last (or extract to separate function)
- If ternary becomes hard to read, use `if` statements instead

### Avoid Destructuring

Prefer direct property access over destructuring. Benefits:
- **Readability** — Clear which object a property belongs to
- **No name conflicts** — No need for renaming (`{ data: userData }`)
- **Type narrowing works** — Discriminated unions narrow correctly

```typescript
// ✓ DO: Direct property access
const query = useQuery();

if (query.isLoading) {
  return <Spinner />;
}
if (query.isSuccess) {
  // Type narrowing works!
  return <div>{query.data.name}</div>; // data is TData
}
if (query.isError) {
  return <Error message={query.error.message} />;
}

// ✗ DON'T: Destructuring breaks type narrowing
const { isLoading, isSuccess, isError, data, error } = useQuery();

if (isLoading) {
  return <Spinner />;
}
if (isSuccess) {
  // Type narrowing doesn't work!
  return <div>{data?.name}</div>; // data is still TData | undefined
}
if (isError) {
  return <Error message={error?.message} />; // error is still Error | null
}
```

**Why destructuring breaks narrowing:**

When you destructure, each variable becomes independent. Checking `isSuccess` doesn't narrow `data` because TypeScript doesn't track the relationship between separate variables.

```typescript
// The discriminated union relationship is lost:
const { isSuccess, data } = query;
// isSuccess and data are now unrelated variables
// Checking isSuccess doesn't affect data's type
```

### Avoid enum

TypeScript `enum` generates runtime code that can't be stripped by type-only transpilers (esbuild, swc in strip-only mode). Use const arrays instead:

```typescript
// ✗ DON'T: enum generates runtime code
enum State {
  Loading = 'loading',
  Success = 'success',
  Error = 'error',
}

// ✓ DO: const array + derived type
const states = ['loading', 'success', 'error'] as const;
type State = (typeof states)[number];  // 'loading' | 'success' | 'error'

// Runtime access still works
states.forEach((s) => console.log(s));
```

#### With Zod

```typescript
import { z } from 'zod';

const states = ['loading', 'success', 'error'] as const;
const StateSchema = z.enum(states);
type State = z.infer<typeof StateSchema>;  // 'loading' | 'success' | 'error'

// Runtime validation
const state = StateSchema.parse('loading');  // ✓ OK
StateSchema.parse('invalid');                // ✗ Throws ZodError

// ✓ DO: Use safeParse to replace includes (avoids type errors)
function isValidState(value: string): value is State {
  return StateSchema.safeParse(value).success;
}

// ✗ DON'T: Array.includes has type issues
// states.includes(unknownString);  // Error: Argument of type 'string' is not assignable
```

**Why avoid enum:**
- `enum` is TypeScript-only syntax that emits runtime JavaScript
- Type-stripping tools (esbuild, swc) can't handle it without full TypeScript compilation
- Const arrays are pure JavaScript + types, fully strippable
- Union types provide the same type safety with better tree-shaking

## Advanced Type Patterns

### Discriminated Unions

Use a common literal property to enable type narrowing:

```typescript
// ✓ DO: Discriminated union with literal discriminator
type Result<TData, TError> =
  | { success: true; data: TData }
  | { success: false; error: TError };

function handleResult(result: Result<User, string>) {
  if (result.success) {
    // TypeScript knows: result.data is User
    console.log(result.data.name);
  } else {
    // TypeScript knows: result.error is string
    console.error(result.error);
  }
}

// ✓ DO: Use 'type' or 'kind' as discriminator for events/actions
type Action =
  | { type: 'INCREMENT'; amount: number }
  | { type: 'DECREMENT'; amount: number }
  | { type: 'RESET' };

function reducer(state: number, action: Action): number {
  switch (action.type) {
    case 'INCREMENT':
      return state + action.amount;
    case 'DECREMENT':
      return state - action.amount;
    case 'RESET':
      return 0;
  }
}
```

**Best practices:**
- Use `type`, `kind`, or `status` as discriminator names
- Discriminator values should be string literals for readability
- Use `satisfies never` for exhaustive handling (see below)

### Exhaustive Handling

Use `satisfies never` to ensure all cases are handled. TypeScript will error if any case is missed.

#### Switch Statement

```typescript
type Route = '/home' | '/about' | '/contact';

function handleRoute(route: Route) {
  switch (route) {
    case '/home':
      return <HomePage />;
    case '/about':
      return <AboutPage />;
    case '/contact':
      return <ContactPage />;
    default:
      route satisfies never; // Error if any route is unhandled
  }
}
```

#### Ternary with IIFE

For ternary expressions, use an IIFE to add exhaustive check:

```typescript
type MessageType = 'error' | 'warning' | 'info';

const Component = messageType === 'error'
  ? ErrorMessage
  : messageType === 'warning'
  ? WarningMessage
  : messageType === 'info'
  ? InfoMessage
  : (() => {
      messageType satisfies never;
      throw new Error(`Unknown message type: ${messageType}`);
    })();
```

#### Partial Exhaustive (Subset Handling)

When you need to handle a subset of types and explicitly allow others to pass through:

```typescript
type ActionType = 'create' | 'update' | 'delete' | 'login' | 'signUp';

// Define which actions bypass normal handling
type PassthroughActions = readonly ['login', 'signUp'];
const passthroughActions: PassthroughActions = ['login', 'signUp'] satisfies ReadonlyArray<ActionType>;
type PassthroughAction = PassthroughActions[number];

function handleAction(actionType: ActionType) {
  switch (actionType) {
    case 'create':
      return createItem();
    case 'update':
      return updateItem();
    case 'delete':
      return deleteItem();
    default:
      // Ensure only PassthroughActions reach here, not forgotten cases
      actionType satisfies PassthroughAction;
      return handlePassthrough(actionType);
  }
}
```

If you add a new `ActionType` but forget to handle it, the `satisfies PassthroughAction` will error unless you explicitly add it to `PassthroughActions`.

### Branded Types

Use branded types to create nominal types that prevent accidental mixing. **Avoid using `as` for branding** — use Zod or type-fest instead for proper runtime validation.

#### With Zod (Recommended)

```typescript
import { z } from 'zod';

// Define branded schemas (Schema suffix for clarity)
const UserIdSchema = z.string().uuid().brand('UserId');
const OrderIdSchema = z.string().uuid().brand('OrderId');

// Infer branded types
type UserId = z.infer<typeof UserIdSchema>;  // string & { __brand: 'UserId' }
type OrderId = z.infer<typeof OrderIdSchema>;

// Parse and validate with branding
const userId = UserIdSchema.parse('550e8400-e29b-41d4-a716-446655440000');
// userId is now typed as UserId, not just string

// Use in functions
function getUser(id: UserId): User { /* ... */ }

getUser(userId);                        // ✓ OK - properly branded
getUser('raw-string');                  // ✗ Error - not branded
getUser(OrderIdSchema.parse('...'));    // ✗ Error - wrong brand
```

#### With type-fest

[type-fest](https://github.com/sindresorhus/type-fest) provides `Tagged` for branding without runtime validation:

```typescript
import type { Tagged } from 'type-fest';

type UserId = Tagged<string, 'UserId'>;
type OrderId = Tagged<string, 'OrderId'>;

// Create branded values through validated functions
function createUserId(id: string): UserId {
  if (!isValidUuid(id)) throw new Error('Invalid UUID');
  return id as UserId;  // as is acceptable inside factory functions
}

const userId = createUserId('550e8400-e29b-41d4-a716-446655440000');
```

#### ✗ DON'T: Use `as` directly

```typescript
// ✗ DON'T: Direct casting bypasses validation
const userId = 'invalid-string' as UserId;  // No validation!
```

**When to use branded types:**
- IDs that shouldn't be mixed (UserId, OrderId, ProductId)
- Units that shouldn't be mixed (Meters, Feet, Celsius, Fahrenheit)
- Validated strings (Email, URL, UUID)
- Money with different currencies

### Template Literal Types

Use template literals for string pattern types:

```typescript
// ✓ DO: Type-safe event names
type EventName = `on${Capitalize<'click' | 'focus' | 'blur'>}`;
// Result: 'onClick' | 'onFocus' | 'onBlur'

// ✓ DO: Type-safe CSS properties
type CSSUnit = 'px' | 'rem' | 'em' | '%';
type CSSValue = `${number}${CSSUnit}`;
// '10px', '1.5rem', '100%' are valid

const width: CSSValue = '100px';  // ✓ OK
const bad: CSSValue = '100';      // ✗ Error: missing unit

// ✓ DO: Type-safe route parameters
type Route = '/users/:userId' | '/posts/:postId';
type ExtractParam<TRoute extends string> =
  TRoute extends `${string}:${infer TParam}`
    ? TParam
    : never;

type UserParam = ExtractParam<'/users/:userId'>;  // 'userId'

// ✓ DO: Type-safe i18n keys
type Locale = 'en' | 'ja' | 'zh';
type I18nKey = 'greeting' | 'farewell';
type LocalizedKey = `${Locale}.${I18nKey}`;
// 'en.greeting' | 'en.farewell' | 'ja.greeting' | ...
```

**Common patterns:**
- `Capitalize<T>`, `Uppercase<T>`, `Lowercase<T>` for case manipulation
- `${infer X}` for extracting parts of strings
- Combine with mapped types for powerful transformations

## Type Testing

Use `*.test-d.ts` files for type-level tests:

```typescript
// myGeneric.test-d.ts
import type { MyGenericType } from './MyGenericType';

const anyObj: any = {};

// Test 1: Extracts correct keys with basic types
(() => {
  type Input = {
    key1: string;
    key2: number;
    other: boolean;
  };
  type Expected = {
    key1: string;
    key2: number;
  };
  type Result = MyGenericType<Input, 'key1' | 'key2'>;

  // Bidirectional satisfies ensures strict equality
  (anyObj as Result satisfies Expected);
  (anyObj as Expected satisfies Result);
})();

// Test 2: Preserves optional modifiers
(() => {
  type Input = {
    required: string;
    optional?: number;
  };
  type Expected = {
    required: string;
    optional?: number;
  };
  type Result = MyGenericType<Input>;

  (anyObj as Result satisfies Expected);
  (anyObj as Expected satisfies Result);
})();

// Test 3: Handles nested objects
(() => {
  type Expected = {
    user: { id: string; name: string };
  };
  type Result = MyGenericType<typeof anyObj, 'user'>;

  (anyObj as Result satisfies Expected);
  (anyObj as Expected satisfies Result);
})();

// Test 4: Handles union types in values
(() => {
  type Expected = {
    status: 'active' | 'inactive';
  };
  type Result = MyGenericType<typeof anyObj, 'status'>;

  (anyObj as Result satisfies Expected);
  (anyObj as Expected satisfies Result);
})();

// Test 5: Empty keys returns empty object
(() => {
  type Expected = Record<string, never>;
  type Result = MyGenericType<typeof anyObj, never>;

  (anyObj as Result satisfies Expected);
  (anyObj as Expected satisfies Result);
})();

// Add more test cases as needed to cover edge cases
```

### Testing Negative Cases

When a type is designed to **reject** certain inputs, test those rejections explicitly using `@ts-expect-error`:

```typescript
// navigate.test-d.ts
import { navigate } from './navigate';

// Test: Valid paths work
navigate('/home');
navigate('/about');

// Test: Invalid paths should cause type errors
// @ts-expect-error invalid path should cause a type error
navigate('/path/not/exist');

// @ts-expect-error numbers are not valid paths
navigate(123);

// @ts-expect-error empty string is not a valid path
navigate('');
```

If the `@ts-expect-error` line does NOT produce an error, TypeScript will report an "Unused '@ts-expect-error' directive" error — this catches regressions where invalid inputs accidentally become valid.

Write as many test cases as needed to thoroughly verify the generic type behavior. Each IIFE isolates the test scope and makes failures easy to locate.

## Environment Setup

### Recommended tsconfig

Use the strictest base from [tsconfig/bases](https://github.com/tsconfig/bases):

```bash
npm install -D @tsconfig/strictest
```

```json
{
  "extends": "@tsconfig/strictest/tsconfig.json",
  "compilerOptions": {
    "outDir": "dist"
  }
}
```

### Important Strict Options

`@tsconfig/strictest` already enables these options. Ensure they remain enabled:

| Option | Effect |
|--------|--------|
| `noUncheckedIndexedAccess` | Array/object index access returns `T \| undefined`, forcing null checks |
| `noPropertyAccessFromIndexSignature` | Requires bracket notation for index signatures, making dynamic access explicit |

If not using `@tsconfig/strictest`, add them manually:

```json
{
  "compilerOptions": {
    "noUncheckedIndexedAccess": true,
    "noPropertyAccessFromIndexSignature": true
  }
}
```

### ts-reset

Install [ts-reset](https://github.com/mattpocock/ts-reset) for better built-in types:

```bash
npm install -D @total-typescript/ts-reset
```

```typescript
// reset.d.ts
import '@total-typescript/ts-reset';
```

Place this file in each TypeScript project root (where `tsconfig.json` is located). If using **project references** (build mode) with multiple `tsconfig.json` files, each project needs its own `reset.d.ts`:

```
packages/
├── core/
│   ├── tsconfig.json
│   └── reset.d.ts        ← needed
├── utils/
│   ├── tsconfig.json
│   └── reset.d.ts        ← needed
└── tsconfig.json         ← root (references only, no reset needed)
```

Benefits:
- `JSON.parse` returns `unknown` instead of `any`
- `.filter(Boolean)` removes falsy types correctly
- `Array.includes` has stricter checking

## Summary Checklist

Before committing TypeScript code, verify:

- [ ] Used `interface` for object types, `type` for unions/mapped/conditional
- [ ] No `as` or `!` assertions — use Zod, `satisfies`, type guards, or explicit null checks
- [ ] Branded types use Zod `.brand()` or type-fest `Tagged` (not manual casting)
- [ ] Naming follows conventions (PascalCase types, `T` prefix for generics, `Id` not `ID`)
- [ ] Types extracted from existing definitions where possible
- [ ] Functions use namespace pattern for complex type organization
- [ ] Arrow functions for const declarations
- [ ] Complex generics have type tests

## Additional Resources

- [tsconfig/bases](https://github.com/tsconfig/bases) - Strictest base configs
- [ts-reset](https://github.com/mattpocock/ts-reset) - Better built-in types
- [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/) - Official documentation

## Notes

- These guidelines complement, not replace, project-specific conventions
- When in doubt, prioritize readability and maintainability
- Runtime type validation (zod, arktype) is recommended for external data
- Avoid over-engineering types; simple is better than clever
