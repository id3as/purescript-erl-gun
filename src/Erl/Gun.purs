module Erl.Gun
  ( Protocol(..)
  , HttpOpts
  , Http2Opts
  , SocksOpts
  , Transport(..)
  , OptionToMaybe
  , HttpVersion
  , SocksAuth
  , TransformHeaderNameFn
  , GunMessage(..)
  , ConnPid
  , DownProtocol
  , DownReason
  , ErrorReason
  , StreamRef
  , AwaitError(..)
  , AwaitResponse(..)
  , AwaitBodyResponse(..)
  , IsFin(..)
  , UpProtocol(..)
  , Frame
  , DataFrame(..)
  , CloseFrame(..)
  , PingPongFrame(..)
  , Status
  , Headers
  , Trailers
  , Method
  , URI
  , Header
  , Trailer
  , open
  , openUnix
  , setOwner
  , shutdown
  , close
  -- info
  , get
  , head
  , options
  , patch
  , patchWithBody
  , post
  , postWithBody
  , put
  , putWithBody
  , delete
  , headers
  , request
  , sendData
  -- connect
  , await
  , awaitBody
  , awaitUp
  , flushConnection
  , flushStream
  , updateFlow
  , cancel
  -- streamInfo
  , wsUpgrade
  , wsSend
  , httpOptions
  , http2Options
  , socksOptions
  , wsOptions
  , tlsOptions
  , class OptionsToErl
  , optionsToErl
  , makeTerms
  , class OptionToErl
  , optionToErl
  ) where

import Prelude
import ConvertableOptions (class ConvertOption, class ConvertOptionsWithDefaults, convertOptionsWithDefaults)
import Data.Either (Either(..))
import Data.Function.Uncurried (Fn1, Fn2, Fn3, Fn4, mkFn1, mkFn2, mkFn3, mkFn4)
import Data.Maybe (Maybe(..), maybe)
import Data.Symbol (class IsSymbol)
import Data.Time.Duration (Milliseconds)
import Effect (Effect)
import Effect.Class (class MonadEffect, liftEffect)
import Erl.Atom (Atom, atom)
import Erl.Atom.Symbol (toAtom)
import Erl.Atom.Symbol as AtomSymbol
import Erl.Data.Binary (Binary)
import Erl.Data.Binary.IOData (IOData)
import Erl.Data.List (List)
import Erl.Data.Map (Map)
import Erl.Data.Map as Map
import Erl.Data.Tuple (Tuple2, tuple2, tuple3)
import Erl.Kernel.Inet (HostAddress, Port)
import Erl.Kernel.Inet as Inet
import Erl.Kernel.Tcp as Tcp
import Erl.Process (Process)
import Erl.Ssl as Ssl
import Erl.Types (class ToErl, IntOrInfinity, NonNegInt, PosInt, Timeout, toErl)
import Erl.Untagged.Union (class CanReceiveMessage, class IsSupportedMessage, class RuntimeType, type (|$|), type (|+|), Nil, RTLiteralAtom, RTLiteralAtomConvert, RTOption, RTTuple2, RTTuple3, RTTuple4, RTTuple5, RTTuple6, RTTuple7, RTWildcard, Union)
import Foreign (Foreign, unsafeToForeign)
import Prim.Row as Row
import Prim.RowList as RL
import Record as Record
import Type.Prelude (Proxy(..))

newtype TransformHeaderNameFn
  = TransformHeaderNameFn (Binary -> Binary)

data HttpVersion
  = Http1_1
  | Http1_0

type HttpOpts
  = ( closing_timeout :: Maybe Timeout
    , cookie_ignore_informational :: Maybe Boolean
    , flow :: Maybe PosInt
    , keepalive :: Maybe Timeout
    , transform_header_name :: Maybe TransformHeaderNameFn
    , version :: Maybe HttpVersion
    )

defaultHttpOpts :: Record HttpOpts
defaultHttpOpts =
  { closing_timeout: Nothing
  , cookie_ignore_informational: Nothing
  , flow: Nothing
  , keepalive: Nothing
  , transform_header_name: Nothing
  , version: Nothing
  }

httpOptions ::
  forall options.
  ConvertOptionsWithDefaults OptionToMaybe (Record HttpOpts) options (Record HttpOpts) =>
  options -> Record HttpOpts
httpOptions = convertOptionsWithDefaults OptionToMaybe defaultHttpOpts

type Http2Opts
  = ( losing_timeout :: Maybe Timeout
    , cookie_ignore_informational :: Maybe Boolean
    , flow :: Maybe PosInt
    , keepalive :: Maybe Timeout
    , connection_window_margin_size :: Maybe NonNegInt -- 0..16#7fffffff
    , connection_window_update_threshold :: Maybe NonNegInt -- 0..16#7fffffff
    , enable_connect_protocol :: Maybe Boolean
    , initial_connection_window_size :: Maybe PosInt -- 65535..16#7fffffff
    , initial_stream_window_size :: Maybe NonNegInt -- 0..16#7fffffff
    , max_concurrent_streams :: Maybe IntOrInfinity -- non_neg_integer() | infinity
    , max_connection_window_size :: Maybe NonNegInt -- 0..16#7fffffff
    , max_decode_table_size :: Maybe NonNegInt
    , max_encode_table_size :: Maybe NonNegInt
    , max_frame_size_received :: Maybe PosInt --16384..16777215
    , max_frame_size_sent :: Maybe IntOrInfinity -- 16384..16777215 | infinity
    , max_stream_buffer_size :: Maybe NonNegInt
    , max_stream_window_size :: Maybe NonNegInt -- 0..16#7fffffff
    , preface_timeout :: Maybe Timeout
    , settings_timeout :: Maybe Timeout
    , stream_window_margin_size :: Maybe NonNegInt -- 0..16#7fffffff
    , stream_window_update_threshold :: Maybe NonNegInt -- 0..16#7fffffff
    )

defaultHttp2Opts :: Record Http2Opts
defaultHttp2Opts =
  { losing_timeout: Nothing
  , cookie_ignore_informational: Nothing
  , flow: Nothing
  , keepalive: Nothing
  , connection_window_margin_size: Nothing
  , connection_window_update_threshold: Nothing
  , enable_connect_protocol: Nothing
  , initial_connection_window_size: Nothing
  , initial_stream_window_size: Nothing
  , max_concurrent_streams: Nothing
  , max_connection_window_size: Nothing
  , max_decode_table_size: Nothing
  , max_encode_table_size: Nothing
  , max_frame_size_received: Nothing
  , max_frame_size_sent: Nothing
  , max_stream_buffer_size: Nothing
  , max_stream_window_size: Nothing
  , preface_timeout: Nothing
  , settings_timeout: Nothing
  , stream_window_margin_size: Nothing
  , stream_window_update_threshold: Nothing
  }

http2Options ::
  forall options.
  ConvertOptionsWithDefaults OptionToMaybe (Record Http2Opts) options (Record Http2Opts) =>
  options -> Record Http2Opts
http2Options = convertOptionsWithDefaults OptionToMaybe defaultHttp2Opts

data SocksAuth
  = None
  | UsernamePassword Binary Binary

type SocksOpts
  = ( host :: Maybe HostAddress
    , port :: Maybe Port
    , auth :: Maybe SocksAuth
    , protocols :: Maybe (List Protocol)
    , transport :: Maybe Transport
    , version :: Maybe PosInt
    , tls_handshake_timeout :: Maybe Timeout
    )

defaultSocksOpts :: Record SocksOpts
defaultSocksOpts =
  { host: Nothing
  , port: Nothing
  , auth: Nothing
  , protocols: Nothing
  , transport: Nothing
  , version: Nothing
  , tls_handshake_timeout: Nothing
  }

socksOptions ::
  forall options.
  ConvertOptionsWithDefaults OptionToMaybe (Record SocksOpts) options (Record SocksOpts) =>
  options -> Record SocksOpts
socksOptions = convertOptionsWithDefaults OptionToMaybe defaultSocksOpts

type WsOpts
  = ( closing_timeout :: Maybe Timeout
    , compress :: Maybe Boolean
    , flow :: Maybe PosInt
    , keepalive :: Maybe Timeout
    -- , protocols ::        => [{binary(), module()}],
    , silence_pings :: Maybe Boolean
    )

defaultWsOpts :: Record WsOpts
defaultWsOpts =
  { closing_timeout: Nothing
  , compress: Nothing
  , flow: Nothing
  , keepalive: Nothing
  -- , protocols: Nothing
  , silence_pings: Nothing
  }

wsOptions ::
  forall options.
  ConvertOptionsWithDefaults OptionToMaybe (Record WsOpts) options (Record WsOpts) =>
  options -> Record WsOpts
wsOptions = convertOptionsWithDefaults OptionToMaybe defaultWsOpts

tlsOptions ::
  forall options.
  ConvertOptionsWithDefaults OptionToMaybe (Record (Ssl.ClientOptions (Ssl.CommonOptions ()))) options (Record (Ssl.ClientOptions (Ssl.CommonOptions ()))) =>
  options -> Record (Ssl.ClientOptions (Ssl.CommonOptions ()))
tlsOptions = convertOptionsWithDefaults OptionToMaybe (Ssl.defaultClientOptions (Ssl.defaultCommonOptions {}))

data Protocol
  = Http (Record HttpOpts)
  | Http2 (Record Http2Opts)
  | Raw
  | Socks (Record SocksOpts)

type RetryFn
  = NonNegInt ->
    Record Options ->
    { retries :: NonNegInt
    , timeout :: Milliseconds
    }

data Transport
  = GunTcp (Record (Tcp.ConnectOptions))
  | GunTls (Record (Tcp.ConnectOptions)) (Record (Ssl.ClientOptions (Ssl.CommonOptions ())))

instance showTranport :: Show Transport where
  show (GunTcp _r) = "GunTcp"
  show (GunTls _r _r2) = "GunTls"

derive instance eqTransport :: Eq Transport

type Options
  = ( connect_timeout :: Maybe Timeout
    --, cookie_store :: CookieStore
    , domain_lookup_timeout :: Maybe Timeout
    , protocols :: Maybe (List Protocol)
    , retry :: Maybe NonNegInt
    --, retry_fun :: RetryFn
    , retry_timeout :: Maybe Timeout
    , supervise :: Maybe Boolean
    , tls_handshake_timeout :: Maybe Timeout
    , trace :: Maybe Boolean
    , transport :: Maybe Transport
    , ws_opts :: Maybe (Record WsOpts)
    )

defaultOptions :: Record Options
defaultOptions =
  { connect_timeout: Nothing
  --, cookie_store: Nothing
  , domain_lookup_timeout: Nothing
  , protocols: Nothing
  , retry: Nothing
  --, retry_fun: Nothing
  , retry_timeout: Nothing
  , supervise: Nothing
  , tls_handshake_timeout: Nothing
  , trace: Nothing
  , transport: Nothing
  , ws_opts: Nothing
  }

type ConnPid
  = Process Void

foreign import data StreamRef :: Type

instance eqStreamRef :: Eq StreamRef where
  eq = nativeEqImpl

foreign import nativeEqImpl :: forall a. a -> a -> Boolean

data UpProtocol
  = UpHttp
  | UpHttp2
  | UpSocks

data DownProtocol
  = DownHttp
  | DownHttp2
  | DownSocks
  | DownWs

type DownReason
  = Foreign

type ErrorReason
  = Foreign

type Header
  = Tuple2 String String

type Headers
  = List Header

type Trailer
  = Tuple2 String String

type Trailers
  = List Trailer

type Method
  = Binary

type URI
  = Binary

type Status
  = NonNegInt

data IsFin
  = Fin
  | Nofin

data PingPongFrame
  = Ping Binary
  | Pong Binary

instance runtimeTypePingPongFrame ::
  RuntimeType
    PingPongFrame
    ( RTOption (RTTuple2 (RTLiteralAtom "ping") RTWildcard)
        (RTTuple2 (RTLiteralAtom "pong") RTWildcard)
    )

data DataFrame
  = Text String
  | Binary Binary
  | Close Binary

instance runtimeTypeDataFrame ::
  RuntimeType
    DataFrame
    ( RTOption (RTTuple2 (RTLiteralAtom "text") RTWildcard)
        ( RTOption (RTTuple2 (RTLiteralAtom "binary") RTWildcard)
            (RTTuple2 (RTLiteralAtom "close") RTWildcard)
        )
    )

data CloseFrame
  = CloseFrame Status Binary

instance runtimeTypeCloseFrame :: RuntimeType CloseFrame (RTTuple3 (RTLiteralAtomConvert "close" "closeFrame") RTWildcard RTWildcard)

type Frame
  = Union
    |$|
    AtomSymbol.Atom "close"
    |+|
    AtomSymbol.Atom "ping"
    |+|
    AtomSymbol.Atom "pong"
    |+|
    DataFrame
    |+|
    PingPongFrame
    |+|
    CloseFrame
    |+|
    Nil

data GunMessage
  = Gun_up ConnPid UpProtocol
  | Gun_tunnel_up ConnPid StreamRef UpProtocol
  | Gun_down ConnPid DownProtocol DownReason (List StreamRef)
  | Gun_upgrade ConnPid StreamRef Foreign Headers
  | Gun_error ConnPid StreamRef ErrorReason
  | Gun_error2 ConnPid ErrorReason
  | Gun_push ConnPid StreamRef StreamRef Method URI Headers
  | Gun_inform ConnPid StreamRef Status Headers
  | Gun_response ConnPid StreamRef Atom Status Headers
  | Gun_data ConnPid StreamRef Atom Binary
  | Gun_trailers ConnPid StreamRef Headers
  | Gun_ws ConnPid StreamRef Frame

instance runtimeTypeGunMessage ::
  RuntimeType
    GunMessage
    ( RTOption (RTTuple3 (RTLiteralAtom "gun_up") RTWildcard RTWildcard)
        ( RTOption (RTTuple4 (RTLiteralAtom "gun_tunnel_up") RTWildcard RTWildcard RTWildcard)
            ( RTOption (RTTuple5 (RTLiteralAtom "gun_down") RTWildcard RTWildcard RTWildcard RTWildcard)
                ( RTOption (RTTuple5 (RTLiteralAtom "gun_upgrade") RTWildcard RTWildcard RTWildcard RTWildcard)
                    ( RTOption (RTTuple4 (RTLiteralAtom "gun_error") RTWildcard RTWildcard RTWildcard)
                        ( RTOption (RTTuple3 (RTLiteralAtomConvert "gun_error" "gun_error2") RTWildcard RTWildcard)
                            ( RTOption (RTTuple7 (RTLiteralAtom "gun_push") RTWildcard RTWildcard RTWildcard RTWildcard RTWildcard RTWildcard)
                                ( RTOption (RTTuple5 (RTLiteralAtom "gun_inform") RTWildcard RTWildcard RTWildcard RTWildcard)
                                    ( RTOption (RTTuple6 (RTLiteralAtom "gun_response") RTWildcard RTWildcard RTWildcard RTWildcard RTWildcard)
                                        ( RTOption (RTTuple5 (RTLiteralAtom "gun_data") RTWildcard RTWildcard RTWildcard RTWildcard)
                                            ( RTOption (RTTuple4 (RTLiteralAtom "gun_trailers") RTWildcard RTWildcard RTWildcard)
                                                (RTTuple4 (RTLiteralAtom "gun_ws") RTWildcard RTWildcard RTWildcard)
                                            )
                                        )
                                    )
                                )
                            )
                        )
                    )
                )
            )
        )
    )

data OptionToMaybe
  = OptionToMaybe

instance convertOption_OptionToMaybe :: ConvertOption OptionToMaybe sym a (Maybe a) where
  convertOption _ _ val = Just val

------------------------------------------------------------------------------
-- open
open ::
  forall options m msg.
  MonadEffect m =>
  CanReceiveMessage GunMessage m =>
  ConvertOptionsWithDefaults OptionToMaybe (Record Options) options (Record Options) =>
  HostAddress -> Port -> options -> m (Either ErrorReason (ConnPid))
open host port opts = do
  let
    erlHost = toErl host

    erlOpts = optionsToErl $ convertOptionsWithDefaults OptionToMaybe defaultOptions opts
  liftEffect $ openImpl Left Right erlHost port erlOpts

foreign import openImpl :: (ErrorReason -> Either ErrorReason (ConnPid)) -> (ConnPid -> Either ErrorReason (ConnPid)) -> Foreign -> Port -> Foreign -> Effect (Either ErrorReason (ConnPid))

------------------------------------------------------------------------------
-- openUnix
openUnix ::
  forall options m msg.
  MonadEffect m =>
  CanReceiveMessage GunMessage m =>
  ConvertOptionsWithDefaults OptionToMaybe (Record Options) options (Record Options) =>
  String -> options -> m (Either ErrorReason (ConnPid))
openUnix socketPath opts = do
  let
    erlOpts = optionsToErl $ convertOptionsWithDefaults OptionToMaybe defaultOptions opts
  liftEffect $ openUnixImpl Left Right socketPath erlOpts

foreign import openUnixImpl :: (ErrorReason -> Either ErrorReason (ConnPid)) -> (ConnPid -> Either ErrorReason (ConnPid)) -> String -> Foreign -> Effect (Either ErrorReason (ConnPid))

------------------------------------------------------------------------------
-- setOwner
setOwner ::
  forall msg.
  IsSupportedMessage GunMessage msg =>
  ConnPid -> Process msg -> Effect Unit
setOwner = setOwnerImpl

foreign import setOwnerImpl :: forall msg. ConnPid -> Process msg -> Effect Unit

------------------------------------------------------------------------------
-- shutdown
shutdown :: ConnPid -> Effect Unit
shutdown = shutdownImpl

foreign import shutdownImpl :: ConnPid -> Effect Unit

------------------------------------------------------------------------------
-- close
close :: ConnPid -> Effect Unit
close = closeImpl

foreign import closeImpl :: ConnPid -> Effect Unit

------------------------------------------------------------------------------
-- info
-- todo
------------------------------------------------------------------------------
-- get
get :: ConnPid -> IOData -> Headers -> Effect StreamRef
get = getImpl

foreign import getImpl :: ConnPid -> IOData -> Headers -> Effect StreamRef

------------------------------------------------------------------------------
-- head
head :: ConnPid -> IOData -> Headers -> Effect StreamRef
head = headImpl

foreign import headImpl :: ConnPid -> IOData -> Headers -> Effect StreamRef

------------------------------------------------------------------------------
-- options
options :: ConnPid -> IOData -> Headers -> Effect StreamRef
options = optionsImpl

foreign import optionsImpl :: ConnPid -> IOData -> Headers -> Effect StreamRef

------------------------------------------------------------------------------
-- patch
patch :: ConnPid -> IOData -> Headers -> Effect StreamRef
patch = patchImpl

foreign import patchImpl :: ConnPid -> IOData -> Headers -> Effect StreamRef

------------------------------------------------------------------------------
-- patchWithBody
patchWithBody :: ConnPid -> IOData -> Headers -> IOData -> Effect StreamRef
patchWithBody = patchWithBodyImpl

foreign import patchWithBodyImpl :: ConnPid -> IOData -> Headers -> IOData -> Effect StreamRef

------------------------------------------------------------------------------
-- post
post :: ConnPid -> IOData -> Headers -> Effect StreamRef
post = postImpl

foreign import postImpl :: ConnPid -> IOData -> Headers -> Effect StreamRef

------------------------------------------------------------------------------
-- postWithBody
postWithBody :: ConnPid -> IOData -> Headers -> IOData -> Effect StreamRef
postWithBody = postWithBodyImpl

foreign import postWithBodyImpl :: ConnPid -> IOData -> Headers -> IOData -> Effect StreamRef

------------------------------------------------------------------------------
-- put
put :: ConnPid -> IOData -> Headers -> Effect StreamRef
put = putImpl

foreign import putImpl :: ConnPid -> IOData -> Headers -> Effect StreamRef

------------------------------------------------------------------------------
-- putWithBody
putWithBody :: ConnPid -> IOData -> Headers -> IOData -> Effect StreamRef
putWithBody = putWithBodyImpl

foreign import putWithBodyImpl :: ConnPid -> IOData -> Headers -> IOData -> Effect StreamRef

------------------------------------------------------------------------------
-- delete
delete :: ConnPid -> IOData -> Headers -> Effect StreamRef
delete = deleteImpl

foreign import deleteImpl :: ConnPid -> IOData -> Headers -> Effect StreamRef

------------------------------------------------------------------------------
-- headers
headers :: ConnPid -> Method -> IOData -> Headers -> Effect StreamRef
headers = headersImpl

foreign import headersImpl :: ConnPid -> Method -> IOData -> Headers -> Effect StreamRef

------------------------------------------------------------------------------
-- request
request :: ConnPid -> Method -> IOData -> Headers -> IOData -> Effect StreamRef
request = requestImpl

foreign import requestImpl :: ConnPid -> Method -> IOData -> Headers -> IOData -> Effect StreamRef

------------------------------------------------------------------------------
-- data
sendData :: ConnPid -> StreamRef -> IsFin -> IOData -> Effect StreamRef
sendData = dataImpl

foreign import dataImpl :: ConnPid -> StreamRef -> IsFin -> IOData -> Effect StreamRef

------------------------------------------------------------------------------
-- connect
-- todo
------------------------------------------------------------------------------
-- await
data AwaitError
  = Stream_error Foreign
  | Connection_error Foreign
  | Down Foreign
  | Timeout

data AwaitResponse
  = Inform Status Headers
  | Response IsFin Status Headers
  | Data IsFin Binary
  | Trailers Trailers
  | Push StreamRef Method URI Headers
  | Upgrade Headers
  | Ws Frame

await :: ConnPid -> StreamRef -> Timeout -> Effect (Either AwaitError AwaitResponse)
await connPid streamRef timeout = do
  let
    erlTimeout = toErl timeout
  awaitImpl
    Left
    (mkFn2 $ (\a b -> Right $ Inform a b))
    (mkFn3 $ (\a b c -> Right $ Response a b c))
    (mkFn2 $ (\a b -> Right $ Data a b))
    (mkFn1 $ (\a -> Right $ Trailers a))
    (mkFn4 $ (\a b c d -> Right $ Push a b c d))
    (mkFn1 $ (\a -> Right $ Upgrade a))
    (mkFn1 $ (\a -> Right $ Ws a))
    connPid
    streamRef
    erlTimeout

foreign import awaitImpl ::
  (AwaitError -> Either AwaitError AwaitResponse) ->
  Fn2 Status Headers (Either AwaitError AwaitResponse) ->
  Fn3 IsFin Status Headers (Either AwaitError AwaitResponse) ->
  Fn2 IsFin Binary (Either AwaitError AwaitResponse) ->
  Fn1 Trailers (Either AwaitError AwaitResponse) ->
  Fn4 StreamRef Method URI Headers (Either AwaitError AwaitResponse) ->
  Fn1 Headers (Either AwaitError AwaitResponse) ->
  Fn1 Frame (Either AwaitError AwaitResponse) ->
  ConnPid ->
  StreamRef ->
  Foreign ->
  Effect (Either AwaitError AwaitResponse)

------------------------------------------------------------------------------
-- awaitBody
data AwaitBodyResponse
  = Body Binary
  | BodyWithTrailers Binary Trailers

awaitBody :: ConnPid -> StreamRef -> Timeout -> Effect (Either AwaitError AwaitBodyResponse)
awaitBody connPid streamRef timeout = do
  let
    erlTimeout = toErl timeout
  awaitBodyImpl Left (mkFn1 $ Right <<< Body) (mkFn2 $ (\a b -> Right $ BodyWithTrailers a b)) connPid streamRef erlTimeout

foreign import awaitBodyImpl ::
  (AwaitError -> Either AwaitError AwaitBodyResponse) ->
  Fn1 Binary (Either AwaitError AwaitBodyResponse) ->
  Fn2 Binary Trailers (Either AwaitError AwaitBodyResponse) ->
  ConnPid ->
  StreamRef ->
  Foreign ->
  Effect (Either AwaitError AwaitBodyResponse)

------------------------------------------------------------------------------
-- awaitUp
awaitUp :: ConnPid -> Timeout -> Effect (Either AwaitError UpProtocol)
awaitUp connPid timeout = do
  let
    erlTimeout = toErl timeout
  awaitUpImpl Left Right connPid erlTimeout

foreign import awaitUpImpl :: (Unit -> Either Unit (ConnPid)) -> (UpProtocol -> Either AwaitError UpProtocol) -> ConnPid -> Foreign -> Effect (Either AwaitError UpProtocol)

------------------------------------------------------------------------------
-- flushConnection
flushConnection :: ConnPid -> Effect Unit
flushConnection = flushImpl <<< unsafeToForeign

------------------------------------------------------------------------------
-- flushStream
flushStream :: StreamRef -> Effect Unit
flushStream = flushImpl <<< unsafeToForeign

foreign import flushImpl :: Foreign -> Effect Unit

------------------------------------------------------------------------------
-- updateFlow
updateFlow :: ConnPid -> StreamRef -> PosInt -> Effect Unit
updateFlow = updateFlowImpl

foreign import updateFlowImpl :: ConnPid -> StreamRef -> PosInt -> Effect Unit

------------------------------------------------------------------------------
-- cancel
cancel :: ConnPid -> StreamRef -> Effect Unit
cancel = cancelImpl

foreign import cancelImpl :: ConnPid -> StreamRef -> Effect Unit

------------------------------------------------------------------------------
-- streamInfo
-- todo
------------------------------------------------------------------------------
-- wsUpgrade
wsUpgrade :: ConnPid -> IOData -> Headers -> Effect StreamRef
wsUpgrade = wsUpgradeImpl

foreign import wsUpgradeImpl :: ConnPid -> IOData -> Headers -> Effect StreamRef

------------------------------------------------------------------------------
-- wsSend
wsSend :: ConnPid -> StreamRef -> List Frame -> Effect Unit
wsSend = wsSendImpl

foreign import wsSendImpl :: ConnPid -> StreamRef -> List Frame -> Effect Unit

-- foo :: String -> Effect Unit
-- foo key = do
--   --"Authorization: Bearer skl-q3IQuEL4gNzfA7H4DK7eeFK0lxFo9Guw0RhGDBJBeuiMLtPPlt27GU4MFLPN" https://api.ticketsource.io/events
--   unsafeRunProcessM $ ((do
--     connPid <- unsafeFromRight "openFailed" <$> open (Host "api.ticketsource.io") 443 { protocols: singleton $ Http $ httpOptions {}
--                                                                                       , transport: GunTls (Tcp.connectOptions {}) (tlsOptions {}) }
--     -- x <- receive
--     -- let _ = trace x
--     streamRef <- liftEffect $ get connPid (fromBinary $ toBinary "/events/evt-3EKzb0nq9yR1awRL") $ (tuple2 "Authorization" ("Bearer " <> key) : tuple2 "Accept" "application/json" : nil)
--     resp <- liftEffect $ awaitBody connPid streamRef InfiniteTimeout
--     -- y <- receive
--     let _ = spy "resp" resp
--     -- z <- receive
--     -- let _ = trace z
--     pure unit) :: ProcessM GunMessage Unit)
--   pure unit
--   where
--     trace x = case x of
--                 Gun_up _ _ -> spy "up" {}
--                 Gun_tunnel_up _ _ _ -> spy "tunnel_up" {}
--                 Gun_down _ _ _ _ -> spy "down" {}
--                 Gun_upgrade _ _ _ _ -> spy "upgrade" {}
--                 Gun_error _ _ _ -> spy "error" {}
--                 Gun_error2 _ _ -> spy "error2" {}
--                 Gun_push _ _ _ _ _ _ -> spy "push" {}
--                 Gun_inform _ _ _ _ -> spy "inform" {}
--                 Gun_response _ _ _ _ headers -> do
--                   let _ = spy "response" {headers}
--                   {}
--                 Gun_data _ _ _ b -> do
--                   let _ = spy "data" {b}
--                   {}
--                 Gun_trailers _ _ _ -> spy "trailers" {}
--                 Gun_ws frame -> do
--                   (case_
--                    # on (\(_ :: CloseFrame) -> spy "closeFrame" {})
--                    # on (\(_ :: PingPongFrame) -> spy "pingPongFrame" {})
--                    # on (\(dataFrame :: DataFrame) -> do
--                             let _ = spy "dataFrame" {dataFrame}
--                             {}
--                         )
--                    # on (\(_ :: AtomSymbol.Atom "pong") -> spy "pong" {})
--                    # on (\(_ :: AtomSymbol.Atom "ping") -> spy "ping" {})
--                    # on (\(_ :: AtomSymbol.Atom "close") -> spy "close" {})
--                     ) frame
instance toErl_Protocol :: ToErl Protocol where
  toErl (Http httpOpts) = unsafeToForeign $ tuple2 (atom "http") (optionsToErl httpOpts)
  toErl (Http2 http2Opts) = unsafeToForeign $ tuple2 (atom "http2") (optionsToErl http2Opts)
  toErl Raw = unsafeToForeign $ atom "raw"
  toErl (Socks socksOpts) = unsafeToForeign $ tuple2 (atom "socks") (optionsToErl socksOpts)

instance toErl_HttpVersion :: ToErl HttpVersion where
  toErl Http1_1 = unsafeToForeign $ atom "HTTP/1.1"
  toErl Http1_0 = unsafeToForeign $ atom "HTTP/1.0"

instance toErl_TransformHeaderNameFn :: ToErl TransformHeaderNameFn where
  toErl = unsafeToForeign

instance toErl_SocksAuth :: ToErl SocksAuth where
  toErl None = unsafeToForeign $ atom "none"
  toErl (UsernamePassword username password) = unsafeToForeign $ tuple3 (atom "username_password") username password

optionsToErl ::
  forall r rl.
  RL.RowToList r rl =>
  OptionsToErl r rl =>
  Record r -> Foreign
optionsToErl = unsafeToForeign <<< makeTerms (Proxy :: _ rl)

class OptionToErl :: Symbol -> Type -> Constraint
class OptionToErl sym option where
  optionToErl :: Map Atom Foreign -> AtomSymbol.Atom sym -> option -> Map Atom Foreign

instance optionToErl_Transport :: OptionToErl "transport" Transport where
  optionToErl acc name (GunTcp tcpOpts) = Map.insert (toAtom name) (unsafeToForeign $ atom "tcp") $ Map.insert (atom "tcp_opts") (unsafeToForeign $ Inet.optionsToErl tcpOpts) acc
  optionToErl acc name (GunTls tcpOpts tlsOpts) =
    Map.insert (toAtom name) (unsafeToForeign $ atom "tls")
      $ Map.insert (atom "tcp_opts") (unsafeToForeign (Inet.optionsToErl tcpOpts))
      $ Map.insert (atom "tls_opts") (unsafeToForeign (Inet.optionsToErl tlsOpts)) acc
else instance optionToErl_List :: (IsSymbol name, ToErl a) => OptionToErl name (List a) where
  optionToErl acc name val = Map.insert (toAtom name) (unsafeToForeign (toErl <$> val)) acc
else instance optionToErl_Record ::
  ( IsSymbol name
  , RL.RowToList r rl
  , OptionsToErl r rl
  ) =>
  OptionToErl name (Record r) where
  optionToErl acc name val = Map.insert (toAtom name) (optionsToErl val) acc
else instance optionToErl_Other :: (IsSymbol name, ToErl a) => OptionToErl name a where
  optionToErl acc name val = Map.insert (toAtom name) (toErl val) acc

class OptionsToErl :: Row Type -> RL.RowList Type -> Constraint
class OptionsToErl r rl where
  makeTerms :: Proxy rl -> Record r -> Map Atom Foreign

instance optionsToErl_nil :: OptionsToErl r RL.Nil where
  makeTerms _ _r = Map.empty

instance optionsToErl_consMaybe ::
  ( IsSymbol sym
  , Row.Cons sym (Maybe a) t1 r
  , OptionsToErl r tail
  , OptionToErl sym a
  ) =>
  OptionsToErl r (RL.Cons sym (Maybe a) tail) where
  makeTerms _ r = do
    let
      tail = makeTerms (Proxy :: _ tail) r
    maybe tail (optionToErl tail (AtomSymbol.atom :: AtomSymbol.Atom sym)) $ Record.get (Proxy :: _ sym) r
else instance optionsToErl_cons ::
  ( IsSymbol sym
  , Row.Cons sym a t1 r
  , OptionsToErl r tail
  , OptionToErl sym a
  ) =>
  OptionsToErl r (RL.Cons sym a tail) where
  makeTerms _ r = do
    let
      tail = makeTerms (Proxy :: _ tail) r
    optionToErl tail (AtomSymbol.atom :: AtomSymbol.Atom sym) $ Record.get (Proxy :: _ sym) r
