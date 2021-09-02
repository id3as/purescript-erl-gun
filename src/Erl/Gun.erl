-module(erl_gun@foreign).

-export([ openImpl/5
        , openUnixImpl/4
        , setOwnerImpl/2
        , shutdownImpl/1
        , closeImpl/1
        , getImpl/3
        , headImpl/3
        , optionsImpl/3
        , patchImpl/3
        , patchWithBodyImpl/4
        , postImpl/3
        , postWithBodyImpl/4
        , putImpl/3
        , putWithBodyImpl/4
        , deleteImpl/3
        , headersImpl/4
        , requestImpl/5
        , dataImpl/4
        , awaitImpl/11
        , awaitBodyImpl/6
        , awaitUpImpl/4
        , flushImpl/1
        , updateFlowImpl/3
        , cancelImpl/2
        , wsUpgradeImpl/3
        , wsSendImpl/3
        , nativeEqImpl/2
        ]).

nativeEqImpl(A, B) -> A =:= B.

openImpl(Left, Right, Host, Port, Opts) ->
    fun() ->
            Host2 = if is_binary(Host) -> binary_to_list(Host);
                       true -> Host
                    end,
            case gun:open(Host2, Port, Opts) of
                {ok, Pid} ->
                    Right(Pid);
                {error, Reason} ->
                    Left(Reason)
            end
    end.

openUnixImpl(Left, Right, SocketPath, Opts) ->
    fun() ->
            case gun:open_unix(SocketPath, Opts) of
                {ok, Pid} ->
                    Right(Pid);
                {error, Reason} ->
                    Left(Reason)
            end
    end.

setOwnerImpl(ConnPid, OwnerPid) ->
    fun() ->
            ok = gun:set_owner(ConnPid, OwnerPid),
            unit
    end.

shutdownImpl(ConnPid) ->
    fun() ->
            ok = gun:shutdown(ConnPid),
            unit
    end.

closeImpl(ConnPid) ->
    fun() ->
            ok = gun:close(ConnPid),
            unit
    end.

getImpl(ConnPid, Path, Headers) ->
    fun() ->
            gun:get(ConnPid, Path, Headers)
    end.

headImpl(ConnPid, Path, Headers) ->
    fun() ->
            gun:head(ConnPid, Path, Headers)
    end.

optionsImpl(ConnPid, Path, Headers) ->
    fun() ->
            gun:options(ConnPid, Path, Headers)
    end.

patchImpl(ConnPid, Path, Headers) ->
    fun() ->
            gun:patch(ConnPid, Path, Headers)
    end.

patchWithBodyImpl(ConnPid, Path, Headers, Body) ->
    fun() ->
            gun:patch(ConnPid, Path, Headers, Body)
    end.

postImpl(ConnPid, Path, Headers) ->
    fun() ->
            gun:post(ConnPid, Path, Headers)
    end.

postWithBodyImpl(ConnPid, Path, Headers, Body) ->
    fun() ->
            gun:post(ConnPid, Path, Headers, Body)
    end.

putImpl(ConnPid, Path, Headers) ->
    fun() ->
            gun:put(ConnPid, Path, Headers)
    end.

putWithBodyImpl(ConnPid, Path, Headers, Body) ->
    fun() ->
            gun:put(ConnPid, Path, Headers, Body)
    end.

deleteImpl(ConnPid, Path, Headers) ->
    fun() ->
            gun:delete(ConnPid, Path, Headers)
    end.

headersImpl(ConnPid, Method, Path, Headers) ->
    fun() ->
            gun:headers(ConnPid, Method, Path, Headers)
    end.

requestImpl(ConnPid, Method, Path, Headers, Body) ->
    fun() ->
            gun:request(ConnPid, Method, Path, Headers, Body)
    end.

dataImpl(ConnPid, StreamRef, IsFin, Data) ->
    fun() ->
            gun:data(ConnPid, StreamRef, IsFin, Data)
    end.

awaitImpl(Left, Inform, Response, Data, Trailers, Push, Upgrade, Ws, ConnPid, StreamRef, Timeout) ->
    fun() ->
            case gun:await(ConnPid, StreamRef, Timeout) of
                {inform, Status, Headers} -> Inform(Status, Headers);
                {response, IsFin, Status, Headers} -> Response(IsFin, Status, Headers);
                {data, IsFin, Bin} -> Data(IsFin, Bin);
                {trailers, TheTrailers} -> Trailers(TheTrailers);
                {push, NewStreamRef, Method, URI, Headers} -> Push(NewStreamRef, Method, URI, Headers);
                {upgrade, _Protocols, Headers} -> Upgrade(Headers);
                {ws, Frame} -> Ws(Frame);
                {error, timeout} -> Left({timeout});
                {error, Other} -> Left(Other)
            end
    end.

awaitBodyImpl(Left, Body, BodyWithTrailer, ConnPid, StreamRef, Timeout) ->
    fun() ->
            case gun:await_body(ConnPid, StreamRef, Timeout) of
                {ok, BodyData} -> Body(BodyData);
                {ok, BodyData, Trailers} -> BodyWithTrailer(BodyData, Trailers);
                {error, timeout} -> Left({timeout});
                {error, Other} -> Left(Other)
            end
    end.

awaitUpImpl(Left, Right, ConnPid, Timeout) ->
    fun() ->
            case gun:await_up(ConnPid, Timeout) of
                {ok, Protocol} -> Right({Protocol});
                {error, timeout} -> Left({timeout});
                {error, Other} -> Left(Other)
            end
    end.

flushImpl(ConnPidOrStreamRef) ->
    fun() ->
            ok = gun:flush(ConnPidOrStreamRef),
            unit
    end.

updateFlowImpl(ConnPid, StreamRef, Flow) ->
    fun() ->
            ok = gun:update_flow(ConnPid, StreamRef, Flow)
    end.

cancelImpl(ConnPid, StreamRef) ->
    fun() ->
            ok = gun:cancel(ConnPid, StreamRef)
    end.

wsUpgradeImpl(ConnPid, Path, Headers) ->
    fun() ->
            gun:ws_upgrade(ConnPid, Path, Headers)
    end.

wsSendImpl(ConnPid, StreamRef, Frames) ->
    fun() ->
            gun:ws_send(ConnPid, StreamRef, Frames)
    end.
