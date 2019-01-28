include("go_types.jl")

mutable struct Board
    num_rows::Int
    num_cols::Int
    _grid::Set
end