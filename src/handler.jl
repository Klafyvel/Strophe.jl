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

# function add_id_handler!(conn::ConnectionTypes, handler::Handler, id)
# end
# function delete_id_handler!(conn::ConnectionTypes, handler::Handler, id)
# end
# function add_timed_handler!(conn::ConnectionTypes, handler::TimedHandler, period)
#     # LibStrophe.xmpp_timed_handler_add(connection(conn), ,period, C_NULL)
# end
# function delete_timed_handler!(conn::ConnectionTypes, handler::TimedHandler)
# end
# function add_global_timed_handler!(conn::ConnectionTypes, handler::TimedHandler, period)
# end
# function delete_global_timed_handler!(conn::ConnectionTypes, handler::TimedHandler)
# end
