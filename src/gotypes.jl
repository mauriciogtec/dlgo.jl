using Base.Enums

@enum Player begin
    black = 1
    white = 2
end
other(player::Player)::Player = player == black ? white : black 

# ----------------------
struct Point 
    row::Int
    col::Int
end

up(p::Point)::Point = Point(p.row - 1, p.col)
down(p::Point)::Point = Point(p.row + 1, p.col)
left(p::Point)::Point = Point(p.row, p.col - 1)
right(p::Point)::Point = Point(p.row, p.col + 1)
nbrs(p::Point)::Vector{Point} = Point[up(p), down(p), left(p), right(p)]

# ----------------------
struct Move
    point::Union{Nothing, Point}
    is_play::Bool
    is_pass::Bool
    is_resign::Bool

    # constructor with defaults for Move
    Move(;point::Union{Nothing, Point} = nothing, is_pass=false, is_resign=false) =
        new(point, point ≢ nothing, is_pass, is_resign)
end

play(p::Point)::Move = Move(point = p)
pass_turn()::Move = Move(is_pass=true)
resign()::Move = Move(is_resign=true)

# ----------------------
struct GoString
    color::Player
    stones::Set{Point}
    liberties::Set{Point}
end

remove_liberty!(str::GoString, p::Point)::Nothing = (delete!(str.liberties, p); nothing)
add_liberty!(str::GoString, p::Point)::Nothing = (push!(str.liberties, p); nothing)
num_liberties(str::GoString)::Int = length(str.liberties)

function merge!(receiver::GoString, sender::GoString)::Nothing
    @assert receiver.color ≡ sender.color
    union!(receiver.stones, sender.stones)
    union!(receiver.liberties, sender.liberties)
    setdiff!(receiver.liberties, receiver.stones)
    nothing
end

# end