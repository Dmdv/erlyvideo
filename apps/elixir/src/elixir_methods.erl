% Holds introspection for methods.
% To check how methods are defined internally, check elixir_def_method.
-module(elixir_methods).
-export([assert_behavior/2, inherit_methods/1, mixin_methods/1]).
-include("elixir.hrl").
-import(lists, [umerge/2, sort/1]).

% Public in Elixir

mixin_methods(#elixir_slate__{module=Module}) ->
  Module:'__mixin_methods__'([]);

mixin_methods(#elixir_module__{data=Data} = Self) when is_atom(Data) ->
  calculate_methods(Self, fun(X) -> Mod = ?ELIXIR_ERL_MODULE(X), Mod:'__local_methods__'([]) end, elixir_module_behavior:mixins(Self), []);

mixin_methods(#elixir_module__{name=Module}) ->
  Module:'__mixin_methods__'([]);

mixin_methods(Self) ->
  Module = elixir_dispatch:builtin_mixin(Self),
  Module:'__mixin_methods__'([]).

% Public in Erlang

assert_behavior(Module, Object) when is_atom(Module) -> 
  Exports = Module:module_info(exports) -- erlang_compiled(),
  Methods = mixin_methods(Object),

  lists:foreach(fun({Name, Arity}) ->
    case lists:member({Name, Arity-1}, Methods) of
      true -> [];
      false -> elixir_errors:error({no_callback, {Name, Arity-1, Object}})
    end
  end, Exports).

inherit_methods(Name) ->
  Name:'__local_methods__'([]) -- elixir_compiled().

%% HELPERS

% Keeps a list of all methods automatically generated by Elixir, with Elixir arity.
elixir_compiled() ->
  [{'__mixins__',0},{'__module_name__',0},{'__module__',0},{'__local_methods__',0},{'__mixin_methods__',0}].

% Keeps a list of all methods that are generated automatically by Erlang.
erlang_compiled() ->
  [{module_info,0},{module_info,1}].

% Convert methods from Elixir arity to Erlang.
% convert_methods(Target) ->
%   lists:map(fun convert_method/1, Target).
% 
% convert_method({Name, Arity}) -> { Name, Arity - 1 }.

% Merge methods from mixins ensuring uniqueness.
calculate_methods(_Self, Fun, List, Acc) ->
  calculate_methods(Fun, List, Acc).

calculate_methods(Fun, [H|T], Acc) ->
  calculate_methods(Fun, T, umerge(Acc, sort(Fun(H))));

calculate_methods(_Fun, [], Acc) ->
  Acc.