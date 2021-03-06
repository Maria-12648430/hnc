%% Copyright (c) 2020, Jan Uhlig <j.uhlig@mailingwork.de>
%% Copyright (c) 2020, Maria Scott <maria-12648430@gmx.net>
%%
%% Permission to use, copy, modify, and/or distribute this software for any
%% purpose with or without fee is hereby granted, provided that the above
%% copyright notice and this permission notice appear in all copies.
%%
%% THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
%% WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
%% MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
%% ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
%% WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
%% ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
%% OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

-module(hnc_worker_sup).

-behavior(supervisor).

-export([start_link/3]).
-export([start_worker/1, stop_worker/2]).
-export([init/1]).

-spec start_link(module(), term(), hnc:shutdown()) -> {ok, pid()}.
start_link(Mod, Args, Shutdown) ->
	supervisor:start_link(?MODULE, {Mod, Args, Shutdown}).

-spec start_worker(pid()) -> {ok, hnc:worker()}.
start_worker(Sup) ->
	supervisor:start_child(Sup, []).

-spec stop_worker(pid(), hnc:worker()) -> ok.
stop_worker(Sup, Worker) ->
	supervisor:terminate_child(Sup, Worker).

init({Mod, Args, Shutdown}) ->
	{module, Mod}=code:ensure_loaded(Mod),
	Modules=case erlang:function_exported(Mod, get_modules, 0) of
		true -> Mod:get_modules();
		false -> [Mod]
	end,
	{
		ok,
		{
			#{
				strategy => simple_one_for_one
			},
			[
				#{
					id => hnc_worker,
					start => {Mod, start_link, [Args]},
					restart => temporary,
					shutdown => Shutdown,
					modules => Modules
				}
			]
		}
	}.
