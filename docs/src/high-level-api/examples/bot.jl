#=

# [Bot example](@id high-level-bot-example)

This is a port of [the bot example from libstrophe](https://github.com/strophe/libstrophe/blob/master/examples/bot.c) to Julia using the high-level API of Strophe.jl.

You need the a server running on localhost (see [high-level-examples](@ref) to set up
a local xmpp server using docker-compose. If that is what you are using, start it
with `docker-compose up`. Depending on your platform, you might need sudo.

You also need [go-sendxmpp](https://salsa.debian.org/mdosch/go-sendxmpp) to listen
to messages from the other side.

If you need a simpler example on how to set-up a basic connection, you can read
first [the basic example](@ref high-level-basic-example) page.

=#
import Strophe
import Strophe: LibStrophe, Stanza, ClientConnection

# ## Boilerplate
# We want some facilities to listen to our xmpp server. The idea is quite simple:
# run `go-sendxmpp -n -p plopiplop -u pinocchio@localhost -l` to listen to messages
# and collect messages in a buffer.
#
# First, we run a process in parallel to listen to our inbox.

pinocchio = PipeBuffer()
listener = run(
    pipeline(
        `go-sendxmpp -n -p plopiplop -u pinocchio@localhost -l`,
        stdin = devnull, stdout = pinocchio, stderr = devnull
    ), wait = false
)

# Then, we write a simple function that we will run in parallel of the main
# thread to send messages to the bot.

function say_as_pinocchio(to, msg)
    io = PipeBuffer()
    write(io, msg)
    return run(`go-sendxmpp -n -p plopiplop -u pinocchio@localhost $to`, io, devnull, stderr)
end

# ## Structure of the bot
# `libstrophe` allows registering handlers. Our bot will be able to respond to version
# requests, messages, and connections.
# ## Global state
# In this example, we store the state of the bot in global variables
reconnect = true

# ## Version handler
# Our bot will implement [XEP-0092 (Software Version)](https://xmpp.org/extensions/xep-0092.html).
# This means other XMPP entities will be able to send a query for the bot version
# and we will respond accordingly. The [example section of the XEP](https://xmpp.org/extensions/xep-0092.html#examples)
# is quite explicit on what the reply should look like. We will build something like:
# ```xml
# <iq
#     type='result'
#     to='<destination>'
#     from='<us>'
#     id='version_1'>
#   <query xmlns='jabber:iq:version'>
#     <name>LibStrophe example bot</name>
#     <version>1.0</version>
#   </query>
# </iq>
# ```
#
# As usual with libstrophe, this is done through a callback function. You might
# want to have a look at the [low-level stanza handling reference](@ref low-level-stanza).

#=
TODO: something like this?
using Strope:s
reply = reply(stanza)(
    s(ctx, name="query", ns="...",)(
        s(ctx, name="name")(s(ctx, text="LibStrophe example bot"),
        s(ctx, name="version")(s(ctx, text="1.0"))
    )
))

so calling te result of `stanza` adds children to the stanza (and release it after), and the correct
functions are called on the stanza to set the kwargs.

We also want the equivalent `name`, `name!` functions, and probably an AbstractTrees
interface to iterate over stanzas

TODO: use the high-level API to build stanzas
=#
function version_handler(conn, stanza, userdata)
    ## As in the basic example, we user the opaque `userdata` to pass around the
    ## context.
    ctx = userdata
    @info "Received version request." LibStrophe.xmpp_stanza_get_from(stanza)

    reply = LibStrophe.xmpp_stanza_reply(stanza)
    LibStrophe.xmpp_stanza_set_type(reply, "result")

    ## First build the `<query/>` node
    query = LibStrophe.xmpp_stanza_new(ctx)
    LibStrophe.xmpp_stanza_set_name(query, "query")
    ns = LibStrophe.xmpp_stanza_get_ns(LibStrophe.xmpp_stanza_get_children(stanza))
    if (ns ≠ C_NULL)
        LibStrophe.xmpp_stanza_set_ns(query, ns)
    end
    ## Then the `<name/>` node
    name = LibStrophe.xmpp_stanza_new(ctx)
    LibStrophe.xmpp_stanza_set_name(name, "name")
    ## We register it as a child of the `<query/>`
    LibStrophe.xmpp_stanza_add_child(query, name)
    ## And we tell libstrophe that this object is now its own responsibility.
    LibStrophe.xmpp_stanza_release(name)

    ## Then we fill the name node with the correct string
    text = LibStrophe.xmpp_stanza_new(ctx)
    LibStrophe.xmpp_stanza_set_text(text, "LibStrophe example bot")
    LibStrophe.xmpp_stanza_add_child(name, text)
    LibStrophe.xmpp_stanza_release(text)

    ## A similar procedure applies for the version.
    version = LibStrophe.xmpp_stanza_new(ctx)
    LibStrophe.xmpp_stanza_set_name(version, "version")
    LibStrophe.xmpp_stanza_add_child(query, version)
    LibStrophe.xmpp_stanza_release(version)

    text = LibStrophe.xmpp_stanza_new(ctx)
    LibStrophe.xmpp_stanza_set_text(text, "1.0")
    LibStrophe.xmpp_stanza_add_child(version, text)
    LibStrophe.xmpp_stanza_release(text)

    ## Finally we register the `<query/>` node as a child of the reply
    LibStrophe.xmpp_stanza_add_child(reply, query)
    LibStrophe.xmpp_stanza_release(query)

    ## and we send it.
    LibStrophe.xmpp_send(conn, reply)
    LibStrophe.xmpp_stanza_release(reply)
    return Int32(1)
end

# As usual when dealing with C API, we need to explicitely create a function pointer
# for the callback.

const version_handler_c = @cfunction(
    version_handler, Cint,
    (Ptr{LibStrophe.xmpp_conn_t}, Ptr{LibStrophe.xmpp_stanza_t}, Ptr{Cvoid})
)

# ## Quit handler
# A simple handler that will disconnect us uppon request.

function _quit_handler(conn, userdata)
    LibStrophe.xmpp_disconnect(conn)
    return Int32(0)
end
const _quit_handler_c = @cfunction(
    _quit_handler, Cint,
    (Ptr{LibStrophe.xmpp_conn_t}, Ptr{Cvoid})
)


# ## Message handler
# We will register a handler that responds to messages here. If you are unfamiliar
# with it, you can check [the relevant section of RFC6121 on messages syntax](https://www.rfc-editor.org/rfc/rfc6121.html#section-5.2).
#
# A message stanza typically looks like this:
# ```xml
# <message
#        from='juliet@example.com/balcony'
#        id='ktx72v49'
#        to='romeo@example.net'
#        type='chat'
#        xml:lang='en'>
#      <body>Art thou not Romeo, and a Montague?</body>
# </message>
# ```

function message_handler(conn, stanza, userdata)
    ## First we recover the body of the message
    body = LibStrophe.xmpp_stanza_get_child_by_name(stanza, "body")
    body == C_NULL && return 1
    type = LibStrophe.xmpp_stanza_get_type(stanza)
    (type != C_NULL && unsafe_string(type) == "error") && return 1

    ## Then we extract its text
    intext = LibStrophe.xmpp_stanza_get_text(body)
    intext_str = unsafe_string(intext)
    LibStrophe.xmpp_free(ctx, intext)

    @info "Incoming message" LibStrophe.xmpp_stanza_get_from(stanza) intext_str

    reply = LibStrophe.xmpp_stanza_reply(stanza)
    if (LibStrophe.xmpp_stanza_get_type(reply) == C_NULL)
        LibStrophe.xmpp_stanza_set_type(reply, "chat")
    end

    if intext_str == "quit"
        replytext = "bye!"
        LibStrophe.xmpp_timed_handler_add(conn, _quit_handler_c, 500, C_NULL)
    elseif intext_str == "reconnect"
        replytext = "alright, let's see what happens!"
        global reconnect = true
        LibStrophe.xmpp_timed_handler_add(conn, _quit_handler_c, 500, C_NULL)
    else
        replytext = intext_str * " to you too!"
    end
    LibStrophe.xmpp_message_set_body(reply, replytext)

    LibStrophe.xmpp_send(conn, reply)
    LibStrophe.xmpp_stanza_release(reply)
    return Int32(1)
end
const message_handler_c = @cfunction(
    message_handler, Cint,
    (Ptr{LibStrophe.xmpp_conn_t}, Ptr{LibStrophe.xmpp_stanza_t}, Ptr{Cvoid})
)

# ## Connection handler
# This is what gets called by libstrophe on connection events.

function connection_handler(conn, status, error, stream_error, userdata)
    ctx = userdata
    if status == LibStrophe.XMPP_CONN_CONNECT # We just connected
        @info "Connected!"
        LibStrophe.xmpp_handler_add(conn, version_handler_c, "jabber:iq:version", "iq", C_NULL, ctx)
        LibStrophe.xmpp_handler_add(conn, message_handler_c, C_NULL, "message", C_NULL, ctx)
        pres = LibStrophe.xmpp_presence_new(ctx) # Send initial <presence/> so that we appear online to contacts
        LibStrophe.xmpp_send(conn, pres)
        LibStrophe.xmpp_stanza_release(pres)
    else
        @info "Disconnected!"
        LibStrophe.xmpp_stop(ctx) # stop the event loop
    end
    return nothing
end

# We need to build a c function to get a pointer that we can use as a callback
# in C code.
const connection_handler_c = @cfunction(
    connection_handler, Cvoid, (
        Ptr{LibStrophe.xmpp_conn_t}, LibStrophe.xmpp_conn_event_t,
        Cint, Ptr{LibStrophe.xmpp_stream_error_t}, Ptr{Cvoid},
    )
)

# ## Main function
# Our main function is considerably simpler than the original example, because
# we offer less flexibility on TLS settings, and use a dummy example password.
# If this is of interest to you, `libstrophe` allows having a vallback to ask
# password!

host = "localhost"
port = 0 # Will use the default port

# First, we initialize the library
LibStrophe.xmpp_initialize()
# Then, we get the default logger. You can silence outputs by passig `C_NULL`.
log = LibStrophe.xmpp_get_default_logger(LibStrophe.XMPP_LEVEL_INFO)
# We use it to reate the libstrophe context.
ctx = LibStrophe.xmpp_ctx_new(C_NULL, log)

# We prepare the configuration of the connection through flags
flags = LibStrophe.XMPP_CONN_FLAG_TRUST_TLS
jid = "gepetto@localhost"
password = "plopiplop"

sm_state = C_NULL

# We use the main loop offered by libstrophe. This will lock the main thread and
# prevent us from interacting. To make this example self-contained, we run a
# parallel thread to send text to the bot. You could instead invoke `go-sendxmpp`
# manually if you want!
speaky_task = Threads.@spawn begin
    sleep(1) # Let's wait one second for the bot to connect.
    say_as_pinocchio(jid, "Hello") # Say hello to the bot
    yield()
    sleep(0.5)
    say_as_pinocchio(jid, "reconnect") # Try the reconnect procedure
    yield()
    sleep(1)
    say_as_pinocchio(jid, "Hello again")
    yield()
    sleep(0.5)
    say_as_pinocchio(jid, "quit") # Make the bot quit
end

# The main loop of the bot. We run it in its own thread, and to allow processing
# of other tasks, we use [`Strophe.LibStrophe.xmpp_run_once`](@ref) instead of [`Strophe.LibStrophe.xmpp_run`](@ref)
botty_task = Threads.@spawn begin
    while reconnect
        global reconnect
        global sm_state

        reconnect = false
        conn = LibStrophe.xmpp_conn_new(ctx)
        LibStrophe.xmpp_conn_set_flags(conn, flags)
        LibStrophe.xmpp_conn_set_jid(conn, jid)
        LibStrophe.xmpp_conn_set_pass(conn, password)

        if sm_state ≠ C_NULL # set Stream-Mangement state if available
            LibStrophe.xmpp_conn_set_sm_state(conn, sm_state)
            sm_state = C_NULL
        end

        connection_status = LibStrophe.xmpp_connect_client(conn, host, port, connection_handler_c, ctx)
        if connection_status == LibStrophe.XMPP_EOK
            while LibStrophe.xmpp_conn_is_connected(conn) == 1
                LibStrophe.xmpp_run_once(ctx, 50) # Run the internal event loop from libstrophe
                yield()
            end
        else
            @warn "Connection to the server failed! Is the server running? Did you register the test users?"
        end

        if reconnect # If a reconnect was requested.
            sm_state = LibStrophe.xmpp_conn_get_sm_state(conn)
        end

        LibStrophe.xmpp_conn_release(conn) # Release the current connection
    end
end

waitall([speaky_task, botty_task])

# After exiting the loop, we release the context and shutdown the library.

LibStrophe.xmpp_ctx_free(ctx)
LibStrophe.xmpp_shutdown()

# ## Checking the bot answers
# Since we had a listener on from the beginning, we received the messages from
# bot and stored them in `pinocchio`. Time to read the mail!
kill(listener)
readlines(pinocchio)

#=
It looks like it works. In addition, we can see the following in our server logs:
```
info	Client connected
info	Stream encrypted (TLSv1.3 with TLS_AES_128_GCM_SHA256)
info	Authenticated as pinocchio@localhost [prosody:registered]
info	Client connected
info	Stream encrypted (TLSv1.3 with TLS_AES_256_GCM_SHA384)
info	Authenticated as gepetto@localhost [prosody:registered]
info	Client connected
info	Stream encrypted (TLSv1.3 with TLS_AES_128_GCM_SHA256)
info	Authenticated as pinocchio@localhost [prosody:registered]
info	Client disconnected: connection closed
info	Client connected
info	Stream encrypted (TLSv1.3 with TLS_AES_128_GCM_SHA256)
info	Authenticated as pinocchio@localhost [prosody:registered]
info	Client disconnected: connection closed
info	Client connected
info	Stream encrypted (TLSv1.3 with TLS_AES_128_GCM_SHA256)
info	Authenticated as pinocchio@localhost [prosody:registered]
info	Client disconnected: connection closed
info	Client connected
info	Stream encrypted (TLSv1.3 with TLS_AES_128_GCM_SHA256)
info	Authenticated as pinocchio@localhost [prosody:registered]
info	Client disconnected: connection closed
info	Client disconnected: connection closed
info	Client connected
info	Stream encrypted (TLSv1.3 with TLS_AES_256_GCM_SHA384)
info	Authenticated as gepetto@localhost [prosody:registered]
info	Client connected
info	Stream encrypted (TLSv1.3 with TLS_AES_128_GCM_SHA256)
info	Authenticated as pinocchio@localhost [prosody:registered]
info	Client disconnected: connection closed
info	Client connected
info	Stream encrypted (TLSv1.3 with TLS_AES_128_GCM_SHA256)
info	Authenticated as pinocchio@localhost [prosody:registered]
info	Client disconnected: connection closed
info	Client connected
info	Stream encrypted (TLSv1.3 with TLS_AES_128_GCM_SHA256)
info	Authenticated as pinocchio@localhost [prosody:registered]
info	Client disconnected: connection closed
info	Client connected
info	Stream encrypted (TLSv1.3 with TLS_AES_128_GCM_SHA256)
info	Authenticated as pinocchio@localhost [prosody:registered]
info	Client disconnected: connection closed
info	Client disconnected: connection closed
info	Client disconnected: unexpected eof while reading
```

We see that the listener process for pinocchio connects first, then our bot
(gepetto). Then pinocchio connects a few times to send commands, and eventually
gepetto reconnects. Pinocchio sends a few more commands before triggereing the
disconnection of gepetto.
=#
