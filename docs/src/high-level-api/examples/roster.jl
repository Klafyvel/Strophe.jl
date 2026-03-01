#=
# [Roster example](@id high-level-roster-example)

This is a port of the [roster example from libstrophe](https://github.com/strophe/libstrophe/blob/master/examples/roster.c) to Julia using the high-level API of Strophe.jl.

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

import Strophe
import Strophe: LibStrophe, Stanza, ClientConnection

# ## Callback to handle the reply to queries
# This is the callback we will register to receive the result of our query.
# It reads the stanza and list the contacts.

function handle_reply(conn, stanza)
    type = Strophe.type(stanza)
    if type == "error"
        @error "Query failed."
    else
        query = Strophe.child(stanza, "query")
        println("Roster:")
        for item in Strophe.children(query)
            jid = item["jid"]
            subscription = item["subscription"]
            if "name" in keys(item)
                name = Strophe.name(item)
                println("\t $(name) ($(jid)) sub=$(subscription)")
            else
                println("\t $(jid) sub=$(subscription)")
            end
        end
        println("END OF LIST")
    end
    Strophe.disconnect(conn)
    return Int32(0)
end

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

function connection_handler(conn, status, error, stream_error)
    if status == LibStrophe.XMPP_CONN_CONNECT
        @info "Connected!"
        ## We can now prepare the `<iq/>` stanza. As per the RFC, it has to have
        ## the type `get`.
        iq = Strophe.iq(type = "get", id = "roster1")(
            Stanza(name = "query", xmlns = LibStrophe.XMPP_NS_ROSTER)
        )
        ## Set up reply handler. We will trigger it uppon receiving a stanza with
        ## id `roster1`.
        Strophe.add_id_handler!(conn, handle_reply, "roster1")
        ## Then we send out the stanza.
        Strophe.send(conn, iq)
    else
        @info "Disconnected!"
        Strophe.stop(conn)
    end
    return nothing
end

# ## Running the program
# This is very similar to the [basic example](@ref low-level-basic-example), so
# the explanations will be limited.


conn = ClientConnection(host = "localhost", handler = connection_handler)
Strophe.trusttls!(conn)

jid = "gepetto@localhost"
password = "plopiplop"
Strophe.jid!(conn, jid)
Strophe.pass!(conn, password)

Strophe.connect(conn)
Strophe.run()

# As expected, pinocchio appears in gepettos's roster!
