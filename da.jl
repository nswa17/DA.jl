#DA Algorithm
#Todo: threading

module DA
    export call_match, check_data, generate_random_preference_data, check_results, stable_matching, call_simple_match

function call_match(m_prefs, f_prefs, rec=false, m_first=true)
    """
    max = maximum([maximum(m_prefs), maximum(f_prefs)])
    T = if max < 2^8
            UInt8
        elseif max < 2^16
            UInt16
        elseif max < 2^32
            UInt32
        else
            UInt64
        end
    """
    T = Int
    m::Int = size(m_prefs, 2)
    n::Int = size(f_prefs, 2)
    if !m_first
        m, n = n, m
        m_prefs, f_prefs = f_prefs, m_prefs
    end
    f_ranks = get_ranks(f_prefs, m, n)
    m_pointers = zeros(T, m)
    f_matched = zeros(T, n)

    m_matched_tf = falses(m)
    m_offers = zeros(T, 2, m+1)
    m_offers[1, 1] = 1

    rec ? recursive_da_match(m, n, f_ranks, m_prefs, f_prefs, m_pointers, f_matched, m_matched_tf, m_offers) : da_match(m, n, f_ranks, m_prefs, f_prefs, m_pointers, f_matched, m_matched_tf, m_offers)
    return m_first ? convert_pointer_to_list(m, f_matched) : reverse(convert_pointer_to_list(m, f_matched))
end

function get_ranks(prefs, m, n)
    ranks = Array(eltype(prefs), (m+1, n))
    for j in 1:n
        for i in 1:(m+1)
            if prefs[i, j] != 0
                ranks[prefs[i, j], j] = prefs[i, j]
            else
                ranks[m+1, j] = prefs[i, j]
            end
        end
    end
    return ranks
end

function convert_pointer_to_list(m::Int, f_matched)
    m_matched = [findfirst(f_matched, i) for i in 1:m]
    return m_matched, f_matched
end

function proceed_pointer!(m::Int, n::Int, m_pointers, m_matched_tf, m_prefs)
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

function create_offers!(m, m_prefs, m_matched_tf, m_pointers, m_offers)
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

function decide_to_accept!(f_matched, f_ranks, f_prefs, m_offers, m_matched_tf)
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

function recursive_da_match(m::Int, n::Int, f_ranks, m_prefs, f_prefs, m_pointers, f_pointers, m_matched_tf, m_offers)
    proceed_pointer!(m, n, m_pointers, m_matched_tf, m_prefs)
    create_offers!(m, m_prefs, m_matched_tf, m_pointers, m_offers)
    decide_to_accept!(f_pointers, f_ranks, f_prefs, m_offers, m_matched_tf)
    m_offers[1, 1] == 0 && return
    recursive_da_match(m, n, f_ranks, m_prefs, f_prefs, m_pointers, f_pointers, m_matched_tf, m_offers)
end

function da_match(m::Int, n::Int, f_ranks, m_prefs, f_prefs, m_pointers, f_matched, m_matched_tf, m_offers)
    while m_offers[1, 1] != 0
        proceed_pointer!(m, n, m_pointers, m_matched_tf, m_prefs)
        create_offers!(m, m_prefs, m_matched_tf, m_pointers, m_offers)
        decide_to_accept!(f_matched, f_ranks, f_prefs, m_offers, m_matched_tf)
    end
end

function call_simple_match(m_prefs, f_prefs, m_first = true)
    max = maximum([maximum(m_prefs), maximum(f_prefs)])
    T = if max < 2^8
            UInt8
        elseif max < 2^16
            UInt16
        elseif max < 2^32
            UInt32
        else
            UInt64
        end
    m::Int = size(m_prefs, 2)
    n::Int = size(f_prefs, 2)
    if !m_first
        m, n = n, m
        m_prefs, f_prefs = f_prefs, m_prefs
    end
    m_pointers = zeros(T, m)
    m_matched_tf = falses(m)
    f_matched = zeros(T, n)
    f_ranks = get_ranks(f_prefs, m, n)
    j::T = 0
    while !(all(m_matched_tf) == true)
        proceed_pointer!(m, n, m_pointers, m_matched_tf, m_prefs)
        for i in 1:m
            if !m_matched_tf[i]
                j = m_prefs[m_pointers[i], i]
                j == 0 && continue
                if f_matched[j] == 0
                    if f_ranks[end, j] > f_ranks[i, j]
                        f_matched[j] = i
                        m_matched_tf[i] = true
                    end
                else
                    if f_ranks[f_matched[j], j] > f_ranks[i, j]
                        m_matched_tf[f_matched[j]] = false
                        f_matched[j] = i
                        m_matched_tf[i] = true
                    end
                end
            end
        end
    end
    return m_first ? (Int[findfirst(f_matched, i) for i in 1:m], f_matched) : (f_matched, [findfirst(f_matched, i) for i in 1:m])
end

#####functions for debug#####

function stable_matching(m_matched, f_matched, m_prefs, f_prefs)
    for (i, j) in enumerate(m_matched)
        j == 0 && continue
        index_of_j = findfirst(m_prefs[:, i], j)
        if index_of_j > 1
            for k in 1:(index_of_j-1)
                better_j = m_prefs[k, i]
                better_j == 0 && continue
                index_of_i = findfirst(f_prefs[:, better_j], f_matched[better_j])
                if index_of_i > 1
                    if in(i, f_prefs[:, better_j][1:(index_of_i-1)])
                        return false
                    end
                end
            end
        end
    end
    return true
end

function check_results(m_matched, f_matched)
    for (i, f) in enumerate(m_matched)
        if f != 0
            f_matched[f] != i && error("Matching Incomplete with male $i, m_matched[$i] = $(m_matched[i]) though f_matched[$f] = $(f_matched[f])")
        elseif f == 0
            in(i, f_matched) && error("Matching Incomplete with male $i, m_matched[$i] = $(m_matched[i]) though f_matched[$f] = $(f_matched[f])")
        end
    end
    for (j, m) in enumerate(f_matched)
        if m != 0
            m_matched[m] != j && error("Matching Incomplete with female $j, f_matched[$j] = $(f_matched[j]) though m_matched[$m] = $(m_matched[m])")
        elseif m == 0
            in(j, m_matched) && error("Matching Incomplete with female $j, f_matched[$j] = $(f_matched[j]) though m_matched[$m] = $(m_matched[m])")
        end
    end
    return true
end

function generate_random_preference_data(m, n)
    m_prefs = Array(Int, n+1, m)
    f_prefs = Array(Int, m+1, n)
    for i in 1:m
        m_prefs[:, i] = shuffle(collect(0:n))
    end
    for j in 1:n
        f_prefs[:, j] = shuffle(collect(0:m))
    end
    return m_prefs, f_prefs
end

function check_data(m_prefs, f_prefs)
    m = size(m_prefs, 2)
    n = size(f_prefs, 2)
    size(m_prefs, 1) != n+1 && error("the size of m_prefs must be (n+1, *)")
    size(f_prefs, 1) != m+1 && error("the size of f_prefs must be (m+1, *)")
    all([Set(m_prefs[:, i]) == Set(0:n) for i in 1:m]) || error("error in m_prefs")
    all([Set(f_prefs[:, j]) == Set(0:m) for j in 1:n]) || error("error in f_prefs")
    return true
end

end
