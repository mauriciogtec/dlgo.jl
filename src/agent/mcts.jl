using Distributions: Beta

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
        state, parent, move, 
        Dict(white => pseudocounts, black => pseudocounts),
        2pseudocounts, MCTSNode[], Point[])
end
MCTSNode(state::GameState)::MCTSNode = MCTSNode(state, nothing, nothing)

is_terminal(node::MCTSNode)::Bool = is_over(node.state)
can_add_child(node::MCTSNode)::Bool = !isempty(node.unvisited_moves)
winning_frac(node::MCTSNode, player::Player)::Float64 = node.win_counts[player] / node.num_rollouts

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
