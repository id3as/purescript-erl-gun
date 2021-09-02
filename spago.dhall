{-
Welcome to a Spago project!
You can edit this file as you like.
-}
{ name = "erl-gun"
, dependencies =
  [ "convertable-options"
  , "datetime"
  , "effect"
  , "either"
  , "erl-atom"
  , "erl-binary"
  , "erl-kernel"
  , "erl-lists"
  , "erl-maps"
  , "erl-process"
  , "erl-ssl"
  , "erl-tuples"
  , "erl-untagged-union"
  , "foreign"
  , "functions"
  , "maybe"
  , "prelude"
  , "record"
  , "simple-json"
  , "typelevel-prelude"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs" ]
, backend = "purerl"
}
