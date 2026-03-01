"Store the registered handlers. Keys are `objectid` of the wrapped functions."
const REGISTERED_HANDLERS = Ref{Dict{UInt, Base.CFunction}}()

struct Event
    name::Ptr{Int8}
    namespace::Ptr{Int8}
    type::Ptr{Int8}
    Event(name::AbstractString, namespace, type) = Event(Base.unsafe_convert(Ptr{Int8}, Base.cconvert(Ptr{Int8}, name)), namespace, type)
    Event(name::Ptr, namespace::AbstractString, type) = Event(name, Base.unsafe_convert(Ptr{Int8}, Base.cconvert(Ptr{Int8}, namespace)), type)
    Event(name::Ptr, namespace::Ptr, type::AbstractString) = new(name, namespace, Base.unsafe_convert(Ptr{Int8}, Base.cconvert(Ptr{Int8}, type)))
    Event(name::Ptr, namespace::Ptr, type::Ptr) = new(name, namespace, type)
end
Event(; name = C_NULL, namespace = C_NULL, type = C_NULL) = Event(name, namespace, type)

Base.@kwdef struct IdEvent
    id::String
end

Base.@kwdef struct TimedEvent
    period::Int
end

"""
    add_handler!(conn, handler[, args][; name][, namespace][,type])
    add_handler!(conn, event, handler[, args])
Add a stanza handler.

The `handler` will be called when any of the specified filters match. The filters
behave as follow:
* `name`: matches to the top level stanza name,
* `namespace`: matches the namespace (`xmlns` attribute) of either the top level stanza or any of it's immediate children. This allows you to to handle specific `<iq/>` stanzas based on the `<query/>` child namespace.
* `type`: matches the `type` attribute of the top level stanza.

Handlers should accept two parameters: a connection (pointer to [`LibStrophe.xmpp_conn_t`](@ref)) and a stanza (pointer to [`LibStrophe.xmpp_stanza_t`](@ref)).

See also [`LibStrophe.xmpp_handler_add`](@ref), [`delete_handler!`](@ref).
"""
function add_handler!(conn, event, handler)
    handler_cfunction = @cfunction($handler, Cint, (Ptr{LibStrophe.xmpp_conn_t}, Ptr{LibStrophe.xmpp_stanza_t}))
    REGISTERED_HANDLERS[][objectid(handler)] = handler_cfunction
    handler_ptr = Base.unsafe_convert(Ptr{Cvoid}, Base.cconvert(Ptr{Cvoid}, handler_cfunction))
    LibStrophe.xmpp_handler_add(connection(conn), handler_ptr, event.namespace, event.name, event.type, C_NULL)
    return nothing
end
add_handler!(conn, handler; name = C_NULL, namespace = C_NULL, type = C_NULL) = add_handler!(conn, Event(name, namespace, type), handler)
"""
    delete_handler!(conn, handler)

Delete a stanza handler.

See also [`LibStrophe.xmpp_handler_delete`](@ref), [`add_handler!`](@ref).
"""
function delete_handler!(conn::ConnectionTypes, handler)
    id = objectid(handler)
    handler_cfunction = REGISTERED_HANDLERS[][id]
    handler_ptr = Base.unsafe_convert(Ptr{Cvoid}, Base.cconvert(Ptr{Cvoid}, handler_cfunction))
    LibStrophe.xmpp_handler_delete(connection(conn), handler_ptr)
    return delete!(REGISTERED_HANDLERS[], id)
end

"""
    add_id_handler!(conn, handler, id)
Add an id based stanza handler.

This function adds a stanza `handler` for an `<iq/>` stanza of type 'result' or
'error' with a specific `id` attribute. This can be used to handle responses to
specific `<iq/>`s.

If the handler function returns true, it will be kept, and if it returns false,
it will be deleted from the list of handlers.

Handlers should accept two parameters: a connection (pointer to [`LibStrophe.xmpp_conn_t`](@ref)) and a stanza (pointer to [`LibStrophe.xmpp_stanza_t`](@ref)).

See also [`LibStrophe.xmpp_id_handler_add`](@ref), [`delete_id_handler!`](@ref).
"""
function add_id_handler!(conn, handler, id)
    handler_cfunction = @cfunction($handler, Cint, (Ptr{LibStrophe.xmpp_conn_t}, Ptr{LibStrophe.xmpp_stanza_t}))
    REGISTERED_HANDLERS[][objectid(handler)] = handler_cfunction
    handler_ptr = Base.unsafe_convert(Ptr{Cvoid}, Base.cconvert(Ptr{Cvoid}, handler_cfunction))
    LibStrophe.xmpp_id_handler_add(connection(conn), handler_ptr, id, C_NULL)
    return nothing
end
"""
    delete_id_handler!(conn, handler)

Delete an id based stanza handler.

See also [`LibStrophe.xmpp_id_handler_delete`](@ref), [`add_id_handler!`](@ref).
"""
function delete_id_handler!(conn, handler, id)
    oid = objectid(handler)
    handler_cfunction = REGISTERED_HANDLERS[][oid]
    handler_ptr = Base.unsafe_convert(Ptr{Cvoid}, Base.cconvert(Ptr{Cvoid}, handler_cfunction))
    LibStrophe.xmpp_id_handler_delete(connection(conn), handler_ptr, id)
    return delete!(REGISTERED_HANDLERS[], oid)
end

"""
    add_timed_handler!(conn, handler, period)
Add a timed handler.

The `handler` will fire for the first time once the `period` has elapsed, and
continue firing regularly after that. Strophe will try its best to fire handlers
as close to the period times as it can, but accuracy will vary depending on the
resolution of the event loop.

If the handler function returns true, it will be kept, and if it returns false,
it will be deleted from the list of handlers.

Handlers should accept one single argument, the connection (pointer to [`LibStrophe.xmpp_conn_t`](@ref)).

See also [`LibStrophe.xmpp_timed_handler_add`](@ref), [`delete_timed_handler!`](@ref).
"""
function add_timed_handler!(conn, handler, period)
    handler_cfunction = @cfunction($handler, Cint, (Ptr{LibStrophe.xmpp_conn_t},))
    REGISTERED_HANDLERS[][objectid(handler)] = handler_cfunction
    handler_ptr = Base.unsafe_convert(Ptr{Cvoid}, Base.cconvert(Ptr{Cvoid}, handler_cfunction))
    LibStrophe.xmpp_timed_handler_add(connection(conn), handler_ptr, period, C_NULL)
    return nothing
end
"""
    delete_timed_handler!(conn, handler)

Delete a timed handler.

See also [`LibStrophe.xmpp_timed_handler_delete`](@ref), [`add_timed_handler!`](@ref).
"""
function delete_timed_handler!(conn::ConnectionTypes, handler)
    id = objectid(handler)
    handler_cfunction = REGISTERED_HANDLERS[][id]
    handler_ptr = Base.unsafe_convert(Ptr{Cvoid}, Base.cconvert(Ptr{Cvoid}, handler_cfunction))
    LibStrophe.xmpp_timed_handler_delete(connection(conn), handler_ptr)
    return delete!(REGISTERED_HANDLERS[], id)
end

"""
    add_global_timed_handler!([ctx,] handler, period)
Add a global timed handler.

The `handler` will fire for the first time once the `period` has elapsed, and
continue firing regularly after that. Strophe will try its best to fire handlers
as close to the period times as it can, but accuracy will vary depending on the
resolution of the event loop.

The main difference between global and ordinary handlers:
* Ordinary handler is related to a connection, fires only when the connection
  is in connected state and is removed once the connection is destroyed.
* Global handler fires regardless of connections state and is related to a
  Strophe context.

The handler is executed in context of the respective event loop.

If the handler function returns true, it will be kept, and if it returns false,
it will be deleted from the list of handlers.

Handlers should accept one single argument, the context (pointer to [`LibStrophe.xmpp_ctx_t`](@ref)).

See also [`add_timed_handler!`](@ref), [`LibStrophe.xmpp_global_timed_handler_add`](@ref), [`delete_global_timed_handler!`](@ref).
"""
function add_global_timed_handler!(ctx, handler, period)
    handler_cfunction = @cfunction($handler, Cint, (Ptr{LibStrophe.xmpp_ctx_t},))
    REGISTERED_HANDLERS[][objectid(handler)] = handler_cfunction
    handler_ptr = Base.unsafe_convert(Ptr{Cvoid}, Base.cconvert(Ptr{Cvoid}, handler_cfunction))
    LibStrophe.xmpp_global_timed_handler_add(context(ctx), handler_ptr, period, C_NULL)
    return nothing
end
"""
    delete_timed_handler!(ctx, handler)

Delete a global timed handler.

See also [`LibStrophe.xmpp_timed_handler_delete`](@ref), [`add_global_timed_handler!`](@ref).
"""
function delete_global_timed_handler!(ctx, handler)
    id = objectid(handler)
    handler_cfunction = REGISTERED_HANDLERS[][id]
    handler_ptr = Base.unsafe_convert(Ptr{Cvoid}, Base.cconvert(Ptr{Cvoid}, handler_cfunction))
    LibStrophe.xmpp_timed_handler_delete(context(ctx), handler_ptr)
    return delete!(REGISTERED_HANDLERS[], id)
end
