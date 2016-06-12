#DA Algorithm

module DA
    export call_match, check_data, generate_random_preference_data, check_results

#####functions for debug#####
function test(m, n)
    m_prefs, f_prefs = generate_random_preference_data(m, n)
    check_data(m, n, m_prefs, f_prefs)
    m_f, f_m = call_match(m, n, m_prefs, f_prefs)
    check_results(m_f, f_m)
end

function check_results(m_f, f_m)
    for (i, f) in enumerate(m_f)
        if f != 0
            f_m[f] != i && error("Matching Incomplete with male $i, m_f[$i] = $(m_f[i]) though f_m[$f] = $(f_m[f])")
        elseif f == 0
            in(i, f_m) && error("Matching Incomplete with male $i, m_f[$i] = $(m_f[i]) though f_m[$f] = $(f_m[f])")
        end
    end
    for (j, m) in enumerate(f_m)
        if m != 0
            m_f[m] != j && error("Matching Incomplete with female $j, f_m[$j] = $(f_m[j]) though m_f[$m] = $(m_f[m])")
        elseif m == 0
            in(j, m_f) && error("Matching Incomplete with female $j, f_m[$j] = $(f_m[j]) though m_f[$m] = $(m_f[m])")
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

function check_data(m::Int, n::Int, m_prefs, f_prefs)
    size(m_prefs) != (n+1, m) && error("the size of m_prefs must be (n+1, m)")
    size(f_prefs) != (n+1, m) && error("the size of f_prefs must be (m+1, n)")
    all([Set(m_prefs[:, i]) == Set(0:n) for i in 1:size(m_prefs, 2)]) || error("error in m_prefs")
    all([Set(f_prefs[:, j]) == Set(0:m) for j in 1:size(f_prefs, 2)]) || error("error in f_prefs")
    return true
end

#####main functions#####

function call_match(m::Int, n::Int, m_prefs, f_prefs, rec=false)
    m_pointers = zeros(Int, m)
    f_pointers = Array(Int, n)
    f_pointers = [findfirst(f_prefs[:, j], 0) for j in 1:n]

    m_matched = falses(m)
    m_offers = zeros(Int, m)

    f_pointers = rec ? recursive_da_match(m, n, m_prefs, f_prefs, m_pointers, f_pointers, m_matched, m_offers) : da_match(m, n, m_prefs, f_prefs, m_pointers, f_pointers, m_matched, m_offers)
    return convert_pointer_to_list(m, m_pointers, f_pointers, f_prefs)
end

function convert_pointer_to_list(m, m_pointers, f_pointers, f_prefs)
    #println(f_pointers)
    f_m = [f_prefs[f_pointer, j] for (j, f_pointer) in enumerate(f_pointers)]
    m_f = [findfirst(f_m, i) for i in 1:m]###########error
    return m_f, f_m
end

function proceed_pointer!(m, n, m_pointers, m_matched, m_prefs)
    for i in 1:m
        if m_pointers[i] + 1 > n + 1
            m_matched[i] = true
        elseif m_prefs[m_pointers[i] + 1, i] == 0
            m_matched[i] = true
            m_pointers[i] += 1
        elseif !m_matched[i]
            m_pointers[i] += 1
        end
    end
end

function create_offers!(m, m_prefs, m_matched, m_pointers, m_offers)
    for i in 1:m
        m_offers[i] = m_matched[i] ? 0 : m_prefs[m_pointers[i], i]
    end
end

function decide_to_accept!(f_pointers, f_prefs, m_offers, m_matched)
    for (i, m_offer) in enumerate(m_offers)
        m_offer == 0 && continue
        male_i_pointer = findfirst(f_prefs[:, m_offer], i)
        if f_pointers[m_offer] > male_i_pointer
            if f_prefs[f_pointers[m_offer], m_offer] != 0
                m_matched[f_prefs[f_pointers[m_offer], m_offer]] = false
            end
            f_pointers[m_offer] = male_i_pointer
            m_matched[i] = true
        end
    end
end

function recursive_da_match(m, n, m_prefs, f_prefs, m_pointers, f_pointers, m_matched, m_offers)
    proceed_pointer!(m, n, m_pointers, m_matched, m_prefs)
    create_offers!(m, m_prefs, m_matched, m_pointers, m_offers)
    decide_to_accept!(f_pointers, f_prefs, m_offers, m_matched)
    if all(m_matched) == true
        return f_pointers
    else
        recursive_da_match(m, n, m_prefs, f_prefs, m_pointers, f_pointers, m_matched, m_offers)
    end
end

function da_match(m, n, m_prefs, f_prefs, m_pointers, f_pointers, m_matched, m_offers)
    while !(all(m_matched) == true)
        proceed_pointer!(m, n, m_pointers, m_matched, m_prefs)
        create_offers!(m, m_prefs, m_matched, m_pointers, m_offers)
        decide_to_accept!(f_pointers, f_prefs, m_offers, m_matched)
    end
    return f_pointers
end

end
