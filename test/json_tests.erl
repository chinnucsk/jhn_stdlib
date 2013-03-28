%%==============================================================================
%% Copyright 2013 Jan Henry Nystrom <JanHenryNystrom@gmail.com>
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%% http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.
%%==============================================================================

%%%-------------------------------------------------------------------
%%% @doc
%%%   eunit unit tests for the json library module.
%%% @end
%%%
%% @author Jan Henry Nystrom <JanHenryNystrom@gmail.com>
%% @copyright (C) 2013, Jan Henry Nystrom <JanHenryNystrom@gmail.com>
%%%-------------------------------------------------------------------
-module(json_tests).
-copyright('Jan Henry Nystrom <JanHenryNystrom@gmail.com>').

%% Includes
-include_lib("eunit/include/eunit.hrl").

%% Defines
-define(BASE,
        [{<<"{}">>, {[]}},
         {<<"{\"empty\":[]}">>, {[{<<"empty">>, []}]}},
         {<<"{\"empty\":{}}">>, {[{<<"empty">>, {[]}}]}},
         {<<"[]">>, []},
         {<<"[[]]">>, [[]]},
         {<<"[{}]">>, [{[]}]},
         {<<"{\"one\":1}">>, {[{<<"one">>, 1}]}},
         {<<"{\"one\":1,\"two\":2}">>, {[{<<"one">>, 1}, {<<"two">>, 2}]}},
         {<<"{\"one\":1.0}">>, {[{<<"one">>, 1.0}]}},
         {<<"{\"one\":0.1,\"two\":2.2}">>,
          {[{<<"one">>, 0.1}, {<<"two">>, 2.2}]}},
         {<<"{\"one\":null}">>, {[{<<"one">>, null}]}},
         {<<"{\"one\":true}">>, {[{<<"one">>, true}]}},
         {<<"{\"one\":false}">>, {[{<<"one">>, false}]}},
         {<<"[null,true,false]">>, [null, true, false]},
         {<<"[1,-1,1.0,-1.0]">>, [1, -1, 1.0, -1.0]}
        ]).

-define(ESCAPE,
        [{<<"[\"\\u0000\\u0001\\u0002\\u0003\\u0004\\u0005\\u0006\"]">>,
          [<<0, 1, 2, 3, 4, 5, 6>>]},
         {<<"[\"\\u0007\\b\\t\\n\\u000B\\f\\r\"]">>,
          [<<7, 8, 9, 10, 11, 12, 13>>]},
         {<<"[\"\\u000E\\u000F\\u0010\\u0011\\u0012\\u0013\\u0014\"]">>,
          [<<14, 15, 16, 17, 18, 19, 20>>]},
         {<<"[\"\\u0015\\u0016\\u0017\\u0018\\u0019\\u001A\\u001B\"]">>,
          [<<21, 22, 23, 24, 25, 26, 27>>]},
         {<<"[\"\\u001C\\u001D\\u001E\\u001F\"]">>,
          [<<28, 29, 30, 31>>]},
         {<<"[\"\\\\\\/\\\"\"]">>,
          [<<"\\/\"">>]},
         {<<"[\"\\\"ABBA\\\"\"]">>,
          [<<"\"ABBA\"">>]}
        ]).

-define(FLOATS_RAW,
        [0.0,
         0.1, 0.01, 0.001, 0.0001, 0.00001, 0.000001, 0.0000001,
         0.1, 0.11, 0.101, 0.1001, 0.10001, 0.100001, 0.1000001,
         1.0, 10.0, 100.0, 1000.0, 10000.0, 100000.0, 1000000.0,
         1.0, 11.0, 101.0, 1001.0, 10001.0, 100001.0, 1000001.0,
         1.1, 10.1, 100.1, 1000.1, 10000.1, 100000.1, 1000000.1,
         1.0e1, 1.0e2, 1.0e3, 1.0e4, 1.0e5, 1.0e6, 1.0e7, 1.0e8,
         1.0e9, 1.0e10, 1.0e11, 1.0e12, 1.0e13, 1.0e14, 1.0e15,
         1.1e1, 1.1e2, 1.1e3, 1.1e4, 1.1e5, 1.1e6, 1.1e7, 1.1e8,
         1.1e9, 1.1e10, 1.1e11, 1.1e12, 1.1e13, 1.1e14, 1.1e15,
         0.1e1, 0.1e2, 0.1e3, 0.1e4, 0.1e5, 0.1e6, 0.1e7, 0.1e8,
         0.1e9, 0.1e10, 0.1e11, 0.1e12, 0.1e13, 0.1e14, 0.1e15,
         1.23456, 12.3456, 123.456, 1234.56, 12345.6, 123456.0,
         123456.0, 12345.6, 1234.56, 123.456, 12.3456
        ]).

-define(FLOATS_PLUS,
        [{iolist_to_binary([$[, hd(io_lib:format("~p", [F])), $]]), [F]} ||
            F <- ?FLOATS_RAW]).

-define(FLOATS_MINUS,
        [{iolist_to_binary([$[, hd(io_lib:format("~p", [-F])), $]]), [-F]} ||
            F <- ?FLOATS_RAW]).

-define(FLOATS, ?FLOATS_PLUS ++ ?FLOATS_MINUS).

-define(STRING,
        [{<<"[\"one\"]">>, [<<"one">>]},
         {<<"[\"a\"]">>, [<<"a">>]},
         {<<"[\"one two\"]">>, [<<"one two">>]},
         {<<"[\" one\"]">>, [<<" one">>]},
         {<<"[\"two \"]">>, [<<"two ">>]},
         {<<"[\" one two \"]">>, [<<" one two ">>]}
        ]).

-define(STRING_ESCAPE, ?STRING ++ ?ESCAPE).

%% decode(JSON) = Term, encode(TERM) = JSON
-define(REVERSIBLE, ?BASE ++ ?STRING_ESCAPE ++ ?FLOATS).

-define(PLAIN_FORMATS,
        [utf8, {utf16, little}, {utf16, big}, {utf32, little}, {utf32, big}]).

-define(ENCODINGS,
        [utf8, {utf16, little}, {utf16, big}, {utf32, little}, {utf32, big}]).



%% ===================================================================
%% Tests.
%% ===================================================================

%% ===================================================================
%% Encoding
%% ===================================================================

%%--------------------------------------------------------------------
%% encode/1
%%--------------------------------------------------------------------
encode_1_test_() ->
    [?_test(?assertEqual(Result, iolist_to_binary(json:encode(Term)))) ||
        {Result, Term} <- ?REVERSIBLE].

%%--------------------------------------------------------------------
%% encode/2
%%--------------------------------------------------------------------
encode_2_test_() ->
    [?_test(?assertEqual(Result, iolist_to_binary(json:encode(Term, [])))) ||
        {Result, Term} <- ?REVERSIBLE].

%%--------------------------------------------------------------------
%% encode/2 with binary
%%--------------------------------------------------------------------
encode_2_binary_test_() ->
    [?_test(?assertEqual(Result, json:encode(Term, [binary]))) ||
        {Result, Term} <- ?REVERSIBLE].

%%--------------------------------------------------------------------
%% encode/2 with iolist
%%--------------------------------------------------------------------
encode_2_iolist_test_() ->
    [?_test(?assertEqual(Result,
                         iolist_to_binary(json:encode(Term, [iolist])))) ||
        {Result, Term} <- ?REVERSIBLE].

%%--------------------------------------------------------------------
%% encode/2 with different encodings
%%--------------------------------------------------------------------
encode_2_encodings_test_() ->
    [?_test(?assertEqual(unicode:characters_to_binary(Result, latin1, Encoding),
                         iolist_to_binary(
                           json:encode(Term, [{encoding, Encoding}])))) ||
        {Result, Term} <- ?REVERSIBLE,
        Encoding <- ?ENCODINGS
    ].


%%--------------------------------------------------------------------
%% encode/2 with encoding = utf8 different plain
%%--------------------------------------------------------------------
encode_2_encodings_plains_test_() ->
    [
     ?_test(
        ?assertEqual(unicode:characters_to_binary(Result, latin1, Encoding),
                     iolist_to_binary(
                       json:encode([unicode:characters_to_binary(String,
                                                                 latin1,
                                                                 Plain)],
                                   [{encoding, Encoding},
                                    {plain_string, Plain}])))) ||
        {Result, [String]} <- ?STRING_ESCAPE,
        Plain <- ?PLAIN_FORMATS,
        Encoding <- ?ENCODINGS
    ].

%% ===================================================================
%% Decoding
%% ===================================================================

%%--------------------------------------------------------------------
%% decode/1
%%--------------------------------------------------------------------
decode_1_test_() ->
    [?_test(
        ?assertEqual(
           Term,
           json:decode(unicode:characters_to_binary(JSON, latin1, Encoding))))||
        {JSON, Term} <- ?REVERSIBLE,
        Encoding <- ?ENCODINGS
    ].

%%--------------------------------------------------------------------
%% decode/2
%%--------------------------------------------------------------------
decode_2_test_() ->
    [?_test(
        ?assertEqual(
           Term,
           json:decode(unicode:characters_to_binary(JSON, latin1, Encoding),
                       []))) ||
        {JSON, Term} <- ?REVERSIBLE,
        Encoding <- ?ENCODINGS
    ].

%% ===================================================================
%% Internal functions.
%% ===================================================================
