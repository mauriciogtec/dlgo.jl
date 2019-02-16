using Test
using Revise
using Pkg; 
Pkg.activate(".")

using dlgo: RandomBot, Board, GameState
using dlgo: new_game, apply_move, play, is_over, select_move
using dlgo: print_board, point_from_coords, print_move

function main()
    board_size = 5
    game = new_game(board_size)
    bot = RandomBot()

    while !is_over(game)
        println("\u1b[2J")
        print_board(game)

        if game.next_player == -1 # black
            print("-- ")
            human_move = readline(stdin)
            point = point_from_coords(strip(human_move))
            while game.board[point].color != 0
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


main()