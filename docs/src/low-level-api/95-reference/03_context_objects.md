# [Context Objects](@id low-level-contexts-reference)

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
