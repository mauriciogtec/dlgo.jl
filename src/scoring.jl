import Base: show

@enum TerritoryType begin
    black_territory = 1
    white_territory = 2
    dame = 3
end

Status = Union{TerritoryType, Player}

struct Territory
    num_black_territory::Int
    num_white_territory::Int
    num_black_stones::Int
    num_white_stones::Int
    num_dame::Int
    dame_points::Set{Point}

    function Territory(territorymap::Set{Tuple{Point, Status}})
        num_black_territory = 0
        num_white_territory = 0
        num_black_stones = 0
        num_white_stones = 0
        num_dame = 0
        dame_points = Set()

        for (point, status) in territorymap
            if status === black
                num_black_stones += 1
            elseif status === white
                num_white_stones += 1
            elseif status === black_territory
                num_black_territory += 1
            elseif status == white_territory
                num_white_territory += 1
            elseif status == dame
                num_dame += 1
                push!(dame_points, point)
            end
        end

        new(num_black_territory, num_white_territory, num_black_stones,
            num_white_stones, num_dame, dame_points)
    end
end

struct GameResult
    b::Int
    w::Int
    komi::Float64
end

function winner(result::GameResult)
    m = result.b  - result.w - result.komi
    w = (m > 0) ? black : white
    w, m
end

function Base.show(io::IO, result::GameResult) 
    w, m = winner(result)
    if m > 0
        print(io, "B+$m")
    else
        print(io, "W+$(-m)")
    end
end

function evaluate_territory(board::Board)
    territorymap = Set{Tuple{Point, Status}}()
    for r in 1:board.num_rows
        for c in 1:board.num_cols
            point = Point(r, c)

            (point in territorymap) && continue 

            stone = board[point]
            if stone !== nothing  
                push!(territorymap, (point, stone.color))
            else
                group, nbrs = collect_region(point, board)
                if length(nbrs) == 1
                    nbr_stone = pop!(nbrs)
                    status = (nbr_stone.color === black) ? territory_black : territory_white
                else
                    status = dame  
                end 
                for q in group
                    push!(territorymap, (q, status))
                end
            end
        end
    end
    Territory(territorymap)
end


function collect_region(start_pos::Point, board::Board, visited=Set{Point}())
    if start_pos in visited
        return Point[], Set{Point}()
    end
    all_points = [start_pos]
    all_borders = Set{Point}()
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
            push!(all_borders, next_p)
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