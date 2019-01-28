using Test
using Revise

@testset "loadtest" begin
    @test (using dlgo; true) == true
end