module dlgo

export Player, black, white, void, other
export Point, Move, GoString, GoStringBuffer, IdType, Board, GameState,
       Territory, TerritoryStatus, GameResult, MCTSNode
export getindex, setindex!, ==
export apply_move, is_valid_mode, is_over, resign, play, pass_turn
export grid, stringdict, stringbuffer, getpointid, setpointid!, getstring, 
       setstring!, place_stone!, remove_string!, remove_point!
export tosymbol, print_board, point_from_coords, print_move
export evaluate_territory, score, compute_game_result
export 

include("gotypes.jl")
include("zobrist.jl")
include("goboard.jl")
include("stringrep.jl")
include("scoring.jl")

include("agent/agent.jl")

end