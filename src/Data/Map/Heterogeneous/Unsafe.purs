module Data.Map.Heterogeneous.Unsafe
  ( UnsafeHMap
  , unsafePop
  , unsafeEmpty
  , unsafeGet
  , unsafeMember
  , unsafeSet
  , unsafeSize
  , unsafeUnion
  ) where

foreign import data UnsafeHMap :: forall k. Row k -> Type

foreign import unsafeGet
  :: forall r a b. (a -> b) -> b -> String -> UnsafeHMap r -> b

foreign import unsafeMember :: forall r. String -> UnsafeHMap r -> Boolean

foreign import unsafePop
  :: forall r1 r2 a b
   . String
  -> b
  -> (a -> UnsafeHMap r2 -> b)
  -> UnsafeHMap r1
  -> b

foreign import unsafeSize :: forall r. UnsafeHMap r -> Int

foreign import unsafeSet
  :: forall r1 r2 a. String -> a -> UnsafeHMap r1 -> UnsafeHMap r2

foreign import unsafeEmpty :: forall r. UnsafeHMap r

foreign import unsafeUnion
  :: forall r1 r2 r3. UnsafeHMap r1 -> UnsafeHMap r2 -> UnsafeHMap r3
