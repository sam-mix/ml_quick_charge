%%%-------------------------------------------------------------------
%% @doc ml_charge public API
%% @end
%%%-------------------------------------------------------------------

-module(ml_charge_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    Dispatch = cowboy_router:compile([
        {'_', [
            {"/quick_callback", quick_charge, []}
        ]}
    ]),
    {ok, _} = cowboy:start_clear(http, [{port, 8080}], #{
        env => #{dispatch => Dispatch}
    }),
    ml_charge_sup:start_link().

stop(_State) ->
    ok.

%% internal functions
