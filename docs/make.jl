using Strophe
using Documenter
using Literate

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

DocMeta.setdocmeta!(Strophe, :DocTestSetup, :(using Strophe); recursive = true)

# Add titles of sections and overrides page titles
const titles = Dict(
    # "10-tutorials" => "Tutorials", # example folder title
    "91-developer.md" => "Developer docs",
    "low-level-api" => "Low level API",
    "low-level-api/examples" => "Examples",
    "high-level-api" => "High level API",
    "high-level-api/examples" => "Examples",
)

function recursively_list_pages(folder, skip = []; path_prefix = "")
    pages_list = Any[]
    addindex = false
    for file in readdir(folder)
        if file == "index.md"
            # We add index.md separately to make sure it is the first in the list
            addindex = true
            continue
        end
        # this is the relative path according to our prefix, not @__DIR__, i.e., relative to `src`
        relpath = joinpath(path_prefix, file)
        # full path of the file
        fullpath = joinpath(folder, file)

        if relpath ∈ skip
            continue
        elseif isdir(fullpath)
            # If this is a folder, enter the recursion case
            subsection = recursively_list_pages(fullpath, skip; path_prefix = relpath)

            # Ignore empty folders
            if length(subsection) > 0
                title = if haskey(titles, relpath)
                    titles[relpath]
                else
                    @error "Bad usage: '$relpath' does not have a title set. Fix in 'docs/make.jl'"
                    relpath
                end
                push!(pages_list, title => subsection)
            end

            continue
        end
        if splitext(file)[2] == ".jl"
            Literate.markdown(fullpath, folder)
        elseif splitext(file)[2] != ".md" # non .md files are ignored
            continue
        elseif haskey(titles, relpath) # case 'title => path'
            push!(pages_list, titles[relpath] => relpath)
        else # case 'title'
            push!(pages_list, relpath)
        end
    end
    if addindex
        return [joinpath(path_prefix, "index.md"); pages_list]
    else
        return pages_list
    end
end

function list_pages(skip = [])
    root_dir = joinpath(@__DIR__, "src")
    pages_list = recursively_list_pages(root_dir, skip)
    return pages_list
end

using Changelog
Changelog.generate(
    Changelog.Documenter(),                 # output type
    joinpath(@__DIR__, "../CHANGELOG.md"),  # input file
    joinpath(@__DIR__, "src/96-changelog.md"); # output file
    repo = "Klafyvel/Strophe.jl",           # default repository for links
)

skip = ["high-level-api/examples/bot.md", "high-level-api/examples/logging.md"]

makedocs(;
    modules = [Strophe],
    authors = "klafyvel <hugo@klafyvel.me>",
    repo = "https://github.com/Klafyvel/Strophe.jl/blob/{commit}{path}#{line}",
    sitename = "Strophe.jl",
    format = Documenter.HTML(; canonical = "https://klafyvel.github.io/Strophe.jl"),
    pages = list_pages(skip),
    pagesonly = true,
    warnonly = true,
)

deploydocs(; repo = "github.com/Klafyvel/Strophe.jl")
