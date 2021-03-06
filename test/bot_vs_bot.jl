using Test
using Pkg; 
Pkg.activate(".")

using ArgParse
using Profile
using dlgo
using dlgo.Agent

function parse_commandline()
    s = ArgParseSettings()
    @add_arg_table s begin
        "--board_size", "-b"
            help = "The game will have dimensions BOARD_SIZExBOARD_SIZE"
            arg_type = Int
            default = 9
        "--num_games", "-n"
            help = "Number of games to play"
            arg_type = Int
            default = 1
        "--komi", "-k"
            help = "White player handicap for scoring"
            arg_type = Float64
            default = 7.5
        "--verbose", "-v"
            help = "print results of game to command line"
            arg_type = Bool
            default = true
        "--profile", "-p"
            help = "profile shows time spent per call"
            arg_type = Bool
            default = false
    end
    return parse_args(s, as_symbols=true)
end


function main(board_size::Int, num_games::Int, komi::Float64, verbose::Bool)
    verbose && println("Playing ", num_games, " game(s) with board size ", board_size, "x", board_size)
    for it in 1:num_games
        game = new_game(board_size)
        bot_black = RandomAgent()
        bot_white = RandomAgent()
        nmoves = 0
        while !is_over(game)
            bot = (game.next_player == black) ? bot_black : bot_white
            move = select_move(bot, game)
            game = apply_move(game, move)
            nmoves += 1
        end
        result = compute_game_result(game, komi)
        verbose && println("Finished game ", it, " in " , nmoves, " moves with result ", result)
        verbose && print_board(game.board)
    end
end

args = parse_commandline()
@time begin
    if args[:profile]
        @profile main(args[:board_size], args[:num_games], args[:komi], args[:verbose])
        Profile.print(format=:flat)
    else
        main(args[:board_size], args[:num_games], args[:komi], args[:verbose])
    end
end