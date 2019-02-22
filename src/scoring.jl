
@enum TerritoryStatus begin
    black_stone = 2
    black_territory = 1
    dame_territory = 0
    white_territory = -1
    white_stone = -2
end


struct Territory
    num_black_territory::Int
    num_white_territory::Int
    num_black_stones::Int
    num_white_stones::Int
    num_dame_territory::Int
    dame_points::Set{Point}

    function Territory(territorymap::Dict{Point, TerritoryStatus})
        num_black_territory = 0
        num_white_territory = 0
        num_black_stones = 0
        num_white_stones = 0
        num_dame_territory = 0
        dame_points = Set()

        for (point, status) in territorymap
            if status === black_stone
                num_black_stones += 1
            elseif status === white_stone
                num_white_stones += 1
            elseif status === black_territory
                num_black_territory += 1
            elseif status == white_territory
                num_white_territory += 1
            elseif status == dame_territory
                num_dame_territory += 1
                push!(dame_points, point)
            end
        end

        new(num_black_territory, num_white_territory, num_black_stones,
            num_white_stones, num_dame_territory, dame_points)
    end
end

struct GameResult
    b::Int
    w::Int
    komi::Float64
end

score(result::GameResult) = result.b  - result.w - result.komi
winnercolor(result::GameResult) = score(result) > 0 ? black : white

function Base.show(io::IO, result::GameResult) 
    s = score(result)
    if s > 0
        print(io, "B+$s")
    else
        print(io, "W+$(-s)")
    end
end

function evaluate_territory(board::Board)
    territorymap = Dict{Point, TerritoryStatus}()
    for r in 1:board.num_rows
        for c in 1:board.num_cols
            point = (row=r, col=c)

            if point in keys(territorymap) # <1>
                continue
            end

            string = board[point]
            if !isvoid(string) # <2>
                territorymap[point] = (string.color === black) ? black_stone : white_stone
            else
                group, nbrs = collect_region(point, board)
                if length(nbrs) == 1 # <3>
                    nbr_string = pop!(nbrs)
                    status = (nbr_string.color === black) ? black_territory : white_territory
                else
                    status = dame_territory # <4>
                end 
                for q in group
                    territorymap[q] = status
                end
            end
        end
    end
    Territory(territorymap)
end

# <1> Skip the point, if you already visited this as part of a different group.
# <2> If the point is a stone, add it as status.
# <3> If a point is completely surrounded by black or white stones, count it as territory.
# <4> Otherwise the point has to be a neutral point, so we add it to dame.
# end::scoring_evaluate_territory[]

function collect_region(start_pos::Point, board::Board, visited=Set{Point}())
    if start_pos in visited
        return Point[], Set{Point}()
    end
    all_points = [start_pos]
    all_borders = Set{GoString}()
    push!(visited, start_pos)
    here = board[start_pos]
    for next_p in nbrs(start_pos)
        !is_on_grid(board, next_p) && continue
        nbr_string = board[next_p]
        if nbr_string === here
            points, borders = collect_region(next_p, board, visited)
            append!(all_points, points)
            union!(all_borders, borders)
        else
            push!(all_borders, nbr_string)
        end
    end
    return all_points, all_borders
end

function compute_game_result(game_state::GameState, komi::Float64 = 7.5)
    territory = evaluate_territory(game_state.board)
    return GameResult(
        territory.num_black_territory + territory.num_black_stones,
        territory.num_white_territory + territory.num_white_stones,
        komi)
end