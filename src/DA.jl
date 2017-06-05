module DA
    export deferred_acceptance, generate_random_prefs

function deferred_acceptance{T <: Integer}(m_prefs::Array{Array{T, 1}, 1}, f_prefs::Array{Array{T, 1}, 1})
    m = length(m_prefs)
    n = length(f_prefs)

    f_ranks = zeros(Int, m+1, n)
    for j in 1:n
        for (r, i) in enumerate(f_prefs[j])
            f_ranks[i, j] = r
        end
    end
    f_ranks[m+1, :] = m + 1

    m_pointers = ones(Int, m)
    f_matched = fill(m+1, n)
    m_matched = zeros(Int, m)
    m_searching = Array(Int, m)
    top = m
    for i in 1:m
        m_searching[i] = i
    end

    while top > 0
        i = m_searching[top]
        if m_pointers[i] > length(m_prefs[i])
            top -= 1
            continue
        end
        f_proposed = m_prefs[i][m_pointers[i]]
        current_m_of_f = f_matched[f_proposed]

        if length(f_prefs[f_proposed]) != 0#if f want to couple with someone(?)
            if f_ranks[i, f_proposed] != 0 && f_ranks[i, f_proposed] < f_ranks[current_m_of_f, f_proposed]
                f_matched[f_proposed] = i
                top -= 1
                if current_m_of_f != m + 1
                    top += 1
                    m_searching[top] = current_m_of_f
                    m_pointers[current_m_of_f] += 1
                end
            else
                m_pointers[i] += 1
            end
        end
    end

    for (j, i) in enumerate(f_matched)
        if i == m + 1
            f_matched[j] = 0
        else
            m_matched[i] = j
        end
    end

    return m_matched, f_matched
end

"""
function call_match{T <: Integer}(m_prefs::Array{T, 2}, f_prefs::Array{T, 2}, caps::Array{T, 1})
    m::Int = size(m_prefs, 2)
    n::Int = size(f_prefs, 2)

    f_ranks = get_ranks(f_prefs)
    m_pointers = zeros(Int, m)
    f_pointers = [binary_maxheap(Int) for j in 1:n] ### f_pointers :: (m x n) matrix

    m_matched_tf = falses(m)
    m_offers = zeros(Int, 2, m+1)
    m_offers[1, 1] = 1

    da_match(m, n, f_ranks, m_prefs, f_prefs, m_pointers, f_pointers, m_matched_tf, m_offers, caps)
    return convert_pointer_to_list(m, n, f_pointers, f_prefs, caps)
end

function call_match{T <: Integer}(m_prefs::Array{T, 2}, f_prefs::Array{T, 2})
    m::Int = size(m_prefs, 2)
    n::Int = size(f_prefs, 2)

    f_ranks = get_ranks(f_prefs)
    m_pointers = zeros(Int, m)
    f_matched = zeros(Int, n)

    m_matched_tf = falses(m)
    m_offers = zeros(Int, 2, m+1)
    m_offers[1, 1] = 1

    da_match(m, n, f_ranks, m_prefs, f_prefs, m_pointers, f_matched, m_matched_tf, m_offers)
    return convert_pointer_to_list(m, f_matched)
end

@inbounds function get_ranks{T <: Integer}(prefs::Array{T, 2})
    ranks = Array(eltype(prefs), size(prefs))
    for j in 1:size(prefs, 2)
        for (r, i) in enumerate(prefs[:, j])
            if i != 0
                ranks[i, j] = r
            else
                ranks[end, j] = r
            end
        end
    end
    return ranks
end

function convert_pointer_to_list{T <: Integer}(m::Int, f_matched::Array{T, 1})
    m_matched = [findfirst(f_matched, i) for i in 1:m]
    return m_matched, f_matched
end

function convert_pointer_to_list(m::Int, n::Int, f_pointers, f_prefs, caps)
    f_matched = zeros(Int, sum(caps))
    m_matched = zeros(Int, m)
    indptr = Array(Int, n+1)
    i::Int = 0
    indptr[1] = 1
    for i in 1:n
        indptr[i+1] = indptr[i] + caps[i]
    end

    total = 1
    for j in 1:n
        for c in 1:caps[j]
            if isempty(f_pointers[j])
                f_matched[total] = 0
            else
                i = pop!(f_pointers[j])
                f_matched[total] = f_prefs[i, j]
                m_matched[f_prefs[i, j]] = j
            end
            total += 1
        end
    end

    return m_matched, f_matched, indptr
end

@inbounds function proceed_pointer!{T <: Integer}(m::Int, n::Int, m_pointers::Array{T, 1}, m_matched_tf, m_prefs)
    for i in 1:m
        if m_pointers[i] > n
            m_matched_tf[i] = true
        else
            if !m_matched_tf[i]
                m_pointers[i] += 1
                if m_prefs[m_pointers[i], i] == 0
                    m_matched_tf[i] = true
                end
            end
        end
    end
end

@inbounds function create_offers!{T <: Integer}(m::Int, m_prefs::Array{T, 2}, m_matched_tf, m_pointers::Array{T, 1}, m_offers)
    c::Int = 1
    for i in 1:m
        if !m_matched_tf[i] && m_prefs[m_pointers[i], i] != 0
            m_offers[1, c] = i
            m_offers[2, c] = m_prefs[m_pointers[i], i]
            c += 1
        end
    end
    m_offers[1, c] = 0
    m_offers[2, c] = 0
end

@inbounds function decide_to_accept!{T <: Integer}(f_matched::Array{T, 1}, f_ranks::Array{T, 2}, f_prefs::Array{T, 2}, m_offers, m_matched_tf)
    for k in 1:length(m_offers)
        m_offers[1, k] == 0 && break
        if f_matched[m_offers[2, k]] == 0
            if f_ranks[end, m_offers[2, k]] > f_ranks[m_offers[1, k], m_offers[2, k]]
                f_matched[m_offers[2, k]] = m_offers[1, k]
                m_matched_tf[m_offers[1, k]] = true
            end
        else
            if f_ranks[f_matched[m_offers[2, k]], m_offers[2, k]] > f_ranks[m_offers[1, k], m_offers[2, k]]
                m_matched_tf[f_matched[m_offers[2, k]]] = false
                f_matched[m_offers[2, k]] = m_offers[1, k]
                m_matched_tf[m_offers[1, k]] = true
            end
        end
    end
end

@inbounds function decide_to_accept!{T <: Integer}(f_pointers, f_ranks::Array{T, 2}, f_prefs::Array{T, 2}, m_offers, m_matched_tf, caps::Array{T, 1})
    for k in 1:length(m_offers)
        m_offers[1, k] == 0 && break
        i = m_offers[1, k]
        j = m_offers[2, k]
        if f_ranks[end, j] > f_ranks[i, j]
            push!(f_pointers[j], f_ranks[i, j])
            m_matched_tf[i] = true
            if caps[j] < length(f_pointers[j])# if f's matching male reaches to the cap
                m_matched_tf[f_prefs[pop!(f_pointers[j]), j]] = false
            end
        end
    end
end

function da_match{T <: Integer}(m::Int, n::Int, f_ranks::Array{T, 2}, m_prefs::Array{T, 2}, f_prefs::Array{T, 2}, m_pointers::Array{T, 1}, f_pointers, m_matched_tf, m_offers, caps::Array{T, 1})
    while m_offers[1, 1] != 0
        proceed_pointer!(m, n, m_pointers, m_matched_tf, m_prefs)
        create_offers!(m, m_prefs, m_matched_tf, m_pointers, m_offers)
        decide_to_accept!(f_pointers, f_ranks, f_prefs, m_offers, m_matched_tf, caps)
    end
end

function da_match{T <: Integer}(m::Int, n::Int, f_ranks::Array{T, 2}, m_prefs::Array{T, 2}, f_prefs::Array{T, 2}, m_pointers::Array{T, 1}, f_matched::Array{T, 1}, m_matched_tf, m_offers)
    while m_offers[1, 1] != 0
        proceed_pointer!(m, n, m_pointers, m_matched_tf, m_prefs)
        create_offers!(m, m_prefs, m_matched_tf, m_pointers, m_offers)
        decide_to_accept!(f_matched, f_ranks, f_prefs, m_offers, m_matched_tf)
    end
end

function call_simple_match{T <: Integer}(m_prefs::Array{T, 2}, f_prefs::Array{T, 2}, m_first = true)
    max = maximum([maximum(m_prefs), maximum(f_prefs)])
    m::Int = size(m_prefs, 2)
    n::Int = size(f_prefs, 2)
    if !m_first
        m, n = n, m
        m_prefs, f_prefs = f_prefs, m_prefs
    end
    m_pointers = zeros(Int, m)
    m_matched_tf = falses(m)
    f_pointers = zeros(Int, n)
    f_ranks = get_ranks(f_prefs)
    j::Int = 0
    while !(all(m_matched_tf) == true)
        proceed_pointer!(m, n, m_pointers, m_matched_tf, m_prefs)
        for i in 1:m
            if !m_matched_tf[i]
                j = m_prefs[m_pointers[i], i]
                j == 0 && continue
                if f_pointers[j] == 0
                    if f_ranks[end, j] > f_ranks[i, j]
                        f_pointers[j] = i
                        m_matched_tf[i] = true
                    end
                else
                    if f_ranks[f_pointers[j], j] > f_ranks[i, j]
                        m_matched_tf[f_pointers[j]] = false
                        f_pointers[j] = i
                        m_matched_tf[i] = true
                    end
                end
            end
        end
    end
    return m_first ? (Int[findfirst(f_pointers, i) for i in 1:m], f_pointers) : (f_pointers, [findfirst(f_pointers, i) for i in 1:m])
end

"""

function generate_random_prefs{T <: Integer}(m::T, n::T)
    m_prefs = Array(Vector{Int}, m)
    f_prefs = Array(Vector{Int}, n)
    for i in 1:m
        m_prefs[i] = shuffle(collect(1:n))
    end
    for j in 1:n
        f_prefs[j] = shuffle(collect(1:m))
    end
    return m_prefs, f_prefs
end

end
