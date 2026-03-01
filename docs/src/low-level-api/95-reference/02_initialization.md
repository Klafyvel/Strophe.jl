# Initialization, Shutdown, and Versioning

These functions initialize and shut down the library, and allow for API version checking.

Failure to properly call these functions may result in strange (and platform dependent) behavior.

Specifically, the socket library on Win32 platforms must be initialized before use (although this is not the case on POSIX systems). The TLS subsystem must also seed the random number generator.

```@docs
Strophe.LibStrophe.xmpp_initialize
Strophe.LibStrophe.xmpp_shutdown
Strophe.LibStrophe.xmpp_version_check
```
