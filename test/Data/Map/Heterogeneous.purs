module Test.Data.Map.Heterogeneous where

import Prelude

import Data.Map.Heterogeneous
  ( HMap
  , clear
  , fromRecord
  , lookup
  , update
  , upsert
  , toRecord
  )
import Data.Map.Heterogeneous.Gen (genHMap)
import Data.Maybe (Maybe(..))
import Data.String (toUpper)
import Record as Record
import Test.QuickCheck (class Arbitrary, arbitrary, (===))
import Test.Spec (Spec, describe, it)
import Test.Spec.QuickCheck (quickCheck)
import Type.Proxy (Proxy(..))

type TestRow =
  ( foo :: Int
  , bar :: String
  )

type Operational = HMap TestRow

type Denotational =
  { foo :: Maybe Int
  , bar :: Maybe String
  }

newtype ArbitraryOperational = ArbitraryOperational Operational

instance arbitraryArbitraryOperational :: Arbitrary ArbitraryOperational where
  arbitrary = ArbitraryOperational <$> genHMap arbitrary

_foo :: Proxy "foo"
_foo = Proxy

_bar :: Proxy "bar"
_bar = Proxy

spec :: Spec Unit
spec = do
  describe "lookup@_foo" $ elimSpec (lookup _foo) (Record.get _foo)
  describe "lookup@_bar" $ elimSpec (lookup _bar) (Record.get _bar)
  describe "upsert@_foo" $ termSpec2 (upsert _foo) Just (Record.set _foo)
  describe "upsert@_bar" $ termSpec2 (upsert _bar) Just (Record.set _bar)
  describe "clear@_foo" $ termSpec (clear _foo) (Record.set _foo Nothing)
  describe "clear@_bar" $ termSpec (clear _bar) (Record.set _bar Nothing)
  describe "update@_foo" do
    termSpec (update _foo (mul 2)) (Record.modify _foo (map (mul 2)))
  describe "update@_bar" do
    termSpec (update _bar toUpper) (Record.modify _bar (map toUpper))

elimSpec
  :: forall a
   . Eq a
  => Show a
  => (Operational -> a)
  -> (Denotational -> a)
  -> Spec Unit
elimSpec op den = do
  it "matches the denotational implementation" do
    quickCheck \(ArbitraryOperational operational) ->
      (op operational) === (den (toRecord operational))

termSpec
  :: (Operational -> Operational)
  -> (Denotational -> Denotational)
  -> Spec Unit
termSpec op den = do
  it "matches the denotational implementation" do
    quickCheck \(ArbitraryOperational operational) ->
      op operational === fromRecord (den (toRecord operational))

termSpec2
  :: forall a b
   . Arbitrary a
  => (a -> Operational -> Operational)
  -> (a -> b)
  -> (b -> Denotational -> Denotational)
  -> Spec Unit
termSpec2 op adapt den = do
  it "matches the denotational implementation" do
    quickCheck \(ArbitraryOperational operational) a ->
      op a operational === fromRecord (den (adapt a) (toRecord operational))
