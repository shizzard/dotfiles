%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Thanks to serge@hq.idt.net %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Authored and refactored by shizzard %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-module(user_default).

%% help
-export([help/0]).
%% debug helpers
-export([dbgtc/1, dbgon/1, dbgon/2, dbgadd/1, dbgadd/2, dbgdel/1, dbgdel/2, dbgoff/0]).
%% reloaders
-export([lm/0, mm/0]).
%% measurements
-export([time/1, himem/1, hibin/1, himq/1, pi/1]).
%% macro
-export([obs/0]).

-import(io, [format/1, format/2]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% HELP %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
help() ->
    shell_default:help(),
    format("** user extended commands **~n"),
    Commands = [
        {"dbgtc(File)","use dbg:trace_client() to read data from File"},
        {"dbgon(M)","enable dbg tracer on all funs in module M"},
        {"dbgon(M,Fun)","enable dbg tracer for module M and function F"},
        {"dbgon(M,File)","enable dbg tracer for module M and log to File"},
        {"dbgadd(M)","enable call tracer for module M"},
        {"dbgadd(M,F)","enable call tracer for function M:F"},
        {"dbgdel(M)","disable call tracer for module M"},
        {"dbgdel(M,F)","disable call tracer for function M:F"},
        {"dbgoff()","disable dbg tracer (calls dbg:stop/0)"},

        {"lm()","load all changed modules"},
        {"mm()","list modified modules"},

        {"time(Fun)", "make timing routines for function"},
        {"himem(Bytes)", "list of processes with memory consumption is higher than the threshold (bytes)"},
        {"hibin(Bytes)", "list of processes with binary memory consumption is higher than the threshold (bytes)"},
        {"himq(Num)", "list of processes with message queue is higher than the threshold"},
        {"pi({Pid, _})", "gather some useful information about process or process list"},

        {"obs()","start observer"}
    ],
    [format("~-15s -- ~s~n", [Fun, Desc]) || {Fun, Desc} <- Commands],
    true.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% DEBUG HELPERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
dbgtc(File) ->
    Fun = fun({trace,_,call,{M,F,A}}, _) ->
        io:format("call: ~w:~w~w~n", [M,F,A]);
            ({trace,_,return_from,{M,F,A},R}, _) ->
        io:format("retn: ~w:~w/~w -> ~w~n", [M,F,A,R]);
            (A,B) ->
        io:format("~w: ~w~n", [A,B])
    end,
    dbg:trace_client(file, File, {Fun, []}).

dbgon(Module) ->
    case dbg:tracer() of
        {ok,_} ->
            dbg:p(all,call),
            dbg:tpl(Module, [{'_',[],[{return_trace}]}]),
            ok;
        Else ->
            Else
    end.

dbgon(Module, Fun) when is_atom(Fun) ->
    {ok,_} = dbg:tracer(),
    dbg:p(all,call),
    dbg:tpl(Module, Fun, [{'_',[],[{return_trace}]}]),
    ok;



dbgon(Module, File) when is_list(File) ->
    {ok,_} = dbg:tracer(port, dbg:trace_port(file, File)),
    dbg:p(all,call),
    dbg:tpl(Module, [{'_',[],[{return_trace}]}]),
    ok.

dbgadd(Module) ->
    dbg:tpl(Module, [{'_',[],[{return_trace}]}]),
    ok.

dbgadd(Module, Fun) ->
    dbg:tpl(Module, Fun, [{'_',[],[{return_trace}]}]),
    ok.

dbgdel(Module) ->
    dbg:ctpl(Module),
    ok.

dbgdel(Module, Fun) ->
    dbg:ctpl(Module, Fun),
    ok.

dbgoff() ->
    dbg:stop().


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% RELOADERS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
lm() ->
    [c:l(M) || M <- mm()].

mm() ->
    modified_modules().

modified_modules() ->
    [M || {M, _} <- code:all_loaded(), module_modified(M) == true].

module_modified(Module) ->
    case code:is_loaded(Module) of
        {file, preloaded} ->
            false;
        {file, Path} ->
            CompileOpts = proplists:get_value(compile, Module:module_info()),
            CompileTime = proplists:get_value(time, CompileOpts),
            Src = proplists:get_value(source, CompileOpts),
            module_modified(Path, CompileTime, Src);
        _ ->
            false
    end.

module_modified(Path, PrevCompileTime, PrevSrc) ->
    case find_module_file(Path) of
        false ->
            false;
        ModPath ->
            case beam_lib:chunks(ModPath, ["CInf"]) of
                {ok, {_, [{_, CB}]}} ->
                    CompileOpts = binary_to_term(CB),
                    CompileTime = proplists:get_value(time, CompileOpts),
                    Src = proplists:get_value(source, CompileOpts),
                    not (CompileTime == PrevCompileTime) and (Src == PrevSrc);
                _ ->
                    false
            end
    end.

find_module_file(Path) ->
    case file:read_file_info(Path) of
        {ok, _} ->
            Path;
        _ ->
            %% may be the path was changed?
            case code:where_is_file(filename:basename(Path)) of
                non_existing ->
                    false;
                NewPath ->
                    NewPath
            end
    end.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% MEASUREMENTS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
time(F) when is_function(F) ->
    S = now(), Res = F(), E = now(), {timer:now_diff(E,S), Res}.

himem(Bytes) ->
    hiparam(Bytes, memory).

hibin(Bytes) ->
    lists:foldl(fun(Pid, Acc0) ->
        {binary, Binaries} = erlang:process_info(Pid, binary),
        Val = lists:foldl(fun({_Ref, Size, _RefCnt}, Acc) ->
            Acc + Size
        end, 0, Binaries),
        if
            Val >= Bytes ->
                [{Pid, Val}] ++ Acc0;
            true ->
                Acc0
        end
    end, [], erlang:processes()).

himq(Count) ->
    hiparam(Count, message_queue_len).

hiparam(Threshold, Param) ->
    lists:foldl(fun(Pid, Acc) ->
        {Param, Val} = erlang:process_info(Pid, Param),
        if
            Val >= Threshold -> [{Pid, Val} | Acc];
            true -> Acc
        end
    end, [], erlang:processes()).

pi({Pid, Any}) when is_pid(Pid) ->
    pi([{Pid, Any}]);
pi(Pid) when is_pid(Pid) ->
    pi([Pid]);
pi([{Pid, _} | Tail]) when is_pid(Pid)->
    output_pi(Pid),
    pi(Tail);
pi([Pid | Tail]) when is_pid(Pid) ->
    output_pi(Pid),
    pi(Tail);
pi([]) ->
    ok.

output_pi(Pid) ->
    Info = process_info(Pid),
    RegName = proplists:get_value(registered_name, Info),
    Status = proplists:get_value(status, Info),
    {IM, IF, IA} = proplists:get_value(initial_call, Info),
    {CM, CF, CA} = proplists:get_value(current_function, Info),
    Dict = proplists:get_value(dictionary, Info),
    Memory = proplists:get_value(memory, Info),
    Links = proplists:get_value(links, Info),
    InMon = proplists:get_value(monitored_by, Info),
    OutMon = proplists:get_value(monitors, Info),
    TrapExit = proplists:get_value(trap_exit, Info),
    case RegName of
        undefined -> format(" ** process ~p is now ~p **~n", [Pid, Status]);
        Name -> format(" ** process ~p (registered as ~p) is now ~p **~n", [Pid, Name, Status])
    end,
    format("~20s: ~p:~p/~p~n", ["initial call", CM, CF, CA]),
    format("~20s: ~p:~p/~p~n", ["current function", IM, IF, IA]),
    format("~20s: ~p~n", ["dictionary", Dict]),
    format("~20s: ~p~n", ["total memory", Memory]),
    format("~20s: ~p~n", ["linked to", Links]),
    format("~20s: ~p~n", ["monitored by", InMon]),
    format("~20s: ~p~n", ["is monitoring", OutMon]),
    format("~20s: ~p~n~n", ["is trapping exits", TrapExit]),
    ok.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% MACRO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
obs() ->
    observer:start().
