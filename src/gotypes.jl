using Base.Enums

# PLAYER CODES
# black = -1
# whote = 1
# empty = 0
otherplayer(player::Int)::Int = -player

# ----------------------
Point = NamedTuple{(:row, :col), Tuple{Int, Int}}

up(p::Point)::Point = (row=p.row - 1, col=p.col)
down(p::Point)::Point = (row=p.row + 1, col=p.col)
left(p::Point)::Point = (row=p.row, col=p.col - 1)
right(p::Point)::Point = (row=p.row, col=p.col + 1)
nbrs(p::Point)::Vector{Point} = [up(p), down(p), left(p), right(p)]
null_point()::Point = (row=0, col=0)

# ----------------------
struct Move
    point::Point
    is_play::Bool
    is_pass::Bool
    is_resign::Bool
end
play(point::Point)::Move = Move(point, true, false, false)
pass_turn()::Move = Move(null_point(), false, true, false)
resign()::Move = Move(null_point(), false, false, true)

# ----------------------
struct GoString
    color::Int
    stones::Set{Point}
    liberties::Set{Point}
end
null_string()::GoString = GoString(0, Set{Point}(), Set{Point}())
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