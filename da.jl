#DA algorithm
#todo: @time to compare recursive version and normal version
#    : test function
#    : order
#    : what if m_pointers[i] exceeds n
#    : change arrange_m_offers into ~
#    : check function
#recursive version
#

module DA
    export call_match

function call_match(m::Int, n::Int, m_prefs, f_prefs)
    #m != length(m_prefs) || n != length(f_prefs) && error("the size of the ")####
    m_pointers = zeros(Int, m)
    f_pointers = Array(Int, n)
    f_pointers = [findfirst(f_prefs[:, j], 0) for j in 1:n]

    m_matched = falses(m)
    m_offers = zeros(Int, m)

    f_pointers = da_match(m, n, m_prefs, f_prefs, m_pointers, f_pointers, m_matched, m_offers)
    return convert_pointer_to_list(m, m_pointers, f_pointers, f_prefs)#########
end

function check_data(m, n, m_prefs, f_prefs)
    size(m_prefs) != (n+1, m) && error("the size of m_prefs must be (n+1, m)")
    size(f_prefs) != (n+1, m) && error("the size of f_prefs must be (m+1, n)")
    all([set(m_pref) for m_pref in m_prefs] .== set(0:n)) && error("there must be no same preference about f")
    all([set(f_pref) for f_pref in f_prefs] .== set(0:m)) && error("there must be no same preference about m")
end

function convert_pointer_to_list(m, m_pointers, f_pointers, f_prefs)
    f_m = [f_prefs[f_pointer, j] for (j, f_pointer) in enumerate(f_pointers)]
    m_f = [findfirst(f_m, i) for i in 1:m]
    return m_f, f_m
end

function proceed_pointer!(m, n, m_pointers, m_matched, m_prefs)
    for i in 1:m
        if m_prefs[m_pointers[i] + 1, i] == 0
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

function get_best_male_pointers(m, n, m_offers, f_prefs)
    best_m_pointers_offererd = zeros(Int, n)
    for j in 1:n
        arranged_offer = findin(m_offers, j)#findin returns indexes in one dimensional array
        if !isempty(arranged_offer)
            best_m_pointers_offererd[j] = minimum(map(j -> findfirst(f_prefs[:, j], j), arranged_offer))
        end
    end
    return best_m_pointers_offererd
end


function decide_to_accept!(m, n, f_pointers, f_prefs, m_offers, m_matched)######a bug is here
    best_male_pointers = get_best_male_pointers(m, n, m_offers, f_prefs)
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

function da_match(m, n, m_prefs, f_prefs, m_pointers, f_pointers, m_matched, m_offers)#m offers to f
    proceed_pointer!(m, n, m_pointers, m_matched, m_prefs)
    #println("called:0")
    create_offers!(m, m_prefs, m_matched, m_pointers, m_offers)
    #println("called:1")
    decide_to_accept!(m, n, f_pointers, f_prefs, m_offers, m_matched)
    #println("called:2")
    if all(m_matched) == true
        return f_pointers
    else
        da_match(m, n, m_prefs, f_prefs, m_pointers, f_pointers, m_matched, m_offers)
    end
end

println(call_match(3, 3, Int[1 0 1; 2 1 3; 3 3 2; 0 2 0], Int[1 2 0; 2 1 2; 3 3 3; 0 0 1]))
println(call_match(3, 3, Int[1 2 3; 2 1 3; 2 3 1; 0 0 0], Int[1 2 3; 2 1 3; 1 2 3; 0 0 0]))

end
