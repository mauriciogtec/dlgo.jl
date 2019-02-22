import Base: copy, show, print
using Base.Enums

@enum Player begin
    void = 0
    black = 1
    white = -1
end
other(player::Player)::Player = if (player == black) white elseif (player == white) black else void end
tosymbol(player::Player) = if (player == black) "x" elseif (player==white) "o" else "." end

# ----------------------
Point = NamedTuple{(:row, :col), Tuple{Int, Int}}

up(p::Point)::Point = (row = p.row - 1, col = p.col)
down(p::Point)::Point = (row = p.row + 1, col = p.col)
left(p::Point)::Point = (row = p.row, col = p.col - 1)
right(p::Point)::Point = (row = p.row, col = p.col + 1)
nbrs(p::Point)::Vector{Point} = [up(p), down(p), left(p), right(p)]

# ----------------------
struct Move
    point::Point
    is_play::Bool
    is_pass::Bool
    is_resign::Bool
end

play(point::Point)::Move = Move(point, true, false, false)
pass_turn()::Move = Move((row=0, col=0), false, true, false)
resign()::Move = Move((row=0, col=0), false, false, true)

# ----------------------
IdType = UInt16

struct GoString
    color::Player
    stones::Set{Point}
    liberties::Set{Point}
    id::IdType
end

remove_liberty!(s::GoString, p::Point)::Nothing = (delete!(s.liberties, p); nothing)
add_liberty!(s::GoString, p::Point)::Nothing = (push!(s.liberties, p); nothing)
num_liberties(s::GoString)::Int = length(s.liberties)

function merge!(receiver::GoString, sender::GoString)::Nothing
    @assert receiver.color === sender.color
    union!(receiver.stones, sender.stones)
    union!(receiver.liberties, sender.liberties)
    setdiff!(receiver.liberties, receiver.stones)
    nothing
end

const EMPTY_STRING = GoString(void, Set{Point}(), Set{Point}(), IdType(0))

isvoid(s::GoString) = (s.color == void)
copy(s::GoString) = isvoid(s) ? EMPTY_STRING : GoString(s.color, copy(s.stones), copy(s.liberties), s.id)
show(io::IO, s::GoString) = print(io, tosymbol(s.color))
print(io::IO, s::GoString) = show(io, s)

mutable struct GoStringBuffer
    dict::Dict{IdType, GoString} 
    lastid::IdType
end