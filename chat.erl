%%% The chat module provides a simple TCP chat server. Users can telnet
%%% into the server and chat with each other.
-module(chat).
-export([accept/1]).

%% Starts a chat server listening for incoming connections on the given Port.
accept(Port) ->
    {ok, Socket} = gen_tcp:listen(Port, [binary, {active, true}, {packet, line}, {reuseaddr, true}]),
    io:format("Chat server listening on port ~p~n", [Port]),
    Chat = spawn(fun () -> chat_loop([]) end),
    server_loop(Socket, Chat).

%% The loop for the chat server process. The chat server process has a list of listening
%% client processes. Send an add message to add a Client to the Clients list. Send a remove
%% message to remove a Client from the Clients list. Send a message message to broadcast
%% a message to all listening clients.
chat_loop(Clients) ->
    receive
        {add, Client} ->
            chat_loop([Client|Clients]);
        {remove, Client} ->
            chat_loop(Clients -- [Client]);
        {message, Client, Message} ->
            send_message(Clients -- [Client], Message),
            chat_loop(Clients)
    end.

%% Send a message to all the clients in the Clients list
send_message([],_) -> ok;
send_message([Client|Tail], Message) ->
    Client ! {message, Message},
    send_message(Tail, Message).

%% Accepts incoming socket connections and passes them off to a separate Handler process
server_loop(Socket, Chat) ->
    {ok, Connection} = gen_tcp:accept(Socket),
    Client = spawn(fun () -> client_loop(Connection, Chat) end),
    Chat ! {add, Client},
    gen_tcp:controlling_process(Connection, Client),
    io:format("New connection ~p~n", [Connection]),
    server_loop(Socket, Chat).


%% The client_loop handles the socket connection to the client. It takes
%% incoming lines and broadcasts them to the Chat process. It handles the TCP
%% connection being closed. It takes care of sending out messages through the
%% connected socket.
client_loop(Connection, Chat) ->
    receive
        {tcp, Connection, Data} ->
            Chat ! {message, self(), Data},
            client_loop(Connection, Chat);
        {tcp_closed} ->
            io:format("Connection closed ~p~n", [Connection]),
            Chat ! {remove, self()};
        {message, Message} ->
            gen_tcp:send(Connection, Message),
            client_loop(Connection, Chat)
    end.
