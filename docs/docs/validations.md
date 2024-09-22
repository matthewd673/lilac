# Validations

Validations ensure that certain invariants hold for a given object in the IL
when enforcing them with C#'s type system is not feasible. Validations are
useful for asserting invariants in unit testing and for validating the IL
output by a custom frontend. For example, you may run many validations while
developing a frontend to catch bugs and then remove them once the frontend's
code generation matures to improve performance.

## Design

Validations should target the minimum possible piece of a Program. For example,
a validation for unique label names should take a `List<Statement>` in its
constructor, not a `FuncDef` or an entire `Program`.
