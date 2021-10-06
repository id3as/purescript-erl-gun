let upstream =
      https://github.com/purerl/package-sets/releases/download/erl-0.14.3-20210709/packages.dhall sha256:9b07e1fe89050620e2ad7f7623d409f19b5e571f43c2bdb61242377f7b89d941

in  upstream
 with convertable-options =
        { repo = "https://github.com/natefaubion/purescript-convertable-options"
        , dependencies = [ "effect", "maybe", "record" ]
        , version = "f20235d464e8767c469c3804cf6bec4501f970e6"
        }
 with erl-untagged-union = ../purescript-erl-untagged-union/spago.dhall as Location
 with erl-kernel = ../purescript-erl-kernel/spago.dhall as Location
 with erl-ssl = ../purescript-erl-ssl/spago.dhall as Location
 with erl-otp-types = ../purescript-erl-otp-types/spago.dhall as Location
 with unsafe-reference =
  { repo = "https://github.com/purerl/purescript-unsafe-reference.git"
  , dependencies = [ "prelude"  ]
  , version = "464ee74d0c3ef50e7b661c13399697431f4b6251"
  }
 with erl-process =
  { repo = "https://github.com/id3as/purescript-erl-process.git"
  , dependencies =
    [ "console"
    , "prelude"
    , "effect"
    ]
  , version = "fc793e11ed2b0a0b3c38441de9dacb8652b1bbeb"
  }
