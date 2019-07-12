# Erlang Chat Server
This is a super simple TCP chat server written in Erlang. Once a
client connects, any line of text that the client sends will be
broadcast to the other connected clients.

## Compiling and Running
Start the Erlang shell

    erl

Then use the following command in the Erlang shell to compile the program.

    c("chat").

To start the server listening on port 6000 use execute the following
command in the Erlang shell.

    chat:accept(6000).
