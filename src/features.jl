function features(board::Board)
    black_stones = zeros(Int, board.num_rows, board.num_cols)
    white_stones = zeros(Int, board.num_rows, board.num_cols)
    for r in 1:board.num_rows
        for c in 1:board.num_cols
            if board[r, c].color === black
                black_stones[r, c] = 1
            elseif board[r, c].color === white
                white_stones[r, c] = 1
            end
        end
    end
    return Int[vec(black_stones); vec(white_stones)]
end

function features(game_state::GameState)
    feats = Int[]
    state = game_state
    for lag in 1:8
        append!(feats, features(state.board))
        if state.prev !== nothing
            state = state.prev
        end
    end
    push!(feats, Int(state.next_player == black))
    feats
end