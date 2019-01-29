# module stringrep

# import ..dlgo: Player, black, white, Move, Board

board_cols()::String = "ABCDEFGHJKLMNOPQRST"

function stone_to_string(x::GoString)::String 
    if x.color ≡ black
        return "x"
    elseif x.color ≡ white
        return "o"
    else
        throw(ArgumentError)
    end
end
stone_to_string(x::Nothing)::String = "."


function print_move(player::Player, move::Move)::Nothing
    move_str = if move.is_pass
        "passes"
    elseif move.is_resign
        "resigns"
    else
        string(col(move.point.col)) + string(move.point.row)
    end

    println(string(player), " ", move_str)
end

function print_board(board::Board)
    for r in reverse(1:board.num_rows)
        bump = (r <= 9) ? " " : ""
        line = " "
        for c in 1:board.num_cols
            stone = board[Point(r, c)]
            line *= stone_to_string(stone)
        end
        println(bump, r, line)
    end

    println("\n   " * board_cols()[1:board.num_cols])
end

print_board(game_state::GameState) = print_board(game_state.board)

# end