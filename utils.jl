charcols()::String = "ABCDEFGHJKLMNOPQRST"
charcols(i::Int)::String = string(charcols()[i])

function stone_to_char(x::Union{Nothing, Player})::String 
    if x ≡ nothing
        return " . "
    elseif x ≡ black
        return " x "
    elseif x ≡ white
        return " o "
    else
        throw(ArgumentError)
    end
end