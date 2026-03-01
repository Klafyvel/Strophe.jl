#=
# [Roster example](@id low-level-roster-example)

This is a port of the [roster example from libstrophe](https://github.com/strophe/libstrophe/blob/master/examples/roster.c) to Julia.

You need the a server running on localhost (see [low-level-examples](@ref) to set up
a local xmpp server using docker-compose. If that is what you are using, start it
with `docker-compose up`. Depending on your platform, you might need sudo.

This example demonstrates how to basic handler functions can be used to print the user's roster.

Rosters are a list of contact for a specific user (see [RFC 6121](https://xmpp.org/rfcs/rfc6121.html)). You can retrieve yours using an `<iq/>` stanza.

## Setting Up

You need to have pinocchio registered in the roster of gepetto. In addition to
the other examples, you may run the following commands.

First install `mod_roster_command`:
```
docker compose -f scripts/docker-compose.yml exec prosody prosodyctl install --server=https://modules.prosody.im/rocks/ mod_roster_command
```

The, subscribe both user to each other:
```
docker compose -f scripts/docker-compose.yml exec prosody prosodyctl mod_roster_command subscribe_both gepetto@localhost pinocchio@localhost
```

=#

# ## Initialization of the library

import Strophe: LibStrophe

# ## Callback to handle the reply to queries
# This is the callback we will register to receive the result of our query.
# It reads the stanza and list the contacts.

function handle_reply(conn, stanza, userdata)
    type = LibStrophe.xmpp_stanza_get_type(stanza)
    if type != C_NULL && unsafe_string(type) == "error"
        @error "Query failed."
    else
        query = LibStrophe.xmpp_stanza_get_child_by_name(stanza, "query")
        println("Roster:")
        item = LibStrophe.xmpp_stanza_get_children(query)
        while item != C_NULL
            name = LibStrophe.xmpp_stanza_get_attribute(item, "name")
            jid = LibStrophe.xmpp_stanza_get_attribute(item, "jid") |> unsafe_string
            subscription = LibStrophe.xmpp_stanza_get_attribute(item, "subscription") |> unsafe_string
            if name != C_NULL
                name = unsafe_string(name)
                println("\t $(name) ($(jid)) sub=$(subscription)")
            else
                println("\t $(jid) sub=$(subscription)")
            end
            item = LibStrophe.xmpp_stanza_get_next(item)
        end
        println("END OF LIST")
    end

    LibStrophe.xmpp_disconnect(conn)

    return Int32(0)
end
#
# We need to build a C function to get a pointer that we can use as a callback
const handle_reply_c = @cfunction(
    handle_reply, Cint, (
        Ptr{LibStrophe.xmpp_conn_t}, Ptr{LibStrophe.xmpp_stanza_t}, Ptr{Cvoid},
    )
)

# ## Connection handler
# This is where we will issue the `<iq/>` stanza and register a handler to deal
# with the answer to that request. The stanza should look like :
#
# ```xml
# <iq from='juliet@example.com/balcony'
#      id='bv1bs71f'
#      type='get'>
#   <query xmlns='jabber:iq:roster'/>
# </iq>
# ```

function connection_handler(conn, status, error, stream_error, userdata)
    ctx = userdata

    if status == LibStrophe.XMPP_CONN_CONNECT
        @info "Connected!"
        ## We can now prepare the `<iq/>` stanza. As per the RFC, it has to have
        ## the type `get`.
        iq = LibStrophe.xmpp_iq_new(ctx, "get", "roster1")

        query = LibStrophe.xmpp_stanza_new(ctx)
        LibStrophe.xmpp_stanza_set_name(query, "query")
        LibStrophe.xmpp_stanza_set_ns(query, LibStrophe.XMPP_NS_ROSTER)
        LibStrophe.xmpp_stanza_add_child(iq, query)

        ## We can release the stanza since it belongs to iq now
        LibStrophe.xmpp_stanza_release(query)

        ## Set up reply handler. We will trigger it uppon receiving a stanza with
        ## id `roster1`.
        LibStrophe.xmpp_id_handler_add(conn, handle_reply_c, "roster1", ctx)

        ## Then we send out the stanza.
        LibStrophe.xmpp_send(conn, iq)

        ## release the stanza since we don't need it anymore.
        LibStrophe.xmpp_stanza_release(iq)
    else
        @info "Disconnected!"
        LibStrophe.xmpp_stop(ctx)
    end
    return nothing
end

# We need to build a C function to get a pointer that we can use as a callback
const connection_handler_c = @cfunction(
    connection_handler, Cvoid, (
        Ptr{LibStrophe.xmpp_conn_t}, LibStrophe.xmpp_conn_event_t,
        Cint, Ptr{LibStrophe.xmpp_stream_error_t}, Ptr{Cvoid},
    )
)

# ## Running the program
# This is very similar to the [basic example](@ref low-level-basic-example), so
# the explanations will be limited.


ctx = LibStrophe.xmpp_ctx_new(C_NULL, C_NULL)

flags = LibStrophe.XMPP_CONN_FLAG_TRUST_TLS
conn = LibStrophe.xmpp_conn_new(ctx)
LibStrophe.xmpp_conn_set_flags(conn, flags)

jid = "gepetto@localhost"
password = "plopiplop"
LibStrophe.xmpp_conn_set_jid(conn, jid)
LibStrophe.xmpp_conn_set_pass(conn, password)

connection_status = LibStrophe.xmpp_connect_client(conn, C_NULL, 0, connection_handler_c, ctx)

if connection_status == LibStrophe.XMPP_EOK
    LibStrophe.xmpp_run(ctx) # Run the internal event loop from libstrophe
else
    @warn "Connection to the server failed! Is the server running? Did you register the test users?"
end

# As expected, pinocchio appears in gepettos's roster!

LibStrophe.xmpp_conn_release(conn)
LibStrophe.xmpp_ctx_free(ctx)

LibStrophe.xmpp_shutdown()
