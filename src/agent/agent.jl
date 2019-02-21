module Agent

using ...dlgo

export AbstractAgent, RandomBot
export is_point_an_eye, select_move

abstract type AbstractAgent end
select_move(agent::AbstractAgent, game_state::GameState) = error("unimplemented")