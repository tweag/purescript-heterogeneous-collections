{ name = "heterogeneous-collections"
, dependencies =
  [ "aff"
  , "arrays"
  , "console"
  , "effect"
  , "lists"
  , "maybe"
  , "prelude"
  , "psci-support"
  , "quickcheck"
  , "record"
  , "spec"
  , "spec-discovery"
  , "spec-quickcheck"
  , "strings"
  , "unsafe-coerce"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
