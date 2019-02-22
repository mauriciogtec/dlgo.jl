module dlgo

export Player, black, white, void
export other, isvoid, nbrs
export Point, Move, GoString, GoStringBuffer, IdType, Board, GameState,
       Territory, TerritoryStatus, GameResult
export getindex, setindex!, ==, is_on_grid
export new_game, apply_move, is_valid_move, is_over, resign, play, pass_turn, legal_moves
export grid, stringdict, stringbuffer, getpointid, setpointid!, getstring, 
       setstring!, place_stone!, remove_string!, remove_point!
export tosymbol, print_board, point_from_coords, print_move
export evaluate_territory, score, winnercolor, compute_game_result

include("gotypes.jl")
include("zobrist.jl")
include("goboard.jl")
include("stringrep.jl")
include("scoring.jl")

include("agent/agent.jl")

end