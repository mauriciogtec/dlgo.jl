using Pkg
Pkg.activate(".")

using ArgParse
using Profile
using dlgo
using dlgo.Agent
using DelimitedFiles
using DataStructures

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
            default = 6.5
        "--verbose", "-v"
            help = "print results of game to command line"
            arg_type = Bool
            default = true
        "--profile", "-p"
            help = "profile shows time spent per call"
            arg_type = Bool
            default = false
        "--num_rounds", "-m"
            help = "number of mcts rollouts per decision"
            arg_type = Int
            default = 10
        "--print_every", "-e"
            help = "only if verbose, print every?"
            arg_type = Int
            default = 1
    end
    return parse_args(s, as_symbols=true)
end

num_rounds = 100
komi = 6.5
board_size = 9

function main(board_size::Int, num_games::Int, komi::Float64, num_rounds::Int, verbose::Bool, print_every::Int)
    verbose && println("Playing ", num_games, " game(s) with board size ", board_size, "x", board_size)

    tree = MCTSTree()
    agent = MCTSAgent(num_rounds, komi)
    
    for it in 1:num_games
        root = MCTSNode(new_game(board_size), tree)
        
        nmoves = 0
        node = root
        while !is_over(node.state)
            if is_leaf(node)
                expand_leaf!(agent, node, tree)
            end
            node = select_move(agent, node)
            nmoves += 1
        end
        result = compute_game_result(node.state, komi)
        verbose && println("Finished game ", it, " in " , nmoves, " moves with result ", result)
        (it % print_every == 0) && verbose && print_board(node.state.board)

        # traverse save the tree and save data
        update_tree!(tree, root)

        # generate and save tree output data
        featdata = []
        outputdata = []
        to_visit = Queue{MCTSNode}()  # bfs traversal to update storage
        enqueue!(to_visit, root)
        while !isempty(to_visit)
            vnode = dequeue!(to_visit)
            if !is_leaf(vnode)
                feats = features(vnode.state)
                push!(featdata, feats)
                probs = search_probabilities(vnode, 250, .03)
                N = num_visits(vnode)
                Nb = num_wins(vnode)[black]
                Nw = num_wins(vnode)[white]
                wb = N / Nb
                ww = N / Nw
                push!(outputdata, [vec(probs); [N, Nb, Nw, wb, ww]])
                for child in vnode.children
                    enqueue!(to_visit, child)
                end
            end
        end
        featmat = vcat([f' for f in featdata]...)
        outputmat = vcat([o' for o in outputdata]...)
        open("test/testdata/features.csv", "w") do io
            writedlm(io, featmat, ',')
        end
        open("test/testdata/target.csv", "w") do io
            writedlm(io, outputmat, ',')
        end
    end

    # flush data
end

args = parse_commandline()
@time begin
    if args[:profile]
        @profile main(args[:board_size], args[:num_games], args[:komi], args[:num_rounds], args[:verbose], args[:print_every])
        Profile.print(format=:flat)
    else
        main(args[:board_size], args[:num_games], args[:komi], args[:num_rounds], args[:verbose], args[:print_every])
    end
end
