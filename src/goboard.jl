import Base: getindex, setindex!, ==, copy, show, print
using Base.Enums


mutable struct Board
    num_rows::Int
    num_cols::Int
    _grid::Matrix{IdType} # points to the gostring id
    _stringbuffer::GoStringBuffer # points the id to string
    _hash::Int
end

# External constructor
function Board(num_rows::Int, num_cols::Int)::Board
    emptymat = fill(0, num_rows, num_cols)
    stringbuffer = GoStringBuffer(Dict(IdType(0) => EMPTY_STRING), IdType(0))
    Board(num_rows, num_cols, emptymat, stringbuffer, EMPTY_BOARD_HASH)
end

# setters getters for dicts
grid(board::Board)::Matrix{IdType} = board._grid
is_on_grid(board::Board, p::Point)::Bool = checkbounds(Bool, grid(board), p.row, p.col)

stringbuffer(board::Board)::GoStringBuffer = board._stringbuffer
stringdict(board::Board)::Dict{IdType, GoString} = stringbuffer(board).dict
getpointid(board::Board, i::Int, j::Int)::IdType = board._grid[i, j]
getpointid(board::Board, p::Point)::IdType = getpointid(board, p.row, p.col)
setpointid!(board::Board, id::IdType, i::Int, j::Int)::Nothing = (board._grid[i, j] = id; nothing)
setpointid!(board::Board, id::IdType, p::Point)::Nothing = setpointid!(board, id, p.row, p.col)

getstring(board::Board, id::IdType)::GoString = stringdict(board)[id]
setstring!(board::Board, s::GoString, id::IdType)::Nothing = (setindex!(stringdict(board), s, id); nothing)
newid!(board::Board)::IdType = stringbuffer(board).lastid += IdType(1)

# advanced indexing (try not to use setindex)
Base.getindex(board::Board, i::Int, j::Int)::GoString = getstring(board, getpointid(board, i, j))
Base.getindex(board::Board, p::Point)::GoString = Base.getindex(board, p.row, p.col)
Base.setindex!(board::Board, string::GoString, i::Int, j::Int)::Nothing = (setstring!(board, string, getpointid(board, i, j)); nothing)
Base.setindex!(board::Board, string::GoString, p::Point)::Nothing = (Base.setindex!(board, string, p.row, p.col); nothing)

# equality
Base.:(==)(board1::Board, board2::Board)::Bool = (board1._grid == board2._grid)

# hashing
zobristhash(board::Board)::Int = board._hash
update_hash!(board::Board, i::Int, j::Int, player::Player)::Int = board._hash ⊻= HASH_CODE[i, j, player]
update_hash!(board::Board, p::Point, player::Player)::Int = update_hash!(board, p.row, p.col, player)

# copymethods
function copy(board::Board)::Board # useful for new iteration
    sb = stringbuffer(board)
    sbcopy = GoStringBuffer(Dict(k => copy(v) for (k, v) in sb.dict), sb.lastid)
    gridcopy = copy(grid(board))
    Board(board.num_rows, board.num_cols, gridcopy, sbcopy, zobristhash(board))
end

# function copyatpoint(board::Board, point::Point)::Board # useful for check valid move
#     id = grid(board)[point.row, point.col]
#     sb = stringbuffer(board)
#     sbcopy = StringBuffer(Dict(i => (i == id ? copy(v) : v) for (i, v) in sb.dict), sb.lastid)
#     gridcopy = copy(board._grid)
#     Board(board.num_rows, board.num_cols, gridcopy, sbcopy, board._hash)
# end

function remove_point!(board::Board, p::Point)::Nothing
    setpointid!(board, IdType(0), p)
end

function remove_string!(board::Board, string::GoString)::Nothing
    @assert !isvoid(string)
    for point in string.stones
        for nbr in nbrs(point)
            if is_on_grid(board, nbr)
                nbr_string = board[nbr]
                if isvoid(nbr_string)
                    continue
                elseif nbr_string !== string
                    add_liberty!(nbr_string, point)
                end
            end
        end
        remove_point!(board, point)
        update_hash!(board, point, string.color)
    end
    delete!(stringdict(board), string.id)
    nothing
end

function place_stone!(board::Board, player::Player, point::Point)::Nothing
    @assert is_on_grid(board, point)
    @assert isvoid(board[point])

    adjacent_same_color = Set{GoString}()
    adjacent_opposite_color = Set{GoString}()
    liberties = Set{Point}()

    for nbr in nbrs(point)
        if is_on_grid(board, nbr)
            nbr_string = board[nbr]
            if isvoid(nbr_string)
                push!(liberties, nbr)
            elseif nbr_string.color === player
                push!(adjacent_same_color, nbr_string)
            else
                push!(adjacent_opposite_color, nbr_string)
            end
        end
    end


    if isempty(adjacent_same_color)
        newstring_id = newid!(board)
        newstring = GoString(player, Set([point]), Set(liberties), newstring_id)
        setstring!(board, newstring, newstring_id)
        setpointid!(board, newstring_id, point)
    else
        samecolor_string = pop!(adjacent_same_color)
        newstring_id = samecolor_string.id
        newstring = GoString(player, Set([point]), Set(liberties), newstring_id)
        merge!(samecolor_string, newstring)
        setpointid!(board, newstring_id, point)

        # if we have more neighbors merge to previously found nbr
        for nbr_string in adjacent_same_color
            merge!(samecolor_string, nbr_string)
            for nbr_point in nbr_string.stones
                setpointid!(board, newstring_id, nbr_point)
            end
            delete!(stringdict(board), nbr_string.id)
        end
    end

    update_hash!(board, point, player)
    
    for opposite_color_string in adjacent_opposite_color
        remove_liberty!(opposite_color_string, point)
        if num_liberties(opposite_color_string) == 0 
            remove_string!(board, opposite_color_string)
        end
    end
end

# ------------
struct GameState
    board::Board
    next_player::Player
    prev::Union{Nothing, GameState}
    prev_hashes::Set{Tuple{Player, Int}}
    last_move::Union{Nothing, Move}
    
    GameState(
            board::Board, 
            next_player::Player, 
            prev::Union{Nothing, GameState}, 
            last_move::Union{Nothing, Move}
    ) = begin
        ph = if (prev ≡ nothing)
            Set{Tuple{Player, Int}}() 
        else 
            newstate = Set([(prev.next_player, zobristhash(prev.board))])
            union(prev.prev_hashes, newstate)
        end
        new(board, next_player, prev, ph, last_move)
    end
end

new_game(num_rows::Int, num_cols::Int)::GameState = GameState(Board(num_rows, num_cols), black, nothing, nothing)
new_game(size::Int)::GameState = GameState(Board(size, size), black, nothing, nothing)

function is_over(game_state::GameState)::Bool
    last_move = game_state.last_move
    if last_move ≡ nothing
        return false
    elseif last_move.is_resign
        return true
    end

    second_last_move = game_state.prev.last_move
    if second_last_move ≡ nothing
        return false
    end

    return last_move.is_pass && second_last_move.is_pass
end

function apply_move(game_state::GameState, move::Move)::GameState
    if move.is_play
        next_board = copy(game_state.board)
        place_stone!(next_board, game_state.next_player, move.point)
    else
        next_board = game_state.board
    end

    return GameState(next_board, other(game_state.next_player), game_state, move)
end

function is_move_self_capture(game_state::GameState, player::Player, move::Move)::Bool
    !move.is_play && (return false)
    next_board = copy(game_state.board)
    place_stone!(next_board, player, move.point)
    newstring = next_board[move.point]
    return (num_liberties(newstring) == 0)
end

function does_move_violate_ko(game_state::GameState, player::Player, move::Move)::Bool
    if !move.is_play
        return false
    end
    next_board = copy(game_state.board)
    place_stone!(next_board, player, move.point)
    next_situation = (other(player), zobristhash(next_board))
    return (next_situation in game_state.prev_hashes)
end

function is_valid_move(game_state::GameState, move::Move)::Bool
    if is_over(game_state)
        return false
    elseif move.is_pass || move.is_resign
        return true
    else
        return isvoid(game_state.board[move.point]) &&
            !is_move_self_capture(game_state, game_state.next_player, move) &&
            !does_move_violate_ko(game_state, game_state.next_player, move)
    end
end

# end