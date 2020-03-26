push!(LOAD_PATH,joinpath(@__DIR__, ".."))
using Documenter, Includev

makedocs(
    modules = [Includev],
    format = Documenter.HTML(; prettyurls = get(ENV, "CI", nothing) == "true"),
    authors = "Jacques David",
    sitename = "Includev.jl",
    pages = Any["index.md"]
    # strict = true,
    # clean = true,
    # checkdocs = :exports,
)

deploydocs(
    repo = "github.com/jdadavid/Includev.jl.git",
)
