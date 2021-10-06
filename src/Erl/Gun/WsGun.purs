module Erl.Gun.WsGun
  ( WebSocketDownReason(..)
  , WebSocket
  , WebSocketPayload(..)
  , WebSocketMessage(..)
  , wsOpen
  ) where

import Prelude
import Data.Either (Either(..), either)
import Data.Time.Duration (Milliseconds(..))
import Effect (Effect)
import Effect.Class (liftEffect)
import Erl.Atom.Symbol as AtomSymbol
import Erl.Data.Binary.IOData (IOData)
import Erl.Data.List as List
import Erl.Gun (CloseFrame, DataFrame(..), GunMessage(..), PingPongFrame, Protocol(..))
import Erl.Gun as Gun
import Erl.Kernel.Inet (HostAddress, Port)
import Erl.Process (ExitReason, receiveWithTrap, spawnLink, trapExit)
import Erl.Types (Timeout(..))
import Erl.Untagged.Union (type (|$|), type (|+|), Nil, Union, case_, on)
import Foreign (Foreign, MultipleErrors, unsafeToForeign)
import Simple.JSON (class ReadForeign, readJSON)

data WebSocketDownReason
  = ProcessExit ExitReason
  | KeepAliveExpiry
  | GunDown Gun.DownReason
  | ConnectionError Gun.ErrorReason
  | StreamError Gun.ErrorReason
  | UnhandledMessage Foreign

newtype WebSocket :: Type -> Type -> Type
newtype WebSocket clientMsg serverMsg
  = WebSocket Gun.ConnPid

derive instance eqWebSocket :: Eq (WebSocket clientMsg serverMsg)

data WebSocketPayload :: Type -> Type
data WebSocketPayload serverMsg
  = WebSocketUp Gun.Headers
  | WebSocketDown WebSocketDownReason
  | Frame serverMsg
  | InvalidFrame MultipleErrors

data WebSocketMessage clientMsg serverMsg
  = OpenFailed Gun.ErrorReason
  | OpenSucceeded (WebSocket clientMsg serverMsg)
  | Message (WebSocket clientMsg serverMsg) (WebSocketPayload serverMsg)

wsOpen ::
  forall clientMsg serverMsg.
  ReadForeign serverMsg =>
  (WebSocketMessage clientMsg serverMsg -> Effect Unit) -> HostAddress -> Port -> IOData -> Effect Unit
wsOpen cb host port path = do
  void $ liftEffect $ spawnLink $ trapExit open
  where
  open = do
    maybeConnPid <-
      Gun.open host port
        { protocols: List.singleton $ Http $ Gun.httpOptions {}
        , retry: 0
        , supervise: false
        , ws_opts:
            Gun.wsOptions
              { compress: true
              , keepalive: Timeout $ Milliseconds 5000.0
              , silence_pings: false
              }
        }
    case maybeConnPid of
      Left err -> do
        liftEffect $ cb $ OpenFailed err
        pure unit
      Right connPid -> do
        let webSocket = WebSocket connPid
        liftEffect $ cb $ OpenSucceeded webSocket
        receiveLoop webSocket

  receiveLoop webSocket = do
    msg <- receiveWithTrap
    case msg of
      Left exitReason ->
        liftEffect $ cb $ Message webSocket $ WebSocketDown $ ProcessExit exitReason

      Right
        (gunMsg' :: Union |$| GunMessage |+| Nil) ->
        ( case_
            # on
                ( \gunMsg ->
                    case gunMsg of
                      Gun_up connPid _protocol -> do
                        _streamRef <- liftEffect $ Gun.wsUpgrade connPid path List.nil
                        receiveLoop webSocket

                      Gun_upgrade _connPid _streamRef _protocols headers -> do
                        liftEffect $ cb $ Message webSocket $ WebSocketUp headers
                        receiveLoop webSocket

                      Gun_ws _connPid _streamRef frame -> do
                        ( case_
                            # on
                                ( \(_close :: CloseFrame) -> do
                                    pure unit
                                )
                            # on
                                ( \(_pingPong :: PingPongFrame) -> do
                                    pure unit
                                )
                            # on
                                ( \(dataFrame :: DataFrame) ->
                                    case dataFrame of
                                      (Text str) -> do
                                        liftEffect $ cb $ Message webSocket $ either InvalidFrame Frame $ readJSON str
                                        pure unit
                                      (Binary _bin) -> do
                                        pure unit
                                      (Close _bin) -> do
                                        pure unit
                                )
                            # on
                                ( \(_pong :: AtomSymbol.Atom "pong") -> do
                                    pure unit
                                )
                            # on
                                ( \(_ping :: AtomSymbol.Atom "ping") -> do
                                    pure unit
                                )
                            # on
                                ( \(_close :: AtomSymbol.Atom "close") -> do
                                    pure unit
                                )
                        )
                          frame
                        receiveLoop webSocket

                      Gun_down _connPid _protocol reason _streamRefs -> do
                        liftEffect $ cb $ Message webSocket $ WebSocketDown $ GunDown reason
                        receiveLoop webSocket

                      Gun_error _connPid _streamRef reason -> do
                        liftEffect $ cb $ Message webSocket $ WebSocketDown $ StreamError reason

                      Gun_error2 _connPid reason -> do
                        liftEffect $ cb $ Message webSocket $ WebSocketDown $ ConnectionError reason

                      other -> do
                        liftEffect $ cb $ Message webSocket $ WebSocketDown $ UnhandledMessage $ unsafeToForeign other
                )
        )
          gunMsg'
