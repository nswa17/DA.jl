#DA algorithm
#todo: @time to compare recursive version and normal version
#    : test function
#    : make code readable
#    : order
#    : not
#    : what if m_pointers[i] exceeds n
#    : change arrange_m_offers into ~
#    : error
#    : bug if call_match(3, 3, Int[1 2 3; 2 1 3; 2 3 1], Int[1 2 3; 2 1 3; 1 2 3])
#    : check function

#recursive version
#
#input: m, n, 1d array of m_prefs, 1d array of f_prefs
#output: m-elements 1d array, n-elements 1d array
#

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

function convert_pointer_to_list(m, m_pointers, f_pointers, f_prefs)
    f_m = [f_prefs[j, f_pointer] for (j, f_pointer) in enumerate(f_pointers)]
    m_f = [findfirst(f_m, i) for i in 1:m]
    return m_f, f_m
end

function proceed_pointer!(m, m_pointers, m_matched)
    for i in 1:m
        if !m_matched[i]
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
    #arranged_offers = arrange_offers(m, n, m_offers)
    #println(arranged_offers) #m_offers[i] is the male i's favorite female
    best_male_pointers = get_best_male_pointers(m, n, m_offers, f_prefs)
    for j in 1:n
        if f_pointers[j] > best_male_pointers[j] && best_male_pointers[j] != 0
            m_matched[f_prefs[best_male_pointers[j], j]] = true
            m_matched[f_prefs[f_pointers[j], j]] = false
            println("m_matched")
            println(m_matched)
            f_pointers[j] = best_male_pointers[j]#findfirst returns zero if it couldn't find the 2nd argument in the 1st argument.#could be an error
        elseif f_pointers[j] == 0 && best_male_pointers[j] != 0
            m_matched[f_prefs[best_male_pointers[j], j]] = true
            f_pointers[j] = best_male_pointers[j]
        end
        println(f_pointers)
    end
end

function da_match(m, n, m_prefs, f_prefs, m_pointers, f_pointers, m_matched, m_offers)#m offers to f
    proceed_pointer!(m, m_pointers, m_matched)
    println("called:0")
    create_offers!(m, m_prefs, m_matched, m_pointers, m_offers)
    println("called:1")

    decide_to_accept!(m, n, f_pointers, f_prefs, m_offers, m_matched)
    println("called:2")

    println(m_matched)
    if all(m_matched) == true
        return f_pointers
    else
        da_match(m, n, m_prefs, f_prefs, m_pointers, f_pointers, m_matched, m_offers)
    end
end

println(call_match(3, 3, Int[1 2 1; 2 1 3; 3 3 2], Int[1 2 1; 2 1 2; 3 3 3]))
