-module(transit_write_handlers).
-compile(export_all).
-include_lib("transit_format.hrl").

-define(UUID_MASK, math:pow(2, 64) - 1).

%%% undefined handler
undefined_tag(_) ->
  ?Null.

undefined_rep(_) ->
  undefined.

undefined_string_rep(_) ->
  <<"null">>.

%%% Integer handler
integer_tag(_I) ->
  ?Int.

integer_rep(I) ->
  I.

integer_string_rep(I) ->
  list_to_binary(integer_to_list(I)).

%%% BigInt handler
bigint_tag(_) ->
  ?BigInt.
bigint_rep(N) ->
  N.
bigint_string_rep(N) ->
  list_to_binary(integer_to_list(N)).

%%% Float handler
float_tag(_) ->
  ?Float.
float_rep(F) ->
  float_to_list(F).
float_string_rep(F) ->
  list_to_binary(float_to_list(F)).

%%% String handler
string_tag(_) ->
  ?String.
string_rep(S) ->
  S.
string_string_rep(S) ->
  S.

%%% bitstring handler
bitstring_tag(_) ->
  ?String.
bitstring_rep(S) ->
  S.
bitstring_string_rep(S) ->
  S.


%%% Boolean handler
boolean_tag(_) ->
  ?Boolean.
boolean_rep(B) ->
  B.
boolean_string_rep(B) ->
  case B of
    true ->
      <<"t">>;
    false ->
      <<"f">>
  end.

%%% List handler
list_tag(_A) ->
  ?Array.
list_rep(A) ->
  A.
list_string_rep(_A) ->
  undefined.

%%% Map handler
map_tag(_M) ->
  ?Map.
map_rep(M) ->
  M.
map_string_rep(_M) ->
  undefined.

%%% Keyword handler
keyword_tag(_K) ->
  ?Keyword.
keyword_rep(K) ->
  atom_to_list(K).
keyword_string_rep(K) ->
  list_to_binary(atom_to_list(K)).

%%% UUID handler
uuid_tag(_U) ->
  ?UUID.
uuid_rep(U) ->
  [U bsr 64, U band ?UUID_MASK].
uuid_string_rep(U) ->
  U. % TODO

%%% URI handler
uri_tag(_U) ->
  ?URI.
uri_rep(U) ->
  U.
uri_string_rep(U) ->
  U.

handler(Data) when is_boolean(Data) ->
  #write_handler{tag = fun boolean_tag/1, rep = fun boolean_rep/1, string_rep = fun boolean_string_rep/1};
handler(Data) when is_float(Data) ->
  #write_handler{tag = fun float_tag/1, rep = fun float_rep/1, string_rep = fun float_string_rep/1};
handler(Data) when is_integer(Data) ->
  #write_handler{tag = fun integer_tag/1, rep = fun integer_rep/1, string_rep = fun integer_string_rep/1};
handler(Data) when is_list(Data) ->
  case io_lib:printable_list(Data) of
    true ->
      #write_handler{tag = fun string_tag/1, rep = fun string_rep/1, string_rep = fun string_string_rep/1};
    false ->
      #write_handler{tag = fun list_tag/1, rep = fun list_rep/1, string_rep = fun list_string_rep/1}
  end;
handler(Data) when is_bitstring(Data) ->
  #write_handler{tag = fun bitstring_tag/1, rep = fun bitstring_rep/1, string_rep = fun bitstring_string_rep/1};
handler(Data) when is_map(Data) ->
  #write_handler{tag = fun map_tag/1, rep = fun map_rep/1, string_rep = fun map_string_rep/1};
handler(Data) when is_atom(Data) ->
  case Data of
    undefined ->
      #write_handler{tag = fun undefined_tag/1, rep = fun undefined_rep/1, string_rep = fun undefined_string_rep/1};
    _ ->
      #write_handler{tag = fun keyword_tag/1, rep = fun keyword_rep/1, string_rep = fun keyword_string_rep/1}
  end;
handler(_TaggedVal=#tagged_value{tag=Tag, rep=Rep, string_rep=Str}) ->
  #write_handler{tag=fun (_) -> Tag end, rep=fun (_) -> Rep end, string_rep = fun (_) -> Str end};

handler(_) ->
  #write_handler{}.

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

handler_test_() ->
  Tests = [{?Int, 1234},
           {?Map, #{}},
           {?Keyword, hi},
           {?Null, undefined}
          ],
  [fun() ->
      IntH = handler(Int),
      Tag = apply(IntH#write_handler.tag, [Int])
  end || {Tag, Int} <- Tests].

-endif.