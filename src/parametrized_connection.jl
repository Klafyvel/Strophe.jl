default_connection_handler(args...) = nothing

"""
```julia
ParametrizedConnection(conn::ParametrizedConnection)
ParametrizedConnection(; type::LibStrophe.xmpp_conn_type_t, conn::Union{Nothing, Connection} = nothing, ctx::Context = context(), host = "", port = 0, handler = default_connection_handler)
```

A wrapper around a [`Connection`](@ref) to remember the kind of connection, the host to connect to, the port, and the handler.

$(TYPEDFIELDS)

See also [`ClientConnection`](@ref), [`ComponentConnection`](@ref), [`connect`](@ref), [`disconnect`](@ref).
"""
mutable struct ParametrizedConnection
    type::LibStrophe.xmpp_conn_type_t
    conn::Connection
    host::String
    port::Int32
    handler::FunctionWrappers.FunctionWrapper{Nothing, Tuple{ParametrizedConnection, LibStrophe.xmpp_conn_event_t, Int32, Ptr{LibStrophe.xmpp_stream_error_t}}}
end

function connection_handler(_, status, error, stream_error, userdata)
    conn_ptr = Base.unsafe_convert(Ptr{ParametrizedConnection}, userdata)
    conn = unsafe_load(conn_ptr)
    conn.handler(conn, status, error, stream_error)
    return nothing
end
const connection_handler_c = Ref{Ptr{Cvoid}}(0)

connection(c::ParametrizedConnection) = connection(c.conn)
context(c::ParametrizedConnection) = context(c.conn)

"""
    ClientConnection(; kwargs...)

Build a [`ParametrizedConnection`](@ref) for a client connection (`type` set to
`LibStrophe.XMPP_CLIENT`.

See also [`ParametrizedConnection`](@ref), [`ComponentConnection`](@ref).
"""
ClientConnection(; kwargs...) = ParametrizedConnection(; type = LibStrophe.XMPP_CLIENT, kwargs...)
"""
    ComponentConnection(; kwargs...)

Build a [`ParametrizedConnection`](@ref) for a client connection (`type` set to
`LibStrophe.XMPP_COMPONENT`.

See also [`ParametrizedConnection`](@ref), [`ClientConnection`](@ref).
"""
ComponentConnection(; kwargs...) = ParametrizedConnection(; type = LibStrophe.XMPP_COMPONENT, kwargs...)
"""
    ClientConnection(conn)

Clone an existing connection to create a client connection.

See also [`LibStrophe.xmpp_conn_clone`](@ref).
"""
function ClientConnection(conn::ParametrizedConnection)
    return ParametrizedConnection(LibStrophe.XMPP_CLIENT, Connection(conn.conn), conn.host, conn.port, conn.handler)
end
"""
    ComponentConnection(conn)

Clone an existing connection to create a component connection.

See also [`LibStrophe.xmpp_conn_clone`](@ref).
"""
function ComponentConnection(conn::ParametrizedConnection)
    return ParametrizedConnection(LibStrophe.XMPP_COMPONENT, Connection(conn.conn), conn.host, conn.port, conn.handler)
end
function ParametrizedConnection(conn::ParametrizedConnection)
    return ParametrizedConnection(conn.type, Connection(conn.conn), conn.host, conn.port, conn.handler)
end
function ParametrizedConnection(; type::LibStrophe.xmpp_conn_type_t, conn::Union{Nothing, Connection} = nothing, ctx::Context = context(), host = "", port = 0, handler = default_connection_handler)
    conn = isnothing(conn) ? Connection(ctx) : conn
    return ParametrizedConnection(type, conn, host, port, handler)
end

function Base.show(io::IO, conn::ParametrizedConnection)
    if conn.type == LibStrophe.XMPP_CLIENT
        write(io, "ClientConnection(")
    elseif conn.type == LibStrophe.XMPP_COMPONENT
        write(io, "ComponentConnection(")
    else
        write(io, "ParametrizedConnection(")
        show(io, conn.type)
        write(io, ", ")
    end
    show(io, conn.conn)
    write(io, ", ")
    show(io, conn.host)
    write(io, ", ")
    show(io, conn.port)
    write(io, ", ")
    show(io, conn.handler)
    return write(io, ")")
end

"""
    connect(conn)

Initiate the connection parametrized by `conn`.

See also [`disconnect`](@ref), [`ParametrizedConnection`](@ref), [`LibStrophe.xmpp_connect_client`](@ref), [`LibStrophe.xmpp_connect_component`](@ref).
"""
function connect(conn::ParametrizedConnection)
    status = if conn.type == LibStrophe.XMPP_CLIENT
        LibStrophe.xmpp_connect_client(
            connection(conn), conn.host, conn.port,
            connection_handler_c[], Ref(conn)
        )
    elseif conn.type == LibStrophe.XMPP_COMPONENT
        LibStrophe.xmpp_connect_component(
            connection(conn), conn.host, conn.port,
            connection_handler_c[], Ref(conn)
        )
    else
        throw(StropheError("Parametrized connection has an unknown type."))
    end
    if status == LibStrophe.XMPP_EOK
        return nothing
    else
        throw(StropheError("Error while connecting client (status $(status))."))
    end
end
"""
    disconnect(conn)

Initiate the connection parametrized by `conn`.

See also [`connect`](@ref), [`ParametrizedConnection`](@ref).
"""
function disconnect(obj)
    LibStrophe.xmpp_disconnect(connection(obj))
    return nothing
end

const ConnectionTypes = Union{Ptr{LibStrophe.xmpp_conn_t}, Connection, ParametrizedConnection}
