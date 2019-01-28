using Base.Enums
@enum Player begin
    black = 1
    white = 2
end
other(player::Player) = player == black ? white : black 


# ----------------------
struct Point 
    row::Int
    col::Int
end

up(p::Point) = Point(p.row - 1, p.col)
down(p::Point) = Point(p.row + 1, p.col)
left(p::Point) = Point(p.row, p.col - 1)
right(p::Point) = Point(p.row, p.col + 1)
nbrs(p::Point) = [up(p), down(p), left(p), right(p)]

# ----------------------
struct Move
    point::Union{Nothing, Point}
    is_play::Bool
    is_pass::Bool
    is_resign::Bool

    # constructor with defaults for Move
    Move(;point::Union{Nothing, Point}=nothing, is_pass=false, is_resign=false) = 
        new(point, (point != nothing), is_pass, is_resign)
end

play(p::Point) = Move(point = p)
pass_turn() = Move(is_pass=true)
resign() = Move(is_resign=true)

# ----------------------
struct GoString
    color::Player
    stones::Set{Point}
    liberties::Set{Point}
end

remove_liberty(str::GoString, p::Point) = delete!(str.liberties, p)
add_liberty(str::GoString, p::Point) = push!(str.liberties, p)
remove_liberty(str::GoString, p::Point) = delete!(str.liberties, p)
num_liberties(str::GoString) = length(str.liberties)

function merge(x::GoString, y::GoString)
    @assert x.color == y.color
    combined_strings = union(x.stones, y.stones)
    combined_liberties = setdiff(union(x.liberties, y.liberties), combined_strings)
    return GoString(x.color, combined_liberties, combined_strings)
end


