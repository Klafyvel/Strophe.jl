# [Reference](@id high-level-reference)

## Contents

```@contents
Pages = ["95-reference.md"]
```

## Exceptions

```@docs
Strophe.StropheError
```

## Context Handling

```@docs
Strophe.Context
Strophe.context
Strophe.run
Strophe.run_once
Strophe.stop
Strophe.timeout!
```

## Stanza

```@docs
Strophe.Stanza
Strophe.stanza
Strophe.clone!
Strophe.release!
Strophe.is_text
Strophe.is_tag
Strophe.render_to_string
Strophe.children
Strophe.siblings
Strophe.child
Strophe.child!
Base.getindex(::Union{Ptr{Strophe.LibStrophe.xmpp_stanza_t}, Strophe.Stanza}, ::AbstractString)
Base.keys(::Union{Ptr{Strophe.LibStrophe.xmpp_stanza_t}, Strophe.Stanza})
Base.values(::Union{Ptr{Strophe.LibStrophe.xmpp_stanza_t}, Strophe.Stanza})
Base.pairs(::Union{Ptr{Strophe.LibStrophe.xmpp_stanza_t}, Strophe.Stanza})
Strophe.text
Strophe.text!
Strophe.name
Strophe.name!
Base.setindex!(::Union{Ptr{Strophe.LibStrophe.xmpp_stanza_t}, Strophe.Stanza}, ::AbstractString, ::AbstractString)
Base.delete!(::Union{Ptr{Strophe.LibStrophe.xmpp_stanza_t}, Strophe.Stanza}, ::AbstractString)
Strophe.ns
Strophe.ns!
Strophe.type
Strophe.type!
Strophe.id
Strophe.id!
Strophe.to
Strophe.to!
Strophe.from
Strophe.from!
Strophe.reply
Strophe.reply_error
Strophe.message
Strophe.body
Strophe.body!
Strophe.iq
Strophe.presence
Strophe.stream_error
```

## Connection Handling

```@docs
Strophe.ParametrizedConnection
Strophe.ClientConnection
Strophe.ComponentConnection
Strophe.connect
Strophe.disconnect
Strophe.Connection
Strophe.connection
Strophe.jid
Strophe.bound_jid
Strophe.jid!
Strophe.pass
Strophe.pass!
Strophe.flags
Strophe.flags!
Strophe.flagenabled
Strophe.enableflag!
Strophe.disabletls
Strophe.disabletls!
Strophe.mandatorytls
Strophe.mandatorytls!
Strophe.legacyssl
Strophe.legacyssl!
Strophe.trusttls
Strophe.trusttls!
Strophe.legacyauth
Strophe.legacyauth!
Strophe.disablesm
Strophe.disablesm!
Strophe.enablecompression
Strophe.enablecompression!
Strophe.compressiondontreset
Strophe.compressiondontreset!
```

## Logging

You may be interested in the [logging example](examples/logging.md).

```@docs
Strophe.logger
```

## Index

```@index
Pages = ["95-reference.md"]
```
