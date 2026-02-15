"""
    Connection()
    Connection(context::Context)
    Connection(connection::Connection)

A wrapper for a libstrophe connection. It handles allocation and
de-allocation for you. If called with an existing `Connection`, use the internal
[`LibStrophe.xmpp_conn_clone`](@ref) to clone the connection. Will use the
default context if none is provided.

See also [`Context`](@ref).
"""
mutable struct Connection
    conn::Ptr{LibStrophe.xmpp_conn_t}
    function Connection(ctx::Context)
        _conn = LibStrophe.xmpp_conn_new(ctx.ctx)
        conn = new(_conn)
        finalizer(conn) do conn
            if conn.conn ≠ C_NULL
                LibStrophe.xmpp_conn_release(conn.conn)
                conn.conn = C_NULL
            end
        end
        return conn
    end
    function Connection(conn::Connection)
        _conn = LibStrophe.xmpp_conn_clone(conn.conn)
        new_conn = new(_conn, conn.ctx)
        finalizer(new_conn) do conn
            if conn.conn ≠ C_NULL
                LibStrophe.xmpp_conn_release(conn.conn)
                conn.conn = C_NULL
            end
        end
        return new_conn
    end
end
Connection() = Connection(context())

"""
    connection(obj)
Get the pointer to the [`LibStrophe.xmpp_conn_t`](@ref) associated to `obj`.
"""
function connection end
connection(conn::Connection) = conn.conn
connection(conn::Ptr{LibStrophe.xmpp_conn_t}) = conn
connection(conn::Ptr{Cvoid}) = conn
context(conn::Connection) = LibStrophe.xmpp_conn_get_context(connection(conn))

"""
    jid(obj)
Get the JID which is or will be bound to the connection associated to `obj`.

See also [`connection`](@ref), [`LibStrophe.xmpp_conn_get_jid`](@ref).
"""
function jid(obj)
    _jid = LibStrophe.xmpp_conn_get_jid(connection(obj))
    result = unsafe_string(_jid)
    LibStrophe.xmpp_free(context(obj), _jid)
    return result
end

"""
    bound_jid(obj)
Get the JID discovered during binding time for the connection associated to `obj`.

See also [`connection`](@ref), [`LibStrophe.xmpp_conn_get_bound_jid`](@ref).
"""
function bound_jid(obj)
    _jid = LibStrophe.xmpp_conn_get_bound_jid(connection(obj))
    result = unsafe_string(_jid)
    LibStrophe.xmpp_free(context(obj), _jid)
    return result
end

"""
    jid!(obj, jid)
Set the JID of the user that will be bound to the connection associated to `obj`.

See also [`connection`](@ref), [`LibStrophe.xmpp_conn_set_jid`](@ref).
"""
function jid!(obj, jid)
    LibStrophe.xmpp_conn_set_jid(connection(obj), jid)
    return nothing
end

"""
    pass(obj)
Get the password used for authentication of the connection associated to `obj`.

See also [`connection`](@ref), [`LibStrophe.xmpp_conn_get_pass`](@ref).
"""
function pass(obj)
    _pass = LibStrophe.xmpp_conn_get_pass(connection(obj))
    result = unsafe_string(_pass)
    LibStrophe.xmpp_free(context(obj), _pass)
    return result
end

"""
    pass!(connection, password)
Set the password used to authenticate the connection associated to `obj`.

See also [`connection`](@ref), [`LibStrophe.xmpp_conn_set_pass`](@ref).
"""
function pass!(obj, password)
    LibStrophe.xmpp_conn_set_pass(connection(obj), password)
    return nothing
end

"""
    flags(obj)

Get the flags of the connection associated to `obj`.

See also [`connection`](@ref), [`LibStrophe.xmpp_conn_get_flags`](@ref), [`flags!`](@ref).
"""
function flags(obj)
    return LibStrophe.xmpp_conn_get_flags(connection(obj))
end
"""
    flags!(obj, flags)

Set the `flags` associated to the connection of `obj`.

See also [`connection`](@ref), [`LibStrophe.xmpp_conn_set_flags`](@ref), [`flags`](@ref).
"""
function flags!(obj, flags)
    status = LibStrophe.xmpp_conn_set_flags(connection(obj), flags)
    status ≠ LibStrophe.XMPP_EOK && throw(StropheError("Failed to set flags $(flags) on connection $(obj)"))
    return nothing
end
"""
    flagenabled(obj, flag)
Return `true` if `flag` is set in the connection associated to `obj`.

See also [`connection`](@ref), [`flags`](@ref).

"""
flagenabled(obj, flag::Culong) = (flags(obj) & flag) > 0
"""
    enableflag!(obj, flag)
Enable `flag` in the connection associated to `obj`.

See also [`connection`](@ref), [`flags!`](@ref).

"""
function enableflag!(connection, flag::Culong, st::Bool)
    current_flags = flags(connection)
    return if st
        flags!(connection, current_flags | flag)
    else
        flags!(connection, current_flags & ~flag)
    end
end
"""
    disabletls(obj)
Return `true` if the `DISABLE_TLS` flag is set in the connection associated to `obj`.

See also [`connection`](@ref), [`flags`](@ref), [`flagenabled`](@ref).
"""
disabletls(obj) = flagenabled(obj, LibStrophe.XMPP_CONN_FLAG_DISABLE_TLS)
"""
    disabletls!(obj, st=true)
Set the `DISABLE_TLS` flag of connection associated to `obj` to `st`.

See also [`connection`](@ref), [`flags!`](@ref), [`enableflag!`](@ref).
"""
disabletls!(obj, st = true) = enableflag!(obj, LibStrophe.XMPP_CONN_FLAG_DISABLE_TLS, st)
"""
    mandatorytls(obj)
Return `true` if the `MANDATORY_TLS` flag is set in the connection associated to `obj`.

See also [`connection`](@ref), [`flags`](@ref), [`flagenabled`](@ref).
"""
mandatorytls(obj) = flagenabled(obj, LibStrophe.XMPP_CONN_FLAG_MANDATORY_TLS)
"""
    mandatorytls!(obj, st=true)
Set the `MANDATORY_TLS` flag in the connection associated to `obj` to `st`.

See also [`connection`](@ref), [`flags!`](@ref), [`enableflag!`](@ref).
"""
mandatorytls!(obj, st = true) = enableflag!(obj, LibStrophe.XMPP_CONN_FLAG_MANDATORY_TLS, st)
"""
    legacyssl(obj)
Return `true` if the `LEGACY_SSL` flag is set in the connection associated to `obj`.

See also [`connection`](@ref), [`flags`](@ref), [`flagenabled`](@ref).
"""
legacyssl(obj) = flagenabled(obj, LibStrophe.XMPP_CONN_FLAG_LEGACY_SSL)
"""
    legacyssl!(obj, st=true)
Set the `LEGACY_SSL` flag in the connection associated to `obj` to `st`.

See also [`connection`](@ref), [`flags!`](@ref), [`enableflag!`](@ref).
"""
legacyssl!(obj, st = true) = enableflag!(obj, LibStrophe.XMPP_CONN_FLAG_LEGACY_SSL, st)
"""
    trusttls(obj)
Return `true` if the `TRUST_TLS` flag is set in the connection associated to `obj`.

See also [`connection`](@ref), [`flags`](@ref), [`flagenabled`](@ref).
"""
trusttls(obj) = flagenabled(obj, LibStrophe.XMPP_CONN_FLAG_TRUST_TLS)
"""
    trusttls!(obj, st=true)
Set the `TRUST_TLS` flag in the connection associated to `obj` to `st`.

See also [`connection`](@ref), [`flags!`](@ref), [`enableflag!`](@ref).
"""
trusttls!(obj, st = true) = enableflag!(obj, LibStrophe.XMPP_CONN_FLAG_TRUST_TLS, st)
"""
    legacyauth(obj)
Return `true` if the `LEGACY_AUTH` flag is set in the connection associated to `obj`.

See also [`connection`](@ref), [`flags`](@ref), [`flagenabled`](@ref).
"""
legacyauth(obj) = flagenabled(obj, LibStrophe.XMPP_CONN_FLAG_LEGACY_AUTH)
"""
    legacyauth!(obj, st=true)
Set the `LEGACY_AUTH` flag in the connection associated to `obj` to `st`.

See also [`connection`](@ref), [`flags!`](@ref), [`enableflag!`](@ref).
"""
legacyauth!(obj, st = true) = enableflag!(obj, LibStrophe.XMPP_CONN_FLAG_LEGACY_AUTH, st)
"""
    disablesm(obj)
Return `true` if the `DISABLE_SM` flag is set in the connection associated to `obj`.

See also [`connection`](@ref), [`flags`](@ref), [`flagenabled`](@ref).
"""
disablesm(obj) = flagenabled(obj, LibStrophe.XMPP_CONN_FLAG_DISABLE_SM)
"""
    disablesm!(obj, st=true)
Set the `DISABLE_SM` flag in the connection associated to `obj` to `st`.

See also [`connection`](@ref), [`flags!`](@ref), [`enableflag!`](@ref).
"""
disablesm!(obj, st = true) = enableflag!(obj, LibStrophe.XMPP_CONN_FLAG_DISABLE_SM, st)
"""
    enablecompression(obj)
Return `true` if the `ENABLE_COMPRESSION` flag is set in the connection associated to `obj`.

See also [`connection`](@ref), [`flags`](@ref), [`flagenabled`](@ref).
"""
enablecompression(obj) = flagenabled(obj, LibStrophe.XMPP_CONN_FLAG_ENABLE_COMPRESSION)
"""
    enablecompression!(obj, st=true)
Set the `ENABLE_COMPRESSION` flag in the connection associated to `obj` to `st`.

See also [`connection`](@ref), [`flags!`](@ref), [`enableflag!`](@ref).
"""
enablecompression!(obj, st = true) = enableflag!(obj, LibStrophe.XMPP_CONN_FLAG_ENABLE_COMPRESSION, st)
"""
    compressiondontreset(obj)
Return `true` if the `COMPRESSION_DONT_RESET` flag is set in the connection associated to `obj`.

See also [`connection`](@ref), [`flags`](@ref), [`flagenabled`](@ref).
"""
compressiondontreset(obj) = flagenabled(obj, LibStrophe.XMPP_CONN_FLAG_COMPRESSION_DONT_RESET)
"""
    compressiondontreset!(obj, st=true)
Set the `COMPRESSION_DONT_RESET` flag in the connection associated to `obj` to `st`.

See also [`connection`](@ref), [`flags!`](@ref), [`enableflag!`](@ref).
"""
compressiondontreset!(obj, st = true) = enableflag!(obj, LibStrophe.XMPP_CONN_FLAG_COMPRESSION_DONT_RESET, st)
