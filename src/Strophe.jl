module Strophe

import FunctionWrappers
using DocStringExtensions: SIGNATURES, TYPEDFIELDS

include("errors.jl")
include("libstrophe.jl")
include("log.jl")
include("context.jl")
include("stanza.jl")
include("connection.jl")
include("parametrized_connection.jl")

function __init__()
    LibStrophe.xmpp_initialize()
    atexit(LibStrophe.xmpp_shutdown)
    connection_handler_c[] = @cfunction(
        connection_handler, Cvoid, (
            Ptr{LibStrophe.xmpp_conn_t}, LibStrophe.xmpp_conn_event_t,
            Cint, Ptr{LibStrophe.xmpp_stream_error_t}, Ptr{Cvoid},
        )
    )
    logger_c = @cfunction(
        logger, Cvoid,
        (Ptr{Cvoid}, LibStrophe.xmpp_log_level_t, Cstring, Cstring)
    )
    DEFAULT_JULIA_LOGGER[] = LibStrophe.xmpp_log_t(logger_c, C_NULL)
    DEFAULT_CONTEXT[] = Context()
    return nothing
end

end
