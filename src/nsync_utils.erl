%% Copyright (c) 2011 Jacob Vorreuter <jacob.vorreuter@gmail.com>
%% 
%% Permission is hereby granted, free of charge, to any person
%% obtaining a copy of this software and associated documentation
%% files (the "Software"), to deal in the Software without
%% restriction, including without limitation the rights to use,
%% copy, modify, merge, publish, distribute, sublicense, and/or sell
%% copies of the Software, and to permit persons to whom the
%% Software is furnished to do so, subject to the following
%% conditions:
%% 
%% The above copyright notice and this permission notice shall be
%% included in all copies or substantial portions of the Software.
%% 
%% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
%% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
%% OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
%% NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
%% HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
%% WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
%% FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
%% OTHER DEALINGS IN THE SOFTWARE.
-module(nsync_utils).
-compile(export_all).

do_callback({M,F}, Args) when is_atom(M), is_atom(F) ->
    apply(M, F, Args);

do_callback({M,F,A}, Args) when is_atom(M), is_atom(F), is_list(A) ->
    apply(M, F, A ++ Args);

do_callback(Fun, Args) when is_function(Fun) ->
    apply(Fun, Args);

do_callback(_Cb, _Args) ->
    exit("Invalid callback").

lookup_write_tid(MasterTid, Name) ->
    case ets:lookup(MasterTid, Name) of
        [{Name, _R, W}] ->
            W;
        [] ->
            W = ets:new(undefined, [protected, set]),
            ets:insert(MasterTid, {Name, W, W}),
            W
    end.

lookup_read_tid(MasterTid, Name) ->
    case ets:lookup(MasterTid, Name) of
        [{Name, R, _W}] ->
            R;
        [] ->
            undefined
    end.

reset_write_tids(MasterTid) ->
    [begin
        W1 = ets:new(undefined, [protected, set]), 
        ets:insert(MasterTid, {Name, R, W1})
    end || {Name, R, _W} <- ets:tab2list(MasterTid)].

failover_tids(MasterTid) ->
    [begin
        ets:insert(MasterTid, {Name, W, W}),
        R =/= W andalso ets:delete(R)
    end || {Name, R, W} <- ets:tab2list(MasterTid)].
