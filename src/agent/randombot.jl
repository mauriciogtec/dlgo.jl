struct RandomBot <: AbstractAgent end

"""
    Chooses a random move that preserves own eyes
"""
function select_move(agent::RandomBot, game_state::GameState)::Move
    candidates = Point[]
    for r in 1:game_state.board.num_rows
        for c in 1:game_state.board.num_cols
            candidate = (row=r, col=c)
            if is_valid_move(game_state, play(candidate)) && 
                    !is_point_an_eye(game_state.board, candidate, game_state.next_player)
                push!(candidates, candidate)
            end
        end
    end
    return !isempty(candidates) ? play(rand(candidates)) : pass_turn()
end
