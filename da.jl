#DA Algorithm

module DA
    export call_match, check_data, generate_random_preference_data, check_results, stable_matching, call_simple_match

function call_match(m_prefs, f_prefs, rec=false, m_first=true)
    m::Int
    n::Int
    m = size(m_prefs, 2)
    n = size(f_prefs, 2)
    if !m_first
        m, n = n, m
        m_prefs, f_prefs = f_prefs, m_prefs
    end
    m_pointers = zeros(Int, m)
    f_pointers = Array(Int, n)
    f_pointers = [findfirst(f_prefs[:, j], 0) for j in 1:n]

    m_matched_tf = falses(m)
    m_offers = zeros(Int, m)

    f_pointers = rec ? recursive_da_match(m, n, m_prefs, f_prefs, m_pointers, f_pointers, m_matched_tf, m_offers) : da_match(m, n, m_prefs, f_prefs, m_pointers, f_pointers, m_matched_tf, m_offers)
    return m_first ? convert_pointer_to_list(m, m_pointers, f_pointers, f_prefs) : reverse(convert_pointer_to_list(m, m_pointers, f_pointers, f_prefs))
end

function convert_pointer_to_list(m::Int, m_pointers, f_pointers, f_prefs)
    f_matched = [f_prefs[f_pointer, j] for (j, f_pointer) in enumerate(f_pointers)]
    m_matched = [findfirst(f_matched, i) for i in 1:m]
    return m_matched, f_matched
end

function proceed_pointer!(m::Int, n::Int, m_pointers, m_matched_tf, m_prefs)
    for i in 1:m
        if m_pointers[i] + 1 > n + 1
            m_matched_tf[i] = true
        elseif m_prefs[m_pointers[i] + 1, i] == 0
            m_matched_tf[i] = true
            m_pointers[i] += 1
        elseif !m_matched_tf[i]
            m_pointers[i] += 1
        end
    end
end

function create_offers!(m, m_prefs, m_matched_tf, m_pointers, m_offers)
    for i in 1:m
        m_offers[i] = m_matched_tf[i] ? 0 : m_prefs[m_pointers[i], i]
    end
end

function decide_to_accept!(f_pointers, f_prefs, m_offers, m_matched_tf)
    for (i, m_offer) in enumerate(m_offers)
        m_offer == 0 && continue
        male_i_pointer = findfirst(f_prefs[:, m_offer], i)
        if f_pointers[m_offer] > male_i_pointer
            if f_prefs[f_pointers[m_offer], m_offer] != 0
                m_matched_tf[f_prefs[f_pointers[m_offer], m_offer]] = false
            end
            f_pointers[m_offer] = male_i_pointer
            m_matched_tf[i] = true
        end
    end
end

function recursive_da_match(m::Int, n::Int, m_prefs, f_prefs, m_pointers, f_pointers, m_matched_tf, m_offers)
    proceed_pointer!(m, n, m_pointers, m_matched_tf, m_prefs)
    create_offers!(m, m_prefs, m_matched_tf, m_pointers, m_offers)
    decide_to_accept!(f_pointers, f_prefs, m_offers, m_matched_tf)
    if all(m_matched_tf) == true
        return f_pointers
    else
        recursive_da_match(m::Int, n::Int, m_prefs, f_prefs, m_pointers, f_pointers, m_matched_tf, m_offers)
    end
end

function da_match(m::Int, n::Int, m_prefs, f_prefs, m_pointers, f_pointers, m_matched_tf, m_offers)
    while !(all(m_matched_tf) == true)
        proceed_pointer!(m, n, m_pointers, m_matched_tf, m_prefs)
        create_offers!(m, m_prefs, m_matched_tf, m_pointers, m_offers)
        decide_to_accept!(f_pointers, f_prefs, m_offers, m_matched_tf)
    end
    return f_pointers
end

function call_simple_match(m_prefs, f_prefs, m_first = true)
    m::Int
    n::Int
    m = size(m_prefs, 2)
    n = size(f_prefs, 2)
    if !m_first
        m, n = n, m
        m_prefs, f_prefs = f_prefs, m_prefs
    end
    m_pointers = zeros(Int, m)
    m_matched_tf = falses(m)
    f_matched = zeros(Int, n)
    j::Int = 0
    while !(all(m_matched_tf) == true)
        proceed_pointer!(m, n, m_pointers, m_matched_tf, m_prefs)
        for i in 1:m
            if !m_matched_tf[i]
                j = m_prefs[m_pointers[i], i]
                j == 0 && continue
                if findfirst(f_prefs[:, j], f_matched[j]) > findfirst(f_prefs[:, j], i)
                    if f_matched[j] != 0
                        m_matched_tf[f_matched[j]] = false
                    end
                    f_matched[j] = i
                    m_matched_tf[i] = true
                end
            end
        end
    end
    return m_first ? ([findfirst(f_matched, i) for i in 1:m], f_matched) : (f_matched, [findfirst(f_matched, i) for i in 1:m])
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

function test(m, n)
    m_prefs, f_prefs = generate_random_preference_data(m, n)
    check_data(m, n, m_prefs, f_prefs)
    m_matched, f_matched = call_match(m_prefs, f_prefs)
    check_results(m_matched, f_matched)
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
    size(m_prefs) != (n+1, m) && error("the size of m_prefs must be (n+1, m)")
    size(f_prefs) != (m+1, n) && error("the size of f_prefs must be (m+1, n)")
    all([Set(m_prefs[:, i]) == Set(0:n) for i in 1:m]) || error("error in m_prefs")
    all([Set(f_prefs[:, j]) == Set(0:m) for j in 1:n]) || error("error in f_prefs")
    return true
end

end
