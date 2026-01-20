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
4. **Generic Const for Strictness** - Use `<const T>` for strict literal inference
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
| Inferred generic | `T` prefix | `TUser`, `TConfig` (never bare `T`) |
| Acronyms | First cap only | `userId`, `ApiResponse` (NOT `userID`, `APIResponse`) |
| Constants | UPPER_SNAKE | `MAX_RETRY_COUNT` |
| Variables/Functions | camelCase | `getUserById`, `isActive` |

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

When a function has overloads, define separate interfaces and extend:

```typescript
// ✓ DO: Extend separate interfaces
namespace myFunction {
  export interface TypeBasic {
    (options: Options): ReturnType;
  }
  export interface TypeWithExtra {
    (options: Options, extra: boolean): ReturnTypeWithExtra;
  }
  export interface Type extends TypeBasic, TypeWithExtra {}
}

// ✗ DON'T: Define all signatures in one interface
namespace myFunction {
  export interface Type {
    (options: Options): ReturnType;
    (options: Options, extra: boolean): ReturnTypeWithExtra;
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
| `type Nullable<T> = { [P in keyof T]: T[P] \| null }` | `interface` for mapped types (impossible) |

### any Usage

| DO | DON'T |
|----|-------|
| `function debounce<T extends (...args: any[]) => any>` | `const data: any = response` |
| Use `unknown` for truly unknown types | Use `any` to silence errors |
| Parse with zod/arktype, then use inferred type | Cast with `as any` |

```typescript
// ✓ DO: Use any only in generic constraints
function debounce<TFunc extends (...args: any[]) => any>(
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
const myFunction = (options: myFunction.Options): myFunction.ReturnType => {
  // implementation
};

// ✗ DON'T: Named function expression
const myFunction: myFunction.Type = function myFunction(options) {
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

// ✓ DO: NonNullable when you know it's defined
const timeout: NonNullable<typeof config['timeout']> = config.timeout!;

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

const config = defineConfig({
  routes: ['/home', '/about'], // inferred as readonly ['/home', '/about']
  debug: true,
});

// ✓ DO: as const satisfies for one-off definitions
const config = {
  routes: ['/home', '/about'],
  debug: true,
} as const satisfies BaseConfig;

// ✗ DON'T: Lose literal types
const config: BaseConfig = {
  routes: ['/home', '/about'], // widened to string[]
  debug: true,
};
```

### Namespace Usage

| DO | DON'T |
|----|-------|
| `namespace myFunc { export interface Options {} }` | `namespace Utils { export function helper() {} }` |
| Group types with their function | Use namespace for runtime code |
| Types only in namespaces | Mix types and implementation |

## Type Testing

Use `*.test-d.ts` files for type-level tests:

```typescript
// myGeneric.test-d.ts
import type { MyGenericType } from './MyGenericType';

const anyObj: any = {};

// Test 1: Extracts correct keys with basic types
(() => {
  type Expected = {
    key1: string;
    key2: number;
  };
  type Result = MyGenericType<typeof anyObj, 'key1' | 'key2'>;

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
  type Expected = {};
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
- [ ] No `as any` except in generic constraints
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
