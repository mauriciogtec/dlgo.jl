
abstract type AbstractAgent 
end
select_move(agent::AbstractAgent, game_state::GameState) = error("unimplemented")


function is_point_an_eye(board::Board, point::Point, color::Player)::Bool
    if !isvoid(board[point])
        return false
    end
    for nbr in nbrs(point)
        if is_on_grid(board, nbr)
            if board[nbr].color !== color
                return false
            end
        end
    end

    friendly_corners = 0
    off_board_corners = 0

    corners = [
        (row = point.row - 1, col = point.col - 1), (row = point.row - 1, col = point.col + 1),
        (row = point.row + 1, col = point.col - 1), (row = point.row + 1, col = point.col + 1)       
    ]

    for corner in corners
        if is_on_grid(board, corner)
            if board[corner].color ≡ color
                friendly_corners += 1
            end
        else
            off_board_corners += 1
        end
    end

    ans = (off_board_corners > 0) ? (off_board_corners + friendly_corners == 4) : (friendly_corners >= 3)

    return ans
end
