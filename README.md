# PureScript Heterogeneous Collections

Heterogeneous collection types implemented with row polymorphism.

## Overview

This library provides additional data types that are parameterized by
polymorphic rows. That is to say, they are type constructors of kind
`Row Type -> Type`. Some examples of existing data structures in the purescript
ecosystem that fit this pattern include:

- [Record](https://pursuit.purescript.org/packages/purescript-record)
  Extensible polymorphic product types. They have size N for an N-row
  parameter.
- [Variant](https://pursuit.purescript.org/packages/purescript-variant)
  Extensible polymorphic sum types. They have size 1 for an N-row parameter.

This library adds the following additional types:

- `HMap` Extensible polymorphic products with optional membership. They have
  size [0, N] for an N-row parameter. These can be thought of as maps with
  finite keys and value types that are determined by the keys. Another way to
  think of them is as records in which every field is optional.
- `NonEmptyHMap` A non-empty version of an HMap. They have size [1, N] for an
  N-row parameter. An interesting way to think about these is as a composition
  of Variants and Records, where each key in the Variant is associated with a
  Tuple that includes a value of the type for the Variant key, and an `HMap`
  with the Variant key removed from the row.
- `Null` An empty collection. They have size 0 for an N-row parameter. Mostly
  included for completeness.
