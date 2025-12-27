#=

# Basic example

This is a port of the [basic example from libstrophe](https://github.com/strophe/libstrophe/blob/master/examples/basic.c) to Julia.

You need the a server running on localhost (see [low-level-examples](@ref) to set up
a local xmpp server using docker-compose. If that is what you are using, start it
with `docker-compose up`. Depending on your platform, you might need sudo.

=#

# ## Initialization of the library

import Strophe: LibStrophe

LibStrophe.xmpp_initialize()

# ## Creation of a callback to react to connection events

function connection_handler(conn, status, error, stream_error, userdata)
    ctx = userdata
    if status == LibStrophe.XMPP_CONN_CONNECT # We just connected
        @info "Connected!"
        LibStrophe.xmpp_disconnect(conn)
    else
        @info "Disconnected!"
        LibStrophe.xmpp_stop(ctx) # stop the event loop
    end
    return nothing
end

# We need to build a c function to get a pointer that we can use as a callback
const connection_handler_c = @cfunction(
    connection_handler, Cvoid, (
        Ptr{LibStrophe.xmpp_conn_t}, LibStrophe.xmpp_conn_event_t,
        Cint, Ptr{LibStrophe.xmpp_stream_error_t}, Ptr{Cvoid},
    )
)

# ## Creation of the XMPP context
#
# First, we initialize libstrophe's logger. You can use `C_NULL` to silence it,
# or use other log levels. For example, `LibStrophe.XMPP_LEVEL_DEBUG` will get
# very verbose!

log = LibStrophe.xmpp_get_default_logger(LibStrophe.XMPP_LEVEL_INFO)

# Then, the context itself.

ctx = LibStrophe.xmpp_ctx_new(C_NULL, log)

# ## Connection to ther server
# The connection is configured through flags.
# The docker image does not have a proper certificate, so we force libstrophe
# to trust it. In real life, you probably don't want to do that!
flags = LibStrophe.XMPP_CONN_FLAG_TRUST_TLS
conn = LibStrophe.xmpp_conn_new(ctx)
LibStrophe.xmpp_conn_set_flags(conn, flags)

# You can change that depending on your configuration
jid = "gepetto@localhost"
password = "plopiplop"
LibStrophe.xmpp_conn_set_jid(conn, jid)
LibStrophe.xmpp_conn_set_pass(conn, password)

# Finally, we can connect:
port = 0 # Will use the default port
host = "localhost"
connection_status = LibStrophe.xmpp_connect_client(conn, host, port, connection_handler_c, ctx)
if connection_status == LibStrophe.XMPP_EOK
    LibStrophe.xmpp_run(ctx) # Run the internal event loop from libstrophe
else
    @warn "Connection to the server failed! Is the server running? Did you register the test users?"
end

# ## Shutdown
# Release the connection and context.

LibStrophe.xmpp_conn_release(conn)
LibStrophe.xmpp_ctx_free(ctx)

# final shutdown of the library.
LibStrophe.xmpp_shutdown()

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
