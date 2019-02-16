using Test
using Revise
using Pkg; Pkg.activate(".")

@testset "loadtest" begin
    @test (using dlgo; true) == true
end