#DA algorithm
#todo: @time to compare recursive version and normal version
#    : change arrange_m_offers into ~
#recursive version
#

module DA
    export call_match, check_data, generate_random_preference_data, check_results, test

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

function call_match(m::Int, n::Int, m_prefs, f_prefs, rec=false)
    #m != length(m_prefs) || n != length(f_prefs) && error("the size of the ")####
    m_pointers = zeros(Int, m)
    f_pointers = Array(Int, n)
    f_pointers = [findfirst(f_prefs[:, j], 0) for j in 1:n]

    m_matched = falses(m)
    m_offers = zeros(Int, m)
    best_male_pointers = zeros(Int, n)

    f_pointers = rec ? recursive_da_match(m, n, m_prefs, f_prefs, m_pointers, f_pointers, m_matched, m_offers, best_male_pointers) : da_match(m, n, m_prefs, f_prefs, m_pointers, f_pointers, m_matched, m_offers, best_male_pointers)
    return convert_pointer_to_list(m, m_pointers, f_pointers, f_prefs)#########
end

function check_data(m::Int, n::Int, m_prefs, f_prefs)
    size(m_prefs) != (n+1, m) && error("the size of m_prefs must be (n+1, m)")
    size(f_prefs) != (n+1, m) && error("the size of f_prefs must be (m+1, n)")
    all([Set(m_pref) for m_pref in m_prefs] .== Set(0:n)) && error("there must be no same preference about f")
    all([Set(f_pref) for f_pref in f_prefs] .== Set(0:m)) && error("there must be no same preference about m")
    return true
end

function convert_pointer_to_list(m, m_pointers, f_pointers, f_prefs)
    f_m = [f_prefs[f_pointer, j] for (j, f_pointer) in enumerate(f_pointers)]
    m_f = [findfirst(f_m, i) for i in 1:m]
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
        if m_matched[i]
            m_offers[i] = 0
        else
            m_offers[i] = m_prefs[m_pointers[i], i]
        end
    end
end

function get_best_male_pointers!(m, n, m_offers, f_prefs, best_m_pointers)
    for j in 1:n
        arranged_offer = findin(m_offers, j)#findin returns indexes in one dimensional array
        if !isempty(arranged_offer)
            best_m_pointers[j] = minimum(map(j -> findfirst(f_prefs[:, j], j), arranged_offer))
        else
            best_m_pointers[j] = 0
        end
    end
end


function decide_to_accept!(m, n, f_pointers, f_prefs, m_offers, m_matched, best_male_pointers)######a bug is here
    get_best_male_pointers!(m, n, m_offers, f_prefs, best_male_pointers)
    for j in 1:n
        if f_pointers[j] > best_male_pointers[j] && best_male_pointers[j] != 0
            m_matched[f_prefs[best_male_pointers[j], j]] = true
            if f_prefs[f_pointers[j], j] != 0
                m_matched[f_prefs[f_pointers[j], j]] = false
            end
            f_pointers[j] = best_male_pointers[j]#findfirst returns zero if it couldn't find the 2nd argument in the 1st argument.
        end
    end
end

function recursive_da_match(m, n, m_prefs, f_prefs, m_pointers, f_pointers, m_matched, m_offers, best_male_pointers)#m offers to f
    proceed_pointer!(m, n, m_pointers, m_matched, m_prefs)
    #println("called:0")
    create_offers!(m, m_prefs, m_matched, m_pointers, m_offers)
    #println("called:1")
    decide_to_accept!(m, n, f_pointers, f_prefs, m_offers, m_matched, best_male_pointers)
    #println("called:2")
    if all(m_matched) == true
        return f_pointers
    else
        recursive_da_match(m, n, m_prefs, f_prefs, m_pointers, f_pointers, m_matched, m_offers, best_male_pointers)
    end
end

function da_match(m, n, m_prefs, f_prefs, m_pointers, f_pointers, m_matched, m_offers, best_male_pointers)#m offers to f
    while any(m_matched) == false
        proceed_pointer!(m, n, m_pointers, m_matched, m_prefs)
        #println("called:0")
        create_offers!(m, m_prefs, m_matched, m_pointers, m_offers)
        #println("called:1")
        decide_to_accept!(m, n, f_pointers, f_prefs, m_offers, m_matched, best_male_pointers)
        #println("called:2")
    end
    return f_pointers
end

end
