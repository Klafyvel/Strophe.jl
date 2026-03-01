# [Event Loop](@id low-level-event-loop)

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
