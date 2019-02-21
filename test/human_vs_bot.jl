using Test
using Revise
using Pkg; 
Pkg.activate(".")

using dlgo: RandomBot, Board, GameState, black, white
using dlgo: new_game, apply_move, play, is_over, select_move, isvoid
using dlgo: print_board, point_from_coords, print_move

function main()
    board_size = 5
    game = new_game(board_size)
    bot = RandomBot()

    while !is_over(game)
        println("\u1b[2J")
        print_board(game)

        if game.next_player == black
            print("-- ")
            human_move = readline(stdin)
            point = point_from_coords(strip(human_move))
            while 1isvoid(game.board[point])
                println(game.board[point])
                human_move = readline(stdin)
                point = point_from_coords(strip(human_move))            
            end
            move = play(point)
        else
            move = select_move(bot, game)
        end
        print_move(game.next_player, move)
        game = apply_move(game, move)
    end
end


if PROGRAM_FILE ==  @__FILE__ 
    main()
end
