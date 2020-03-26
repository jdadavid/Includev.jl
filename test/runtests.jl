using Includev
using Test
using GR

testfiletoinc = joinpath(@__DIR__,"plotrandomwalk.jl")
includev(testfiletoinc)

