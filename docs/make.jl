push!(LOAD_PATH,joinpath(@__DIR__, ".."))
using Documenter, vinclude

makedocs(
    modules = [vinclude],
    format = Documenter.HTML(; prettyurls = get(ENV, "CI", nothing) == "true"),
    authors = "Jacques David",
    sitename = "vinclude.jl",
    pages = Any["index.md"]
    # strict = true,
    # clean = true,
    # checkdocs = :exports,
)

deploydocs(
    repo = "github.com/jdadavid/vinclude.jl.git",
)
