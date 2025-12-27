module LibStrophe

using libstrophe_jll: libstrophe_jll, libstrophe
export libstrophe_jll

function xmpp_initialize()
    return ccall((:xmpp_initialize, libstrophe), Cvoid, ())
end

function xmpp_shutdown()
    return ccall((:xmpp_shutdown, libstrophe), Cvoid, ())
end

function xmpp_version_check(major, minor)
    return ccall((:xmpp_version_check, libstrophe), Cint, (Cint, Cint), major, minor)
end

struct _xmpp_mem_t
    alloc::Ptr{Cvoid}
    free::Ptr{Cvoid}
    realloc::Ptr{Cvoid}
    userdata::Ptr{Cvoid}
end

const xmpp_mem_t = _xmpp_mem_t

# typedef void ( * xmpp_log_handler ) ( void * userdata , xmpp_log_level_t level , const char * area , const char * msg )
const xmpp_log_handler = Ptr{Cvoid}

struct _xmpp_log_t
    handler::xmpp_log_handler
    userdata::Ptr{Cvoid}
end

const xmpp_log_t = _xmpp_log_t

mutable struct _xmpp_ctx_t end

const xmpp_ctx_t = _xmpp_ctx_t

mutable struct _xmpp_tlscert_t end

const xmpp_tlscert_t = _xmpp_tlscert_t

function xmpp_ctx_new(mem, log)
    return ccall((:xmpp_ctx_new, libstrophe), Ptr{xmpp_ctx_t}, (Ptr{xmpp_mem_t}, Ptr{xmpp_log_t}), mem, log)
end

function xmpp_ctx_free(ctx)
    return ccall((:xmpp_ctx_free, libstrophe), Cvoid, (Ptr{xmpp_ctx_t},), ctx)
end

function xmpp_ctx_set_verbosity(ctx, level)
    return ccall((:xmpp_ctx_set_verbosity, libstrophe), Cvoid, (Ptr{xmpp_ctx_t}, Cint), ctx, level)
end

function xmpp_free(ctx, p)
    return ccall((:xmpp_free, libstrophe), Cvoid, (Ptr{xmpp_ctx_t}, Ptr{Cvoid}), ctx, p)
end

@enum xmpp_log_level_t::UInt32 begin
    XMPP_LEVEL_DEBUG = 0
    XMPP_LEVEL_INFO = 1
    XMPP_LEVEL_WARN = 2
    XMPP_LEVEL_ERROR = 3
end

@enum xmpp_conn_type_t::UInt32 begin
    XMPP_UNKNOWN = 0
    XMPP_CLIENT = 1
    XMPP_COMPONENT = 2
end

function xmpp_get_default_logger(level)
    return ccall((:xmpp_get_default_logger, libstrophe), Ptr{xmpp_log_t}, (xmpp_log_level_t,), level)
end

mutable struct _xmpp_conn_t end

const xmpp_conn_t = _xmpp_conn_t

mutable struct _xmpp_stanza_t end

const xmpp_stanza_t = _xmpp_stanza_t

mutable struct _xmpp_sm_t end

const xmpp_sm_state_t = _xmpp_sm_t

@enum xmpp_conn_event_t::UInt32 begin
    XMPP_CONN_CONNECT = 0
    XMPP_CONN_RAW_CONNECT = 1
    XMPP_CONN_DISCONNECT = 2
    XMPP_CONN_FAIL = 3
end

@enum xmpp_error_type_t::UInt32 begin
    XMPP_SE_BAD_FORMAT = 0
    XMPP_SE_BAD_NS_PREFIX = 1
    XMPP_SE_CONFLICT = 2
    XMPP_SE_CONN_TIMEOUT = 3
    XMPP_SE_HOST_GONE = 4
    XMPP_SE_HOST_UNKNOWN = 5
    XMPP_SE_IMPROPER_ADDR = 6
    XMPP_SE_INTERNAL_SERVER_ERROR = 7
    XMPP_SE_INVALID_FROM = 8
    XMPP_SE_INVALID_ID = 9
    XMPP_SE_INVALID_NS = 10
    XMPP_SE_INVALID_XML = 11
    XMPP_SE_NOT_AUTHORIZED = 12
    XMPP_SE_POLICY_VIOLATION = 13
    XMPP_SE_REMOTE_CONN_FAILED = 14
    XMPP_SE_RESOURCE_CONSTRAINT = 15
    XMPP_SE_RESTRICTED_XML = 16
    XMPP_SE_SEE_OTHER_HOST = 17
    XMPP_SE_SYSTEM_SHUTDOWN = 18
    XMPP_SE_UNDEFINED_CONDITION = 19
    XMPP_SE_UNSUPPORTED_ENCODING = 20
    XMPP_SE_UNSUPPORTED_STANZA_TYPE = 21
    XMPP_SE_UNSUPPORTED_VERSION = 22
    XMPP_SE_XML_NOT_WELL_FORMED = 23
end

"""
    xmpp_cert_element_t

Certificate Elements

` TLS`
"""
@enum xmpp_cert_element_t::UInt32 begin
    XMPP_CERT_VERSION = 0
    XMPP_CERT_SERIALNUMBER = 1
    XMPP_CERT_SUBJECT = 2
    XMPP_CERT_ISSUER = 3
    XMPP_CERT_NOTBEFORE = 4
    XMPP_CERT_NOTAFTER = 5
    XMPP_CERT_KEYALG = 6
    XMPP_CERT_SIGALG = 7
    XMPP_CERT_FINGERPRINT_SHA1 = 8
    XMPP_CERT_FINGERPRINT_SHA256 = 9
    XMPP_CERT_ELEMENT_MAX = 10
end

struct xmpp_stream_error_t
    type::xmpp_error_type_t
    text::Ptr{Cchar}
    stanza::Ptr{xmpp_stanza_t}
end

# typedef void ( * xmpp_conn_handler ) ( xmpp_conn_t * conn , xmpp_conn_event_t event , int error , xmpp_stream_error_t * stream_error , void * userdata )
const xmpp_conn_handler = Ptr{Cvoid}

# typedef int ( * xmpp_certfail_handler ) ( const xmpp_tlscert_t * cert , const char * const errormsg )
"""
The Handler function which will be called when the TLS stack can't verify the authenticity of a Certificate that gets presented by the server we're trying to connect to.

When this function is called and details of the `cert` have to be kept, please copy them yourself. The `cert` object will be free'd automatically when this function returns.

NB: `errormsg` is specific per certificate on OpenSSL and the same for all certificates on GnuTLS.

` TLS`

# Arguments
* `cert`: a Strophe certificate object
* `errormsg`: The error that caused this.
# Returns
0 if the connection attempt should be terminated, 1 if the connection should be established.
"""
const xmpp_certfail_handler = Ptr{Cvoid}

# typedef int ( * xmpp_password_callback ) ( char * pw , size_t pw_max , xmpp_conn_t * conn , void * userdata )
"""
The Handler function which will be called when the TLS stack can't decrypt a password protected key file.

When this callback is called it shall write a NULL-terminated string of maximum length `pw\\_max - 1` to `pw`.

This is currently only supported for GnuTLS and OpenSSL.

On 2022-02-02 the following maximum lengths are valid: ``` include/gnutls/pkcs11.h: #define GNUTLS\\_PKCS11\\_MAX\\_PIN\\_LEN 256 include/openssl/pem.h: #define PEM\\_BUFSIZE 1024 ```

We expect the buffer to be NULL-terminated, therefore the usable lengths are:

* 255 for GnuTLS * 1023 for OpenSSL

Useful API's inside this callback are e.g.

xmpp_conn_get_keyfile

` TLS`

# Arguments
* `pw`: The buffer where the password shall be stored.
* `pw_max`: The maximum length of the password.
* `conn`: The Strophe connection object this callback originates from.
* `userdata`: The userdata pointer as supplied when setting this callback.
# Returns
-1 on error, else the number of bytes written to `pw` w/o terminating NUL byte
"""
const xmpp_password_callback = Ptr{Cvoid}

# typedef int ( * xmpp_sockopt_callback ) ( xmpp_conn_t * conn , void * sock )
"""
The function which will be called when Strophe creates a new socket.

The `sock` argument is a pointer that is dependent on the architecture Strophe is compiled for.

For POSIX compatible systems usage shall be: ``` int soc = *((int*)sock); ```

On Windows usage shall be: ``` SOCKET soc = *((SOCKET*)sock); ```

This function will be called for each socket that is created.

`examples/bot.c` uses a libstrophe supplied callback function that sets basic keepalive parameters (`[`xmpp_sockopt_cb_keepalive`](@ref)()`).

`examples/complex.c` implements a custom function that could be useful for an application.

` Connections`

# Arguments
* `conn`: The Strophe connection object this callback originates from.
* `sock`: A pointer to the underlying file descriptor.
# Returns
0 on success, -1 on error
"""
const xmpp_sockopt_callback = Ptr{Cvoid}

function xmpp_sockopt_cb_keepalive(conn, sock)
    return ccall((:xmpp_sockopt_cb_keepalive, libstrophe), Cint, (Ptr{xmpp_conn_t}, Ptr{Cvoid}), conn, sock)
end

function xmpp_send_error(conn, type, text)
    return ccall((:xmpp_send_error, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, xmpp_error_type_t, Ptr{Cchar}), conn, type, text)
end

function xmpp_conn_new(ctx)
    return ccall((:xmpp_conn_new, libstrophe), Ptr{xmpp_conn_t}, (Ptr{xmpp_ctx_t},), ctx)
end

function xmpp_conn_clone(conn)
    return ccall((:xmpp_conn_clone, libstrophe), Ptr{xmpp_conn_t}, (Ptr{xmpp_conn_t},), conn)
end

function xmpp_conn_release(conn)
    return ccall((:xmpp_conn_release, libstrophe), Cint, (Ptr{xmpp_conn_t},), conn)
end

function xmpp_conn_get_flags(conn)
    return ccall((:xmpp_conn_get_flags, libstrophe), Clong, (Ptr{xmpp_conn_t},), conn)
end

function xmpp_conn_set_flags(conn, flags)
    return ccall((:xmpp_conn_set_flags, libstrophe), Cint, (Ptr{xmpp_conn_t}, Clong), conn, flags)
end

function xmpp_conn_get_jid(conn)
    return ccall((:xmpp_conn_get_jid, libstrophe), Ptr{Cchar}, (Ptr{xmpp_conn_t},), conn)
end

function xmpp_conn_get_bound_jid(conn)
    return ccall((:xmpp_conn_get_bound_jid, libstrophe), Ptr{Cchar}, (Ptr{xmpp_conn_t},), conn)
end

function xmpp_conn_set_jid(conn, jid)
    return ccall((:xmpp_conn_set_jid, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, Ptr{Cchar}), conn, jid)
end

function xmpp_conn_set_cafile(conn, path)
    return ccall((:xmpp_conn_set_cafile, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, Ptr{Cchar}), conn, path)
end

function xmpp_conn_set_capath(conn, path)
    return ccall((:xmpp_conn_set_capath, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, Ptr{Cchar}), conn, path)
end

function xmpp_conn_set_certfail_handler(conn, hndl)
    return ccall((:xmpp_conn_set_certfail_handler, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, xmpp_certfail_handler), conn, hndl)
end

function xmpp_conn_get_peer_cert(conn)
    return ccall((:xmpp_conn_get_peer_cert, libstrophe), Ptr{xmpp_tlscert_t}, (Ptr{xmpp_conn_t},), conn)
end

function xmpp_conn_set_password_callback(conn, cb, userdata)
    return ccall((:xmpp_conn_set_password_callback, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, xmpp_password_callback, Ptr{Cvoid}), conn, cb, userdata)
end

function xmpp_conn_set_password_retries(conn, retries)
    return ccall((:xmpp_conn_set_password_retries, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, Cuint), conn, retries)
end

function xmpp_conn_get_keyfile(conn)
    return ccall((:xmpp_conn_get_keyfile, libstrophe), Ptr{Cchar}, (Ptr{xmpp_conn_t},), conn)
end

function xmpp_conn_set_client_cert(conn, cert, key)
    return ccall((:xmpp_conn_set_client_cert, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, Ptr{Cchar}, Ptr{Cchar}), conn, cert, key)
end

function xmpp_conn_cert_xmppaddr_num(conn)
    return ccall((:xmpp_conn_cert_xmppaddr_num, libstrophe), Cuint, (Ptr{xmpp_conn_t},), conn)
end

function xmpp_conn_cert_xmppaddr(conn, n)
    return ccall((:xmpp_conn_cert_xmppaddr, libstrophe), Ptr{Cchar}, (Ptr{xmpp_conn_t}, Cuint), conn, n)
end

function xmpp_conn_get_pass(conn)
    return ccall((:xmpp_conn_get_pass, libstrophe), Ptr{Cchar}, (Ptr{xmpp_conn_t},), conn)
end

function xmpp_conn_set_pass(conn, pass)
    return ccall((:xmpp_conn_set_pass, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, Ptr{Cchar}), conn, pass)
end

function xmpp_conn_get_context(conn)
    return ccall((:xmpp_conn_get_context, libstrophe), Ptr{xmpp_ctx_t}, (Ptr{xmpp_conn_t},), conn)
end

function xmpp_conn_is_secured(conn)
    return ccall((:xmpp_conn_is_secured, libstrophe), Cint, (Ptr{xmpp_conn_t},), conn)
end

function xmpp_conn_set_sockopt_callback(conn, callback)
    return ccall((:xmpp_conn_set_sockopt_callback, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, xmpp_sockopt_callback), conn, callback)
end

function xmpp_conn_is_connecting(conn)
    return ccall((:xmpp_conn_is_connecting, libstrophe), Cint, (Ptr{xmpp_conn_t},), conn)
end

function xmpp_conn_is_connected(conn)
    return ccall((:xmpp_conn_is_connected, libstrophe), Cint, (Ptr{xmpp_conn_t},), conn)
end

function xmpp_conn_is_disconnected(conn)
    return ccall((:xmpp_conn_is_disconnected, libstrophe), Cint, (Ptr{xmpp_conn_t},), conn)
end

function xmpp_conn_send_queue_len(conn)
    return ccall((:xmpp_conn_send_queue_len, libstrophe), Cint, (Ptr{xmpp_conn_t},), conn)
end

@enum xmpp_queue_element_t::Int32 begin
    XMPP_QUEUE_OLDEST = -1
    XMPP_QUEUE_YOUNGEST = -2
end

function xmpp_conn_send_queue_drop_element(conn, which)
    return ccall((:xmpp_conn_send_queue_drop_element, libstrophe), Ptr{Cchar}, (Ptr{xmpp_conn_t}, xmpp_queue_element_t), conn, which)
end

function xmpp_conn_set_sm_state(conn, sm_state)
    return ccall((:xmpp_conn_set_sm_state, libstrophe), Cint, (Ptr{xmpp_conn_t}, Ptr{xmpp_sm_state_t}), conn, sm_state)
end

function xmpp_conn_get_sm_state(conn)
    return ccall((:xmpp_conn_get_sm_state, libstrophe), Ptr{xmpp_sm_state_t}, (Ptr{xmpp_conn_t},), conn)
end

# typedef void ( * xmpp_sm_callback ) ( xmpp_conn_t * conn , void * ctx , const unsigned char * sm_state , size_t sm_state_len )
"""
The function which will be called when Strophe updates its internal SM state.

Please note that you have to create a copy of the buffer, since the library will free the buffer right after return of the callback function.

` Connections`

# Arguments
* `conn`: The Strophe connection object this callback originates from.
* `ctx`: The `ctx` pointer as passed to xmpp_conn_set_sm_callback
* `sm_state`: A pointer to a buffer containing the serialized SM state.
* `sm_state_len`: The length of `sm_state`.
# Returns
0 on success, -1 on error
"""
const xmpp_sm_callback = Ptr{Cvoid}

function xmpp_conn_set_sm_callback(conn, cb, ctx)
    return ccall((:xmpp_conn_set_sm_callback, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, xmpp_sm_callback, Ptr{Cvoid}), conn, cb, ctx)
end

function xmpp_conn_restore_sm_state(conn, sm_state, sm_state_len)
    return ccall((:xmpp_conn_restore_sm_state, libstrophe), Cint, (Ptr{xmpp_conn_t}, Ptr{Cuchar}, Csize_t), conn, sm_state, sm_state_len)
end

function xmpp_free_sm_state(sm_state)
    return ccall((:xmpp_free_sm_state, libstrophe), Cvoid, (Ptr{xmpp_sm_state_t},), sm_state)
end

function xmpp_connect_client(conn, altdomain, altport, callback, userdata)
    return ccall((:xmpp_connect_client, libstrophe), Cint, (Ptr{xmpp_conn_t}, Ptr{Cchar}, Cushort, xmpp_conn_handler, Ptr{Cvoid}), conn, altdomain, altport, callback, userdata)
end

function xmpp_connect_component(conn, server, port, callback, userdata)
    return ccall((:xmpp_connect_component, libstrophe), Cint, (Ptr{xmpp_conn_t}, Ptr{Cchar}, Cushort, xmpp_conn_handler, Ptr{Cvoid}), conn, server, port, callback, userdata)
end

function xmpp_connect_raw(conn, altdomain, altport, callback, userdata)
    return ccall((:xmpp_connect_raw, libstrophe), Cint, (Ptr{xmpp_conn_t}, Ptr{Cchar}, Cushort, xmpp_conn_handler, Ptr{Cvoid}), conn, altdomain, altport, callback, userdata)
end

function xmpp_conn_open_stream_default(conn)
    return ccall((:xmpp_conn_open_stream_default, libstrophe), Cint, (Ptr{xmpp_conn_t},), conn)
end

function xmpp_conn_open_stream(conn, attributes, attributes_len)
    return ccall((:xmpp_conn_open_stream, libstrophe), Cint, (Ptr{xmpp_conn_t}, Ptr{Ptr{Cchar}}, Csize_t), conn, attributes, attributes_len)
end

function xmpp_conn_tls_start(conn)
    return ccall((:xmpp_conn_tls_start, libstrophe), Cint, (Ptr{xmpp_conn_t},), conn)
end

function xmpp_disconnect(conn)
    return ccall((:xmpp_disconnect, libstrophe), Cvoid, (Ptr{xmpp_conn_t},), conn)
end

function xmpp_send(conn, stanza)
    return ccall((:xmpp_send, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, Ptr{xmpp_stanza_t}), conn, stanza)
end

function xmpp_send_raw(conn, data, len)
    return ccall((:xmpp_send_raw, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, Ptr{Cchar}, Csize_t), conn, data, len)
end

# typedef int ( * xmpp_timed_handler ) ( xmpp_conn_t * conn , void * userdata )
const xmpp_timed_handler = Ptr{Cvoid}

function xmpp_timed_handler_add(conn, handler, period, userdata)
    return ccall((:xmpp_timed_handler_add, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, xmpp_timed_handler, Culong, Ptr{Cvoid}), conn, handler, period, userdata)
end

function xmpp_timed_handler_delete(conn, handler)
    return ccall((:xmpp_timed_handler_delete, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, xmpp_timed_handler), conn, handler)
end

# typedef int ( * xmpp_global_timed_handler ) ( xmpp_ctx_t * ctx , void * userdata )
const xmpp_global_timed_handler = Ptr{Cvoid}

function xmpp_global_timed_handler_add(ctx, handler, period, userdata)
    return ccall((:xmpp_global_timed_handler_add, libstrophe), Cvoid, (Ptr{xmpp_ctx_t}, xmpp_global_timed_handler, Culong, Ptr{Cvoid}), ctx, handler, period, userdata)
end

function xmpp_global_timed_handler_delete(ctx, handler)
    return ccall((:xmpp_global_timed_handler_delete, libstrophe), Cvoid, (Ptr{xmpp_ctx_t}, xmpp_global_timed_handler), ctx, handler)
end

# typedef int ( * xmpp_handler ) ( xmpp_conn_t * conn , xmpp_stanza_t * stanza , void * userdata )
const xmpp_handler = Ptr{Cvoid}

function xmpp_handler_add(conn, handler, ns, name, type, userdata)
    return ccall((:xmpp_handler_add, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, xmpp_handler, Ptr{Cchar}, Ptr{Cchar}, Ptr{Cchar}, Ptr{Cvoid}), conn, handler, ns, name, type, userdata)
end

function xmpp_handler_delete(conn, handler)
    return ccall((:xmpp_handler_delete, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, xmpp_handler), conn, handler)
end

function xmpp_id_handler_add(conn, handler, id, userdata)
    return ccall((:xmpp_id_handler_add, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, xmpp_handler, Ptr{Cchar}, Ptr{Cvoid}), conn, handler, id, userdata)
end

function xmpp_id_handler_delete(conn, handler, id)
    return ccall((:xmpp_id_handler_delete, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, xmpp_handler, Ptr{Cchar}), conn, handler, id)
end

function xmpp_stanza_new(ctx)
    return ccall((:xmpp_stanza_new, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_ctx_t},), ctx)
end

function xmpp_stanza_new_from_string(ctx, str)
    return ccall((:xmpp_stanza_new_from_string, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_ctx_t}, Ptr{Cchar}), ctx, str)
end

function xmpp_stanza_clone(stanza)
    return ccall((:xmpp_stanza_clone, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_stanza_t},), stanza)
end

function xmpp_stanza_copy(stanza)
    return ccall((:xmpp_stanza_copy, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_stanza_t},), stanza)
end

function xmpp_stanza_release(stanza)
    return ccall((:xmpp_stanza_release, libstrophe), Cint, (Ptr{xmpp_stanza_t},), stanza)
end

function xmpp_stanza_get_context(stanza)
    return ccall((:xmpp_stanza_get_context, libstrophe), Ptr{xmpp_ctx_t}, (Ptr{xmpp_stanza_t},), stanza)
end

function xmpp_stanza_is_text(stanza)
    return ccall((:xmpp_stanza_is_text, libstrophe), Cint, (Ptr{xmpp_stanza_t},), stanza)
end

function xmpp_stanza_is_tag(stanza)
    return ccall((:xmpp_stanza_is_tag, libstrophe), Cint, (Ptr{xmpp_stanza_t},), stanza)
end

function xmpp_stanza_to_text(stanza, buf, buflen)
    return ccall((:xmpp_stanza_to_text, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{Ptr{Cchar}}, Ptr{Csize_t}), stanza, buf, buflen)
end

function xmpp_stanza_get_children(stanza)
    return ccall((:xmpp_stanza_get_children, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_stanza_t},), stanza)
end

function xmpp_stanza_get_child_by_name(stanza, name)
    return ccall((:xmpp_stanza_get_child_by_name, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_stanza_t}, Ptr{Cchar}), stanza, name)
end

function xmpp_stanza_get_child_by_ns(stanza, ns)
    return ccall((:xmpp_stanza_get_child_by_ns, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_stanza_t}, Ptr{Cchar}), stanza, ns)
end

function xmpp_stanza_get_child_by_name_and_ns(stanza, name, ns)
    return ccall((:xmpp_stanza_get_child_by_name_and_ns, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_stanza_t}, Ptr{Cchar}, Ptr{Cchar}), stanza, name, ns)
end

function xmpp_stanza_get_next(stanza)
    return ccall((:xmpp_stanza_get_next, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_stanza_t},), stanza)
end

function xmpp_stanza_add_child(stanza, child)
    return ccall((:xmpp_stanza_add_child, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{xmpp_stanza_t}), stanza, child)
end

function xmpp_stanza_add_child_ex(stanza, child, do_clone)
    return ccall((:xmpp_stanza_add_child_ex, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{xmpp_stanza_t}, Cint), stanza, child, do_clone)
end

function xmpp_stanza_get_attribute(stanza, name)
    return ccall((:xmpp_stanza_get_attribute, libstrophe), Ptr{Cchar}, (Ptr{xmpp_stanza_t}, Ptr{Cchar}), stanza, name)
end

function xmpp_stanza_get_attribute_count(stanza)
    return ccall((:xmpp_stanza_get_attribute_count, libstrophe), Cint, (Ptr{xmpp_stanza_t},), stanza)
end

function xmpp_stanza_get_attributes(stanza, attr, attrlen)
    return ccall((:xmpp_stanza_get_attributes, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{Ptr{Cchar}}, Cint), stanza, attr, attrlen)
end

function xmpp_stanza_get_text(stanza)
    return ccall((:xmpp_stanza_get_text, libstrophe), Ptr{Cchar}, (Ptr{xmpp_stanza_t},), stanza)
end

function xmpp_stanza_get_text_ptr(stanza)
    return ccall((:xmpp_stanza_get_text_ptr, libstrophe), Ptr{Cchar}, (Ptr{xmpp_stanza_t},), stanza)
end

function xmpp_stanza_get_name(stanza)
    return ccall((:xmpp_stanza_get_name, libstrophe), Ptr{Cchar}, (Ptr{xmpp_stanza_t},), stanza)
end

function xmpp_stanza_set_attribute(stanza, key, value)
    return ccall((:xmpp_stanza_set_attribute, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{Cchar}, Ptr{Cchar}), stanza, key, value)
end

function xmpp_stanza_set_name(stanza, name)
    return ccall((:xmpp_stanza_set_name, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{Cchar}), stanza, name)
end

function xmpp_stanza_set_text(stanza, text)
    return ccall((:xmpp_stanza_set_text, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{Cchar}), stanza, text)
end

function xmpp_stanza_set_text_with_size(stanza, text, size)
    return ccall((:xmpp_stanza_set_text_with_size, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{Cchar}, Csize_t), stanza, text, size)
end

function xmpp_stanza_del_attribute(stanza, name)
    return ccall((:xmpp_stanza_del_attribute, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{Cchar}), stanza, name)
end

function xmpp_stanza_get_ns(stanza)
    return ccall((:xmpp_stanza_get_ns, libstrophe), Ptr{Cchar}, (Ptr{xmpp_stanza_t},), stanza)
end

function xmpp_stanza_get_type(stanza)
    return ccall((:xmpp_stanza_get_type, libstrophe), Ptr{Cchar}, (Ptr{xmpp_stanza_t},), stanza)
end

function xmpp_stanza_get_id(stanza)
    return ccall((:xmpp_stanza_get_id, libstrophe), Ptr{Cchar}, (Ptr{xmpp_stanza_t},), stanza)
end

function xmpp_stanza_get_to(stanza)
    return ccall((:xmpp_stanza_get_to, libstrophe), Ptr{Cchar}, (Ptr{xmpp_stanza_t},), stanza)
end

function xmpp_stanza_get_from(stanza)
    return ccall((:xmpp_stanza_get_from, libstrophe), Ptr{Cchar}, (Ptr{xmpp_stanza_t},), stanza)
end

function xmpp_stanza_set_ns(stanza, ns)
    return ccall((:xmpp_stanza_set_ns, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{Cchar}), stanza, ns)
end

function xmpp_stanza_set_id(stanza, id)
    return ccall((:xmpp_stanza_set_id, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{Cchar}), stanza, id)
end

function xmpp_stanza_set_type(stanza, type)
    return ccall((:xmpp_stanza_set_type, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{Cchar}), stanza, type)
end

function xmpp_stanza_set_to(stanza, to)
    return ccall((:xmpp_stanza_set_to, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{Cchar}), stanza, to)
end

function xmpp_stanza_set_from(stanza, from)
    return ccall((:xmpp_stanza_set_from, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{Cchar}), stanza, from)
end

function xmpp_stanza_reply(stanza)
    return ccall((:xmpp_stanza_reply, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_stanza_t},), stanza)
end

function xmpp_stanza_reply_error(stanza, error_type, condition, text)
    return ccall((:xmpp_stanza_reply_error, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_stanza_t}, Ptr{Cchar}, Ptr{Cchar}, Ptr{Cchar}), stanza, error_type, condition, text)
end

function xmpp_message_new(ctx, type, to, id)
    return ccall((:xmpp_message_new, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_ctx_t}, Ptr{Cchar}, Ptr{Cchar}, Ptr{Cchar}), ctx, type, to, id)
end

function xmpp_message_get_body(msg)
    return ccall((:xmpp_message_get_body, libstrophe), Ptr{Cchar}, (Ptr{xmpp_stanza_t},), msg)
end

function xmpp_message_set_body(msg, text)
    return ccall((:xmpp_message_set_body, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{Cchar}), msg, text)
end

function xmpp_iq_new(ctx, type, id)
    return ccall((:xmpp_iq_new, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_ctx_t}, Ptr{Cchar}, Ptr{Cchar}), ctx, type, id)
end

function xmpp_presence_new(ctx)
    return ccall((:xmpp_presence_new, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_ctx_t},), ctx)
end

function xmpp_error_new(ctx, type, text)
    return ccall((:xmpp_error_new, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_ctx_t}, xmpp_error_type_t, Ptr{Cchar}), ctx, type, text)
end

function xmpp_jid_new(ctx, node, domain, resource)
    return ccall((:xmpp_jid_new, libstrophe), Ptr{Cchar}, (Ptr{xmpp_ctx_t}, Ptr{Cchar}, Ptr{Cchar}, Ptr{Cchar}), ctx, node, domain, resource)
end

function xmpp_jid_bare(ctx, jid)
    return ccall((:xmpp_jid_bare, libstrophe), Ptr{Cchar}, (Ptr{xmpp_ctx_t}, Ptr{Cchar}), ctx, jid)
end

function xmpp_jid_node(ctx, jid)
    return ccall((:xmpp_jid_node, libstrophe), Ptr{Cchar}, (Ptr{xmpp_ctx_t}, Ptr{Cchar}), ctx, jid)
end

function xmpp_jid_domain(ctx, jid)
    return ccall((:xmpp_jid_domain, libstrophe), Ptr{Cchar}, (Ptr{xmpp_ctx_t}, Ptr{Cchar}), ctx, jid)
end

function xmpp_jid_resource(ctx, jid)
    return ccall((:xmpp_jid_resource, libstrophe), Ptr{Cchar}, (Ptr{xmpp_ctx_t}, Ptr{Cchar}), ctx, jid)
end

function xmpp_run_once(ctx, timeout)
    return ccall((:xmpp_run_once, libstrophe), Cvoid, (Ptr{xmpp_ctx_t}, Culong), ctx, timeout)
end

function xmpp_run(ctx)
    return ccall((:xmpp_run, libstrophe), Cvoid, (Ptr{xmpp_ctx_t},), ctx)
end

function xmpp_stop(ctx)
    return ccall((:xmpp_stop, libstrophe), Cvoid, (Ptr{xmpp_ctx_t},), ctx)
end

function xmpp_ctx_set_timeout(ctx, timeout)
    return ccall((:xmpp_ctx_set_timeout, libstrophe), Cvoid, (Ptr{xmpp_ctx_t}, Culong), ctx, timeout)
end

function xmpp_tlscert_get_ctx(cert)
    return ccall((:xmpp_tlscert_get_ctx, libstrophe), Ptr{xmpp_ctx_t}, (Ptr{xmpp_tlscert_t},), cert)
end

function xmpp_tlscert_get_conn(cert)
    return ccall((:xmpp_tlscert_get_conn, libstrophe), Ptr{xmpp_conn_t}, (Ptr{xmpp_tlscert_t},), cert)
end

function xmpp_tlscert_get_pem(cert)
    return ccall((:xmpp_tlscert_get_pem, libstrophe), Ptr{Cchar}, (Ptr{xmpp_tlscert_t},), cert)
end

function xmpp_tlscert_get_dnsname(cert, n)
    return ccall((:xmpp_tlscert_get_dnsname, libstrophe), Ptr{Cchar}, (Ptr{xmpp_tlscert_t}, Csize_t), cert, n)
end

function xmpp_tlscert_get_string(cert, elmnt)
    return ccall((:xmpp_tlscert_get_string, libstrophe), Ptr{Cchar}, (Ptr{xmpp_tlscert_t}, xmpp_cert_element_t), cert, elmnt)
end

function xmpp_tlscert_get_description(elmnt)
    return ccall((:xmpp_tlscert_get_description, libstrophe), Ptr{Cchar}, (xmpp_cert_element_t,), elmnt)
end

function xmpp_tlscert_free(cert)
    return ccall((:xmpp_tlscert_free, libstrophe), Cvoid, (Ptr{xmpp_tlscert_t},), cert)
end

function xmpp_uuid_gen(ctx)
    return ccall((:xmpp_uuid_gen, libstrophe), Ptr{Cchar}, (Ptr{xmpp_ctx_t},), ctx)
end

mutable struct _xmpp_sha1_t end

const xmpp_sha1_t = _xmpp_sha1_t

function xmpp_sha1(ctx, data, len)
    return ccall((:xmpp_sha1, libstrophe), Ptr{Cchar}, (Ptr{xmpp_ctx_t}, Ptr{Cuchar}, Csize_t), ctx, data, len)
end

function xmpp_sha1_digest(data, len, digest)
    return ccall((:xmpp_sha1_digest, libstrophe), Cvoid, (Ptr{Cuchar}, Csize_t, Ptr{Cuchar}), data, len, digest)
end

function xmpp_sha1_new(ctx)
    return ccall((:xmpp_sha1_new, libstrophe), Ptr{xmpp_sha1_t}, (Ptr{xmpp_ctx_t},), ctx)
end

function xmpp_sha1_free(sha1)
    return ccall((:xmpp_sha1_free, libstrophe), Cvoid, (Ptr{xmpp_sha1_t},), sha1)
end

function xmpp_sha1_update(sha1, data, len)
    return ccall((:xmpp_sha1_update, libstrophe), Cvoid, (Ptr{xmpp_sha1_t}, Ptr{Cuchar}, Csize_t), sha1, data, len)
end

function xmpp_sha1_final(sha1)
    return ccall((:xmpp_sha1_final, libstrophe), Cvoid, (Ptr{xmpp_sha1_t},), sha1)
end

function xmpp_sha1_to_string(sha1, s, slen)
    return ccall((:xmpp_sha1_to_string, libstrophe), Ptr{Cchar}, (Ptr{xmpp_sha1_t}, Ptr{Cchar}, Csize_t), sha1, s, slen)
end

function xmpp_sha1_to_string_alloc(sha1)
    return ccall((:xmpp_sha1_to_string_alloc, libstrophe), Ptr{Cchar}, (Ptr{xmpp_sha1_t},), sha1)
end

function xmpp_sha1_to_digest(sha1, digest)
    return ccall((:xmpp_sha1_to_digest, libstrophe), Cvoid, (Ptr{xmpp_sha1_t}, Ptr{Cuchar}), sha1, digest)
end

function xmpp_base64_encode(ctx, data, len)
    return ccall((:xmpp_base64_encode, libstrophe), Ptr{Cchar}, (Ptr{xmpp_ctx_t}, Ptr{Cuchar}, Csize_t), ctx, data, len)
end

function xmpp_base64_decode_str(ctx, base64, len)
    return ccall((:xmpp_base64_decode_str, libstrophe), Ptr{Cchar}, (Ptr{xmpp_ctx_t}, Ptr{Cchar}, Csize_t), ctx, base64, len)
end

function xmpp_base64_decode_bin(ctx, base64, len, out, outlen)
    return ccall((:xmpp_base64_decode_bin, libstrophe), Cvoid, (Ptr{xmpp_ctx_t}, Ptr{Cchar}, Csize_t, Ptr{Ptr{Cuchar}}, Ptr{Csize_t}), ctx, base64, len, out, outlen)
end

mutable struct _xmpp_rand_t end

const xmpp_rand_t = _xmpp_rand_t

"""
    xmpp_rand_new(ctx)

Create new [`xmpp_rand_t`](@ref) object.

` Random`

# Arguments
* `ctx`: A Strophe context object
"""
function xmpp_rand_new(ctx)
    return ccall((:xmpp_rand_new, libstrophe), Ptr{xmpp_rand_t}, (Ptr{xmpp_ctx_t},), ctx)
end

"""
    xmpp_rand_free(ctx, rand)

Destroy an [`xmpp_rand_t`](@ref) object.

` Random`

# Arguments
* `ctx`: A Strophe context object
* `rand`: A [`xmpp_rand_t`](@ref) object
"""
function xmpp_rand_free(ctx, rand)
    return ccall((:xmpp_rand_free, libstrophe), Cvoid, (Ptr{xmpp_ctx_t}, Ptr{xmpp_rand_t}), ctx, rand)
end

"""
    xmpp_rand(rand)

Generate random integer. Analogue of rand(3).

` Random`
"""
function xmpp_rand(rand)
    return ccall((:xmpp_rand, libstrophe), Cint, (Ptr{xmpp_rand_t},), rand)
end

"""
    xmpp_rand_bytes(rand, output, len)

Generate random bytes. Generates len bytes and stores them to the output buffer.

` Random`

# Arguments
* `rand`: A [`xmpp_rand_t`](@ref) object
* `output`: A buffer where a len random bytes will be placed.
* `len`: Number of bytes reserved for the output..
"""
function xmpp_rand_bytes(rand, output, len)
    return ccall((:xmpp_rand_bytes, libstrophe), Cvoid, (Ptr{xmpp_rand_t}, Ptr{Cuchar}, Csize_t), rand, output, len)
end

"""
    xmpp_rand_nonce(rand, output, len)

Generate a nonce that is printable randomized string. This function doesn't allocate memory and doesn't fail.

` Random`

# Arguments
* `rand`: A [`xmpp_rand_t`](@ref) object
* `output`: A buffer where a NULL-terminated string will be placed. The string will contain len-1 printable symbols.
* `len`: Number of bytes reserved for the output string, including end of line '\\0'.
"""
function xmpp_rand_nonce(rand, output, len)
    return ccall((:xmpp_rand_nonce, libstrophe), Cvoid, (Ptr{xmpp_rand_t}, Ptr{Cchar}, Csize_t), rand, output, len)
end

function xmpp_alloc(ctx, size)
    return ccall((:xmpp_alloc, libstrophe), Ptr{Cvoid}, (Ptr{xmpp_ctx_t}, Csize_t), ctx, size)
end

function xmpp_realloc(ctx, p, size)
    return ccall((:xmpp_realloc, libstrophe), Ptr{Cvoid}, (Ptr{xmpp_ctx_t}, Ptr{Cvoid}, Csize_t), ctx, p, size)
end

function xmpp_strdup(ctx, s)
    return ccall((:xmpp_strdup, libstrophe), Ptr{Cchar}, (Ptr{xmpp_ctx_t}, Ptr{Cchar}), ctx, s)
end

function xmpp_strndup(ctx, s, len)
    return ccall((:xmpp_strndup, libstrophe), Ptr{Cchar}, (Ptr{xmpp_ctx_t}, Ptr{Cchar}, Csize_t), ctx, s, len)
end

function xmpp_strtok_r(s, delim, saveptr)
    return ccall((:xmpp_strtok_r, libstrophe), Ptr{Cchar}, (Ptr{Cchar}, Ptr{Cchar}, Ptr{Ptr{Cchar}}), s, delim, saveptr)
end

function xmpp_conn_set_keepalive(conn, timeout, interval)
    return ccall((:xmpp_conn_set_keepalive, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, Cint, Cint), conn, timeout, interval)
end

function xmpp_conn_disable_tls(conn)
    return ccall((:xmpp_conn_disable_tls, libstrophe), Cvoid, (Ptr{xmpp_conn_t},), conn)
end

const XMPP_NS_CLIENT = "jabber:client"

const XMPP_NS_COMPONENT = "jabber:component:accept"

const XMPP_NS_STREAMS = "http://etherx.jabber.org/streams"

const XMPP_NS_STREAMS_IETF = "urn:ietf:params:xml:ns:xmpp-streams"

const XMPP_NS_STANZAS_IETF = "urn:ietf:params:xml:ns:xmpp-stanzas"

const XMPP_NS_TLS = "urn:ietf:params:xml:ns:xmpp-tls"

const XMPP_NS_SASL = "urn:ietf:params:xml:ns:xmpp-sasl"

const XMPP_NS_BIND = "urn:ietf:params:xml:ns:xmpp-bind"

const XMPP_NS_SESSION = "urn:ietf:params:xml:ns:xmpp-session"

const XMPP_NS_AUTH = "jabber:iq:auth"

const XMPP_NS_DISCO_INFO = "http://jabber.org/protocol/disco#info"

const XMPP_NS_DISCO_ITEMS = "http://jabber.org/protocol/disco#items"

const XMPP_NS_ROSTER = "jabber:iq:roster"

const XMPP_NS_REGISTER = "jabber:iq:register"

const XMPP_NS_SM = "urn:xmpp:sm:3"

const XMPP_NS_COMPRESSION = "http://jabber.org/protocol/compress"

const XMPP_NS_FEATURE_COMPRESSION = "http://jabber.org/features/compress"

const XMPP_EOK = 0

const XMPP_EMEM = -1

const XMPP_EINVOP = -2

const XMPP_EINT = -3

const XMPP_CONN_FLAG_DISABLE_TLS = Culong(1) << 0

const XMPP_CONN_FLAG_MANDATORY_TLS = Culong(1) << 1

const XMPP_CONN_FLAG_LEGACY_SSL = Culong(1) << 2

const XMPP_CONN_FLAG_TRUST_TLS = Culong(1) << 3

const XMPP_CONN_FLAG_LEGACY_AUTH = Culong(1) << 4

const XMPP_CONN_FLAG_DISABLE_SM = Culong(1) << 5

const XMPP_CONN_FLAG_ENABLE_COMPRESSION = Culong(1) << 6

const XMPP_CONN_FLAG_COMPRESSION_DONT_RESET = Culong(1) << 7

const XMPP_SHA1_DIGEST_SIZE = 20

end # module
