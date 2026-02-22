#=

# [Bot example](@id high-level-bot-example)

This is a port of [the bot example from libstrophe](https://github.com/strophe/libstrophe/blob/master/examples/bot.c) to Julia using the high-level API of Strophe.jl.

You need the a server running on localhost (see [high-level-examples](@ref) to set up
a local xmpp server using docker-compose). If that is what you are using, start it
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
#     <name>Strophe example bot</name>
#     <version>1.0</version>
#   </query>
# </iq>
# ```
#
# As usual with libstrophe, this is done through a callback function. You might
# want to have a look at the [low-level stanza handling reference](@ref low-level-stanza).

function version_handler(conn, stanza)
    stanza = Stanza(stanza, true)
    @info "Received version request." Strophe.from(stanza)
    query = Stanza(name = "query")(
        Stanza(name = "name")("Strophe example bot"),
        Stanza(name = "version")("1.0"),
    )
    ns = Strophe.ns(first(Strophe.children(stanza)))
    if !isnothing(ns)
        Strophe.ns!(query, ns)
    end
    reply = Strophe.reply(stanza)(query)
    Strophe.send(conn, reply)
    return Int32(1)
end

# ## Quit handler
# A simple handler that will disconnect us uppon request.

function quit_handler(conn)
    Strophe.disconnect(conn)
    return Int32(0)
end

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

function message_handler(conn, stanza)
    type = Strophe.type(stanza)
    (!isnothing(type) && type == "error") && return 1
    ## First we recover the body of the message
    intext = Strophe.body(stanza)
    isnothing(intext) && return 1
    @info "Incoming message" Strophe.from(stanza) intext

    reply = Strophe.reply(stanza)
    if isnothing(Strophe.type(reply))
        Strophe.type!(reply, "chat")
    end

    if intext == "quit"
        replytext = "bye!"
        Strophe.add_timed_handler!(conn, quit_handler, 500)
    elseif intext == "reconnect"
        replytext = "alright, let's see what happens!"
        global reconnect = true
        Strophe.add_timed_handler!(conn, quit_handler, 500)
    else
        replytext = intext * " to you too!"
    end
    Strophe.body!(reply, replytext)
    Strophe.send(conn, reply)
    return Int32(1)
end

# ## Connection handler
# This is what gets called by libstrophe on connection events.

function connection_handler(conn, status, error, stream_error)
    if status == LibStrophe.XMPP_CONN_CONNECT # We just connected
        @info "Connected!"
        Strophe.add_handler!(conn, version_handler, name = "iq", namespace = "jabber:iq:version")
        Strophe.add_handler!(conn, message_handler, name = "message")
        pres = Strophe.presence() # Send initial <presence/> so that we appear online to contacts
        Strophe.send(conn, pres)
    else
        @info "Disconnected!"
        Strophe.stop(conn)
    end
    return nothing
end

# ## Main function
# Our main function is considerably simpler than the original example, because
# we offer less flexibility on TLS settings, and use a dummy example password.
# If this is of interest to you, `libstrophe` allows having a vallback to ask
# password!

host = "localhost"

jid = "gepetto@localhost"
password = "plopiplop"

sm_state = nothing

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

# The main loop of the bot. We run it in its own thread.
function main()
    while reconnect
        global reconnect
        global sm_state

        reconnect = false
        conn = ClientConnection(host = host, handler = connection_handler)
        Strophe.trusttls!(conn)
        Strophe.jid!(conn, jid)
        Strophe.pass!(conn, password)

        if !isnothing(sm_state) # set Stream-Management state if available
            Strophe.stream_management_state!(conn, sm_state)
            sm_state = nothing
        end

        Strophe.connect(conn)
        Strophe.run()
        if reconnect # If a reconnect was requested.
            sm_state = Strophe.stream_management_state(conn)
        end
    end
    return
end
botty_task = Threads.@spawn main()
waitall([speaky_task, botty_task])


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
info	Client disconnected: connection closed
info	Client disconnected: unexpected eof while reading
```

We see that the listener process for pinocchio connects first, then our bot
(gepetto). Then pinocchio connects a few times to send commands, and eventually
gepetto reconnects. Pinocchio sends a few more commands before triggereing the
disconnection of gepetto.
=#
