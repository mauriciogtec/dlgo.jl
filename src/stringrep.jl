# module stringrep

# import ..dlgo: Player, black, white, Move, Board

const BOARDCOLS = "ABCDEFGHJKLMNOPQRST"
const BOARDCOLSIDX = Dict(letter => i for (i, letter) in enumerate(BOARDCOLS))


function print_move(player::Player, move::Move)::Nothing
    move_str = if move.is_pass
        "passes"
    elseif move.is_resign
        "resigns"
    else
        string(BOARDCOLS[move.point.col]) * string(move.point.row)
    end

    println(tosymbol(player), " ", move_str)
end

function print_board(board::Board)
    for r in reverse(1:board.num_rows)
        bump = (r <= 9) ? " " : ""
        line = " "
        for c in 1:board.num_cols
            line *= tosymbol(board[r, c].color)
        end
        println(bump, r, line)
    end

    println("\n   " * BOARDCOLS[1:board.num_cols])
end

print_board(game_state::GameState) = print_board(game_state.board)

function point_from_coords(coords::AbstractString)::Point
    @assert length(coords) >= 2
    col = BOARDCOLSIDX[coords[1]]
    row = parse(Int, coords[2:end])
    return Point(row, col)
end
# end