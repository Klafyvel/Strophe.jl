"""
Wraps a pointer to a libstrophe stream-management object.

This can be used to store the stream-management state of a connection after deconnecting
and reloading it when connecting again.

See also [`XEP-0198`](https://xmpp.org/extensions/xep-0198.html).

# Examples

```julia
Strophe.run() # After this call, the main loop ends and we disconnected
sm_state = Strophe.stream_management_state(conn)
# Later, we can reconnect and load this stream management state
Strophe.stream_management_state!(new_conn, sm_state)
Strophe.connect(new_conn)
Strophe.run()
```
"""
mutable struct StreamManagementState
    sm_state::Ptr{LibStrophe.xmpp_sm_state_t}
    function StreamManagementState(sm_state::Ptr{LibStrophe.xmpp_sm_state_t})
        obj = new(sm_state)
        Base.finalizer(obj) do obj::StreamManagementState
            if sm_state != C_NULL
                LibStrophe.xmpp_free_sm_state(obj.sm_state)
            end
        end
        return obj
    end
end

"""
    stream_management_state(conn)
Get the [`StreamManagementState`](@ref) associated to `conn`.
"""
stream_management_state(conn) = StreamManagementState(LibStrophe.xmpp_conn_get_sm_state(connection(conn)))
"""
    stream_management_state!(conn, sm_state)
Set the [`StreamManagementState`](@ref) associated to `conn` to `sm_state`. The
`sm_state` object will be rendered unusable.
"""
function stream_management_state!(conn, sm_state::StreamManagementState)
    LibStrophe.xmpp_conn_set_sm_state(connection(conn), sm_state.sm_state)
    sm_state.sm_state = C_NULL
    return nothing
end

"""
    restore_state_management_state!(conn, sm_state)
Restore the serialized stream management state of a connection.

See the `stream_management_callback` field of [`ParametrizedConnection`](@ref)
for setting a callback function that will be called to store the state.
"""
function restore_state_management_state!(conn, sm_state)
    c_string = Base.unsafe_convert(Cstring, Base.cconvert(Cstring, sm_state))
    ret = LibStrophe.xmpp_conn_restore_sm_state(connection(conn), c_string, length(sm_state))
    if ret < 0
        throw(StropheError("Failed to restore stream management state."))
    end
    return nothing
end
