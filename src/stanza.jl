"""
Wraps a pointer to a libstrophe stanza, handling release at finalization.

# Constructors

    Stanza()
    Stanza(ctx)
    Stanza(ctx; text)
    Stanza(ctx; name, attributes...)
Construct a stanza by extracting the context of `ctx` using [`context`](@ref).
Defaults to using the default context.
The `name` keyword will make constructor call [`name!`](@ref) function on the
stanza and make it a tag stanza. The other keyword arguments `attributes`.
should be of type `AbstractString` and will be passed to `setindex!`, and require
the `name` keyword argument. The `text` keyword will make the constructor
call the [`text!`](@ref) function on the stanza and make it a text stanza. This
keyword arguments thus excludes the use of others.

    Stanza([ctx,] str::String)
Construct a stanza from the given string. Will throw a [`StropheError`](@ref) on
failure. Defaults to using the default context.
See also [`LibStrophe.xmpp_stanza_new_from_string`](@ref).

    Stanza(stanza::Stanza)
Copy an existing stanza along with all its children and returns the new stanza
and children with a reference count of 1. The returned stanza will have no
parent and no siblings. This is useful for extracting a child stanza for
inclusion in another tree. See also [`LibStrophe.xmpp_stanza_copy`](@ref).

See also [`message`](@ref), [`reply`](@ref), [`iq`](@ref), [`presence`](@ref),
[`reply_error`](@ref), [`stream_error`](@ref) for specialized constructors.

# Callable API

`Stanza` object are callable. This allows you to build stanzas with children in
a compact way. The return value of calling a `Stanza` object is the object itself.
In the following, we assume `s` is a `Stanza` object.

    s(text)
If `s` is not a tag stanza, set the `text` of a stanza (making it a text stanza).
Otherwise, add a text child containing `text`.

    s(children...[; attributes])
When `s` is a tag stanza, add children to the stanza, and optionally add the
relevant `attributes`. The children will be rendered unusable after that and should
be considered released.

# Examples

Here are two ways of creating the `<iq/>` following stanza (inspired by the
[bot example](@ref high-level-bot-example)):
```xml
<iq
    type='result'
    to='romeo@example.net'
    from='juliet@example.com'
    id='version_1'>
  <query xmlns='jabber:iq:version'>
    <name>LibStrophe example bot</name>
    <version>1.0</version>
  </query>
</iq>
```

First manually:
```julia
Stanza(name="iq", type="result",
       to="romeo@example.net", from="juliet@example.com",
       id="version_1")(
    Stanza(name="query", xmlns="jabber:iq:version")(
        Stanza(name="name")("LibStrophe example bot"),
        Stanza(name="version")("1.0")
    )
)
```
Alternatively, using convenience constructors and functions:
```julia
iq(type="result", id="version_1")(
    Stanza(name="query", xmlns="jabber:iq:version")(
        Stanza(name="name")("LibStrophe example bot"),
        Stanza(name="version")("1.0")
    )
)
```
Note that you can also build the stanza bits by bits:
```julia
s = iq(type="result")
id!(s, "version_1")
to!(s, "romeo@example.net")
from!(s, "juliet@example.com")
query = Stanza()
name!(query, "query")
ns!(query, "jabber:iq:version")
name = Stanza(name="name")("LibStrophe example bot")
version = Stanza(name="version")("1.0")
child!(query, name)
child!(query, version)
child!(iq, query)
```

!!! note
    Unlike when using the [low-level API](@ref low-level-api), you do not need
    to take care of memory management manually here.

See also [`iq`](@ref), [`id!`](@ref), [`to!`](@ref), [`from!`](@ref), [`name!`](@ref),
[`ns!`](@ref), [`child!`](@ref).
"""
mutable struct Stanza
    stanza::Ptr{LibStrophe.xmpp_stanza_t}
    released::Bool
    function Stanza(s::Ptr{LibStrophe.xmpp_stanza_t}, released::Bool = false)
        obj = new(s, released)
        Base.finalizer(obj) do s::Stanza
            if s.stanza ≠ C_NULL && !s.released
                release!(s)
            end
        end
        return obj
    end
end

const StanzaTypes = Union{Stanza, Ptr{LibStrophe.xmpp_stanza_t}}

"""
    stanza(obj)

Get the pointer to the [`LibStrophe.xmpp_stanza_t`](@ref) object associated to `obj`.
"""
function stanza(obj::Stanza)
    if obj.stanza == C_NULL
        throw(StropheError("Trying to access a freed stanza."))
    end
    return obj.stanza
end
stanza(obj::Ptr{LibStrophe.xmpp_stanza_t}) = obj
stanza(obj::Ptr{Cvoid}) = obj
context(obj::Stanza) = LibStrophe.xmpp_stanza_get_context(stanza(obj))
context(obj::Ptr{LibStrophe.xmpp_stanza_t}) = LibStrophe.xmpp_stanza_get_context(obj)

Stanza(; kwargs...) = Stanza(context(); kwargs...)
function Stanza(obj; kwargs...)
    has_name = haskey(kwargs, :name)
    has_text = haskey(kwargs, :text)
    has_name && has_text && throw(ArgumentError("Stanza cannot have a name and text."))
    has_text && length(kwargs) > 1 && throw(ArgumentError("`text` keyword argument forbids adding attributes."))
    ctx = context(obj)
    stanza = LibStrophe.xmpp_stanza_new(ctx)
    if has_name
        name = kwargs[:name]
        name!(stanza, name)
        for (k, v) in kwargs
            if k == :name
                continue
            else
                stanza[string(k)] = v
            end
        end
    elseif has_text
        text!(stanza, kwargs[:text])
    end
    return Stanza(stanza, false)
end

Stanza(s::String) = Stanza(context(), s)
function Stanza(ctx, s::String)
    stanza = LibStrophe.xmpp_stanza_new_from_string(context(ctx), s)
    if stanza == C_NULL
        throw(StropheError("Failed to create a valid stanza fro string."))
    end
    return Stanza(stanza)
end

function Stanza(s::Stanza)
    new_stanza = LibStrophe.xmpp_stanza_copy(stanza(s))
    return Stanza(new_stanza)
end

"""
    clone!(stanza)
Clone a stanza. The returned [`Stanza`](@ref) object will point to the same
[`LibStrophe.xmpp_stanza_t`](@ref) object, with its reference counter increased
by one.

See also [`LibStrophe.xmpp_stanza_clone`](@ref).
"""
clone!(s) = Stanza(LibStrophe.xmpp_stanza_clone(stanza(s)))
"""
    release!(stanza)
Release a stanza object and all of its children. This will cause the stanza's
context to decrement the stanza's counter, and will lead to the object(s) to
be freed if the counter falls to zero. In this case, accessing the stanza is no
longer valid. This is typically used by the finalizer of [`Stanza`](@ref).
"""
function release!(s::Stanza)
    r = LibStrophe.xmpp_stanza_release(stanza(s))
    if r == 1
        s.stanza = C_NULL
    end
    s.released = true
    return nothing
end
"""
    is_text(stanza)
Return true if the `stanza` is a text node.
"""
is_text(obj) = LibStrophe.xmpp_stanza_is_text(stanza(obj)) == 1
"""
    is_tag(stanza)
Return true if the `stanza` is a tag node.
"""
is_tag(obj) = LibStrophe.xmpp_stanza_is_tag(stanza(obj)) == 1

"""
    render_to_string(stanza)
Render a `stanza` to text.
"""
function render_to_string(obj)
    s = stanza(obj)
    buflen = Ref{Csize_t}()
    buf = Ptr{Cstring}()
    return_code = LibStrophe.xmpp_stanza_to_text(s, buf, buflen)
    if return_code < 0
        throw(StropheError("Could not render stanza to string."))
    end
    return_cstring = unsafe_load(buf)
    return_string = unsafe_string(return_cstring)
    LibStrophe.xmpp_free(context(s), convert(Ptr{Cvoid}, return_cstring))
    return return_string
end

struct SiblingIterator
    init::Ptr{LibStrophe.xmpp_stanza_t}
end
Base.IteratorSize(::Type{SiblingIterator}) = Base.SizeUnknown()
Base.IteratorEltype(::Type{SiblingIterator}) = Base.HasEltype()
Base.eltype(::Type{SiblingIterator}) = Stanza # Ptr{LibStrophe.xmpp_stanza_t}
Base.isdone(::SiblingIterator, state::Ptr{LibStrophe.xmpp_stanza_t}) = state == C_NULL
function Base.iterate(it::SiblingIterator, next::Ptr{LibStrophe.xmpp_stanza_t} = it.init)
    next == C_NULL && return nothing
    current = Stanza(next, true)
    next = LibStrophe.xmpp_stanza_get_next(next)
    return current, next
end
"""
    children(stanza)
Iterate over the children of a `stanza`.

See also [`LibStrophe.xmpp_stanza_get_children`](@ref).
"""
function children(obj)
    s = stanza(obj)
    init = LibStrophe.xmpp_stanza_get_children(s)
    return SiblingIterator(init)
end


"""
    child(stanza, name)
Get the first child of `stanza` named `name`, or return `nothing` if none is found.

See also [`LibStrophe.xmpp_stanza_get_child_by_name`](@ref).
"""
function child(obj, name::AbstractString)
    s = stanza(obj)
    found = LibStrophe.xmpp_stanza_get_child_by_name(s, name)
    if found == C_NULL
        return nothing
    else
        return Stanza(found, true)
    end
end

"""
    child(stanza, name, ns)
Get the first child of `stanza` named `name` and in namespace `ns`, or return
nothing if none is found.

See also [`LibStrophe.xmpp_stanza_get_child_by_name_and_ns`](@ref).
"""
function child(obj, name::AbstractString, ns::AbstractString)
    s = stanza(obj)
    found = LibStrophe.xmpp_stanza_get_child_by_name_and_ns(s, name, ns)
    if found == C_NULL
        return nothing
    else
        return Stanza(found, true)
    end
end

"""
    child(stanza; name, ns)
Get the first child of `stanza` named `name` and in namespace `ns`, or return
`nothing` if none is found. Both keywords can be specified, and at least one
must be specified.

See also [`LibStrophe.xmpp_stanza_get_child_by_name`](@ref), [`LibStrophe.xmpp_stanza_get_child_by_ns`](@ref), [`LibStrophe.xmpp_stanza_get_child_by_name_and_ns`](@ref).
"""
function child(obj; kwargs...)
    has_ns = haskey(kwargs, :ns)
    has_name = haskey(kwargs, :name)
    if !has_ns && has_name
        return child(obj, kwargs[:name])
    elseif has_ns && !has_name
        ns = kwargs[:ns]
        s = stanza(obj)
        found = LibStrophe.xmpp_stanza_get_child_by_ns(s, ns)
        if found == C_NULL
            return nothing
        else
            return Stanza(found, true)
        end
    elseif !has_ns && !has_name
        throw(ArgumentError("At least one keyword argument `name` or `ns` must be specified."))
    else
        name = kwargs[:name]
        ns = kwargs[:ns]
        return child(obj, name, ns)
    end
end


"""
    siblings(stanza)
Iterate over the next siblings of `stanza`.

See also [`LibStrophe.xmpp_stanza_get_next`](@ref).
"""
function siblings(obj)
    s = stanza(obj)
    next = LibStrophe.xmpp_stanza_get_next(s)
    return SiblingIterator(next)
end

"""
    child!(stanza, child[; do_clone=true])

Add to `stanza` the child `child`. if `do_clone` is set to `false`, the user
releases ownership of the child and must not release it or transfer ownership.

Will throw a [`StropheError`](@ref) when adding the child fails.

See also [`LibStrophe.xmpp_stanza_add_child`](@ref),
[`LibStrophe.xmpp_stanza_add_child_ex`](@ref).
"""
function child!(obj, child; do_clone = true)
    s = stanza(obj)
    c = stanza(child)
    ret = LibStrophe.XMPP_EOK
    if do_clone
        ret = LibStrophe.xmpp_stanza_add_child(s, c)
    else
        ret = LibStrophe.xmpp_stanza_add_child_ex(s, c, 0)
    end
    if ret < 0
        throw(StropheError("Failed to add a child."))
    end
    return nothing
end

"""
    getindex(stanza, attribute)
Get an `attribute` from a `stanza`. Throws a `KeyError` if the attribute does not
exist.

See also [`LibStrophe.xmpp_stanza_get_attribute`](@ref).
"""
function Base.getindex(obj::StanzaTypes, attribute::AbstractString)
    ret = LibStrophe.xmpp_stanza_get_attribute(stanza(obj), attribute)
    if ret == C_NULL
        throw(KeyError("No attribute $(attribute) found in stanza."))
    end
    result = unsafe_string(ret)
    return result
end

"""
    keys(stanza)

Return the list of attributes defined for the `stanza`.

See also [`LibStrophe.xmpp_stanza_get_attribute_count`](@ref), [`LibStrophe.xmpp_stanza_get_attributes`](@ref), [`Base.pairs`](@ref).
"""
function Base.keys(obj::StanzaTypes)
    return map(first, pairs(obj))
end

"""
    values(stanza)

Return the list of attributes defined for the `stanza`.

See also [`LibStrophe.xmpp_stanza_get_attribute_count`](@ref), [`LibStrophe.xmpp_stanza_get_attributes`](@ref), [`Base.pairs`](@ref).
"""
function Base.values(obj::StanzaTypes)
    return map(last, pairs(obj))
end

"""
    pairs(stanza)
Return the an array of attribute `key=>value` pairs.

See also [`LibStrophe.xmpp_stanza_get_attribute_count`](@ref), [`LibStrophe.xmpp_stanza_get_attributes`](@ref), [`Base.pairs`](@ref).
"""
function Base.pairs(obj::StanzaTypes)
    s = stanza(obj)
    number_of_attributes = LibStrophe.xmpp_stanza_get_attribute_count(s)
    attribute_pointers = Array{Ptr{Cchar}, 1}(undef, 2number_of_attributes)
    LibStrophe.xmpp_stanza_get_attributes(s, attribute_pointers, 2number_of_attributes)
    result = Array{Pair{String, String}, 1}(undef, number_of_attributes)
    for i in 1:number_of_attributes
        key = unsafe_string(attribute_pointers[2(i - 1) + 1])
        value = unsafe_string(attribute_pointers[2i])
        result[i] = key => value
    end
    return result
end

"""
    text(stanza)
Get the text data for a text stanza.

See also [`LibStrophe.xmpp_stanza_get_text`](@ref), [`text!`](@ref).
"""
function text(obj)
    s = stanza(obj)
    t = LibStrophe.xmpp_stanza_get_text(s)
    result = unsafe_string(t)
    ctx = LibStrophe.xmpp_stanza_get_context(s)
    LibStrophe.xmpp_free(ctx, t)
    return result
end

"""
    name(stanza)
Get the stanza name.

See also [`LibStrophe.xmpp_stanza_get_name`](@ref), [`name!`](@ref).
"""
function name(obj)
    s = stanza(obj)
    t = LibStrophe.xmpp_stanza_get_name(s)
    result = unsafe_string(t)
    return result
end

"""
    setindex!(stanza, value, key)

Set a `stanza` attribute `key` to `value`. Throws a [`StropheError`](@ref) on
failure.

See also [`LibStrophe.xmpp_stanza_set_attribute`](@ref).
"""
function Base.setindex!(obj::StanzaTypes, value::AbstractString, key::AbstractString)
    s = stanza(obj)
    r = LibStrophe.xmpp_stanza_set_attribute(s, key, value)
    if r < 0
        throw(StropheError("Unable to set attribute $(key)=>$(value)."))
    end
    return nothing
end

"""
    name!(stanza, name)
Set the `name` of a `stanza`. Throws a [`StropheError`](@ref) on failure.

See also [`LibStrophe.xmpp_stanza_set_name`](@ref), [`name`](@ref).
"""
function name!(obj, name)
    s = stanza(obj)
    r = LibStrophe.xmpp_stanza_set_name(s, name)
    if r < 0
        msg = "Error while setting name"
        if r == LibStrophe.XMPP_EMEM
            msg *= " (memory error)"
        elseif r == LibStrophe.XMPP_EINVOP
            msg *= " (invocation error)"
        end
        msg *= "."
        throw(StropheError(msg))
    end
    return nothing
end

"""
    text!(stanza, text)
Set the `text` data for a text `stanza`. This will throw a [`StropheError`](@ref)
when ran on a `stanza` that has a name.

See also [`text`](@ref), [`LibStrophe.xmpp_stanza_set_text`](@ref).
"""
function text!(obj, text)
    s = stanza(obj)
    r = LibStrophe.xmpp_stanza_set_text(s, text)
    if r < 0
        msg = "Unable to set stanza's text"
        if r == LibStrophe.XMPP_EINVOP
            msg *= " (stanza has a name)"
        end
        msg *= "."
        throw(StropheError(msg))
    end
    return nothing
end

"""
    delete!(stanza, attribute)

Delete the `attribute` of `stanza`.

See also [`LibStrophe.xmpp_stanza_del_attribute`](@ref).
"""
function Base.delete!(obj::StanzaTypes, attribute::AbstractString)
    s = stanza(obj)
    r = LibStrophe.xmpp_stanza_del_attribute(s, attribute)
    if r < 0
        throw(StropheError("Failed to delete attribute $(attribute)."))
    end
    return nothing
end

"""
$(SIGNATURES)

Get the namespace attribute of `stanza`. Return the string with the 'xmlns'
attribute value, or nothing if it does not exist.

See also [`ns!`](@ref), [`LibStrophe.xmpp_stanza_get_ns`](@ref).
"""
function ns(obj)
    s = stanza(obj)
    r = LibStrophe.xmpp_stanza_get_ns(s)
    if r == C_NULL
        return nothing
    else
        return unsafe_string(r)
    end
end
"""
$(SIGNATURES)

Set the namespace attribute of `stanza`.

See also [`ns`](@ref), [`LibStrophe.xmpp_stanza_set_ns`](@ref).
"""
function ns!(obj, ns)
    s = stanza(obj)
    r = LibStrophe.xmpp_stanza_set_ns(s, ns)
    if r < 0
        throw(StropheError("Unable to set the namespace of stanza."))
    end
    return nothing
end

"""
$(SIGNATURES)

Get the type attribute of `stanza`. Return the string with the 'type'
attribute value, or nothing if it does not exist.
.

See also [`type!`](@ref), [`LibStrophe.xmpp_stanza_get_type`](@ref).
"""
function type(obj)
    s = stanza(obj)
    r = LibStrophe.xmpp_stanza_get_type(s)
    if r == C_NULL
        return nothing
    else
        return unsafe_string(r)
    end
end
"""
$(SIGNATURES)

Set the type attribute of `stanza`.

See also [`type`](@ref), [`LibStrophe.xmpp_stanza_set_type`](@ref).
"""
function type!(obj, type)
    s = stanza(obj)
    r = LibStrophe.xmpp_stanza_set_type(s, type)
    if r < 0
        throw(StropheError("Unable to set the type of stanza."))
    end
    return nothing
end

"""
$(SIGNATURES)

Get the id attribute of `stanza`. Return the string with the 'id' attribute
value, or nothing if it does not exist.

See also [`id!`](@ref), [`LibStrophe.xmpp_stanza_get_id`](@ref).
"""
function id(obj)
    s = stanza(obj)
    r = LibStrophe.xmpp_stanza_get_id(s)
    if r == C_NULL
        return nothing
    else
        return unsafe_string(r)
    end
end
"""
$(SIGNATURES)

Set the id attribute of `stanza`.

See also [`id`](@ref), [`LibStrophe.xmpp_stanza_set_id`](@ref).
"""
function id!(obj, id)
    s = stanza(obj)
    r = LibStrophe.xmpp_stanza_set_id(s, id)
    if r < 0
        throw(StropheError("Unable to set the id of stanza."))
    end
    return nothing
end

"""
$(SIGNATURES)

Get the to attribute of `stanza`. Return the string with the 'to' attribute
value, or nothing if it does not exist.

See also [`to!`](@ref), [`LibStrophe.xmpp_stanza_get_to`](@ref).
"""
function to(obj)
    s = stanza(obj)
    r = LibStrophe.xmpp_stanza_get_to(s)
    if r == C_NULL
        return nothing
    else
        return unsafe_string(r)
    end
end
"""
$(SIGNATURES)

Set the to attribute of `stanza`.

See also [`to`](@ref), [`LibStrophe.xmpp_stanza_set_to`](@ref).
"""
function to!(obj, to)
    s = stanza(obj)
    r = LibStrophe.xmpp_stanza_set_to(s, to)
    if r < 0
        throw(StropheError("Unable to set the to of stanza."))
    end
    return nothing
end

"""
$(SIGNATURES)

Get the from attribute of `stanza`. Return the string with the 'from' attribute
value, or nothing if it does not exist.

See also [`from!`](@ref), [`LibStrophe.xmpp_stanza_get_from`](@ref).
"""
function from(obj)
    s = stanza(obj)
    r = LibStrophe.xmpp_stanza_get_from(s)
    if r == C_NULL
        return nothing
    else
        return unsafe_string(r)
    end
end
"""
$(SIGNATURES)

Set the from attribute of `stanza`.

See also [`from`](@ref), [`LibStrophe.xmpp_stanza_set_from`](@ref).
"""
function from!(obj, from)
    s = stanza(obj)
    r = LibStrophe.xmpp_stanza_set_from(s, from)
    if r < 0
        throw(StropheError("Unable to set the from of stanza."))
    end
    return nothing
end

"""
$(SIGNATURES)

Create a stanza object in reply to another.

See also [`LibStrophe.xmpp_stanza_reply`](@ref).
"""
function reply(obj)
    s = stanza(obj)
    reply = LibStrophe.xmpp_stanza_reply(s)
    return Stanza(reply, false)
end

"""
    reply_error(stanza, error_type, condition[, text])

Create an error stanza object in reply to the provided stanza.

Check https://tools.ietf.org/html/rfc6120#section-8.3 for details.

Parameters:
* `stanza` the stanza to reply to
* `error_type` the type attribute for the `<error/>` child element
* `condition` the defined-condition (e.g. "item-not-found")
* `text` optional description

See also [`LibStrophe.xmpp_stanza_reply_error`](@ref).
"""
function reply_error(obj, type::AbstractString, condition::AbstractString)
    s = stanza(obj)
    reply = LibStrophe.xmpp_stanza_reply_error(s, type, condition, C_NULL)
    return Stanza(reply, false)
end
function reply_error(obj, type::AbstractString, condition::AbstractString, text::AbstractString)
    s = stanza(obj)
    reply = LibStrophe.xmpp_stanza_reply_error(s, type, condition, text)
    return Stanza(reply, false)
end

"""
    message([ctx]; type, to, id)
Create a `<message/>` stanza object with the given attributes. Attributes are
optional. Defaults to the default context.

See also [`LibStrophe.xmpp_message_new`](@ref).
"""
function message(obj; kwargs...)
    type = get(kwargs, :type, C_NULL)
    to = get(kwargs, :to, C_NULL)
    id = get(kwargs, :id, C_NULL)
    ctx = context(obj)
    s = LibStrophe.xmpp_message_new(ctx, type, to, id)
    return Stanza(s, false)
end
message(; kwargs...) = message(context(); kwargs...)

"""
    body(message)
Get text from `<body/>` child element. Will return `nothing` when
`message` does not have a `<body/>` element and on memory allocation error.

See also [`LibStrophe.xmpp_message_get_body`](@ref), [`body!`](@ref).
"""
function body(obj)
    msg = stanza(obj)
    r = LibStrophe.xmpp_message_get_body(msg)
    if r == C_NULL
        return nothing
    end
    ctx = LibStrophe.xmpp_stanza_get_context(msg)
    result = unsafe_string(r)
    LibStrophe.xmpp_free(ctx, r)
    return result
end
"""
    body!(message, text)
Add a `<body/>` child element to a `<message/>` stanza with the given `text`.
Will throw a `StropheError` on failure.

See also [`LibStrophe.xmpp_message_set_body`](@ref), [`body`](@ref).
"""
function body!(obj, text)
    msg = stanza(obj)
    r = LibStrophe.xmpp_message_set_body(msg, text)
    if r < 0
        throw(StropheError("Failure to set message body."))
    end
    return nothing
end

"""
    iq([ctx]; type, id)
Create a `<iq/>` stanza object with given attributes. Attributes are optional.
Defaults to the default context.

See also [`LibStrophe.xmpp_iq_new`](@ref).
"""
function iq(obj; kwargs...)
    type = get(kwargs, :type, C_NULL)
    id = get(kwargs, :id, C_NULL)
    ctx = context(obj)
    s = LibStrophe.xmpp_iq_new(ctx, type, id)
    return Stanza(s, false)
end
iq(; kwargs...) = iq(context(); kwargs...)

"""
    presence([ctx])
Create a `<presence/>` stanza object. Defaults to the default context.

See also [`LibStrophe.xmpp_presence_new`](@ref).
"""
function presence(obj)
    ctx = context(obj)
    s = LibStrophe.xmpp_presence_new(ctx)
    return Stanza(s, false)
end
presence() = presence(context())

"""
    stream_error([ctx]; type, text)
Create an `<stream:error/>` stanza object with given `type` and an optional error
`text`. Defaults to the default context.

See also [`LibStrophe.xmpp_error_new`](@ref)
"""
function stream_error(obj; type, kwargs...)
    text = get(kwargs, :text, C_NULL)
    ctx = context(obj)
    s = LibStrophe.xmpp_error_new(ctx, type, text)
    return Stanza(s, false)
end
stream_error(; kwargs...) = stream_error(context(); kwargs...)

function (s::Stanza)(text::AbstractString)
    if !is_tag(s)
        text!(s, text)
    else
        s(Stanza(context(s))(text))
    end
    return s
end

function (s::Stanza)(children::Stanza...; attributes...)
    if !is_tag(s)
        throw(ArgumentError("Cannot add children to a non-tag stanza. Give it a name first!"))
    end
    for child in children
        child!(s, child, do_clone = false)
        child.released = true
    end
    for (k, v) in attributes
        s[string(k)] = v
    end
    return s
end
