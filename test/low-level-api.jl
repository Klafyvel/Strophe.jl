#=

The underlying libstrophe library is already tested. Here we simply want to
perform some integration tests to verify that things work. This is essentially
running the examples from the doc.

=#

@testsnippet LowLevelAPI begin
    @info "Starting low level API integration tests"
    using Sockets

    function wait_for_port(host, port; timeout = 10.0, interval = 0.5)
        deadline = time() + timeout
        while time() < deadline
            try
                sock = connect(host, port)
                close(sock)
                return true
            catch
                sleep(interval)
            end
        end
        return false
    end

    @assert all(
        map(
            fetch,
            [
                Threads.@spawn wait_for_port("localhost", port; timeout = 5)
                    for port in (5222, 5269)
            ]
        )
    ) "Test connection to XMPP server failed. Start it using the docker-compose.yml file in $(joinpath(pkgdir(Strophe), "scripts")))"
    @info "Successfully tested Server's connectivity"
    import Strophe: LibStrophe
end

@testitem "Basic example" tags = [:lowlevel, :integration] setup = [LowLevelAPI] begin
    @info "Running basic example"
    function connection_handler(conn, status, error, stream_error, userdata)
        ctx = userdata
        if status == LibStrophe.XMPP_CONN_CONNECT # We just connected
            @info "Connected!"
            LibStrophe.xmpp_disconnect(conn)
        else # Something else happended.
            @info "Disconnected!"
            LibStrophe.xmpp_stop(ctx) # stop the event loop
        end
        return nothing
    end

    const connection_handler_c = @cfunction(
        connection_handler, Cvoid, (
            Ptr{LibStrophe.xmpp_conn_t}, LibStrophe.xmpp_conn_event_t,
            Cint, Ptr{LibStrophe.xmpp_stream_error_t}, Ptr{Cvoid},
        )
    )

    log = LibStrophe.xmpp_get_default_logger(LibStrophe.XMPP_LEVEL_INFO)
    @test log isa Ptr{LibStrophe.xmpp_log_t}
    @test log ≠ C_NULL

    ctx = LibStrophe.xmpp_ctx_new(C_NULL, log)
    @test ctx isa Ptr{LibStrophe.xmpp_ctx_t}
    @test ctx ≠ C_NULL

    flags = LibStrophe.XMPP_CONN_FLAG_TRUST_TLS
    conn = LibStrophe.xmpp_conn_new(ctx)
    @test conn isa Ptr{LibStrophe.xmpp_conn_t}
    @test conn ≠ C_NULL

    ret = LibStrophe.xmpp_conn_set_flags(conn, flags)
    @test ret == LibStrophe.XMPP_EOK

    jid = "gepetto@localhost"
    password = "plopiplop"
    LibStrophe.xmpp_conn_set_jid(conn, jid)
    LibStrophe.xmpp_conn_set_pass(conn, password)

    port = 0 # Will use the default port
    host = "localhost"
    connection_status = LibStrophe.xmpp_connect_client(conn, host, port, connection_handler_c, ctx)
    @test connection_status == LibStrophe.XMPP_EOK
    if connection_status == LibStrophe.XMPP_EOK
        @info "Connection successful, starting main loop"
        @test_logs (:info, "Connected!") (:info, "Disconnected!") LibStrophe.xmpp_run(ctx) # Run the internal event loop from libstrophe
    else
        @warn "Connection to the server failed! Is the server running? Did you register the test users?"
    end
    LibStrophe.xmpp_conn_release(conn)
    LibStrophe.xmpp_ctx_free(ctx)
    @info "End of basic example"
end

@testitem "Bot example" tags = [:lowlevel, :integration] setup = [LowLevelAPI] begin
    @info "Running bot example"
    # @assert Threads.nthreads() ≥ 2 "The bot example requires at least two threads"
    @assert success(`go-sendxmpp --help`) "The bot example requires `go-sendxmpp` to be installed."
    pinocchio = PipeBuffer()
    listener = run(
        pipeline(
            `go-sendxmpp -n -p plopiplop -u pinocchio@localhost -l`,
            stdin = devnull, stdout = pinocchio, stderr = devnull
        ), wait = false
    )
    @assert process_running(listener) "The listener process exited. Do the users exist on the server?"
    function say_as_pinocchio(to, msg)
        @info "Pinocchio says \"$(msg)\""
        io = PipeBuffer()
        write(io, msg)
        return run(`go-sendxmpp -n -p plopiplop -u pinocchio@localhost $to`, io, devnull, stderr)
    end
    function _quit_handler(conn, userdata)
        LibStrophe.xmpp_disconnect(conn)
        return Int32(0)
    end
    const _quit_handler_c = @cfunction(
        _quit_handler, Cint,
        (Ptr{LibStrophe.xmpp_conn_t}, Ptr{Cvoid})
    )
    reconnect = true
    function message_handler(conn, stanza, userdata)
        body = LibStrophe.xmpp_stanza_get_child_by_name(stanza, "body")
        body == C_NULL && return 1
        type = LibStrophe.xmpp_stanza_get_type(stanza)
        (type != C_NULL && unsafe_string(type) == "error") && return 1

        intext = LibStrophe.xmpp_stanza_get_text(body)
        intext_str = unsafe_string(intext)
        @info "Message handler received \"$(intext_str)\""
        LibStrophe.xmpp_free(ctx, intext)

        reply = LibStrophe.xmpp_stanza_reply(stanza)
        if (LibStrophe.xmpp_stanza_get_type(reply) == C_NULL)
            LibStrophe.xmpp_stanza_set_type(reply, "chat")
        end

        if intext_str == "quit"
            replytext = "bye!"
            LibStrophe.xmpp_timed_handler_add(conn, _quit_handler_c, 500, C_NULL)
        elseif intext_str == "reconnect"
            replytext = "alright, let's see what happens!"
            global reconnect = true
            LibStrophe.xmpp_timed_handler_add(conn, _quit_handler_c, 500, C_NULL)
        else
            replytext = intext_str * " to you too!"
        end
        LibStrophe.xmpp_message_set_body(reply, replytext)

        LibStrophe.xmpp_send(conn, reply)
        LibStrophe.xmpp_stanza_release(reply)
        return Int32(1)
    end
    const message_handler_c = @cfunction(
        message_handler, Cint,
        (Ptr{LibStrophe.xmpp_conn_t}, Ptr{LibStrophe.xmpp_stanza_t}, Ptr{Cvoid})
    )
    function connection_handler(conn, status, error, stream_error, userdata)
        ctx = userdata
        @info "Connection handler fired" status LibStrophe.XMPP_CONN_CONNECT
        if status == LibStrophe.XMPP_CONN_CONNECT # We just connected
            LibStrophe.xmpp_handler_add(conn, message_handler_c, C_NULL, "message", C_NULL, ctx)
            pres = LibStrophe.xmpp_presence_new(ctx) # Send initial <presence/> so that we appear online to contacts
            LibStrophe.xmpp_send(conn, pres)
            LibStrophe.xmpp_stanza_release(pres)
        else
            LibStrophe.xmpp_stop(ctx) # stop the event loop
        end
        return nothing
    end
    connection_handler_c = @cfunction(
        connection_handler, Cvoid, (
            Ptr{LibStrophe.xmpp_conn_t}, LibStrophe.xmpp_conn_event_t,
            Cint, Ptr{LibStrophe.xmpp_stream_error_t}, Ptr{Cvoid},
        )
    )
    host = "localhost"
    port = 0 # Will use the default port

    log = LibStrophe.xmpp_get_default_logger(LibStrophe.XMPP_LEVEL_INFO)
    @test log isa Ptr{LibStrophe.xmpp_log_t}
    @test log ≠ C_NULL

    ctx = LibStrophe.xmpp_ctx_new(C_NULL, log)
    @test ctx isa Ptr{LibStrophe.xmpp_ctx_t}
    @test ctx ≠ C_NULL

    # We prepare the configuration of the connection through flags
    flags = LibStrophe.XMPP_CONN_FLAG_TRUST_TLS
    jid = "gepetto@localhost"
    password = "plopiplop"

    sm_state = C_NULL
    speaky_task = Threads.@spawn begin
        sleep(1) # Let's wait one second for the bot to connect.
        say_as_pinocchio(jid, "Hello") # Say hello to the bot
        yield()
        sleep(0.5)
        say_as_pinocchio(jid, "reconnect") # Try the reconnect procedure
        yield()
        sleep(1)
        say_as_pinocchio(jid, "Hello again")
        yield()
        sleep(0.5)
        say_as_pinocchio(jid, "quit") # Make the bot quit
    end
    botty_task = Threads.@spawn begin
        @info "Connection successful, starting main loop"
        while reconnect
            global reconnect
            global sm_state

            reconnect = false
            conn = LibStrophe.xmpp_conn_new(ctx)
            LibStrophe.xmpp_conn_set_flags(conn, flags)
            LibStrophe.xmpp_conn_set_jid(conn, jid)
            LibStrophe.xmpp_conn_set_pass(conn, password)

            if sm_state ≠ C_NULL # set Stream-Mangement state if available
                LibStrophe.xmpp_conn_set_sm_state(conn, sm_state)
                sm_state = C_NULL
            end

            connection_status = LibStrophe.xmpp_connect_client(conn, host, port, connection_handler_c, ctx)
            if connection_status == LibStrophe.XMPP_EOK
                while LibStrophe.xmpp_conn_is_connected(conn) == 1
                    LibStrophe.xmpp_run_once(ctx, 50) # Run the internal event loop from libstrophe
                    yield()
                end
            else
                @warn "Connection to the server failed! Is the server running? Did you register the test users?"
            end

            if reconnect # If a reconnect was requested.
                sm_state = LibStrophe.xmpp_conn_get_sm_state(conn)
            end

            LibStrophe.xmpp_conn_release(conn) # Release the current connection
        end
    end
    @assert !istaskfailed(speaky_task) "The speaky_task failed"
    @assert !istaskfailed(botty_task) "The botty_task failed"
    waitall([speaky_task, botty_task])
    LibStrophe.xmpp_ctx_free(ctx)
    kill(listener)
    results = readlines(pinocchio)
    expected_results = [
        "pinocchio@localhost: Hello"
        "gepetto@localhost: Hello to you too!"
        "pinocchio@localhost: reconnect"
        "gepetto@localhost: alright, let's see what happens!"
        "pinocchio@localhost: Hello again"
        "gepetto@localhost: Hello again to you too!"
        "pinocchio@localhost: quit"
        "gepetto@localhost: bye!"
    ]
    for (result, expected_result) in zip(results, expected_results)
        @test endswith(result, expected_result)
    end
    @info "End of bot example"
end
