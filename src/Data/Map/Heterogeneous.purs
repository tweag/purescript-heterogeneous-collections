module Data.Map.Heterogeneous
  ( HMap
  , addLabel
  , alter
  , class EqHMapFields
  , class HMapRecord
  , class ShowHMapFields
  , clear
  , delete
  , empty
  , eqHMapFields
  , expand
  , fromRecord
  , hmapFromRecord
  , hmapToRecord
  , insert
  , isEmpty
  , lookup
  , member
  , pop
  , rename
  , showHMapFields
  , singleton
  , size
  , toRecord
  , union
  , unions
  , update
  , upsert
  , upsertWith
  ) where

import Prelude

import Data.Array as Array
import Data.Foldable (class Foldable, foldl)
import Data.List (List)
import Data.List as List
import Data.Map.Heterogeneous.Unsafe (UnsafeHMap, unsafeEmpty, unsafeGet, unsafeMember, unsafePop, unsafeSet, unsafeSize, unsafeUnion)
import Data.Maybe (Maybe(..), maybe)
import Data.String (joinWith)
import Data.Symbol (class IsSymbol, reflectSymbol)
import Data.Tuple (Tuple(..))
import Prim.Row as R
import Prim.RowList (class RowToList, Cons, Nil, RowList)
import Record as Record
import Type.Proxy (Proxy(..))
import Unsafe.Coerce (unsafeCoerce)

-- TODO add HMap and HFoldl instances
-- TODO add toUnfoldable :: HMap r -> f (Variant r)
-- TODO add unsafeToUnfoldable :: HMap r -> f (Variant r)      (unrdered)
-- TODO add isSubmap :: HMap r1 -> HMap r2 -> Boolean
-- TODO add intersectionWith :: Record duplicateHandlers -> HMap r1 -> HMap r2 -> HMap duplicates
-- TODO add intersection :: HMap r1 -> HMap r2 -> HMap r3
-- TODO add intersections :: f (HMap r) -> HMap r
-- TODO add fromFoldable :: f (Variant r) -> HMap r
-- TODO add filterKeys :: MaskFields r mask r' (Const Unit) => Record mask -> HMap r -> HMap r'
-- TODO add filter :: MaskFields r mask r' Predicate => Record mask -> HMap r -> HMap r'
-- TODO add difference :: HMap r1 -> HMap r2 -> HMap r3
-- TODO add compact :: HMap rMaybes -> HMap r
-- TODO add compactMap :: Record maybeMappers -> HMap r1 -> HMap r2
-- TODO add map :: Record mappers -> HMap r1 -> HMap r2

-- | A map whose keys and values are backed by a row or types. Within the map,
-- | the types of values is determined by the value of the keys. Values may or
-- | may not be present in the map. This makes it conceptually analogous to a
-- | record with all optional fields.
-- |
-- | In the taxonomy of Row-backed collections, HMap is the most general. For
-- | a row of length N, it can contain between zero and N members, making it a
-- | superset of all row-backed collections.
-- |
-- | Note: because of the close analogy with Records, and because of the
-- | intended use at the time of writing, the API more closely resembles that
-- | of Record than Data.Map (e.g. it has a `get` method rather than a
-- | `lookup` method). Some of the API of `Data.Map` is provided in the cases
-- | where a matching method doesn't exist for `Record` however (such as
-- | `member`).
newtype HMap :: forall k. Row k -> Type
newtype HMap r = HMap (UnsafeHMap r)

-- | A class used to define structural equality on HMaps
class EqHMapFields (rl :: RowList Type) (r :: Row Type) | rl -> r where
  eqHMapFields :: Proxy rl -> HMap r -> HMap r -> Boolean

instance eqHMapFieldsNil :: EqHMapFields Nil () where
  eqHMapFields _ _ _ = true

instance eqHMapFieldsCons ::
  ( EqHMapFields rl r'
  , R.Lacks l r'
  , R.Cons l a r' r
  , IsSymbol l
  , Eq a
  ) =>
  EqHMapFields (Cons l a rl) r where
  eqHMapFields _ a b =
    lookup (Proxy :: _ l) a == lookup (Proxy :: _ l) b
      && eqHMapFields (Proxy :: _ rl) (unsafeCoerce a) (unsafeCoerce b)

instance eqHMap :: (RowToList r rl, EqHMapFields rl r) => Eq (HMap r) where
  eq a b = eqHMapFields (Proxy :: _ rl) a b

-- | A class used to define structural stringification on HMaps
class ShowHMapFields (rl :: RowList Type) (r :: Row Type) | rl -> r where
  showHMapFields :: Proxy rl -> HMap r -> List String

instance showHMapNil :: ShowHMapFields Nil () where
  showHMapFields _ _ = List.Nil

instance showHMapCons ::
  ( ShowHMapFields rl r'
  , R.Lacks l r'
  , R.Cons l a r' r
  , IsSymbol l
  , Show a
  ) =>
  ShowHMapFields (Cons l a rl) r where
  showHMapFields _ hmap =
    List.fromFoldable (showAtLabel <$> lookup (Proxy :: _ l) hmap)
      <> showHMapFields (Proxy :: _ rl) (unsafeCoerce hmap)
    where
    showAtLabel a = joinWith ": " [ reflectSymbol (Proxy :: _ l), show a ]

instance showHMap ::
  ( RowToList r rl
  , ShowHMapFields rl r
  ) =>
  Show (HMap r) where
  show a = case Array.fromFoldable $ showHMapFields (Proxy :: _ rl) a of
    [] -> "(HMap {})"
    fields -> joinWith " " [ "(HMap {", joinWith ", " fields, "})" ]

-- | A class used to witness the isomorphism between HMaps and Records.
class
  HMapRecord (rl :: RowList Type) (r :: Row Type) (rec :: Row Type)
  | rl -> r rec where
  -- | Convert a HMap to a Record with the same labels with the values
  -- | wrapped in a Maybe.
  hmapToRecord :: Proxy rl -> HMap r -> Record rec
  -- | Convert a Record with Maybe fields to a HMap with the same labels
  -- | and unwrapped values.
  hmapFromRecord :: Proxy rl -> Record rec -> HMap r

instance hmapRecordNil :: HMapRecord Nil () () where
  hmapToRecord _ _ = {}
  hmapFromRecord _ _ = empty

instance hmapRecordCons ::
  ( HMapRecord rl r' rec'
  , R.Lacks l rec'
  , R.Lacks l r'
  , R.Cons l a r' r
  , R.Cons l (Maybe a) rec' rec
  , IsSymbol l
  ) =>
  HMapRecord (Cons l a rl) r rec where
  hmapToRecord _ r = Record.insert label (lookup label r) $ hmapToRecord rl $
    unsafeCoerce r
    where
    label :: Proxy l
    label = Proxy

    rl :: Proxy rl
    rl = Proxy
  hmapFromRecord _ r =
    case Record.get label r of
      Nothing -> unsafeCoerce $ hmapFromRecord rl $ unsafeCoerce r
      Just a -> insert label a $ hmapFromRecord rl $ unsafeCoerce r
    where
    label :: Proxy l
    label = Proxy

    rl :: Proxy rl
    rl = Proxy

-- | Lookup a value for a specified key.
lookup
  :: forall r' r k a
   . IsSymbol k
  => R.Cons k a r' r
  => Proxy k
  -> HMap r
  -> Maybe a
lookup k (HMap m) = unsafeGet Just Nothing (reflectSymbol k) m

-- | Test if a key is present.
member
  :: forall r' r k a
   . IsSymbol k
  => R.Cons k a r' r
  => Proxy k
  -> HMap r
  -> Boolean
member k (HMap m) = unsafeMember (reflectSymbol k) m

-- | Insert a value at the specified key.
insert
  :: forall r1 r2 l a
   . IsSymbol l
  => R.Lacks l r1
  => R.Cons l a r1 r2
  => Proxy l
  -> a
  -> HMap r1
  -> HMap r2
insert p a (HMap m) = HMap $ unsafeSet (reflectSymbol p) a m

-- | Insert or update a value at the specified key.
upsert
  :: forall r1 r2 r k a b
   . IsSymbol k
  => R.Cons k a r r1
  => R.Cons k b r r2
  => Proxy k
  -> b
  -> HMap r1
  -> HMap r2
upsert p b (HMap m) = HMap $ unsafeSet (reflectSymbol p) b m

-- | Add a value to a HMap without affecting the row type. The provided
-- | function is used to combine the new value with the existing value, if
-- | there is one.
upsertWith
  :: forall r1 r2 r l a b
   . IsSymbol l
  => R.Cons l a r r1
  => R.Cons l b r r2
  => (b -> a -> b)
  -> Proxy l
  -> b
  -> HMap r1
  -> HMap r2
upsertWith f k b m = flip (upsert k) m $ maybe b (f b) $ lookup k m

-- | Insert the value, delete a value, or update a value for a key in a map
alter
  :: forall r1 r2 r l a b
   . IsSymbol l
  => R.Cons l a r r1
  => R.Cons l b r r2
  => R.Lacks l r
  => (Maybe a -> Maybe b)
  -> Proxy l
  -> HMap r1
  -> HMap r2
alter f k m = case pop k m of
  Nothing -> case f Nothing of
    Nothing -> addLabel k $ delete k m
    Just b -> upsert k b m
  Just (Tuple a m') -> case f (Just a) of
    Nothing -> addLabel k m'
    Just b -> insert k b m'

-- | Remove a value from a HMap, removing the label from the row.
delete
  :: forall r1 r2 l a
   . IsSymbol l
  => R.Cons l a r2 r1
  => R.Lacks l r2
  => Proxy l
  -> HMap r1
  -> HMap r2
delete label (HMap m) =
  HMap $ unsafePop (reflectSymbol label) (unsafeCoerce m) const m

-- | Delete a key and its corresponding value from a map, returning the value
-- | as well as the subsequent map.
pop
  :: forall r' r l a
   . IsSymbol l
  => R.Cons l a r' r
  => Proxy l
  -> HMap r
  -> Maybe (Tuple a (HMap r'))
pop label (HMap m) =
  unsafePop (reflectSymbol label) Nothing (\a -> Just <<< Tuple a <<< HMap) m

-- | Remove a value from a HMap without affecting the row type.
clear
  :: forall r' r l a
   . IsSymbol l
  => R.Cons l a r' r
  => R.Lacks l r'
  => Proxy l
  -> HMap r
  -> HMap r
clear label (HMap m) =
  unsafePop (reflectSymbol label) (HMap m) (const $ addLabel label <<< HMap) m

-- | Change a value within a row map with an update function.
update
  :: forall r1 r2 r l a b
   . IsSymbol l
  => R.Cons l a r r1
  => R.Cons l b r r2
  => Proxy l
  -> (a -> b)
  -> HMap r1
  -> HMap r2
update p f m = case lookup p m of
  Nothing -> unsafeCoerce m
  Just a -> upsert p (f a) m

-- | Add new labels to the row.
expand :: forall r1 r2 r. R.Union r1 r2 r => HMap r1 -> HMap r
expand = unsafeCoerce

-- | Union many HMaps
unions :: forall f r. Foldable f => f (HMap r) -> HMap r
unions maps = HMap $ foldl (flip (unsafeUnion <<< unHMap)) unsafeEmpty maps
  where
  unHMap (HMap m) = m

-- | Compute the union of two maps, preferring values from the first map in the
-- | of duplicate keys
union :: forall r1 r2 r. R.Union r1 r2 r => HMap r1 -> HMap r2 -> HMap r
union (HMap m) (HMap n) = HMap $ unsafeUnion m n

-- | Add a new label to the row without adding a value.
addLabel
  :: forall r1 r2 l a
   . IsSymbol l
  => R.Lacks l r1
  => R.Cons l a r1 r2
  => Proxy l
  -> HMap r1
  -> HMap r2
addLabel _ = unsafeCoerce

-- | Change one of the labels in a row.
rename
  :: forall prev next a input inter output
   . IsSymbol prev
  => IsSymbol next
  => R.Cons prev a inter input
  => R.Lacks prev inter
  => R.Cons next a inter output
  => R.Lacks next inter
  => Proxy prev
  -> Proxy next
  -> HMap input
  -> HMap output
rename prev next r =
  case lookup prev r of
    Nothing -> addLabel next (delete prev r :: HMap inter)
    Just a -> insert next a (delete prev r :: HMap inter)

-- | Create a Row Map with one element
singleton
  :: forall r' r label a
   . IsSymbol label
  => R.Lacks label r'
  => R.Cons label a r' r
  => Proxy label
  -> a
  -> HMap r
singleton label a = insert label a empty

-- | The number of keys present in the map
size :: forall r. HMap r -> Int
size (HMap unsafe) = unsafeSize unsafe

-- | True for maps with no keys
isEmpty :: forall r. HMap r -> Boolean
isEmpty = eq 0 <<< size

-- | Create an empty Row Map
empty :: forall r. HMap r
empty = HMap $ unsafeEmpty

-- | Convert a HMap to a Record of Maybes
toRecord
  :: forall rl r rec
   . HMapRecord rl r rec
  => RowToList r rl
  => HMap r
  -> Record rec
toRecord = hmapToRecord (Proxy :: _ rl)

-- | Convert a Record of Maybes to a HMap.
fromRecord
  :: forall rl r rec
   . HMapRecord rl r rec
  => RowToList r rl
  => Record rec
  -> HMap r
fromRecord = hmapFromRecord (Proxy :: _ rl)
