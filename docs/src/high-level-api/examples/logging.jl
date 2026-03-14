#=

# [Logging example](@id high-level-loging-example)

This example dives into the specifics of logging using [the basic example](@ref high-level-basic-example).
You may want to start there if you are just starting.

=#

# ## Initialization
# We will not repeat here the explanations of the basic example, let's include all
# the preparations already!

import Strophe
import Strophe: LibStrophe
using Logging

function connection_handler(conn, status, error, stream_error)
    if status == LibStrophe.XMPP_CONN_CONNECT # We just connected
        @info "Connected!"
        Strophe.disconnect(conn)
    else
        @info "Disconnected!"
        Strophe.stop(conn) # stop the event loop
    end
    return nothing
end
conn = Strophe.ClientConnection(host = "localhost", handler = connection_handler)
Strophe.trusttls!(conn)
jid = "gepetto@localhost"
password = "plopiplop"
Strophe.jid!(conn, jid)
Strophe.pass!(conn, password)

# ## Connection
# This time, let's have a logger to intercept even debug-level logs!
debuglogger = ConsoleLogger(stderr, Logging.Debug)
with_logger(debuglogger) do
    Strophe.connect(conn) # Will raise a StropheError if connection fails.
    Strophe.run(conn) # Run the internal event loop from libstrophe
end

# This was **very** verbose! Strophe.jl replaces the default logger of libstrophe
# with the [`Strophe.logger`](@ref) function. You can check its implementation,
# it simply translates the libstrophe log levels (see [`Strophe.LibStrophe.xmpp_log_level_t`](@ref))
# to Julia's logging system.
#
# ## Displaying libstrophe's area parameter
# Libstrophe provides a key `area` that gets attached to the log event. We can
# use the `meta_formatter` argument of [`ConsoleLogger`](https://docs.julialang.org/en/v1/stdlib/Logging/#Base.CoreLogging.ConsoleLogger)
# to add this information to the log statements. We use Base.CoreLogging.default_metafmt
# as a template to get started.

function meta_formatter(level::LogLevel, _module, group, id, file, line)
    @nospecialize
    color = Logging.default_logcolor(level)
    prefix = string(level == Warn ? "Warning" : string(level), '[', group, ']', ':')
    suffix::String = ""
    Info <= level < Warn && return color, prefix, suffix
    _module !== nothing && (suffix *= string(_module)::String)
    if file !== nothing
        _module !== nothing && (suffix *= " ")
        suffix *= contractuser(file)::String
        if line !== nothing
            suffix *= ":$(isa(line, UnitRange) ? "$(first(line))-$(last(line))" : line)"
        end
    end
    !isempty(suffix) && (suffix = "@ " * suffix)
    return color, prefix, suffix
end
debuglogger = ConsoleLogger(stderr, Logging.Debug; meta_formatter)
with_logger(debuglogger) do
    Strophe.connect(conn) # Will raise a StropheError if connection fails.
    Strophe.run(conn) # Run the internal event loop from libstrophe
end

# Now, each log statement also contains the group. However we can do better, for
# example using [LoggingExtras.jl](https://github.com/JuliaLogging/LoggingExtras.jl)
#
# ## Filtering log events based on libstrophe's area
# LoggingExtras.jl's [`EarlyFilteredLogger`](https://julialogging.github.io/reference/loggingextras/#LoggingExtras.EarlyFilteredLogger)
# is well adapted to the task. We can simply write a function that discriminates
# based on the group of the log event.
using LoggingExtras
selected_group = :conn
debuglogger = EarlyFilteredLogger(debuglogger) do (level, _module, group, id)
    return (_module == Strophe && group == selected_group) || (_module != Strophe)
end
with_logger(debuglogger) do
    Strophe.connect(conn) # Will raise a StropheError if connection fails.
    Strophe.run(conn) # Run the internal event loop from libstrophe
end

# We now have a logger that only handles `conn` events!
