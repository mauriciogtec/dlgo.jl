# module agent

# using ..gotypes
# using ..goboard_slow

# export AbstractAgent, RandomBot
# export is_point_an_eye, select_move

function is_point_an_eye(board::Board, point::Point, color::Player)::Bool
    if board[point] ≢ nothing
        return false
    end
    for nbr in nbrs(point)
        if is_on_grid(board, nbr)
            if board[nbr] ≢ nothing && board[nbr].color ≢ color
                return false
            end
        end
    end

    friendly_corners = 0
    off_board_corners = 0

    corners = [
        Point(point.row - 1, point.col - 1), Point(point.row - 1, point.col + 1),
        Point(point.row + 1, point.col - 1), Point(point.row + 1, point.col + 1)       
    ]

    for corner in corners
        if is_on_grid(board, corner)
            if board[corner] ≢ nothing && board[corner].color ≡ color
                friendly_corners += 1
            end
        else
            off_board_corners += 1
        end
    end

    ans = (off_board_corners > 0) ? (off_board_corners + friendly_corners == 4) : (friendly_corners >= 3)

    return ans
end

# -----------
abstract type AbstractAgent end
select_move(agent::AbstractAgent, game_state::GameState) = error("unimplemented")

struct RandomBot <: AbstractAgent end

"""
    Chooses a random move that preserves own eyes
"""
function select_move(agent::RandomBot, game_state::GameState)::Move
    candidates = Point[]
    for r in 1:game_state.board.num_rows
        for c in 1:game_state.board.num_cols
            candidate = Point(r, c)
            if is_valid_move(game_state, play(candidate)) && 
                    !is_point_an_eye(game_state.board, candidate, game_state.next_player)
                push!(candidates, candidate)
            end
        end
    end
    
    return !isempty(candidates) ? play(rand(candidates)) : pass_turn()
end


# end