let upstream =
      https://github.com/purerl/package-sets/releases/download/erl-0.14.4-20211012-1/packages.dhall sha256:04b7cb6aaf4cc7323c2560c7b5c2f5e8459d2951997cf5084748e0f1cdbabd26

let additions =
    { convertable-options =
      { repo = "https://github.com/natefaubion/purescript-convertable-options"
      , dependencies = [ "effect", "maybe", "record" ]
      , version = "f20235d464e8767c469c3804cf6bec4501f970e6"
      }
    , unsafe-reference =
      { repo = "https://github.com/purerl/purescript-unsafe-reference.git"
      , dependencies = [ "prelude"  ]
      , version = "464ee74d0c3ef50e7b661c13399697431f4b6251"
      }
    , erl-otp-types =
      { dependencies =
        [ "erl-atom"
        , "erl-binary"
        , "erl-kernel"
        , "foreign"
        , "prelude"
        , "unsafe-reference"
        ]
      , repo = "https://github.com/id3as/purescript-erl-otp-types.git"
      , version = "2ff85e38ea1f5a4cf91142b0e680985afc2be666"
      }
    , erl-ssl =
      { dependencies =
        [ "convertable-options"
        , "datetime"
        , "effect"
        , "either"
        , "maybe"
        , "erl-atom"
        , "erl-binary"
        , "erl-lists"
        , "erl-kernel"
        , "erl-tuples"
        , "erl-logger"
        , "erl-otp-types"
        , "foreign"
        , "maybe"
        , "partial"
        , "prelude"
        , "record"
        , "unsafe-reference"
        ]
      , repo = "https://github.com/id3as/purescript-erl-ssl.git"
      , version = "9d8a9d0fb0e50d72fbae2f733c5a638ece2055ea"
      }
    }

in (upstream // additions)
  with erl-untagged-union.version = "781b2894f9ffcc91b7aea482e435bb9284596f62"
  with erl-kernel.version = "a862207a32a8c61e66f7c8d5cfbfee47c91b529e"
  with erl-process.repo = "https://github.com/id3as/purescript-erl-process.git"
  with erl-process.version = "67787f787d3f6a0523f931e651156ec82709e7f1"
  with simple-json.version = "v7.0.0-erl5"
