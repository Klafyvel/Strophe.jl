# Noteworthy differences with libstrophe

Due to the differences between Julia and C (and the abilities of the author of Strophe.jl!), there are some differences between the two libraries

```@contents
Pages = ["21_differences_with_libstrophe.md"]
```

## Low- and High-Level APIs

At this time Strophe.jl offers two APIs. The first one is the [low-level API](@ref low-level-api). It maps closely to the C library, and allows you to translate quite easily C code to Julia implementations (see the [Low-Level Examples](@ref low-level-examples)). However, this presents the inconvenience that you often need to manage the memory manually. The second is the [High-Level API](@ref high-level-api). It provides a more Julian interface, but some of the features of the C libraries are not yet supported ([you are welcome to contribute!](@ref dev_docs)).

## Socket Options Callbacks

The C library allows the user to manually tune the socket options using a callback (see the [complex example](https://github.com/strophe/libstrophe/blob/master/examples/complex.c) of the C library). However this is a bit tricky to do cleanly in Julia, since this is platform-dependent. For now, the recommended way is to use the default callback provided by the library using [`Strophe.LibStrophe.xmpp_sockopt_cb_keepalive`](@ref) through the provided [`Strophe.sockopt_cb_keepalive`](@ref) reference. The high-level API is opinionated and uses this callback.

## Memory Management

Memory management in the C library is handled through context objects. This behavior is mapped one-to-one in the low-level API. The high-level API uses [finalizers](https://docs.julialang.org/en/v1/base/base/#Base.finalizer) to cleanup underlying objects (this is why we have wrappers such as [`Strophe.Context`](@ref) or [`Strophe.Connection`](@ref)). In addition, there is a globally shared context (available as [`Strophe.DEFAULT_CONTEXT`](@ref)) that allows you to mostly forget about context objects when using the high-level API. You are of course still free to use your own [`Strophe.Context`](@ref) objects.
