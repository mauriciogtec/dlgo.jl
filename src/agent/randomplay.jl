
struct RandomAgent <: AbstractAgent end

function select_move(agent::RandomAgent, game_state::GameState)::Move
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

function simulate_random_game(state::GameState)
        game = state
        bot_black = RandomAgent()
        bot_white = RandomAgent()
        while !is_over(game)
            bot = (game.next_player == black) ? bot_black : bot_white
            move = select_move(bot, game)
            game = apply_move(game, move)
        end
        return game
end