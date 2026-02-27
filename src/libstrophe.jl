"""
The low-level binding to the underlying C-library libstrophe.
"""
module LibStrophe

using DocStringExtensions: SIGNATURES, TYPEDFIELDS
import Glossaries
using libstrophe_jll: libstrophe_jll, libstrophe
export libstrophe_jll

_g = Glossaries.Glossary()
Glossaries.define!(_g, :ctx, :name, "ctx")
Glossaries.define!(_g, :ctx, :type, "Ptr{xmpp_ctx_t}")
Glossaries.define!(_g, :ctx, :description, "A Strophe context object")
Glossaries.define!(_g, :conn, :name, "conn")
Glossaries.define!(_g, :conn, :type, "Ptr{xmpp_conn_t}")
Glossaries.define!(_g, :conn, :description, "A Strophe connection object")
Glossaries.define!(_g, :stanza, :name, "stanza")
Glossaries.define!(_g, :stanza, :type, "Ptr{xmpp_stanza_t}")
Glossaries.define!(_g, :stanza, :description, "A Strophe stanza object")
_arg = Glossaries.Argument()

"""
$(SIGNATURES)

Initialize the Strophe library.

This function initializes subcomponents of the Strophe library and must be called for Strophe to operate correctly.

"""
function xmpp_initialize()
    return ccall((:xmpp_initialize, libstrophe), Cvoid, ())
end

"""
$(SIGNATURES)

Shutdown the Strophe library.
"""
function xmpp_shutdown()
    return ccall((:xmpp_shutdown, libstrophe), Cvoid, ())
end

"""
$(SIGNATURES)

Check that Strophe supports a specific API version.

# Arguments
* `major`	the major version number
* `minor`	the minor version number

# Returns
`true` if the version is supported and `false` if unsupported
"""
function xmpp_version_check(major, minor)
    return ccall((:xmpp_version_check, libstrophe), Bool, (Cint, Cint), major, minor)
end

struct _xmpp_mem_t
    alloc::Ptr{Cvoid}
    free::Ptr{Cvoid}
    realloc::Ptr{Cvoid}
    userdata::Ptr{Cvoid}
end

const xmpp_mem_t = _xmpp_mem_t

"""
```c
typedef void ( * xmpp_log_handler ) ( void * userdata , xmpp_log_level_t level , const char * area , const char * msg )
```
"""
const xmpp_log_handler = Ptr{Cvoid}

mutable struct _xmpp_log_t
    handler::xmpp_log_handler
    userdata::Ptr{Cvoid}
end

const xmpp_log_t = _xmpp_log_t

mutable struct _xmpp_ctx_t end

"""
Internal, opaque, type used for storing context.
"""
const xmpp_ctx_t = _xmpp_ctx_t

mutable struct _xmpp_tlscert_t end

const xmpp_tlscert_t = _xmpp_tlscert_t

"""
$(SIGNATURES)

Create and initialize a Strophe context object.

If mem is NULL, a default allocation setup will be used which wraps `malloc()`,
`free()`, and `realloc()` from the standard library. If `log` is `C_NULL`, a
default logger will be used which does no logging. Basic filtered logging to
stderr can be done with the [`xmpp_get_default_logger`](@ref) convenience function.

# Arguments
* `mem`	a pointer to an `xmpp_mem_t` structure or `C_NULL`
* `log`	a pointer to an `xmpp_log_t` structure or `C_NULL`

# Returns
The allocated Strophe context object or `C_NULL` on an error.
"""
function xmpp_ctx_new(mem, log)
    return ccall((:xmpp_ctx_new, libstrophe), Ptr{xmpp_ctx_t}, (Ptr{xmpp_mem_t}, Ptr{xmpp_log_t}), mem, log)
end

"""
$(SIGNATURES)

Free a Strophe context object that is no longer in use.

# Arguments
$(_arg(_g, [:ctx]))
"""
function xmpp_ctx_free(ctx)
    return ccall((:xmpp_ctx_free, libstrophe), Cvoid, (Ptr{xmpp_ctx_t},), ctx)
end

"""
$(SIGNATURES)

Set the verbosity level of a Strophe context.

# Arguments
$(_arg(_g, [:ctx]))
* `level` the verbosity level
"""
function xmpp_ctx_set_verbosity(ctx, level)
    return ccall((:xmpp_ctx_set_verbosity, libstrophe), Cvoid, (Ptr{xmpp_ctx_t}, Cint), ctx, level)
end

"""
$(SIGNATURES)

Free some blocks returned by other APIs, for example the buffer you get
from [`xmpp_stanza_to_text`](@ref).
"""
function xmpp_free(ctx, p)
    return ccall((:xmpp_free, libstrophe), Cvoid, (Ptr{xmpp_ctx_t}, Ptr{Cvoid}), ctx, p)
end

"""
An enumeration for the log level used by Strophe.

Members:
* `XMPP_LEVEL_DEBUG`
* `XMPP_LEVEL_INFO`
* `XMPP_LEVEL_WARN`
* `XMPP_LEVEL_ERROR`
"""
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

"""
$(SIGNATURES)

Get a default logger with filtering.

The default logger provides a basic logging setup which writes log messages to stderr. Only messages where level is greater than or equal to the filter level will be logged.

# Arguments
* `level` the highest level the logger will log at

# Returns
The log structure for the given level
"""
function xmpp_get_default_logger(level)
    return ccall((:xmpp_get_default_logger, libstrophe), Ptr{xmpp_log_t}, (xmpp_log_level_t,), level)
end

mutable struct _xmpp_conn_t end

"""
Internal, opaque, type used for storing connection.
"""
const xmpp_conn_t = _xmpp_conn_t

mutable struct _xmpp_stanza_t end

"""
Internal, opaque, type used for storing stanza.
"""
const xmpp_stanza_t = _xmpp_stanza_t

mutable struct _xmpp_sm_t end

"""
Internal, opaque, type used for Stream-Management state storage.
"""
const xmpp_sm_state_t = _xmpp_sm_t

"""
Status flag passed to a [`xmpp_conn_handler`](@ref)

Members:
* `XMPP_CONN_CONNECT`
* `XMPP_CONN_RAW_CONNECT`
* `XMPP_CONN_DISCONNECT`
* `XMPP_CONN_FAIL`
"""
@enum xmpp_conn_event_t::UInt32 begin
    XMPP_CONN_CONNECT = 0
    XMPP_CONN_RAW_CONNECT = 1
    XMPP_CONN_DISCONNECT = 2
    XMPP_CONN_FAIL = 3
end

"""
Error type enumeration of the error stream passed to a [`xmpp_conn_handler`](@ref)

Members:
* `XMPP_SE_BAD_FORMAT`
* `XMPP_SE_BAD_NS_PREFIX`
* `XMPP_SE_CONFLICT`
* `XMPP_SE_CONN_TIMEOUT`
* `XMPP_SE_HOST_GONE`
* `XMPP_SE_HOST_UNKNOWN`
* `XMPP_SE_IMPROPER_ADDR`
* `XMPP_SE_INTERNAL_SERVER_ERROR`
* `XMPP_SE_INVALID_FROM`
* `XMPP_SE_INVALID_ID`
* `XMPP_SE_INVALID_NS`
* `XMPP_SE_INVALID_XML`
* `XMPP_SE_NOT_AUTHORIZED`
* `XMPP_SE_POLICY_VIOLATION`
* `XMPP_SE_REMOTE_CONN_FAILED`
* `XMPP_SE_RESOURCE_CONSTRAINT`
* `XMPP_SE_RESTRICTED_XML`
* `XMPP_SE_SEE_OTHER_HOST`
* `XMPP_SE_SYSTEM_SHUTDOWN`
* `XMPP_SE_UNDEFINED_CONDITION`
* `XMPP_SE_UNSUPPORTED_ENCODING`
* `XMPP_SE_UNSUPPORTED_STANZA_TYPE`
* `XMPP_SE_UNSUPPORTED_VERSION`
* `XMPP_SE_XML_NOT_WELL_FORMED`
"""
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

Members:
* `XMPP_CERT_VERSION`: X.509 Version.
* `XMPP_CERT_SERIALNUMBER`: SerialNumber.
* `XMPP_CERT_SUBJECT`: Subject.
* `XMPP_CERT_ISSUER`: Issuer.
* `XMPP_CERT_NOTBEFORE`: Issued on.
* `XMPP_CERT_NOTAFTER`: Expires on.
* `XMPP_CERT_KEYALG`: Public Key Algorithm.
* `XMPP_CERT_SIGALG`: Certificate Signature Algorithm.
* `XMPP_CERT_FINGERPRINT_SHA1`: Fingerprint SHA-1.
* `XMPP_CERT_FINGERPRINT_SHA256`: Fingerprint SHA-256.
* `XMPP_CERT_ELEMENT_MAX`: Last element of the enum.
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

"""
Represents an [XMPP stream error](https://datatracker.ietf.org/doc/html/rfc6120#section-4.9).

$(TYPEDFIELDS)
"""
struct xmpp_stream_error_t
    type::xmpp_error_type_t
    text::Ptr{Cchar}
    stanza::Ptr{xmpp_stanza_t}
end

"""
Pointer to a callback that will receive notifications of connection status.
Defined as:
```c
typedef void ( * xmpp_conn_handler ) ( xmpp_conn_t * conn , xmpp_conn_event_t event , int error , xmpp_stream_error_t * stream_error , void * userdata )
```
"""
const xmpp_conn_handler = Ptr{Cvoid}

"""
The Handler function which will be called when the TLS stack can't verify the authenticity of a Certificate that gets presented by the server we're trying to connect to.

When this function is called and details of the `cert` have to be kept, please copy them yourself. The `cert` object will be free'd automatically when this function returns.

NB: `errormsg` is specific per certificate on OpenSSL and the same for all certificates on GnuTLS.

Defined as:
```c
typedef int ( * xmpp_certfail_handler ) ( const xmpp_tlscert_t * cert , const char * const errormsg )
```

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

On 2022-02-02 the following maximum lengths are valid:
```
include/gnutls/pkcs11.h:
#define GNUTLS\\_PKCS11\\_MAX\\_PIN\\_LEN 256
include/openssl/pem.h:
#define PEM\\_BUFSIZE 1024
```

We expect the buffer to be NULL-terminated, therefore the usable lengths are:

* 255 for GnuTLS * 1023 for OpenSSL

Useful API's inside this callback are e.g. [`xmpp_conn_get_keyfile`](@ref)

# Arguments
* `pw`: The buffer where the password shall be stored.
* `pw_max`: The maximum length of the password.
$(_arg(_g, [:conn]))
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

[`examples/bot.c`](@ref low-level-bot-example) uses a libstrophe supplied callback function that sets basic keepalive parameters ([`xmpp_sockopt_cb_keepalive`](@ref)).

`examples/complex.c` implements a custom function that could be useful for an application.

` Connections`

# Arguments
$(_arg(_g, [:conn]))
* `sock`: A pointer to the underlying file descriptor.
# Returns
0 on success, -1 on error
"""
const xmpp_sockopt_callback = Ptr{Cvoid}

"""
$(SIGNATURES)

Example sockopt callback function An example function that can be used to set
reasonable default keepalive options on sockets when registered for a connection
with [`xmpp_conn_set_sockopt_callback`](@ref)

# Arguments
$(_arg(_g, [:conn]))
* `sock`: pointer to a socket descriptor

See also [`xmpp_conn_set_sockopt_callback`](@ref).
"""
function xmpp_sockopt_cb_keepalive(conn, sock)
    return ccall((:xmpp_sockopt_cb_keepalive, libstrophe), Cint, (Ptr{xmpp_conn_t}, Ptr{Cvoid}), conn, sock)
end

function xmpp_send_error(conn, type, text)
    return ccall((:xmpp_send_error, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, xmpp_error_type_t, Ptr{Cchar}), conn, type, text)
end

"""
$(SIGNATURES)

Create a new Strophe connection object.

# Arguments
$(_arg(_g, [:ctx]))

# Returns
A Strophe connection object or `C_NULL` on an error
"""
function xmpp_conn_new(ctx)
    return ccall((:xmpp_conn_new, libstrophe), Ptr{xmpp_conn_t}, (Ptr{xmpp_ctx_t},), ctx)
end

"""
$(SIGNATURES)

Clone a Strophe connection object.

# Arguments
$(_arg(_g, [:conn]))

# Returns
The same conn object passed in with its reference count incremented by 1
"""
function xmpp_conn_clone(conn)
    return ccall((:xmpp_conn_clone, libstrophe), Ptr{xmpp_conn_t}, (Ptr{xmpp_conn_t},), conn)
end

"""
$(SIGNATURES)

Release a Strophe connection object.

Decrement the reference count by one for a connection, freeing the connection object if the count reaches 0.

# Arguments
$(_arg(_g, [:conn]))

# Returns
`true` if the connection object was freed and `false` otherwise
"""
function xmpp_conn_release(conn)
    return ccall((:xmpp_conn_release, libstrophe), Bool, (Ptr{xmpp_conn_t},), conn)
end

"""
$(SIGNATURES)

Return applied flags for the connection.

# Arguments
$(_arg(_g, [:conn]))
"""
function xmpp_conn_get_flags(conn)
    return ccall((:xmpp_conn_get_flags, libstrophe), Clong, (Ptr{xmpp_conn_t},), conn)
end

"""
$(SIGNATURES)

Set flags for the connection.

This function applies set flags and resets unset ones. Default connection
configuration is all flags unset. Flags can be applied only for a connection in
disconnected state. All unsupported flags are ignored. If a flag is unset after
successful set operation then the flag is not supported by current version.

Supported flags are:
* `LibStrophe.XMPP_CONN_FLAG_DISABLE_TLS`
* `LibStrophe.XMPP_CONN_FLAG_MANDATORY_TLS`
* `LibStrophe.XMPP_CONN_FLAG_LEGACY_SSL`
* `LibStrophe.XMPP_CONN_FLAG_TRUST_TLS`
* `LibStrophe.XMPP_CONN_FLAG_LEGACY_AUTH`
* `LibStrophe.XMPP_CONN_FLAG_DISABLE_SM`
* `LibStrophe.XMPP_CONN_FLAG_ENABLE_COMPRESSION`
* `LibStrophe.XMPP_CONN_FLAG_COMPRESSION_DONT_RESET`


# Arguments
$(_arg(_g, [:conn]))
* `fags` ORed connection flags

# Returns
[`XMPP_EOK`](@ref) (0) on success or a number less than 0 on failure
"""
function xmpp_conn_set_flags(conn, flags)
    return ccall((:xmpp_conn_set_flags, libstrophe), Cint, (Ptr{xmpp_conn_t}, Clong), conn, flags)
end

"""
$(SIGNATURES)

Get the JID which is or will be bound to the connection.

# Arguments
$(_arg(_g, [:conn]))

# Returns
A string containing the full JID or `C_NULL` if it has not been set.
"""
function xmpp_conn_get_jid(conn)
    return ccall((:xmpp_conn_get_jid, libstrophe), Ptr{Cchar}, (Ptr{xmpp_conn_t},), conn)
end

"""
$(SIGNATURES)

Get the JID discovered during binding time.

This JID will contain the resource used by the current connection. This is
useful in the case where a resource was not specified for binding.

# Arguments
$(_arg(_g, [:conn]))

# Returns
A string containing the full JID or `C_NULL` if it's not been discovered
"""
function xmpp_conn_get_bound_jid(conn)
    return ccall((:xmpp_conn_get_bound_jid, libstrophe), Ptr{Cchar}, (Ptr{xmpp_conn_t},), conn)
end

"""
$(SIGNATURES)

Set the JID of the user that will be bound to the connection.

If any JID was previously set, it will be discarded. This should not be be used
after a connection is created. The function will make a copy of the JID string.
If the supplied JID is missing the node, SASL ANONYMOUS authentication will be
used.

# Arguments
$(_arg(_g, [:conn]))
* `jid` a full or bare JID
"""
function xmpp_conn_set_jid(conn, jid)
    return ccall((:xmpp_conn_set_jid, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, Ptr{Cchar}), conn, jid)
end

"""
$(SIGNATURES)

Set the CAfile.

# Arguments
$(_arg(_g, [:conn]))
* `path` path to a certificate file
"""
function xmpp_conn_set_cafile(conn, path)
    return ccall((:xmpp_conn_set_cafile, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, Ptr{Cchar}), conn, path)
end

"""
$(SIGNATURES)

Set the CApath.

# Arguments
$(_arg(_g, [:conn]))
* `path` path to a folder containing certificates
"""
function xmpp_conn_set_capath(conn, path)
    return ccall((:xmpp_conn_set_capath, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, Ptr{Cchar}), conn, path)
end

"""
$(SIGNATURES)

Set the Handler function which will be called when the TLS stack can't verify the CA of the server we're trying to connect to.

# Arguments
$(_arg(_g, [:conn]))
* `hndl` certfail Handler function
"""
function xmpp_conn_set_certfail_handler(conn, hndl)
    return ccall((:xmpp_conn_set_certfail_handler, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, xmpp_certfail_handler), conn, hndl)
end

"""
$(SIGNATURES)

Retrieve the peer certificate.

The returned Certificate object must be free'd by calling [`xmpp_tlscert_free`](@ref)

# Arguments
$(_arg(_g, [:conn]))

# Returns
A Strophe Certificate object
"""
function xmpp_conn_get_peer_cert(conn)
    return ccall((:xmpp_conn_get_peer_cert, libstrophe), Ptr{xmpp_tlscert_t}, (Ptr{xmpp_conn_t},), conn)
end

"""
$(SIGNATURES)

Set the Callback function which will be called when the TLS stack can't decrypt a password protected key file.

# Arguments
$(_arg(_g, [:conn]))
* `cb` The callback function that shall be called
* `userdata` An opaque data pointer that will be passed to the callback
"""
function xmpp_conn_set_password_callback(conn, cb, userdata)
    return ccall((:xmpp_conn_set_password_callback, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, xmpp_password_callback, Ptr{Cvoid}), conn, cb, userdata)
end

"""
$(SIGNATURES)

Set the number of retry attempts to decrypt a private key file.

In case the user enters the password manually it can be useful to directly retry if the decryption of the key file failed.

# Arguments
$(_arg(_g, [:conn]))
* `retires` The number of retries that should be tried
"""
function xmpp_conn_set_password_retries(conn, retries)
    return ccall((:xmpp_conn_set_password_retries, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, Cuint), conn, retries)
end

"""
$(SIGNATURES)

Retrieve the path of the key file that shall be unlocked.

This makes usually sense to be called from the [`xmpp_password_callback`](@ref).

# Arguments
$(_arg(_g, [:conn]))

# Returns
A String of the path to the key file
"""
function xmpp_conn_get_keyfile(conn)
    return ccall((:xmpp_conn_get_keyfile, libstrophe), Ptr{Cchar}, (Ptr{xmpp_conn_t},), conn)
end

"""
$(SIGNATURES)

Set the Client Certificate and Private Key or PKCS#12 encoded file that will be bound to the connection.

If any of them was previously set, it will be discarded. This should not be used after a connection is created. The function will make a copy of the strings passed in.

In case the Private Key is encrypted, a callback must be set via [`xmpp_conn_set_password_callback`](@ref) so the TLS stack can retrieve the password.

In case one wants to use a PKCS#12 encoded file, it should be passed via the cert parameter and key should be `C_NULL`. Passing a PKCS#12 file in key is deprecated.

# Arguments
$(_arg(_g, [:conn]))
* `cert` path to a certificate file or a P12 file
* `key` path to a private key file or a P12 file
"""
function xmpp_conn_set_client_cert(conn, cert, key)
    return ccall((:xmpp_conn_set_client_cert, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, Ptr{Cchar}, Ptr{Cchar}), conn, cert, key)
end

"""
$(SIGNATURES)

Get the number of xmppAddr entries in the client certificate.

# Arguments
$(_arg(_g, [:conn]))

# Returns
The number of xmppAddr entries in the client certificate
"""
function xmpp_conn_cert_xmppaddr_num(conn)
    return ccall((:xmpp_conn_cert_xmppaddr_num, libstrophe), Cuint, (Ptr{xmpp_conn_t},), conn)
end

"""
$(SIGNATURES)

Get a specific xmppAddr entry.

# Arguments
$(_arg(_g, [:conn]))
* `n` the index of the entry, starting at 0

# Returns
A string containing the xmppAddr or `C_NULL` if n is out of range
"""
function xmpp_conn_cert_xmppaddr(conn, n)
    return ccall((:xmpp_conn_cert_xmppaddr, libstrophe), Ptr{Cchar}, (Ptr{xmpp_conn_t}, Cuint), conn, n)
end

"""
$(SIGNATURES)

Get the password used for authentication of a connection.

# Arguments
$(_arg(_g, [:conn]))

# Returns
A string containing the password or `C_NULL` if it has not been set.
"""
function xmpp_conn_get_pass(conn)
    return ccall((:xmpp_conn_get_pass, libstrophe), Ptr{Cchar}, (Ptr{xmpp_conn_t},), conn)
end

"""
$(SIGNATURES)

Set the password used to authenticate the connection.

If any password was previously set, it will be discarded. The function will
make a copy of the password string.

# Arguments
$(_arg(_g, [:conn]))
* `pass` the password
"""
function xmpp_conn_set_pass(conn, pass)
    return ccall((:xmpp_conn_set_pass, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, Ptr{Cchar}), conn, pass)
end

"""
$(SIGNATURES)

Get the strophe context that the connection is associated with.

# Arguments
$(_arg(_g, [:conn]))

# Returns
A Strophe context
"""
function xmpp_conn_get_context(conn)
    return ccall((:xmpp_conn_get_context, libstrophe), Ptr{xmpp_ctx_t}, (Ptr{xmpp_conn_t},), conn)
end

"""
$(SIGNATURES)

Return whether TLS session is established or not.

# Arguments
$(_arg(_g, [:conn]))

# Returns
`true` if TLS session is established and `false` otherwise
"""
function xmpp_conn_is_secured(conn)
    return ccall((:xmpp_conn_is_secured, libstrophe), Bool, (Ptr{xmpp_conn_t},), conn)
end

"""
$(SIGNATURES)

Register sockopt callback Set function to be called when a new socket is created
to allow setting socket options before connection is started.

If the connection is already connected, this callback will be called immediately.

To set options that can only be applied to disconnected sockets, the callback
must be registered before connecting.

# Arguments
$(_arg(_g, [:conn]))
"""
function xmpp_conn_set_sockopt_callback(conn, callback)
    return ccall((:xmpp_conn_set_sockopt_callback, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, xmpp_sockopt_callback), conn, callback)
end

"""
$(SIGNATURES)

# Arguments
$(_arg(_g, [:conn]))

# Returns
`true` if connection is in connecting state and `false` otherwise
"""
function xmpp_conn_is_connecting(conn)
    return ccall((:xmpp_conn_is_connecting, libstrophe), Bool, (Ptr{xmpp_conn_t},), conn)
end

"""
$(SIGNATURES)

# Arguments
$(_arg(_g, [:conn]))

# Returns
`true` if connection is established and `false` otherwise
"""
function xmpp_conn_is_connected(conn)
    return ccall((:xmpp_conn_is_connected, libstrophe), Bool, (Ptr{xmpp_conn_t},), conn)
end

"""
$(SIGNATURES)

# Arguments
$(_arg(_g, [:conn]))

# Returns
`true` if connection is in disconnected state and `false` otherwise
"""
function xmpp_conn_is_disconnected(conn)
    return ccall((:xmpp_conn_is_disconnected, libstrophe), Bool, (Ptr{xmpp_conn_t},), conn)
end

"""
$(SIGNATURES)

# Arguments
$(_arg(_g, [:conn]))

# Returns
The number of entries in the send queue
"""
function xmpp_conn_send_queue_len(conn)
    return ccall((:xmpp_conn_send_queue_len, libstrophe), Cint, (Ptr{xmpp_conn_t},), conn)
end

"""
Enumeration members:
* `XMPP_QUEUE_OLDEST`
* `XMPP_QUEUE_YOUNGEST`
"""
@enum xmpp_queue_element_t::Int32 begin
    XMPP_QUEUE_OLDEST = -1
    XMPP_QUEUE_YOUNGEST = -2
end

"""
$(SIGNATURES)

Drop an element of the send queue.

This can be used to manage the send queue in case a server isn't fast enough in
processing the elements you're trying to send or your outgoing bandwidth isn't
fast enough to transfer everything you want to send out.

# Arguments
$(_arg(_g, [:conn]))
* `which` the element that shall be removed. See [`xmpp_queue_element_t`](@ref)

# Returns
The rendered stanza. The pointer returned has to be free'd by the caller
of this function.
"""
function xmpp_conn_send_queue_drop_element(conn, which)
    return ccall((:xmpp_conn_send_queue_drop_element, libstrophe), Ptr{Cchar}, (Ptr{xmpp_conn_t}, xmpp_queue_element_t), conn, which)
end

"""
$(SIGNATURES)

# Arguments
$(_arg(_g, [:conn]))
* `sm_state` A Stream Management state returned from a call to
    [`xmpp_conn_get_sm_state`](@ref)

# Returns
`XMPP_EOK` (0) on success or a number less than 0 on failure.
"""
function xmpp_conn_set_sm_state(conn, sm_state)
    return ccall((:xmpp_conn_set_sm_state, libstrophe), Cint, (Ptr{xmpp_conn_t}, Ptr{xmpp_sm_state_t}), conn, sm_state)
end

"""
$(SIGNATURES)

This returns the Stream Management state of a connection object after it has
been disconnected.

One can then initialise a fresh connection object and set this Stream Management
state by calling [`xmpp_conn_set_sm_state`](@ref)

In case one wants to dispose of the state w/o setting it into a fresh connection
object, one can call [`xmpp_free_sm_state`](@ref)

After calling this function to retrieve the state, only call one of the other two.

# Arguments
$(_arg(_g, [:conn]))

# Returns
The Stream Management state of the connection or `C_NULL` on error
"""
function xmpp_conn_get_sm_state(conn)
    return ccall((:xmpp_conn_get_sm_state, libstrophe), Ptr{xmpp_sm_state_t}, (Ptr{xmpp_conn_t},), conn)
end

# typedef void ( * xmpp_sm_callback ) ( xmpp_conn_t * conn , void * ctx , const unsigned char * sm_state , size_t sm_state_len )
"""
The function which will be called when Strophe updates its internal SM state.

Please note that you have to create a copy of the buffer, since the library will free the buffer right after return of the callback function.

# Arguments
$(_arg(_g, [:conn, :ctx]))
* `sm_state`: A pointer to a buffer containing the serialized SM state.
* `sm_state_len`: The length of `sm_state`.
# Returns
0 on success, -1 on error
"""
const xmpp_sm_callback = Ptr{Cvoid}

"""
This sets the Stream Management callback function

After setting this API, the library will call the given callback function
each time when the internal SM state is updated.

This can be used in conjunction with [`xmpp_conn_restore_sm_state`](@ref) to
e.g. implement a mechanism that retains an SM state over potential
application terminations.

# Arguments
* `conn`: The Strophe connection object this callback originates from.
* `cb`: a callback function or `C_NULL` to disable
* `ctx`: The `ctx` pointer as passed on invocation of the callback function
"""
function xmpp_conn_set_sm_callback(conn, cb, ctx)
    return ccall((:xmpp_conn_set_sm_callback, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, xmpp_sm_callback, Ptr{Cvoid}), conn, cb, ctx)
end

"""
This restores the serialized Stream Management state

After setting this API, the library will call the given callback function
each time when the internal SM state is updated.

This can be used in conjunction with [`xmpp_conn_set_sm_state`](@ref) to
e.g. implement a mechanism that retains an SM state over potential
application terminations.

# Arguments
$(_arg(_g, [:conn]))
* `sm_state`: a buffer as passed to the SM callback
* `sm_state_len`: the length of `sm_state`
# Returns
0 on success, -1 on error
"""
function xmpp_conn_restore_sm_state(conn, sm_state, sm_state_len)
    return ccall((:xmpp_conn_restore_sm_state, libstrophe), Cint, (Ptr{xmpp_conn_t}, Ptr{Cuchar}, Csize_t), conn, sm_state, sm_state_len)
end

"""
$(SIGNATURES)

c.f. [`xmpp_conn_get_sm_state`](@ref) for usage documentation

# Arguments
* `sm_state` a Stream Management state returned from a call to
    [`xmpp_conn_get_sm_state`](@ref)
"""
function xmpp_free_sm_state(sm_state)
    return ccall((:xmpp_free_sm_state, libstrophe), Cvoid, (Ptr{xmpp_sm_state_t},), sm_state)
end

"""
$(SIGNATURES)

Initiate a connection to the XMPP server.

This function returns immediately after starting the connection process to the
XMPP server, and notifications of connection state changes will be sent to the
callback function. The domain and port to connect to are usually determined by
an SRV lookup for the xmpp-client service at the domain specified in the JID.
If SRV lookup fails, altdomain and altport will be used instead if specified.

# Arguments
$(_arg(_g, [:conn]))
* `altdomain` a string with domain to use if SRV lookup fails. If this is `C_NULL`,
    the domain from the JID will be used.
* `altport` an integer port number to use if SRV lookup fails. If this is 0,
    the default port will be assumed.
* `callback` a [`xmpp_conn_handler`](@ref) callback function that will receive
    notifications of connection status
* `userdata` an opaque data pointer that will be passed to the callback

# Returns
[`XMPP_EOK`](@ref) (0) on success or a number less than 0 on failure
"""
function xmpp_connect_client(conn, altdomain, altport, callback, userdata)
    return ccall((:xmpp_connect_client, libstrophe), Cint, (Ptr{xmpp_conn_t}, Ptr{Cchar}, Cushort, xmpp_conn_handler, Ptr{Cvoid}), conn, altdomain, altport, callback, userdata)
end

"""
$(SIGNATURES)

Initiate a component connection to server.

This function returns immediately after starting the connection process to the
XMPP server, and notifications of connection state changes will be sent to the
internal callback function that will set up handler for the component handshake
as defined in [XEP-0114](https://xmpp.org/extensions/xep-0114.html). The domain
and port to connect to must be provided in this case as the JID provided to the
call serves as component identifier to the server and is not subject to DNS
resolution.

# Arguments
$(_arg(_g, [:conn]))
* `server` a string with domain to use directly as the domain can't be extracted
    from the component name/JID. If this is not set, the call will fail. the
    domain from the JID will be used.
* `port` an integer port number to use to connect to server expecting an external
    component. If this is 0, the port 5347 will be assumed. the default port will
    be assumed.
* `callback` a [`xmpp_conn_handler`](@ref) callback function that will receive
    notifications of connection status
* `userdata` an opaque data pointer that will be passed to the callback

# Returns
[`XMPP_EOK`](@ref) (0) on success or a number less than 0 on failure
"""
function xmpp_connect_component(conn, server, port, callback, userdata)
    return ccall((:xmpp_connect_component, libstrophe), Cint, (Ptr{xmpp_conn_t}, Ptr{Cchar}, Cushort, xmpp_conn_handler, Ptr{Cvoid}), conn, server, port, callback, userdata)
end

"""
$(SIGNATURES)

Initiate a raw connection to the XMPP server.

Arguments and behaviour of the function are similar to [`xmpp_connect_client`](@ref),
but it skips authentication process. In opposite to [`xmpp_connect_client`](@ref)
during connection process two events are generated instead of one. User's callback
is called with event `XMPP_CONN_RAW_CONNECT` when the TCP connection with the server
is established. At this point user might want to open an XMPP stream with
[`xmpp_conn_open_stream`](@ref) or establish TLS session with
[`xmpp_conn_tls_start`](@ref). Event `XMPP_CONN_CONNECT` is generated when the
XMPP stream is opened successfully and user may send stanzas over the connection.

This function doesn't use password nor node part of a jid. Therefore, the only
required configuration is a domain (or full jid) passed via [`xmpp_conn_set_jid`](@ref).

# Arguments
$(_arg(_g, [:conn]))
* `altdomain` a string with domain to use if SRV lookup fails. If this is `C_NULL`,
    the domain from the JID will be used.
* `altport` an integer port number to use if SRV lookup fails. If this is 0,
    the default port will be assumed.
* `callback` a [`xmpp_conn_handler`](@ref) callback function that will receive
    notifications of connection status
* `userdata` an opaque data pointer that will be passed to the callback

# Returns
[`XMPP_EOK`](@ref) (0) on success or a number less than 0 on failure
"""
function xmpp_connect_raw(conn, altdomain, altport, callback, userdata)
    return ccall((:xmpp_connect_raw, libstrophe), Cint, (Ptr{xmpp_conn_t}, Ptr{Cchar}, Cushort, xmpp_conn_handler, Ptr{Cvoid}), conn, altdomain, altport, callback, userdata)
end

"""
$(SIGNATURES)

Send the default opening stream tag.

The default tag is the one sent by [`xmpp_connect_client`](@ref). User's
connection handler is called with event `XMPP_CONN_CONNECT` when server replies
with its opening tag.

# Arguments
$(_arg(_g, [:conn]))

# Returns
[`XMPP_EOK`](@ref) (0) on success or a number less than 0 on failure

!!! note
    The connection must be connected with [`xmpp_connect_raw`](@ref).
"""
function xmpp_conn_open_stream_default(conn)
    return ccall((:xmpp_conn_open_stream_default, libstrophe), Cint, (Ptr{xmpp_conn_t},), conn)
end

"""
$(SIGNATURES)

Send an opening stream tag.

User's connection handler is called with event `XMPP_CONN_CONNECT` when server
replies with its opening tag.

# Arguments
$(_arg(_g, [:conn]))
* `attributes` Array of strings in format: even index points to an attribute
   name and odd index points to its value
* `attributes_len` Number of elements in the attributes array, it should be
    number of attributes multiplied by 2

# Returns
[`XMPP_EOK`](@ref) (0) on success or a number less than 0 on failure

!!! note
    The connection must be connected with [`xmpp_connect_raw`](@ref).
"""
function xmpp_conn_open_stream(conn, attributes, attributes_len)
    return ccall((:xmpp_conn_open_stream, libstrophe), Cint, (Ptr{xmpp_conn_t}, Ptr{Ptr{Cchar}}, Csize_t), conn, attributes, attributes_len)
end

"""
$(SIGNATURES)

Start synchronous TLS handshake with the server.

# Arguments
$(_arg(_g, [:conn]))

# Returns
[`XMPP_EOK`](@ref) (0) on success or a number less than 0 on failure
"""
function xmpp_conn_tls_start(conn)
    return ccall((:xmpp_conn_tls_start, libstrophe), Cint, (Ptr{xmpp_conn_t},), conn)
end

"""
$(SIGNATURES)

Initiate termination of the connection to the XMPP server.

This function starts the disconnection sequence by sending `</stream:stream>`
to the XMPP server. This function will do nothing if the connection state is
different from `CONNECTING` or `CONNECTED`.

# Arguments
$(_arg(_g, [:conn]))
"""
function xmpp_disconnect(conn)
    return ccall((:xmpp_disconnect, libstrophe), Cvoid, (Ptr{xmpp_conn_t},), conn)
end

"""
$(SIGNATURES)

Send an XML stanza to the XMPP server.

This is the main way to send data to the XMPP server. The function will
terminate without action if the connection state is not `CONNECTED`.

# Arguments
$(_arg(_g, [:conn]))
* `stanza` a Strophe stanza object
"""
function xmpp_send(conn, stanza)
    return ccall((:xmpp_send, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, Ptr{xmpp_stanza_t}), conn, stanza)
end

"""
$(SIGNATURES)

Send raw bytes to the XMPP server.

This function is a convenience function to send raw bytes to the XMPP server.
It is used primarily by `xmpp_send_raw_string`. This function should be used
with care as it does not validate the bytes and invalid data may result in
stream termination by the XMPP server.

# Arguments
$(_arg(_g, [:conn]))
* `data` a buffer of raw bytes
* `len` the length of the data in the buffer
"""
function xmpp_send_raw(conn, data, len)
    return ccall((:xmpp_send_raw, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, Ptr{Cchar}, Csize_t), conn, data, len)
end

"""
```c
typedef int ( * xmpp_timed_handler ) ( xmpp_conn_t * conn , void * userdata )
```
"""
const xmpp_timed_handler = Ptr{Cvoid}

"""
$(SIGNATURES)

Add a timed handler.

The handler will fire for the first time once the period has elapsed, and
continue firing regularly after that. Strophe will try its best to fire handlers
as close to the period times as it can, but accuracy will vary depending on the
resolution of the event loop.

If the handler function returns true, it will be kept, and if it returns false,
it will be deleted from the list of handlers.

# Arguments
$(_arg(_g, [:conn]))
* `handler` a function pointer to a timed handler
* `period` the time in milliseconds between firings
* `userdata` an opaque data pointer that will be passed to the handler
"""
function xmpp_timed_handler_add(conn, handler, period, userdata)
    return ccall((:xmpp_timed_handler_add, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, xmpp_timed_handler, Culong, Ptr{Cvoid}), conn, handler, period, userdata)
end

"""
$(SIGNATURES)

Delete a timed handler.

# Arguments
$(_arg(_g, [:conn]))
* `handler` function pointer to the handler
"""
function xmpp_timed_handler_delete(conn, handler)
    return ccall((:xmpp_timed_handler_delete, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, xmpp_timed_handler), conn, handler)
end

"""
```c
typedef int ( * xmpp_global_timed_handler ) ( xmpp_ctx_t * ctx , void * userdata )
```
"""
const xmpp_global_timed_handler = Ptr{Cvoid}

"""
$(SIGNATURES)

Add a global timed handler.

The handler will fire for the first time once the period has elapsed, and
continue firing regularly after that. Strophe will try its best to fire handlers
as close to the period times as it can, but accuracy will vary depending on the
resolution of the event loop.

The main difference between global and ordinary handlers:
* Ordinary handler is related to a connection, fires only when the connection
  is in connected state and is removed once the connection is destroyed.
* Global handler fires regardless of connections state and is related to a
  Strophe context.

The handler is executed in context of the respective event loop.

If the handler function returns 1, it will be kept, and if it returns 0, it
will be deleted from the list of handlers.

Notice, the same handler pointer may be added multiple times with different
userdata pointers. However, [`xmpp_global_timed_handler_delete`](@ref) deletes
all occurrences.

# Arguments
$(_arg(_g, [:ctx]))
* `handler` a function pointer to a timed handler
* `period` the time in milliseconds between firings
* `userdata` an opaque data pointer that will be passed to the handler
"""
function xmpp_global_timed_handler_add(ctx, handler, period, userdata)
    return ccall((:xmpp_global_timed_handler_add, libstrophe), Cvoid, (Ptr{xmpp_ctx_t}, xmpp_global_timed_handler, Culong, Ptr{Cvoid}), ctx, handler, period, userdata)
end

"""
$(SIGNATURES)

Delete a global timed handler.

# Arguments
$(_arg(_g, [:ctx]))
* `handler` function pointer to the handler
"""
function xmpp_global_timed_handler_delete(ctx, handler)
    return ccall((:xmpp_global_timed_handler_delete, libstrophe), Cvoid, (Ptr{xmpp_ctx_t}, xmpp_global_timed_handler), ctx, handler)
end

"""
```c
typedef int ( * xmpp_handler ) ( xmpp_conn_t * conn , xmpp_stanza_t * stanza , void * userdata )
```
"""
const xmpp_handler = Ptr{Cvoid}

"""
$(SIGNATURES)

Add a stanza handler.

This function is used to add a stanza handler to a connection. The handler will
be called when the any of the filters match. The name filter matches to the top
level stanza name. The type filter matches the 'type' attribute of the top level
stanza. The ns filter matches the namespace ('xmlns' attribute) of either the
top level stanza or any of it's immediate children (this allows you do handle
specific `<iq/>` stanzas based on the `<query/>` child namespace.

If the handler function returns 1, it will be kept, and if it returns 0,
it will be deleted from the list of handlers.

# Arguments
$(_arg(_g, [:conn]))
* `handler` a function pointer to a stanza handler
* `ns` a string with the namespace to match
* `name` a string with the stanza name to match
* `type` a string with the 'type' attribute to match
* `userdata` an opaque data pointer that will be passed to the handler
"""
function xmpp_handler_add(conn, handler, ns, name, type, userdata)
    return ccall((:xmpp_handler_add, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, xmpp_handler, Ptr{Cchar}, Ptr{Cchar}, Ptr{Cchar}, Ptr{Cvoid}), conn, handler, ns, name, type, userdata)
end

"""
$(SIGNATURES)

Delete a stanza handler.

# Arguments
$(_arg(_g, [:conn]))
* `handler` a function pointer to a stanza handler
"""
function xmpp_handler_delete(conn, handler)
    return ccall((:xmpp_handler_delete, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, xmpp_handler), conn, handler)
end

"""
$(SIGNATURES)

Add an id based stanza handler.

This function adds a stanza handler for an `<iq/>` stanza of type 'result' or
'error' with a specific id attribute. This can be used to handle responses to
specific `<iq/>`s.

If the handler function returns true, it will be kept, and if it returns false,
it will be deleted from the list of handlers.

# Arguments
$(_arg(_g, [:conn]))
* `handler` a function pointer to a stanza handler
* `id` a string with the id
* `userdata` an opaque data pointer that will be passed to the handler
"""
function xmpp_id_handler_add(conn, handler, id, userdata)
    return ccall((:xmpp_id_handler_add, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, xmpp_handler, Ptr{Cchar}, Ptr{Cvoid}), conn, handler, id, userdata)
end

"""
$(SIGNATURES)

Delete an id based stanza handler.

# Arguments
$(_arg(_g, [:conn]))
* `handler` a function pointer to a stanza handler
* `id` a string containing the id the handler is for
"""
function xmpp_id_handler_delete(conn, handler, id)
    return ccall((:xmpp_id_handler_delete, libstrophe), Cvoid, (Ptr{xmpp_conn_t}, xmpp_handler, Ptr{Cchar}), conn, handler, id)
end

"""
$(SIGNATURES)

Create a stanza object.

This function allocates and initializes a blank stanza object. The stanza will have a reference count of one, so the caller does not need to clone it.

# Arguments
$(_arg(_g, [:ctx]))

# Returns
A stanza object
"""
function xmpp_stanza_new(ctx)
    return ccall((:xmpp_stanza_new, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_ctx_t},), ctx)
end

"""
$(SIGNATURES)

Create a stanza object from the string.

This function allocates and initializes a stanza object which represents stanza
located in the string. The stanza will have a reference count of one, so the
caller does not need to clone it.

# Arguments
$(_arg(_g, [:ctx]))
* `str` stanza in `NULL` terminated string representation

# Returns
A stanza object or `C_NULL` on an error
"""
function xmpp_stanza_new_from_string(ctx, str)
    return ccall((:xmpp_stanza_new_from_string, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_ctx_t}, Ptr{Cchar}), ctx, str)
end

"""
$(SIGNATURES)

Clone a stanza object.

This function increments the reference count of the stanza object.

# Arguments
* `stanza` a Strophe stanza object

# Returns
The stanza object with it's reference count incremented
"""
function xmpp_stanza_clone(stanza)
    return ccall((:xmpp_stanza_clone, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_stanza_t},), stanza)
end

"""
$(SIGNATURES)

Copy a stanza and its children.

This function copies a stanza along with all its children and returns the new stanza and children with a reference count of 1. The returned stanza will have no parent and no siblings. This function is useful for extracting a child stanza for inclusion in another tree.

# Arguments
$(_arg(_g, [:ctx]))

# Returns
A new stanza object
"""
function xmpp_stanza_copy(stanza)
    return ccall((:xmpp_stanza_copy, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_stanza_t},), stanza)
end

"""
$(SIGNATURES)

Release a stanza object and all of its children.

This function releases a stanza object and potentially all of its children, which may cause the object(s) to be freed.

# Arguments
* `stanza` a Strophe stanza object

# Returns
`true` if the object was freed and `false` otherwise
"""
function xmpp_stanza_release(stanza)
    return ccall((:xmpp_stanza_release, libstrophe), Bool, (Ptr{xmpp_stanza_t},), stanza)
end

function xmpp_stanza_get_context(stanza)
    return ccall((:xmpp_stanza_get_context, libstrophe), Ptr{xmpp_ctx_t}, (Ptr{xmpp_stanza_t},), stanza)
end

"""
$(SIGNATURES)

Determine if a stanza is a text node.

# Arguments
* `stanza` a Strophe stanza object

# Returns
`true` if the stanza is a text node, `false` otherwise
"""
function xmpp_stanza_is_text(stanza)
    return ccall((:xmpp_stanza_is_text, libstrophe), Bool, (Ptr{xmpp_stanza_t},), stanza)
end

"""
$(SIGNATURES)

Determine if a stanza is a tag node.

# Arguments
* `stanza` a Strophe stanza object

# Returns
`true` if the stanza is a tag node, `false` otherwise
"""
function xmpp_stanza_is_tag(stanza)
    return ccall((:xmpp_stanza_is_tag, libstrophe), Cint, (Ptr{xmpp_stanza_t},), stanza)
end

"""
$(SIGNATURES)

Render a stanza object to text.

This function renders a given stanza object, along with its children, to text.
The text is returned in an allocated, null-terminated buffer. It starts by
allocating a 1024 byte buffer and reallocates more memory if that is not large
enough.

# Arguments
* `stanza` a Strophe stanza object
* `buf` a reference to a string pointer
* `buflen` a reference to a `size_t`

# Returns
0 on success ([`XMPP_EOK`](@ref)), and a number less than 0 on failure
([`XMPP_EMEM`](@ref), [`XMPP_EINVOP`](@ref))
"""
function xmpp_stanza_to_text(stanza, buf, buflen)
    return ccall((:xmpp_stanza_to_text, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{Ptr{Cchar}}, Ptr{Csize_t}), stanza, buf, buflen)
end

"""
$(SIGNATURES)

Get the list of children.

This function returns the first child of the stanza object. The rest of the
children can be obtained by calling [`xmpp_stanza_get_next`](@ref) to iterate
over the siblings.

# Arguments
* `stanza` a Strophe stanza object

# Returns
The first child stanza or `C_NULL` if there are no children
"""
function xmpp_stanza_get_children(stanza)
    return ccall((:xmpp_stanza_get_children, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_stanza_t},), stanza)
end

"""
$(SIGNATURES)

Get the first child of stanza with name.

This function searches all the immediate children of stanza for a child stanza
that matches the name. The first matching child is returned.

# Arguments
* `stanza` a Strophe stanza object
* `name` a string with the name to match

# Returns
The matching child stanza object or `C_NULL` if no match was found
"""
function xmpp_stanza_get_child_by_name(stanza, name)
    return ccall((:xmpp_stanza_get_child_by_name, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_stanza_t}, Ptr{Cchar}), stanza, name)
end

"""
$(SIGNATURES)

Get the first child of a stanza with a given namespace.

This function searches all the immediate children of a stanza for a child stanza
that matches the namespace provided. The first matching child is returned.

# Arguments
* `stanza` a Strophe stanza object
* `ns` a string with the namespace to match

# Returns
The matching child stanza object or `C_NULL` if no match was found
"""
function xmpp_stanza_get_child_by_ns(stanza, ns)
    return ccall((:xmpp_stanza_get_child_by_ns, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_stanza_t}, Ptr{Cchar}), stanza, ns)
end

"""
$(SIGNATURES)

Get the first child of stanza with name and a given namespace.

This function searches all the immediate children of stanza for a child stanza
that matches the name and namespace provided. The first matching child is returned.

# Arguments
* `stanza` a Strophe stanza object
* `name` a string with the name to match
* `ns`	a string with the namespace to match

# Returns
The matching child stanza object or `C_NULL` if no match was found
"""
function xmpp_stanza_get_child_by_name_and_ns(stanza, name, ns)
    return ccall((:xmpp_stanza_get_child_by_name_and_ns, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_stanza_t}, Ptr{Cchar}, Ptr{Cchar}), stanza, name, ns)
end

"""
$(SIGNATURES)

Get the next sibling of a stanza.

# Arguments
* `stanza` a Strophe stanza object

# Returns
The next sibling stanza or `C_NULL` if there are no more siblings
"""
function xmpp_stanza_get_next(stanza)
    return ccall((:xmpp_stanza_get_next, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_stanza_t},), stanza)
end

"""
$(SIGNATURES)

Add a child stanza to a stanza object.

This function clones the child and appends it to the stanza object's children.

# Arguments
* `stanza` a Strophe stanza object
* `child` the child stanza object

# Returns
[`XMPP_EOK`](@ref) (0) on success or a number less than 0 on failure
"""
function xmpp_stanza_add_child(stanza, child)
    return ccall((:xmpp_stanza_add_child, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{xmpp_stanza_t}), stanza, child)
end

"""
$(SIGNATURES)

Add a child stanza to a stanza object.

If `do_clone` is 1, user keeps reference to the child stanza and must call
[`xmpp_stanza_release`](@ref) to release the reference. If `do_clone` is 0,
user transfers ownership and must not neither call [`xmpp_stanza_release`](@ref)
for the child stanza nor use it.

# Arguments
* `stanza` a Strophe stanza object
* `child` the child stanza object
* `do_clone` 1 to increase ref count of child (default for [`xmpp_stanza_add_child`](@ref))

# Returns
[`XMPP_EOK`](@ref) (0) on success or a number less than 0 on failure
"""
function xmpp_stanza_add_child_ex(stanza, child, do_clone)
    return ccall((:xmpp_stanza_add_child_ex, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{xmpp_stanza_t}, Cint), stanza, child, do_clone)
end

"""
$(SIGNATURES)

Get an attribute from a stanza.

This function returns a pointer to the attribute value. If the caller wishes to
save this value it must make its own copy.

# Arguments
* `stanza` a Strophe stanza object
* `name` a string containing attribute name

# Returns
A string with the attribute value or `C_NULL` on an error
"""
function xmpp_stanza_get_attribute(stanza, name)
    return ccall((:xmpp_stanza_get_attribute, libstrophe), Ptr{Cchar}, (Ptr{xmpp_stanza_t}, Ptr{Cchar}), stanza, name)
end

"""
$(SIGNATURES)

Count the attributes in a stanza object.

# Arguments
* `stanza` a Strophe stanza object

# Returns
The number of attributes for the stanza object
"""
function xmpp_stanza_get_attribute_count(stanza)
    return ccall((:xmpp_stanza_get_attribute_count, libstrophe), Cint, (Ptr{xmpp_stanza_t},), stanza)
end

"""
$(SIGNATURES)

Get all attributes for a stanza object.

This function populates the array with attributes from the stanza. The `attr`
array will be in the format: `attr[i] = attribute name`, `attr[i+1] = attribute value`.

# Arguments
* `stanza` a Strophe stanza object
* `attr` the string array to populate
* `attrlen` the size of the array

# Returns
The number of slots used in the array, which will be 2 times the number
of attributes in the stanza
"""
function xmpp_stanza_get_attributes(stanza, attr, attrlen)
    return ccall((:xmpp_stanza_get_attributes, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{Ptr{Cchar}}, Cint), stanza, attr, attrlen)
end

"""
$(SIGNATURES)

Get the text data for a text stanza.

This function copies the text data from a stanza and returns the new allocated
string. The caller is responsible for freeing this string with [`xmpp_free`](@ref).

# Arguments
* `stanza` a Strophe stanza object

# Returns
An allocated string with the text data
"""
function xmpp_stanza_get_text(stanza)
    return ccall((:xmpp_stanza_get_text, libstrophe), Ptr{Cchar}, (Ptr{xmpp_stanza_t},), stanza)
end

"""
$(SIGNATURES)

Get the text data pointer for a text stanza.

This function copies returns the raw pointer to the text data in the stanza.
This should only be used in very special cases where the caller needs to
translate the datatype as this will save a double allocation. The caller should
not hold onto this pointer, and is responsible for allocating a copy if it needs
one.

# Arguments
* `stanza` a Strophe stanza object

# Returns
An string pointer to the data or `C_NULL`
"""
function xmpp_stanza_get_text_ptr(stanza)
    return ccall((:xmpp_stanza_get_text_ptr, libstrophe), Ptr{Cchar}, (Ptr{xmpp_stanza_t},), stanza)
end

"""
$(SIGNATURES)

Get the stanza name.

This function returns a pointer to the stanza name. If the caller needs to store this data, it must make a copy.

# Arguments
* `stanza` a Strophe stanza object

# Returns
A string with the stanza name
"""
function xmpp_stanza_get_name(stanza)
    return ccall((:xmpp_stanza_get_name, libstrophe), Ptr{Cchar}, (Ptr{xmpp_stanza_t},), stanza)
end

"""
$(SIGNATURES)

Set an attribute for a stanza object.

# Arguments
* `stanza` a Strophe stanza object
* `key` a string with the attribute name
* `value` a string with the attribute value

# Returns
[`XMPP_EOK`](@ref) (0) on success or a number less than 0 on failure
"""
function xmpp_stanza_set_attribute(stanza, key, value)
    return ccall((:xmpp_stanza_set_attribute, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{Cchar}, Ptr{Cchar}), stanza, key, value)
end

"""
$(SIGNATURES)

Set the name of a stanza.

# Arguments
* `stanza` a Strophe stanza object
* `name` a string with the name of the stanza

# Returns
0 on success ([`XMPP_EOK`](@ref)), and a number less than 0 on failure
([`XMPP_EMEM`](@ref), [`XMPP_EINVOP`](@ref))
"""
function xmpp_stanza_set_name(stanza, name)
    return ccall((:xmpp_stanza_set_name, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{Cchar}), stanza, name)
end

"""
$(SIGNATURES)

Set the text data for a text stanza.

This function copies the text given and sets the stanza object's text to it.
Attempting to use this function on a stanza that has a name will fail with
[`XMPP_EINVOP`](@ref). This function takes the text as a null-terminated string.

# Arguments
* `stanza` a Strophe stanza object
* `text` a string with the text

# Returns
0 on success ([`XMPP_EOK`](@ref)), and a number less than 0 on failure
"""
function xmpp_stanza_set_text(stanza, text)
    return ccall((:xmpp_stanza_set_text, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{Cchar}), stanza, text)
end

"""
$(SIGNATURES)

Set the text data for a text stanza.

This function copies the text given and sets the stanza object's text to it.
Attempting to use this function on a stanza that has a name will fail with
[`XMPP_EINVOP`](@ref). This function takes the text as buffer and a length as opposed to
a null-terminated string.

# Arguments
* `stanza` a Strophe stanza object
* `text` a buffer with the text
* `size` the length of the text

# Returns
0 on success ([`XMPP_EOK`](@ref)), and a number less than 0 on failure
"""
function xmpp_stanza_set_text_with_size(stanza, text, size)
    return ccall((:xmpp_stanza_set_text_with_size, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{Cchar}, Csize_t), stanza, text, size)
end

"""
$(SIGNATURES)

Delete an attribute from a stanza.

# Arguments
* `stanza` a Strophe stanza object
* `name` a string containing attribute name

# Returns
0 on success ([`XMPP_EOK`](@ref)), and a number less than 0 on failure
"""
function xmpp_stanza_del_attribute(stanza, name)
    return ccall((:xmpp_stanza_del_attribute, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{Cchar}), stanza, name)
end

"""
$(SIGNATURES)

Get the namespace attribute of the stanza object.

This is a convenience function equivalent to: `xmpp_stanza_get_attribute(stanza, "xmlns")`

# Arguments
* `stanza` a Strophe stanza object

# Returns
A string with the 'xmlns' attribute value
"""
function xmpp_stanza_get_ns(stanza)
    return ccall((:xmpp_stanza_get_ns, libstrophe), Ptr{Cchar}, (Ptr{xmpp_stanza_t},), stanza)
end

"""
$(SIGNATURES)

Get the 'type' attribute of the stanza object.

This is a convenience function equivalent to: `xmpp_stanza_get_attribute(stanza, "type")`

# Arguments
* `stanza` a Strophe stanza object

# Returns
A string with the 'type' attribute value
"""
function xmpp_stanza_get_type(stanza)
    return ccall((:xmpp_stanza_get_type, libstrophe), Ptr{Cchar}, (Ptr{xmpp_stanza_t},), stanza)
end

"""
$(SIGNATURES)

Get the 'id' attribute of the stanza object.

This is a convenience function equivalent to: `xmpp_stanza_get_attribute(stanza, "id")`

# Arguments
* `stanza` a Strophe stanza object

# Returns
A string with the 'id' attribute value
"""
function xmpp_stanza_get_id(stanza)
    return ccall((:xmpp_stanza_get_id, libstrophe), Ptr{Cchar}, (Ptr{xmpp_stanza_t},), stanza)
end

"""
$(SIGNATURES)

Get the 'to' attribute of the stanza object.

This is a convenience function equivalent to: `xmpp_stanza_get_attribute(stanza, "to")`

# Arguments
* `stanza` a Strophe stanza object

# Returns
A string with the 'to' attribute value
"""
function xmpp_stanza_get_to(stanza)
    return ccall((:xmpp_stanza_get_to, libstrophe), Ptr{Cchar}, (Ptr{xmpp_stanza_t},), stanza)
end

"""
$(SIGNATURES)

Get the 'from' attribute of the stanza object.

This is a convenience function equivalent to: `xmpp_stanza_get_attribute(stanza, "from")`

# Arguments
* `stanza` a Strophe stanza object

# Returns
A string with the 'from' attribute value
"""
function xmpp_stanza_get_from(stanza)
    return ccall((:xmpp_stanza_get_from, libstrophe), Ptr{Cchar}, (Ptr{xmpp_stanza_t},), stanza)
end

"""
$(SIGNATURES)

Set the stanza namespace.

This is a convenience function equivalent to calling: `xmpp_stanza_set_attribute(stanza, "xmlns", ns)`

# Arguments
* `stanza` a Strophe stanza object
* `ns` a string with the namespace

# Returns
[`XMPP_EOK`](@ref) (0) on success or a number less than 0 on failure
"""
function xmpp_stanza_set_ns(stanza, ns)
    return ccall((:xmpp_stanza_set_ns, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{Cchar}), stanza, ns)
end

"""
$(SIGNATURES)

Set the 'id' attribute of a stanza.

This is a convenience function for: `xmpp_stanza_set_attribute(stanza, 'id', id)`

# Arguments
* `stanza` a Strophe stanza object
* `id` a string containing the 'id' value

# Returns
[`XMPP_EOK`](@ref) (0) on success or a number less than 0 on failure
"""
function xmpp_stanza_set_id(stanza, id)
    return ccall((:xmpp_stanza_set_id, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{Cchar}), stanza, id)
end

"""
$(SIGNATURES)

Set the 'type' attribute of a stanza.

This is a convenience function for: `xmpp_stanza_set_attribute(stanza, 'type', type)`

# Arguments
* `stanza` a Strophe stanza object
* `type` a string containing the 'type' value

# Returns
[`XMPP_EOK`](@ref) (0) on success or a number less than 0 on failure
"""
function xmpp_stanza_set_type(stanza, type)
    return ccall((:xmpp_stanza_set_type, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{Cchar}), stanza, type)
end

"""
$(SIGNATURES)

Set the 'to' attribute of a stanza.

This is a convenience function for: `xmpp_stanza_set_attribute(stanza, 'to', to)`

# Arguments
* `stanza` a Strophe stanza object
* `to` a string containing the 'to' value

# Returns
[`XMPP_EOK`](@ref) (0) on success or a number less than 0 on failure
"""
function xmpp_stanza_set_to(stanza, to)
    return ccall((:xmpp_stanza_set_to, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{Cchar}), stanza, to)
end

"""
$(SIGNATURES)

Set the 'from' attribute of a stanza.

This is a convenience function for: `xmpp_stanza_set_attribute(stanza, 'from', from)`

# Arguments
* `stanza` a Strophe stanza object
* `from` a string containing the 'from' value

# Returns
[`XMPP_EOK`](@ref) (0) on success or a number less than 0 on failure
"""
function xmpp_stanza_set_from(stanza, from)
    return ccall((:xmpp_stanza_set_from, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{Cchar}), stanza, from)
end

"""
$(SIGNATURES)

Create a stanza object in reply to another.

This function makes a copy of a stanza object with the attribute "to" set its
original "from". The stanza will have a reference count of one, so the caller
does not need to clone it.

# Arguments
* `stanza` a Strophe stanza object

# Returns
A new Strophe stanza object
"""
function xmpp_stanza_reply(stanza)
    return ccall((:xmpp_stanza_reply, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_stanza_t},), stanza)
end

"""
$(SIGNATURES)

Create an error stanza in reply to the provided stanza.

Check https://tools.ietf.org/html/rfc6120#section-8.3 for details.

# Arguments
* `stanza` a Strophe stanza object
* `error_type` type attribute in the `<error/>` child element
* `condition` the defined-condition (e.g. "item-not-found")
* `text` optional description, may be `C_NULL`

# Returns
A new Strophe stanza object
"""
function xmpp_stanza_reply_error(stanza, error_type, condition, text)
    return ccall((:xmpp_stanza_reply_error, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_stanza_t}, Ptr{Cchar}, Ptr{Cchar}, Ptr{Cchar}), stanza, error_type, condition, text)
end

"""
$(SIGNATURES)

Create a `<message/>` stanza object with given attributes.

Attributes are optional and may be `C_NULL`.

# Arguments
$(_arg(_g, [:ctx]))
* `type` attribute 'type'
* `to` attribute 'to'
* `id` attribute 'id'

# Returns
A new Strophe stanza object
"""
function xmpp_message_new(ctx, type, to, id)
    return ccall((:xmpp_message_new, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_ctx_t}, Ptr{Cchar}, Ptr{Cchar}, Ptr{Cchar}), ctx, type, to, id)
end

"""
$(SIGNATURES)

Get text from `<body/>` child element.

This function returns new allocated string. The caller is responsible for
freeing this string with [`xmpp_free`](@ref).

# Arguments
* `msg` well formed `<message/>` stanza

# Returns
Allocated string or `C_NULL` on failure (no `<body/>` element or memory
allocation error)
"""
function xmpp_message_get_body(msg)
    return ccall((:xmpp_message_get_body, libstrophe), Ptr{Cchar}, (Ptr{xmpp_stanza_t},), msg)
end

"""
$(SIGNATURES)

Add `<body/>` child element to a `<message/>` stanza with the given text.

# Arguments
* `msg` a `<message>` stanza object without `<body/>` child element.
* `text` The text that shall be placed in the body.

# Returns
0 on success ([`XMPP_EOK`](@ref)), and a number less than 0 on failure
([`XMPP_EMEM`](@ref), [`XMPP_EINVOP`](@ref))
"""
function xmpp_message_set_body(msg, text)
    return ccall((:xmpp_message_set_body, libstrophe), Cint, (Ptr{xmpp_stanza_t}, Ptr{Cchar}), msg, text)
end

"""
$(SIGNATURES)

Create an `<iq/>` stanza object with given attributes.

Attributes are optional and may be `C_NULL`.

# Arguments
$(_arg(_g, [:ctx]))
* `type` attribute 'type'
* `id` attribute 'id'

# Returns
A new Strophe stanza object
"""
function xmpp_iq_new(ctx, type, id)
    return ccall((:xmpp_iq_new, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_ctx_t}, Ptr{Cchar}, Ptr{Cchar}), ctx, type, id)
end

"""
$(SIGNATURES)

Create a `<presence/>` stanza object.

# Arguments
$(_arg(_g, [:ctx]))

# Returns
A new Strophe stanza object
"""
function xmpp_presence_new(ctx)
    return ccall((:xmpp_presence_new, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_ctx_t},), ctx)
end

"""
$(SIGNATURES)

Create an `<stream:error/>` stanza object with given type and error text.

The error text is optional and may be `C_NULL`.

# Arguments
$(_arg(_g, [:ctx]))
* `type` enum of strophe_error_type_t
* `text` content of a 'text'

# Returns
A new Strophe stanza object
"""
function xmpp_error_new(ctx, type, text)
    return ccall((:xmpp_error_new, libstrophe), Ptr{xmpp_stanza_t}, (Ptr{xmpp_ctx_t}, xmpp_error_type_t, Ptr{Cchar}), ctx, type, text)
end

"""
$(SIGNATURES)

Create a JID string from component parts node, domain, and resource.

# Arguments
$(_arg(_g, [:ctx]))
* `node` a string representing the node
* `domain` a string representing the domain.  Required.
* `resource` a string representing the resource

# Returns
An allocated string with the full JID or `C_NULL` if no domain is specified
"""
function xmpp_jid_new(ctx, node, domain, resource)
    return ccall((:xmpp_jid_new, libstrophe), Ptr{Cchar}, (Ptr{xmpp_ctx_t}, Ptr{Cchar}, Ptr{Cchar}, Ptr{Cchar}), ctx, node, domain, resource)
end

"""
$(SIGNATURES)

Create a bare JID from a JID.

# Arguments
$(_arg(_g, [:ctx]))
* `jid` the JID

# Returns
An allocated string with the bare JID or `C_NULL` on an error
"""
function xmpp_jid_bare(ctx, jid)
    return ccall((:xmpp_jid_bare, libstrophe), Ptr{Cchar}, (Ptr{xmpp_ctx_t}, Ptr{Cchar}), ctx, jid)
end

"""
$(SIGNATURES)

Create a node string from a JID.

# Arguments
$(_arg(_g, [:ctx]))
* `jid` the JID

# Returns
An allocated string with the node JID or `C_NULL` on an error
"""
function xmpp_jid_node(ctx, jid)
    return ccall((:xmpp_jid_node, libstrophe), Ptr{Cchar}, (Ptr{xmpp_ctx_t}, Ptr{Cchar}), ctx, jid)
end

"""
$(SIGNATURES)

Create a domain string from a JID.

# Arguments
$(_arg(_g, [:ctx]))
* `jid` the JID

# Returns
An allocated string with the domain or `C_NULL` on an error
"""
function xmpp_jid_domain(ctx, jid)
    return ccall((:xmpp_jid_domain, libstrophe), Ptr{Cchar}, (Ptr{xmpp_ctx_t}, Ptr{Cchar}), ctx, jid)
end

"""
$(SIGNATURES)

Create a resource string from a JID.

# Arguments
$(_arg(_g, [:ctx]))
* `jid` the JID

# Returns
An allocated string with the resource or `C_NULL` if no resource is found or an error occurs
"""
function xmpp_jid_resource(ctx, jid)
    return ccall((:xmpp_jid_resource, libstrophe), Ptr{Cchar}, (Ptr{xmpp_ctx_t}, Ptr{Cchar}), ctx, jid)
end

"""
$(SIGNATURES)

Run the event loop once.

This function will run send any data that has been queued by xmpp_send and
related functions and run through the Strophe even loop a single time, and
will not wait more than timeout milliseconds for events. This is provided to
support integration with event loops outside the library, and if used, should
be called regularly to achieve low latency event handling.

# Arguments
$(_arg(_g, [:ctx]))
* `timeout` time to wait for events in milliseconds
"""
function xmpp_run_once(ctx, timeout)
    return ccall((:xmpp_run_once, libstrophe), Cvoid, (Ptr{xmpp_ctx_t}, Culong), ctx, timeout)
end

"""
$(SIGNATURES)

Start the event loop.

This function continuously calls [`xmpp_run_once`](@ref) and does not return
until xmpp_stop has been called.

# Arguments
$(_arg(_g, [:ctx]))
"""
function xmpp_run(ctx)
    return ccall((:xmpp_run, libstrophe), Cvoid, (Ptr{xmpp_ctx_t},), ctx)
end

"""
$(SIGNATURES)

Stop the event loop.

This will stop the event loop after the current iteration and cause
[`xmpp_run`](@ref) to exit.

# Arguments
$(_arg(_g, [:ctx]))
"""
function xmpp_stop(ctx)
    return ccall((:xmpp_stop, libstrophe), Cvoid, (Ptr{xmpp_ctx_t},), ctx)
end

"""
$(SIGNATURES)

Set the timeout to use when calling [`xmpp_run`](@ref).

# Arguments
$(_arg(_g, [:ctx]))
* `timeout` the time to wait for events in milliseconds
"""
function xmpp_ctx_set_timeout(ctx, timeout)
    return ccall((:xmpp_ctx_set_timeout, libstrophe), Cvoid, (Ptr{xmpp_ctx_t}, Culong), ctx, timeout)
end

"""
$(SIGNATURES)

Get the Strophe context which is assigned to this certificate.

# Arguments
* `cert` a Strophe TLS certificate object

# Returns
The Strophe context object where this certificate originates from
"""
function xmpp_tlscert_get_ctx(cert)
    return ccall((:xmpp_tlscert_get_ctx, libstrophe), Ptr{xmpp_ctx_t}, (Ptr{xmpp_tlscert_t},), cert)
end

"""
$(SIGNATURES)

Get the Strophe connection which is assigned to this certificate.

# Arguments
* `cert` a Strophe TLS certificate object

# Returns
The Strophe connection object where this certificate originates from
"""
function xmpp_tlscert_get_conn(cert)
    return ccall((:xmpp_tlscert_get_conn, libstrophe), Ptr{xmpp_conn_t}, (Ptr{xmpp_tlscert_t},), cert)
end

"""
$(SIGNATURES)

Get the complete PEM of this certificate.

# Arguments
* `cert` a Strophe TLS certificate object

# Returns
A string containing the PEM of this certificate
"""
function xmpp_tlscert_get_pem(cert)
    return ccall((:xmpp_tlscert_get_pem, libstrophe), Ptr{Cchar}, (Ptr{xmpp_tlscert_t},), cert)
end

"""
$(SIGNATURES)

Get the dnsName entries out of the SubjectAlternativeNames.

Note: Max. MAX_NUM_DNSNAMES are supported.

# Arguments
* `cert` a Strophe TLS certificate object
* `n` which dnsName entry

# Returns
A string with the n'th dnsName
"""
function xmpp_tlscert_get_dnsname(cert, n)
    return ccall((:xmpp_tlscert_get_dnsname, libstrophe), Ptr{Cchar}, (Ptr{xmpp_tlscert_t}, Csize_t), cert, n)
end

"""
$(SIGNATURES)

Get various parts of the certificate as String.

c.f. [`xmpp_cert_element_t`](@ref) for details.

# Arguments
* `cert` a Strophe TLS certificate object
* `elmnt` which part of the certificate

# Returns
A string with the part of the certificate
"""
function xmpp_tlscert_get_string(cert, elmnt)
    return ccall((:xmpp_tlscert_get_string, libstrophe), Ptr{Cchar}, (Ptr{xmpp_tlscert_t}, xmpp_cert_element_t), cert, elmnt)
end

"""
$(SIGNATURES)

Get a descriptive string for each xmpp_cert_element_t.

c.f. [`xmpp_cert_element_t`](@ref) for details.

# Arguments
* `elmnt` which part of the certificate

# Returns
A string with the description
"""
function xmpp_tlscert_get_description(elmnt)
    return ccall((:xmpp_tlscert_get_description, libstrophe), Ptr{Cchar}, (xmpp_cert_element_t,), elmnt)
end

"""
$(SIGNATURES)

Free a certificate object.

# Arguments
* `cert` a Strophe TLS certificate object
"""
function xmpp_tlscert_free(cert)
    return ccall((:xmpp_tlscert_free, libstrophe), Cvoid, (Ptr{xmpp_tlscert_t},), cert)
end

function xmpp_uuid_gen(ctx)
    return ccall((:xmpp_uuid_gen, libstrophe), Ptr{Cchar}, (Ptr{xmpp_ctx_t},), ctx)
end

mutable struct _xmpp_sha1_t end

const xmpp_sha1_t = _xmpp_sha1_t

"""
$(SIGNATURES)

Compute SHA1 message digest.

# Returns
An allocated string which represents SHA1 message digest in hexadecimal notation. The string must be freed with [`xmpp_free`](@ref).

# Arguments
$(_arg(_g, [:ctx]))
* `data` buffer for digest computation
* `len` size of the data buffer

# Returns
An allocated string or `C_NULL` on allocation error
"""
function xmpp_sha1(ctx, data, len)
    return ccall((:xmpp_sha1, libstrophe), Ptr{Cchar}, (Ptr{xmpp_ctx_t}, Ptr{Cuchar}, Csize_t), ctx, data, len)
end

"""
$(SIGNATURES)

Compute SHA1 message digest.

Stores digest in user's buffer which must be at least XMPP_SHA1_DIGEST_SIZE bytes long.

# Arguments
* `data` buffer for digest computation
* `len` size of the data buffer
* `digest` output buffer of XMPP_SHA1_DIGEST_SIZE bytes
"""
function xmpp_sha1_digest(data, len, digest)
    return ccall((:xmpp_sha1_digest, libstrophe), Cvoid, (Ptr{Cuchar}, Csize_t, Ptr{Cuchar}), data, len, digest)
end

"""
$(SIGNATURES)

Create new SHA1 object.

SHA1 object is used to compute SHA1 digest of a buffer that is split in multiple chunks or provided in stream mode. A single buffer can be processed by short functions [`xmpp_sha1`](@ref) and [`xmpp_sha1_digest`](@ref). Follow the next use-case for xmpp_sha1_t object:

```julia
sha1 = LibStrophe.xmpp_sha1_new(ctx)
# Repeat update for all chunks of data
LibStrophe.xmpp_sha1_update(sha1, data, len)
LibStrophe.xmpp_sha1_final(sha1)
digest = LibStrophe.xmpp_sha1_to_string_alloc(sha1)
xmpp_sha1_free(sha1)
```

# Arguments
$(_arg(_g, [:ctx]))

# Returns
New SHA1 object
"""
function xmpp_sha1_new(ctx)
    return ccall((:xmpp_sha1_new, libstrophe), Ptr{xmpp_sha1_t}, (Ptr{xmpp_ctx_t},), ctx)
end

"""
$(SIGNATURES)

Destroy SHA1 object.

# Arguments
* `sha1` a SHA1 object
"""
function xmpp_sha1_free(sha1)
    return ccall((:xmpp_sha1_free, libstrophe), Cvoid, (Ptr{xmpp_sha1_t},), sha1)
end

"""
$(SIGNATURES)

Update SHA1 context with the next portion of data.

Can be called repeatedly.

# Arguments
* `sha1` a SHA1 object
* `data` pointer to a buffer to be hashed
* `len` size of the data buffer
"""
function xmpp_sha1_update(sha1, data, len)
    return ccall((:xmpp_sha1_update, libstrophe), Cvoid, (Ptr{xmpp_sha1_t}, Ptr{Cuchar}, Csize_t), sha1, data, len)
end

"""
$(SIGNATURES)

Finish SHA1 computation.

Don't call [`xmpp_sha1_update`](@ref) after this function. Retrieve resulting message digest with [`xmpp_sha1_to_string`](@ref) or [`xmpp_sha1_to_digest`](@ref).

# Arguments
* `sha1` a SHA1 object
"""
function xmpp_sha1_final(sha1)
    return ccall((:xmpp_sha1_final, libstrophe), Cvoid, (Ptr{xmpp_sha1_t},), sha1)
end

"""
$(SIGNATURES)

Return message digest rendered as a string.

Stores the string to a user's buffer and returns the buffer. Call this function after [`xmpp_sha1_final`](@ref).

# Arguments
* `sha1` a SHA1 object
* `s` output string
* `slen` size reserved for the string including '\0'

# Returns
Pointer `s` or `C_NULL` if resulting string is bigger than slen bytes
"""
function xmpp_sha1_to_string(sha1, s, slen)
    return ccall((:xmpp_sha1_to_string, libstrophe), Ptr{Cchar}, (Ptr{xmpp_sha1_t}, Ptr{Cchar}, Csize_t), sha1, s, slen)
end

"""
$(SIGNATURES)

Return message digest rendered as a string.

# Returns
An allocated string. Free the string by calling [`xmpp_free`](@ref) using the Strophe context which is passed to [`xmpp_sha1_new`](@ref). Call this function after [`xmpp_sha1_final`](@ref).

# Arguments
* `sha1` a SHA1 object

# Returns
An allocated string
"""
function xmpp_sha1_to_string_alloc(sha1)
    return ccall((:xmpp_sha1_to_string_alloc, libstrophe), Ptr{Cchar}, (Ptr{xmpp_sha1_t},), sha1)
end

"""
$(SIGNATURES)

Stores message digest to a user's buffer.

# Arguments
* `sha1` a SHA1 object
* `digest` output buffer of `XMPP_SHA1_DIGEST_SIZE` bytes
"""
function xmpp_sha1_to_digest(sha1, digest)
    return ccall((:xmpp_sha1_to_digest, libstrophe), Cvoid, (Ptr{xmpp_sha1_t}, Ptr{Cuchar}), sha1, digest)
end

"""
$(SIGNATURES)

Base64 encoding routine.

# Returns
An allocated string which must be freed with [`xmpp_free`](@ref).

# Arguments
$(_arg(_g, [:ctx]))
* `data` buffer to encode
* `len` size of the data buffer

# Returns
An allocated null-terminated string or `C_NULL` on error
"""
function xmpp_base64_encode(ctx, data, len)
    return ccall((:xmpp_base64_encode, libstrophe), Ptr{Cchar}, (Ptr{xmpp_ctx_t}, Ptr{Cuchar}, Csize_t), ctx, data, len)
end

"""
$(SIGNATURES)

Base64 decoding routine.

# Returns
An allocated string which must be freed with [`xmpp_free`](@ref). User calls this function when the result must be a string. When decoded buffer contains '\0' NULL is returned.

# Arguments
$(_arg(_g, [:ctx]))
* `base64` encoded buffer
* `len` size of the buffer

# Returns
An allocated null-terminated string or `C_NULL` on error
"""
function xmpp_base64_decode_str(ctx, base64, len)
    return ccall((:xmpp_base64_decode_str, libstrophe), Ptr{Cchar}, (Ptr{xmpp_ctx_t}, Ptr{Cchar}, Csize_t), ctx, base64, len)
end

"""
$(SIGNATURES)

Base64 decoding routine.

# Returns
An allocated buffer which must be freed with [`xmpp_free`](@ref).

# Arguments
$(_arg(_g, [:ctx]))
* `base64` encoded buffer
* `len` size of the encoded buffer
* `out` allocated buffer is stored here
* `outlen` size of the allocated buffer

!!! note
    on an error the `out` pointer will be `C_NULL`
"""
function xmpp_base64_decode_bin(ctx, base64, len, out, outlen)
    return ccall((:xmpp_base64_decode_bin, libstrophe), Cvoid, (Ptr{xmpp_ctx_t}, Ptr{Cchar}, Csize_t, Ptr{Ptr{Cuchar}}, Ptr{Csize_t}), ctx, base64, len, out, outlen)
end

mutable struct _xmpp_rand_t end

"""
Random number generator
"""
const xmpp_rand_t = _xmpp_rand_t

"""
    xmpp_rand_new(ctx)

Create new [`xmpp_rand_t`](@ref) object.

# Arguments
$(_arg(_g, [:ctx]))
"""
function xmpp_rand_new(ctx)
    return ccall((:xmpp_rand_new, libstrophe), Ptr{xmpp_rand_t}, (Ptr{xmpp_ctx_t},), ctx)
end

"""
    xmpp_rand_free(ctx, rand)

Destroy an [`xmpp_rand_t`](@ref) object.

# Arguments
$(_arg(_g, [:ctx]))
* `rand`: A [`xmpp_rand_t`](@ref) object
"""
function xmpp_rand_free(ctx, rand)
    return ccall((:xmpp_rand_free, libstrophe), Cvoid, (Ptr{xmpp_ctx_t}, Ptr{xmpp_rand_t}), ctx, rand)
end

"""
    xmpp_rand(rand)

Generate random integer. Analogue of rand(3).

"""
function xmpp_rand(rand)
    return ccall((:xmpp_rand, libstrophe), Cint, (Ptr{xmpp_rand_t},), rand)
end

"""
    xmpp_rand_bytes(rand, output, len)

Generate random bytes. Generates len bytes and stores them to the output buffer.

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

"""
Return code signaling no error
"""
const XMPP_EOK = 0

"""
Memory related failure error code.

This is returned on allocation errors and signals that the host may
be out of memory.
"""
const XMPP_EMEM = -1

"""
Invalid operation error code.

This error code is returned when the operation was invalid and signals
that the Strophe API is being used incorrectly.
"""
const XMPP_EINVOP = -2

"""
Internal failure error code.
"""
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

# Non public elements used to rewrite xmpp_run in a Julia Task-friendly way.
@enum LoopStatus::UInt32 begin
    XMPP_LOOP_NOTSTARTED = 0
    XMPP_LOOP_RUNNING = 1
    XMPP_LOOP_QUIT = 2
end
mutable struct _ctx
    mem::Ptr{Cvoid}
    log::Ptr{Cvoid}
    verbosity::Cint
    rand::Ptr{Cvoid}
    loop_status::LoopStatus
    connlist::Ptr{Cvoid}
    handlist::Ptr{Cvoid}
    timeout::Culong
end

end # module
