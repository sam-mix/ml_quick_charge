-module(quick_charge).

%% #{a => 30, p=>\"dev\",z=>1,rid=>1, ip=>\"127.0.0.1\",g=>\"ml\",no => \"asdhjfljhawlejkr_awejljr\", gold => 300, c => 2}.
%% a -> account 金额 正整数
%% p -> platform 字符串
%% z -> zone_id 正整数
%% rid -> role_id 正整数
%% ip -> 游戏服IP 字符串
%% g -> game_name 固定 "ml" 字符串
%% no -> 游戏内部订单号 字符串
%% gold -> 金币数量 正整数
%% c -> charge_type 充值类型 正整数 
%%



-define(data, "@159@87@97@97@162@169@160@160@81@170@153@167@168@158@167@158@116@133@99@96@104@132@132@153@161@156@213@156@155@164@155@161@133@139@136@122@144@105@85@84@164@168@149@163@153@150@164@159@165@200@111@84@166@209@134@115@96@102@164@116@163@171@157@199@206@169@152@159@194@158@152@167@164@149@155@154@115@113@165@149@170@214@147@153@157@160@160@157@166@152@218@157@165@170@114@148@159@101@157@167@194@165@152@167@165@114@112@152@157@150@166@158@156@207@112@106@112@154@156@112@98@156@206@153@160@164@153@208@161@114@151@156@196@159@161@153@157@147@169@158@153@115@106@99@104@155@102@103@116@145@199@156@148@167@212@157@158@149@169@205@199@116@112@155@196@158@152@147@160@166@152@154@167@115@105@98@106@151@103@104@111@154@157@112@98@160@199@165@151@149@163@214@199@155@166@114@159@160@165@152@150@166@147@163@164@115@105@98@108@149@98@99@110@146@154@101@101@106@151@108@100@104@100@152@151@103@101@106@155@101@102@103@109@99@163@167@153@154@170@143@165@210@112@110@168@195@221@147@167@162@211@157@112@104@100@149@153@99@100@106@144@98@101@84@98@101@110@105@103@111@106@96@115@146@162@147@177@193@216@157@160@158@164@116@147@163@163@217@209@170@114@101@145@97@99@112@96@149@161@164@170@163@172@110@115@214@166@147@172@215@215@114@99@117@149@171@166@151@168@217@214@116@112@153@219@165@165@149@164@147@164@150@167@150@165@163@117@222@99@175@151@221@150@177@111@104@203@176@166@168@149@215@194@166@149@166@196@158@166@114@109@99@161@154@168@168@153@151@156@161@110@97@169@215@205@151@158@172@202@163@145@163@153@215@214@151@155@153@161").
-define(key, "rckhzzvprbruovhysretkuyrn9xebpb2").
-define(sign, "@198@108@104@104@198@98@102@104@98@104@104@106@106@106@112@96@110@198@100@100@112@196@200@104@102@114@204@112@100@108@104@200").
-define(sign_origin, "c644c134144555807c228bd439f8264d").
-define(data_origin, "<!--?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?--><quicksdk_message><message><is_test>0</is_test><channel>8888</channel><channel_uid>231845</channel_uid><game_order>123456789</game_order><order_no>12520160612114220441168433</order_no><pay_time>2016-06-12 11:42:20</pay_time><amount>1.00</amount><status>0</status><extras_params><![CDATA[#{a => 30, p=>\"dev\",z=>1,rid=>1, ip=>\"127.0.0.1\",g=>\"ml\",no => \"asdhjfljhawlejkr_awejljr\", gold => 300, c => 2}.]]></extras_params></message></quicksdk_message>").


-export([
	init/2
	,decode/2
	,test/0
	,get_integer/1
	,encode/2
	]).


init(Req0 = #{method := <<"GET">>}, Opts) ->
	#{
		nt_data := NtDataBin
		,sign := SignBin
		,md5Sign := Md5SignBin
	} = cowboy_req:match_qs([
		nt_data
		,sign
		,md5Sign
	],Req0),
	NtData = erlang:binary_to_list(NtDataBin),
	Sign = erlang:binary_to_list(SignBin),
	Md5Sign = erlang:binary_to_list(Md5SignBin),
	io:format("NtData = [~ts],
		Sign = [~ts],
		Md5Sign = [~ts]~n",[
		NtData,
		Sign,
		Md5Sign
	]),
    Sign2 = md5(NtData++Sign++?key),
    io:format("Sign2 = [~ts]~n", [Sign2]),
    io:format("Sign2 =:= Md5Sign => [~w]~n", [Sign2 =:= Md5Sign]),
    Reply = 
    case Sign2 =:= Md5Sign of
        true ->
            Data = decode(NtData,?key),
            case get_info(Data) of
                {true,_Amount,_OrderNo, ExtraInfo}->
                    {ok, Tokens, _} = erl_scan:string(ExtraInfo),
                    case erl_parse:parse_term(Tokens) of
                        {ok, 
                            #{
                                p := P,
                                z := Z,
                                rid := Rid,
                                ip := Ip,
                                g := G,
                                no  := No,
                                a := A,
                                gold := Gold,
                                c := C
                            }
                        } ->
                            Node = list_to_atom(lists:concat([G, "_", P, "_", Z, "@", "127.0.0.1"])),
                            case rpc:call(Node, charge, notice_test, [Rid, P, Z, No]) of
                                {badrpc,nodedown} ->
                                    io:format("p = [~ts], z = [~w] nodedown~n", [P, Z]),
                                    <<"NodeDownError">>;
                                ok ->
                                    io:format("充值成功~n"),
                                    <<"Success">>;
                                {false, Msg} ->
                                    io:format("玩家不在线 [~ts]~n", [Msg]),
                                    <<"NotOnlineError">>;
                                _CElse ->
                                    io:format("未知错误 [~ts]~n", [_CElse]),
                                    <<"UnkownError">>
                            end;
                        _PElse -> 
                            io:format("ExtraInfoError [~w]~n", [_PElse]),
                            <<"ExtraInfoError">>
                    end;
                false ->
                    <<"GetInfoError">>;
                _ ->
                	<<"ParseError">>
            end;
        false ->
            <<"SignError">>
    end,
	Req = cowboy_req:reply(200, #{
			<<"content-type">> => <<"text/plain">>
		}, Reply, Req0),
	{ok, Req, Opts}.

test() ->
	M = encode(?data_origin,?key),
	io:format("M = ~ts~n", [M]),
	S = encode(?sign_origin,?key),
	io:format("Sign = ~ts~n", [S]),
	io:format("eq = ~w~n", [M == ?data]),
	D = decode(M, ?key),
	Md5Sign = md5(M ++ S ++ ?key),
	io:format("Md5Sign = [~ts]~n", [Md5Sign]),
	get_info(D).

md5(S) ->
    lists:flatten([io_lib:format("~2.16.0b",[N]) || N <- binary_to_list(erlang:md5(S))]).

%加密
encode(Src,Key) ->
    case lists:member(undefined,[Src,Key]) of
        true ->
            io:formt("has null Src :~w Key: ~w ~n",[Src,Key]);
        false ->
            SrcLength = length(Src),
            KeyLength = length(Key),
            Temp = lists:seq(1,SrcLength),
            Result = lists:foldl(fun(Index,Acc0) ->
                DataElement = lists:nth(Index,Src),
                KeyElement = lists:nth(((Index-1) rem KeyLength)+1,Key),
                ResultElement = (DataElement band 16#ff) + (KeyElement band 16#ff),
                Acc0++"@"++integer_to_list(ResultElement)
                end,[],Temp),
            Result
    end.

%解密
decode(Src,Key) ->
    NewSrc = predeal(Src),
    % ?INFO("after predeal ~w ~n",[NewSrc]),
    NewSrcLength = length(NewSrc),
    case NewSrcLength >0 of
        true ->
            KeyLength = length(Key),
            Temp = lists:seq(1,NewSrcLength),
            ResultData1 = lists:foldl(fun(Index,Acc) ->
                DataElement = lists:nth(Index,NewSrc),
                KeyElement = lists:nth((((Index-1) rem KeyLength)+1),Key),
                NewDate = DataElement - (16#ff band KeyElement),
                [NewDate|Acc]
                end,[],Temp),
            lists:reverse(ResultData1);
        false ->
            io:format("NewSrc ~w length is 0 ~n",[NewSrc]),
            Src
    end.

%去除Src中的@字符
predeal(Src) ->
    case length(Src) > 0 of
        true ->
            List = string:tokens(Src,"@"),
            to_integers(List);
        false ->
            []
    end.

 to_integers(List) ->
 	to_integer(List, []).

to_integer([], R) ->
 	lists:reverse(R);
to_integer([H|T], R) ->
	case get_integer(H) of
		is_not_integer ->
			[];
		E ->
			to_integer(T, [E|R])
	end.

 get_integer(X) -> 
    case string:to_integer(X) of
        {error,no_integer} -> is_not_integer;
        {A, B} -> 
        	if length(B) == 0 ->
			    A;
			true ->
			  is_not_integer
			end    
    end.

get_info(Data)-> 
    {ParsedDocumentRootElement, _RemainingText = ""} = xmerl_scan:string(Data),
    [{_,_,_,_,ChannelID,_}] = xmerl_xpath:string("//channel/text()",ParsedDocumentRootElement),
    [{_,_,_,_,Amount,_}] = xmerl_xpath:string("//amount/text()",ParsedDocumentRootElement),
    [{_,_,_,_,Status,_}] = xmerl_xpath:string("//status/text()",ParsedDocumentRootElement),
    [{_,_,_,_,ExtraInfo,_}] = xmerl_xpath:string("//extras_params/text()",ParsedDocumentRootElement),
    [{_,_,_,_,OrderNo,_}] = xmerl_xpath:string("//order_no/text()",ParsedDocumentRootElement),
    [{_,_,_,_,IsTest,_}] = xmerl_xpath:string("//is_test/text()",ParsedDocumentRootElement),
    [{_,_,_,_,ChannelUID,_}] = xmerl_xpath:string("//channel_uid/text()",ParsedDocumentRootElement),
    [{_,_,_,_,GameOrder,_}] = xmerl_xpath:string("//game_order/text()",ParsedDocumentRootElement),
    [{_,_,_,_,PayTime,_}] = xmerl_xpath:string("//pay_time/text()",ParsedDocumentRootElement),
    io:format("ChannelID = [~ts], 
    	Amount = [~ts], 
    	Status = [~ts], 
    	ExtraInfo = [~ts], 
    	IsTest = [~ts], 
    	ChannelUID = [~ts], 
    	GameOrder = [~ts], 
    	PayTime = [~ts], 
    	OrderNo = [~ts]~n", 
    	[ChannelID, 
    	Amount, 
    	Status, 
    	ExtraInfo,
    	IsTest,
    	ChannelUID, 
    	GameOrder,
    	PayTime,
    	OrderNo
    ]),
    {true,trunc(list_to_float(Amount)),OrderNo, ExtraInfo}.
