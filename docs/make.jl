push!(LOAD_PATH,joinpath(@__DIR__, ".."))
using Documenter, Vinclude

makedocs(
    modules = [Vinclude],
    format = Documenter.HTML(; prettyurls = get(ENV, "CI", nothing) == "true"),
    authors = "Jacques David",
    sitename = "Vinclude.jl",
    pages = Any["index.md"]
    # strict = true,
    # clean = true,
    # checkdocs = :exports,
)

deploydocs(
    repo = "github.com/jdadavid/Vinclude.jl.git",
)
