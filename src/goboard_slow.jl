# module goboard_slow
# using ..gotypes

import Base: getindex, setindex!, ==

export Board, GameState
export getindex, setindex!, ==, is_on_grid, remove_string!, place_stone!, new_game, is_over, apply_move, is_valid_move


mutable struct Board
    num_rows::Int
    num_cols::Int
    _grid::Matrix{<:Union{Nothing, GoString}}
    Board(num_rows::Int, num_cols::Int) = begin
        @assert num_rows >= 1
        @assert num_cols >= 1
        new(num_rows, num_cols, Union{Nothing, GoString}[nothing for i in 1:num_rows, j in 1:num_cols])
    end
end

Base.getindex(board::Board, p::Point)::Union{Nothing, GoString} = board._grid[p.row, p.col]
Base.setindex!(board::Board, str::Union{Nothing, GoString}, p::Point)::Nothing = (board._grid[p.row, p.col] = str; return)
Base.:(==)(board1::Board, board2::Board)::Bool = (board1._grid == board2._grid)
is_on_grid(board::Board, p::Point)::Bool = (1 <= p.row <= board.num_rows) && (1 <= p.col <= board.num_cols)

function remove_string!(board::Board, string::GoString)::Nothing
    for point in string.stones
        for nbr in nbrs(point)
            nbr_string = board[nbr]
            if nbr_string ≢ nothing
                continue
            elseif nbr_string ≢ string
                add_liberty!(nbr_string, point)
            end
            board[nbr] = nothing  
        end
    end
end

function place_stone!(board::Board, player::Player, point::Point)::Nothing
    @assert is_on_grid(board, point)
    @assert board[point] ≡ nothing

    adjacent_same_color = Point[]
    adjacent_opposite_color = Point[]
    liberties = Point[]

    for nbr in nbrs(point)
        if is_on_grid(board, nbr)
            nbr_string = board[nbr]
            if nbr_string ≡ nothing
                push!(liberties, nbr)
            elseif nbr_string.color ≡ Player && !(nbr_string in adjacent_same_color)
                push!(adjacent_same_color, nbr_string)
            elseif !(nbr_string.color ≡ Player) && !(nbr_string in adjacent_opposite_color)
                push!(adjacent_opposite_color, nbr_string)
            end
        end
    end
    newstring = GoString(player, Set([point]), Set(liberties))

    for same_color_string in adjacent_same_color
        merge!(newstring, same_color_string)
    end
    for newstring_point in newstring.stones
        board[newstring_point] = newstring
    end
    for opposite_color_string in adjacent_opposite_color
        remove_liberty!(opposite_color_string, newstring)
    end
    for opposite_color_string in adjacent_opposite_color
        if num_liberties(opposite_color_string) == 0 
            remove_string!(board, opposite_color_string)
        end
    end
end

# ------------
struct GameState
    board::Board
    next_player::Player
    previous_state::Union{Nothing, GameState}
    last_move::Union{Nothing, Move}
end

new_game(num_rows::Int, num_cols::Int)::GameState = GameState(Board(num_rows, num_cols), black, nothing, nothing)
new_game(size::Int)::GameState = GameState(Board(size, size), black, nothing, nothing)

function is_over(game_state::GameState)::Bool
    last_move = game_state.last_move
    if last_move ≡ nothing
        return false
    elseif last_move.is_resign
        return true
    end

    second_last_move = game_state.last_move.laste_move
    if second_last_move ≡ nothing
        return false
    end

    return last_move.is_pass && second_last_move.is_pass
end

function apply_move(game_state::GameState, move::Move)::GameState
    if move.is_play
        next_board = deepcopy(game_state.board)
        place_stone!(next_board, game_state.next_player, move.point)
    else
        next_board = game_state.board
    end

    return GameState(next_board, other(game_state.next_player), game_state, move)
end

function is_move_self_capture(game_state::GameState, player::Player, move::Move)::Bool
    !move.is_play && (return false)
    next_board = deepcopy(game_state.board)
    place_stone!(next_board, move.point)
    newstring = next_board[move.point]
    return num_liberties(newstring) == 0
end

function does_move_violate_ko(game_state::GameState, player::Player, move::Move)::Bool
    if !move.is_play
        return false
    end
    next_board = deepcopy(game_state.board)
    place_stone!(next_board, move.point)
    next_situation = (other(player), next_board)
    past_state = game_state.previous_state
    while past_state ≢ nothing
        if (past_state.player, past_state.board) == next_situation
            return true
        end
        past_state = past_state.previous_state
    end
    return false
end

function is_valid_move(game_state::GameState, move::Move)::Bool
    if is_over(game_state)
        return false
    elseif move.is_pass || move.is_resign
        return true
    else
        ans = game_state.board[move.point] ≡ nothing &&
            !is_move_self_capture(game_state, game_state.next_player, move) &&
            !does_move_violate_ko(game_state, game_state.next_player, move)
        return ans
    end
end

# end