"""
    Context()

A wrapper for the internal libstrophe context. It handles allocation and
de-allocation for you, as well as translating the internal libstrophe logger to
Julia's native logging system.
"""
mutable struct Context
    ctx::Ptr{LibStrophe.xmpp_ctx_t}
    function Context()
        # log = LibStrophe.xmpp_get_default_logger(LibStrophe.XMPP_LEVEL_INFO)
        _ctx = LibStrophe.xmpp_ctx_new(C_NULL, default_julia_logger)
        ctx = new(_ctx)
        finalizer(ctx) do ctx
            if ctx.ctx ≠ C_NULL
                LibStrophe.xmpp_ctx_free(ctx.ctx)
                ctx.ctx = C_NULL
            end
        end
        return ctx
    end
end
"""
    context(obj)

Get the pointer to the [`LibStrophe.xmpp_ctx_t`](@ref) object associated to `obj`.
"""
context(ctx::Context) = ctx.ctx
context(ctx::Ptr{LibStrophe.xmpp_ctx_t}) = ctx
context(ctx::Ptr{Cvoid}) = ctx

"""
$(SIGNATURES)

Run the internal libstrophe main loop in the context related to `obj` until it
is stopped by a [`stop`](@ref) call. This is not directly wrapping the internal
[`LibStrophe.xmpp_run`](@ref) function. Instead, it is a nearly-identical rewrite
that introduces a `yield()` call after each [`LibStrophe.xmpp_run_once`](@ref)
call, allowing other tasks to be run.

!!! warn
    This does **not** make the library thread-safe, and all Strophe-related things
    should run in the same thread. It does, however, allow you to perform other
    tasks in parallel.

See also [`run_once`](@ref), [`timeout!`](@ref), [`context`](@ref), [`LibStrophe.xmpp_run`](@ref).
"""
function run(obj)
    ctx_ptr = Base.unsafe_convert(Ptr{LibStrophe._ctx}, context(obj))
    if ctx_ptr == C_NULL
        throw(StropheError("Trying to call run on a NULL context."))
    end
    ctx = unsafe_load(ctx_ptr)
    if ctx.loop_status != LibStrophe.XMPP_LOOP_NOTSTARTED
        return
    end

    ctx.loop_status = LibStrophe.XMPP_LOOP_RUNNING
    unsafe_store!(ctx_ptr, ctx)
    while ctx.loop_status == LibStrophe.XMPP_LOOP_RUNNING
        LibStrophe.xmpp_run_once(ctx_ptr, ctx.timeout)
        yield()
        ctx = unsafe_load(ctx_ptr)
    end

    ctx.loop_status = LibStrophe.XMPP_LOOP_NOTSTARTED
    unsafe_store!(ctx_ptr, ctx)

    logger(LibStrophe.XMPP_LEVEL_DEBUG, "event", "Event loop completed.")
    return nothing
end
"""
$(SIGNATURES)

Run one iteration of the internal libstrophe main loop in the context related
to `obj`. Will send queued data, and go through the event loop once. It will wait
no more than `timeout` milliseconds.

See also [`run`](@ref), [`LibStrophe.xmpp_run_once`](@ref).
"""
function run_once(obj, timeout)
    LibStrophe.xmpp_run_once(context(obj), timeout)
    return nothing
end
"""
$(SIGNATURES)

Stop the main loop triggered by [`run`](@ref).

See also [`run`](@ref), [`LibStrophe.xmpp_stop`](@ref).
"""
function stop(obj)
    LibStrophe.xmpp_stop(context(obj))
    return nothing
end
"""
$(SIGNATURES)

Set the `timeout` in milliseconds to use when calling [`run`](@ref).

See also [`run`](@ref), [`LibStrophe.xmpp_ctx_set_timeout`](@ref).
"""
function timeout!(obj, timeout)
    LibStrophe.xmpp_ctx_set_timeout(context(obj), timeout)
    return nothing
end
