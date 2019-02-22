module Agent

using ...dlgo

export AbstractAgent, RandomAgent, MCTSNode, MCTSAgent
export is_point_an_eye, select_move, select_child

abstract type AbstractAgent end

select_move(agent::AbstractAgent, game_state::GameState) = error("unimplemented")

include("utils.jl")
include("randomplay.jl")
include("mcts.jl")

end