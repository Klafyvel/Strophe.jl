# [Reference](@id low-level-reference)

This is an adaptation of the documentation of [libstrophe](https://strophe.im/libstrophe/doc/0.13.0) to the Julia binding.

## Contents

```@contents
Pages = ["95-reference.md"]
```

## Misc

```@docs
Strophe.LibStrophe
Strophe.LibStrophe.xmpp_free
```

## Initialization, shutdown, and versioning

These functions initialize and shutdown the library, and also allow for API version checking.

Failure to properly call these functions may result in strange (and platform dependent) behavior.

Specifically, the socket library on Win32 platforms must be initialized before use (although this is not the case on POSIX systems). The TLS subsystem must also seed the random number generator.

```@docs
Strophe.LibStrophe.xmpp_initialize
Strophe.LibStrophe.xmpp_shutdown
Strophe.LibStrophe.xmpp_version_check
```

## [Context objects](@id low-level-contexts-reference)

These functions create and manipulate Strophe context objects.

In order to support usage in a variety of environments, the Strophe library uses a runtime context object. This object contains the information on how to do memory allocation and logging. This allows the user to control how memory is allocated and what do to with log messages.

These issues do not affect programs in the common case, but many environments require special treatment. Abstracting these into a runtime context object makes it easy to use Strophe on embedded platforms.

Objects in Strophe are reference counted to ease memory management issues, but the context objects are not.

```@docs
Strophe.LibStrophe.xmpp_ctx_new
Strophe.LibStrophe.xmpp_ctx_free
Strophe.LibStrophe.xmpp_ctx_set_verbosity
Strophe.LibStrophe.xmpp_get_default_logger
Strophe.LibStrophe.xmpp_log_level_t
Strophe.LibStrophe.xmpp_ctx_t
Strophe.LibStrophe.xmpp_log_handler
```

## [Connection management](@id low-level-connections-reference)

These functions manage a connection object.

A part of those functions is listed under the [SSL/TLS specific functionality](@ref low-level-SSL) section.

```@docs
Strophe.LibStrophe.xmpp_sockopt_callback
Strophe.LibStrophe.xmpp_conn_new
Strophe.LibStrophe.xmpp_conn_clone
Strophe.LibStrophe.xmpp_conn_set_sockopt_callback
Strophe.LibStrophe.xmpp_conn_release
Strophe.LibStrophe.xmpp_conn_get_jid
Strophe.LibStrophe.xmpp_conn_get_bound_jid
Strophe.LibStrophe.xmpp_conn_set_jid
Strophe.LibStrophe.xmpp_conn_get_pass
Strophe.LibStrophe.xmpp_conn_set_pass
Strophe.LibStrophe.xmpp_conn_get_context
Strophe.LibStrophe.xmpp_connect_client
Strophe.LibStrophe.xmpp_connect_component
Strophe.LibStrophe.xmpp_connect_raw
Strophe.LibStrophe.xmpp_conn_handler
Strophe.LibStrophe.xmpp_conn_open_stream_default
Strophe.LibStrophe.xmpp_conn_open_stream
Strophe.LibStrophe.xmpp_conn_tls_start
Strophe.LibStrophe.xmpp_disconnect
Strophe.LibStrophe.xmpp_send_raw
Strophe.LibStrophe.xmpp_send
Strophe.LibStrophe.xmpp_conn_get_flags
Strophe.LibStrophe.xmpp_conn_set_flags
Strophe.LibStrophe.xmpp_conn_is_secured
Strophe.LibStrophe.xmpp_conn_is_connecting
Strophe.LibStrophe.xmpp_conn_is_connected
Strophe.LibStrophe.xmpp_conn_is_disconnected
Strophe.LibStrophe.xmpp_conn_get_sm_state
Strophe.LibStrophe.xmpp_conn_set_sm_state
Strophe.LibStrophe.xmpp_free_sm_state
Strophe.LibStrophe.xmpp_conn_send_queue_len
Strophe.LibStrophe.xmpp_conn_send_queue_drop_element
Strophe.LibStrophe.xmpp_queue_element_t
Strophe.LibStrophe.xmpp_sockopt_cb_keepalive
Strophe.LibStrophe.xmpp_conn_t
Strophe.LibStrophe.xmpp_sm_callback
Strophe.LibStrophe.xmpp_conn_set_sm_callback
Strophe.LibStrophe.xmpp_conn_restore_sm_state
Strophe.LibStrophe.xmpp_conn_event_t
Strophe.LibStrophe.xmpp_stream_error_t
Strophe.LibStrophe.xmpp_error_type_t
```

## [SSL/TLS specific functionality](@id low-level-SSL)

These functions provide SSL/TLS specific functionality.

```@docs
Strophe.LibStrophe.xmpp_certfail_handler
Strophe.LibStrophe.xmpp_password_callback
Strophe.LibStrophe.xmpp_cert_element_t
Strophe.LibStrophe.xmpp_conn_set_certfail_handler
Strophe.LibStrophe.xmpp_conn_set_cafile
Strophe.LibStrophe.xmpp_conn_set_capath
Strophe.LibStrophe.xmpp_conn_get_peer_cert
Strophe.LibStrophe.xmpp_conn_set_password_callback
Strophe.LibStrophe.xmpp_conn_set_password_retries
Strophe.LibStrophe.xmpp_conn_get_keyfile
Strophe.LibStrophe.xmpp_conn_set_client_cert
Strophe.LibStrophe.xmpp_conn_cert_xmppaddr_num
Strophe.LibStrophe.xmpp_conn_cert_xmppaddr
Strophe.LibStrophe.xmpp_tlscert_get_ctx
Strophe.LibStrophe.xmpp_tlscert_get_conn
Strophe.LibStrophe.xmpp_tlscert_get_pem
Strophe.LibStrophe.xmpp_tlscert_get_dnsname
Strophe.LibStrophe.xmpp_tlscert_get_string
Strophe.LibStrophe.xmpp_tlscert_get_description
Strophe.LibStrophe.xmpp_tlscert_free
```

## [Event loop](@id low-level-event-loop)

These functions manage the Strophe event loop.

Simple tools can use [`Strophe.LibStrophe.xmpp_run`](@ref) and [`Strophe.LibStrophe.xmpp_stop`](@ref) to manage the
life cycle of the program. A common idiom is to set up a few initial event
handers, call [`Strophe.LibStrophe.xmpp_run`](@ref), and then respond and react to events as they
come in. At some point, one of the handlers will call [`Strophe.LibStrophe.xmpp_stop`](@ref) to
quit the event loop which leads to the program terminating.

More complex programs will have their own event loops, and should ensure that
[`Strophe.LibStrophe.xmpp_run_once`](@ref) is called regularly from there. For example, a GUI
program will already include an event loop to process UI events from users,
and [`Strophe.LibStrophe.xmpp_run_once`](@ref) would be called from an idle function.

```@docs
Strophe.LibStrophe.xmpp_run_once
Strophe.LibStrophe.xmpp_run
Strophe.LibStrophe.xmpp_stop
Strophe.LibStrophe.xmpp_ctx_set_timeout
```

## [Stanza](@id low-level-stanza)

```@docs
Strophe.LibStrophe.xmpp_stanza_t
Strophe.LibStrophe.xmpp_stanza_new
Strophe.LibStrophe.xmpp_stanza_clone
Strophe.LibStrophe.xmpp_stanza_copy
Strophe.LibStrophe.xmpp_stanza_release
Strophe.LibStrophe.xmpp_stanza_is_text
Strophe.LibStrophe.xmpp_stanza_is_tag
Strophe.LibStrophe.xmpp_stanza_to_text
Strophe.LibStrophe.xmpp_stanza_set_name
Strophe.LibStrophe.xmpp_stanza_get_name
Strophe.LibStrophe.xmpp_stanza_get_attribute_count
Strophe.LibStrophe.xmpp_stanza_get_attributes
Strophe.LibStrophe.xmpp_stanza_set_attribute
Strophe.LibStrophe.xmpp_stanza_set_ns
Strophe.LibStrophe.xmpp_stanza_add_child_ex
Strophe.LibStrophe.xmpp_stanza_add_child
Strophe.LibStrophe.xmpp_stanza_set_text
Strophe.LibStrophe.xmpp_stanza_set_text_with_size
Strophe.LibStrophe.xmpp_stanza_get_id
Strophe.LibStrophe.xmpp_stanza_get_ns
Strophe.LibStrophe.xmpp_stanza_get_type
Strophe.LibStrophe.xmpp_stanza_get_to
Strophe.LibStrophe.xmpp_stanza_get_from
Strophe.LibStrophe.xmpp_stanza_get_child_by_name
Strophe.LibStrophe.xmpp_stanza_get_child_by_ns
Strophe.LibStrophe.xmpp_stanza_get_child_by_name_and_ns
Strophe.LibStrophe.xmpp_stanza_get_children
Strophe.LibStrophe.xmpp_stanza_get_next
Strophe.LibStrophe.xmpp_stanza_get_text
Strophe.LibStrophe.xmpp_stanza_get_text_ptr
Strophe.LibStrophe.xmpp_stanza_set_id
Strophe.LibStrophe.xmpp_stanza_set_type
Strophe.LibStrophe.xmpp_stanza_set_to
Strophe.LibStrophe.xmpp_stanza_set_from
Strophe.LibStrophe.xmpp_stanza_get_attribute
Strophe.LibStrophe.xmpp_stanza_del_attribute
Strophe.LibStrophe.xmpp_stanza_reply
Strophe.LibStrophe.xmpp_stanza_reply_error
Strophe.LibStrophe.xmpp_message_new
Strophe.LibStrophe.xmpp_message_get_body
Strophe.LibStrophe.xmpp_message_set_body
Strophe.LibStrophe.xmpp_iq_new
Strophe.LibStrophe.xmpp_presence_new
Strophe.LibStrophe.xmpp_error_new
Strophe.LibStrophe.xmpp_stanza_new_from_string
```

## Stanza and timed event handlers

```@docs
Strophe.LibStrophe.xmpp_timed_handler_delete
Strophe.LibStrophe.xmpp_id_handler_delete
Strophe.LibStrophe.xmpp_handler_delete
Strophe.LibStrophe.xmpp_timed_handler_add
Strophe.LibStrophe.xmpp_id_handler_add
Strophe.LibStrophe.xmpp_handler_add
Strophe.LibStrophe.xmpp_global_timed_handler_add
Strophe.LibStrophe.xmpp_global_timed_handler_delete
Strophe.LibStrophe.xmpp_handler
Strophe.LibStrophe.xmpp_timed_handler
Strophe.LibStrophe.xmpp_global_timed_handler
```

## JID creation and parsing

!!! warning
    The return value of these functions need to be freed using [`Strophe.LibStrophe.xmpp_free`](@ref)

```@docs
Strophe.LibStrophe.xmpp_jid_new
Strophe.LibStrophe.xmpp_jid_bare
Strophe.LibStrophe.xmpp_jid_node
Strophe.LibStrophe.xmpp_jid_domain
Strophe.LibStrophe.xmpp_jid_resource
```

## Pseudo-random number generator

```@docs
Strophe.LibStrophe.xmpp_rand_new
Strophe.LibStrophe.xmpp_rand_free
Strophe.LibStrophe.xmpp_rand
Strophe.LibStrophe.xmpp_rand_bytes
Strophe.LibStrophe.xmpp_rand_nonce
Strophe.LibStrophe.xmpp_rand_t
```

## Message digests

```@docs
Strophe.LibStrophe.xmpp_sha1
Strophe.LibStrophe.xmpp_sha1_digest
Strophe.LibStrophe.xmpp_sha1_new
Strophe.LibStrophe.xmpp_sha1_free
Strophe.LibStrophe.xmpp_sha1_update
Strophe.LibStrophe.xmpp_sha1_final
Strophe.LibStrophe.xmpp_sha1_to_string
Strophe.LibStrophe.xmpp_sha1_to_string_alloc
Strophe.LibStrophe.xmpp_sha1_to_digest
```

## Encodings

```@docs
Strophe.LibStrophe.xmpp_base64_encode
Strophe.LibStrophe.xmpp_base64_decode_str
Strophe.LibStrophe.xmpp_base64_decode_bin
```

## Constants

```@docs
Strophe.LibStrophe.XMPP_EOK
Strophe.LibStrophe.XMPP_EMEM
Strophe.LibStrophe.XMPP_EINVOP
Strophe.LibStrophe.XMPP_EINT
```

## Index

```@index
Pages = ["95-reference.md"]
```
