"""
    logger([_userdata::Ptr{Cvoid},] level::LibStrophe.xmpp_log_level_t, area, msg)
A logger to replace libstrophe's default logger and integrate logs in Julia's log system.
`_userdata` is unused here and defaults to `C_NULL`.

The generated log event will have an `area` key corresponding to the `area`
argument of this function.

See also [`LibStrophe.xmpp_get_default_logger`](@ref).
"""
function logger(_userdata::Ptr{Cvoid}, level::LibStrophe.xmpp_log_level_t, _area::Cstring, _msg::Cstring)
    area = unsafe_string(_area)
    msg = unsafe_string(_msg)
    if level == LibStrophe.XMPP_LEVEL_DEBUG
        @debug "$(msg)" _group = Symbol(area)
    elseif level == LibStrophe.XMPP_LEVEL_INFO
        @info "$(msg)" _group = Symbol(area)
    elseif level == LibStrophe.XMPP_LEVEL_WARN
        @warn "$(msg)" _group = Symbol(area)
    else # level == LibStrophe.XMPP_LEVEL_ERROR
        @error "$(msg)" _group = Symbol(area)
    end
    return nothing
end
logger(level, area, msg) = logger(C_NULL, level, area, msg)
logger(
    userdata::Ptr{Cvoid}, level::LibStrophe.xmpp_log_level_t,
    area::AbstractString, msg::AbstractString
) = logger(
    userdata, level,
    Base.unsafe_convert(Cstring, Base.cconvert(Cstring, area)),
    Base.unsafe_convert(Cstring, Base.cconvert(Cstring, msg))
)

const default_julia_logger = Ref{LibStrophe.xmpp_log_t}()
