%%%-------------------------------------------------------------------
%%% @author Brian Ward <bward@brianw2.local>
%%% @copyright (C) 2015, Brian Ward
%%% @doc
%%%
%%% @end
%%% Created : 16 Mar 2015 by Brian Ward <bward@brianw2.local>
%%%-------------------------------------------------------------------
-module(spike_gen_server).

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-define(SERVER, ?MODULE).

-record(state, {nodes=[],nodedown_action_timer}).

%%%===================================================================
%%% API
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initializes the server
%%
%% @spec init(Args) -> {ok, State} |
%%                     {ok, State, Timeout} |
%%                     ignore |
%%                     {stop, Reason}
%% @end
%%--------------------------------------------------------------------
init([]) ->
    net_kernel:monitor_nodes(true, [nodedown_reason]),
    io:format("here 1~n"),
    erlang:send_after(1500,self(),send_time),
    io:format("here 2~n"),
    Nodes=lists:usort(nodes()),
    io:format("Nodes are ~p~n",[Nodes]),
    {ok,#state{nodes = Nodes}}.


%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling call messages
%%
%% @spec handle_call(Request, From, State) ->
%%                                   {reply, Reply, State} |
%%                                   {reply, Reply, State, Timeout} |
%%                                   {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, Reply, State} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling cast messages
%%
%% @spec handle_cast(Msg, State) -> {noreply, State} |
%%                                  {noreply, State, Timeout} |
%%                                  {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_cast({receive_time, Time}, State) ->
    io:format("At the tone, the time will be ~p~n", [Time]),
    {noreply, State};
handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_info(send_time,State) ->
    lists:foreach(fun(Node) ->
                      Now = now(),
                      io:format("Sending time ~p to ~p~n", [Now, Node]),
                      gen_server:cast({?SERVER, Node}, {receive_time, Now})
                  end, State#state.nodes),
    erlang:send_after(1500,self(),send_time),
    {noreply,State};
handle_info({nodedown,Node, InfoList},State) ->
    NewState=start_nodedown_timer(Node,InfoList,State),
    {noreply,NewState};
handle_info({nodedown,Node},State) ->
    NewState=start_nodedown_timer(Node,[],State),
    {noreply,NewState};
handle_info({nodeup,Node,InfoList},State) ->
    NewState=cancel_nodedown_timer(Node,InfoList,State),
    {noreply,NewState#state{nodes = lists:usort(State#state.nodes ++ [Node])}};
handle_info({nodeup,Node},State) ->
    NewState=cancel_nodedown_timer(Node,[],State),
    {noreply,NewState#state{nodes = lists:usort(State#state.nodes ++ [Node])}};
handle_info(nodedown_action,State) ->
    io:format("NODE DOWN!!!! AAHHHH!!!~n"),
    {noreply,State#state{nodedown_action_timer=undefined}};
handle_info(Info, State) ->
    io:format("unsolicited message from Jake -> ~p~n",[Info]),
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
start_nodedown_timer(Node,InfoList,State) ->
    io:format("nodedown: ~p with reason ~p~n",[Node,InfoList]), 
    Response=timer:send_after(60000, nodedown_action),
    State#state{nodedown_action_timer=Response}.

cancel_nodedown_timer(Node,InfoList,#state{nodedown_action_timer={ok, TRef}} = State) ->
    io:format("nodeup: ~p with reason ~p, stopping timer~n",[Node,InfoList]), 
    timer:cancel(TRef),
    State#state{nodedown_action_timer=undefined};
cancel_nodedown_timer(Node,InfoList,State) ->
    io:format("nodeup: ~p with reason ~p, No timer to stop~n",[Node,InfoList]), 
    State#state{nodedown_action_timer=undefined}.

