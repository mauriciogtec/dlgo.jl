using Distributions: Beta
using Base.Threads
using Random

mutable struct MCTSNode
    state::GameState
    parent::Union{Nothing, MCTSNode}
    move::Union{Nothing, Move}
    win_counts::Dict{Player, Int}
    num_rollouts::Int
    children::Vector{MCTSNode}
    unvisited_moves::Vector{Move}
end

function MCTSNode(
    state::GameState, 
    parent::Union{Nothing, MCTSNode}, 
    move::Union{Nothing, Move}; 
    pseudocounts::Int=1
)::MCTSNode
    MCTSNode(
        state, parent, move, Dict(white => pseudocounts, black => pseudocounts),
        pseudocounts*2, MCTSNode[], legal_moves(state))
end
MCTSNode(state::GameState)::MCTSNode = MCTSNode(state, nothing, nothing)

is_terminal(node::MCTSNode)::Bool = is_over(node.state)
can_add_child(node::MCTSNode)::Bool = !isempty(node.unvisited_moves)
winning_pct(node::MCTSNode, player::Player)::Float64 = node.win_counts[player] / node.num_rollouts

function add_random_child!(node::MCTSNode)::MCTSNode
    index = rand(1:length(node.unvisited_moves))
    new_move = node.unvisited_moves[index]
    deleteat!(node.unvisited_moves, index)
    new_state = apply_move(node.state, new_move)
    new_node = MCTSNode(new_state, node, new_move)
    push!(node.children, new_node)
    new_node
end

function record_win!(node::MCTSNode, winner::Player)::Nothing
    node.win_counts[winner] += 1
    node.num_rollouts += 1
    nothing
end

struct MCTSAgent <: AbstractAgent
    num_rounds::Int
    komi::Float64
end

function select_move(agent::MCTSAgent, state::GameState)
    root = MCTSNode(state)
  
    nodelist = MCTSNode[]
    for i in 1:agent.num_rounds
        node = root
        while !can_add_child(node) && !is_terminal(node)
            node = select_child(agent, node)
        end

        if can_add_child(node)
            node = add_random_child!(node)
        end

        push!(nodelist, node)
    end

    winners = Dict{MCTSNode, Player}()
    @threads for i in 1:length(nodelist)
        node = nodelist[i]
        finalstate = simulate_random_game(node.state)
        result = compute_game_result(finalstate, agent.komi)
        winners[node] = winnercolor(result)
    end

    for (node_, winner) in winners
        node = node_
        while node !== nothing
            record_win!(node, winner)
            node = node.parent
        end
    end

    best_idx = 0
    best_pct = -1.0
    for (i, c) in enumerate(root.children)
        c_pct = winning_pct(c, c.state.next_player) 
        if c_pct > best_pct
            best_idx = i
            best_pct = c_pct
        end
    end
    best_move = root.children[best_idx].move

    return best_move
end

function select_child(agent::MCTSAgent, node::MCTSNode)
    best_val = -1.0
    best_idx = 0
    rollouts = sum([c.num_rollouts for c in node.children])
    for (i, c) in enumerate(node.children)
        wins = c.win_counts[c.state.next_player]
        val = rand(Beta(wins, rollouts - wins))
        if val > best_val
            best_idx = i
            best_val = val
        end
    end
    best_child = node.children[best_idx]

    return best_child
end