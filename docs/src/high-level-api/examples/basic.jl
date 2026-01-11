#=

# [Basic example](@id high-level-basic-example)

This is a port of the [basic example from libstrophe](https://github.com/strophe/libstrophe/blob/master/examples/basic.c) to Julia using the high-level API of Strophe.jl.

You need the a server running on localhost (see [high-level-examples](@ref) to set up
a local xmpp server using docker-compose. If that is what you are using, start it
with `docker-compose up`. Depending on your platform, you might need sudo.

=#

# ## Initialization of the library

import Strophe: ClientConnection, LibStrophe, connect, disconnect, trusttls!, jid!, pass!, context, stop, run

# ## Creation of a callback to react to connection events
# The connection handler will be called by the underlying LibStrophe library
# after connection. It must accept the following parameters:
# * a [`Strophe.ParametrizedConnection`](@ref) object representing the connection,
# * a status flag, of type [`Strophe.LibStrophe.xmpp_conn_event_t`](@ref),
# * an error code (<0 when an error occured),
# * a pointer to a [`Strophe.LibStrophe.xmpp_stream_error_t`](@ref) object.

function connection_handler(conn, status, error, stream_error)
    if status == LibStrophe.XMPP_CONN_CONNECT # We just connected
        @info "Connected!"
        disconnect(conn)
    else
        @info "Disconnected!"
        stop(conn) # stop the event loop
    end
    return nothing
end

# ## Creation of the XMPP connection
# The high-level API represents connections using [`Strophe.ParametrizedConnection`](@ref)
# objects. They have convenience constructors for client and component connections.

conn = ClientConnection(host = "localhost", handler = connection_handler)

# ## Connection to ther server
# The docker image does not have a proper certificate, so we force libstrophe
# to trust it. In real life, you probably don't want to do that!
trusttls!(conn)


# You can change that depending on your configuration
jid = "gepetto@localhost"
password = "plopiplop"

jid!(conn, jid)
pass!(conn, password)

# Finally, we can connect:
connect(conn) # Will raise a StropheError if connection fails.
run(conn) # Run the internal event loop from libstrophe

# ## But did it work?
# If you check in the logs of your server, you'll see the following:
# ```
# info	Client connected
# info	Stream encrypted (TLSv1.3 with TLS_AES_256_GCM_SHA384)
# info	Authenticated as gepetto@localhost [prosody:registered]
# info	Client disconnected: connection closed
# ```
#
# We sucessfully connected!
#
# ## Under the hood...
# In this example, we have skipped an important detail. If you have a look at
# [the corresponding low-level API example](../../low-level-api/examples/basic.md),
# you will see that the underlying [`Strophe.LibStrophe`](@ref) has the concept of **context**.
# In a more complex example, you would be able to have several connections running
# in a single context. In fact, the [`Strophe.run`](@ref) function uses the [`Strophe.context`](@ref)
# function to recover the context from our [`Strophe.ParametrizedConnection`](@ref) `conn`
# object. If you want to share the same context for several connections, you could
# either:
# * Explicitely create a [`Strophe.Context`](@ref) object,
# * Create subsequent connections by clonning an existing connection using the
#   constructor of [`Strophe.ParametrizedConnection`](@ref) that takes another connection
#   as its sole parameter.
