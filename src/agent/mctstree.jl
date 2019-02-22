using Distributions: Beta, Dirichlet
using DataStructures: Queue, enqueue!, dequeue!
import Base: display, show
using Random

# losely basedon alpha zero but simpler
# bonus: uses Thompson sampling instread of uct
# winning probs come from a quick mc sampling

# ----

mutable struct NodeInfo
    num_visits::Int
    num_wins::Dict{Player, Int}
end
NodeInfo()::NodeInfo = NodeInfo(0, Dict(black => 0, white => 0))

mutable struct MCTSNode
    state::GameState
    parent::Union{Nothing, MCTSNode}
    move::Union{Nothing, Move}
    info::NodeInfo 
    children::Vector{MCTSNode}
    _unvisited::Set{Move}
end
info(node::MCTSNode)::NodeInfo = node.info
num_visits(node::MCTSNode)::Int = info(node).num_visits
num_wins(node::MCTSNode)::Dict{Player, Int} = info(node).num_wins
unvisited_moves(node::MCTSNode) = node._unvisited
Base.display(io::IO, node::MCTSNode) = print(io, "Node with $(info(node).num_visits) visits and $(length(node.children)) children")
Base.show(io::IO, node::MCTSNode) = print(io, "Node with $(info(node).num_visits) visits and $(length(node.children)) children")

struct MCTSTree
    _storage::Dict{Int, NodeInfo} # hashcode -> info
end
MCTSTree()::MCTSTree = MCTSTree(Dict{Int, NodeInfo}())
storage(tree::MCTSTree) = tree._storage

function recover_nodeinfo(state, tree::MCTSTree)::NodeInfo
    id = zobristhash(state.board)
    id in keys(storage(tree)) ? storage(tree)[id] : NodeInfo()
end

function candidate_moves(state::GameState)::Vector{Move}
    not_eyes = filter(legal_moves(state)) do move
        !move.is_pass && !is_point_an_eye(state.board, move.point, state.next_player)
    end
    [not_eyes; pass_turn()]
end

MCTSNode(state::GameState, parent::Union{Nothing, MCTSNode}, move::Union{Nothing, Move}, tree::MCTSTree)::MCTSNode =
    MCTSNode(state, parent, move, recover_nodeinfo(state, tree), MCTSNode[], Set(candidate_moves(state)))
MCTSNode(state::GameState, tree::MCTSTree)::MCTSNode = MCTSNode(state, nothing, nothing, tree)

function update_tree!(tree::MCTSTree, node::MCTSNode)::Nothing
    to_visit = Queue{MCTSNode}()  # bfs traversal to update storage
    enqueue!(to_visit, node)
    while !isempty(to_visit)
        vnode = dequeue!(to_visit)
        storage(tree)[zobristhash(vnode.state.board)] = info(vnode)
        if !is_leaf(vnode)
            for child in vnode.children
                enqueue!(to_visit, child)
            end
        end
    end
end

record_win!(node::MCTSNode, winner::Player)::Nothing = (info(node).num_wins[winner] += 1; nothing)
record_visit!(node::MCTSNode)::Nothing = (info(node).num_visits += 1; nothing)

is_leaf(node::MCTSNode)::Bool = (length(node.children) == 0)
is_terminal(node::MCTSNode)::Bool = is_over(info(node).state)
winning_pct(node::MCTSNode, player::Player)::Float64 = info(node).num_wins[player] / info(node).num_visits

struct MCTSAgent <: AbstractAgent
    num_rounds::Int
    komi::Float64
end

function thompson_sampling(children::Vector{MCTSNode}, player::Player)::Int
    childvisits = [info(child).num_visits for child in children]
    childwins = [info(child).num_wins[player] for child in children]
    childvals = [rand(Beta(wins + 1, visits - wins + 1)) for (visits, wins) in zip(childvisits, childwins)]
    argmax(childvals)
end

function select_move(agent::MCTSAgent, node::MCTSNode)::MCTSNode
    # implements Thompson sampling
    children = node.children
    player = node.state.next_player
    best_idx = thompson_sampling(children, player)
    return children[best_idx]
end

function random_child!(agent::MCTSAgent, node::MCTSNode, tree::MCTSTree)::MCTSNode
    move = rand(candidate_moves(node.state))
    new_state = apply_move(node.state, move)
    child = MCTSNode(new_state, node, move, tree)
    if move in unvisited_moves(node)
        delete!(unvisited_moves(node), move)
        push!(node.children, child)
    end
    child
end
select_ramdom_move(agent::MCTSAgent, node::MCTSNode, tree::MCTSTree)::Move = rand(candidate_moves(node))

function expand_leaf!(agent::MCTSAgent, node::MCTSNode, tree::MCTSTree)::Nothing
    @assert is_leaf(node) # leaf node

    for i in 1:agent.num_rounds
        # ==== This part should be neural network/model guided =====
        # <1> choose child at random
        child = random_child!(agent, node, tree)
        # <2> play until end of game
        currstate = child.state
        while !is_over(currstate)
            move = rand(candidate_moves(currstate));
            currstate = apply_move(currstate, move);
        end
        # <3> declare winner
        result = compute_game_result(currstate, agent.komi)
        winner = winnercolor(result)
        # <4> backprop to root, if is not leaf, record winner
        currnode = child
        while currnode !== nothing
            record_win!(currnode, winner)
            record_visit!(currnode)
            currnode = currnode.parent
        end
    end
end


function search_probabilities(node::MCTSNode, mc_sims::Int, ε::Float64)::Matrix{Float64}
    num_rows = node.state.board.num_rows
    num_cols = node.state.board.num_cols
    size = num_rows * num_cols
    noise = reshape(rand(Dirichlet(size, 1.)), num_rows, num_cols)

    children = node.children
    player = node.state.next_player

    prob = ε * noise
    for i in 1:mc_sims
        idx = thompson_sampling(children, player)
        point = children[idx].move.point
        if point.row != 0
            prob[point.row, point.col] += (1.0 - ε) / mc_sims
        end
    end
    return prob  
end