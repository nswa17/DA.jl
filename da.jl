#DA algorythm
#todo: @time to compare recursive version and normal version
#    : test function
#    : make code readable
#    : order
#    : not
#    : what if pointers[i] exceeds n

#recursive version
#
#input: m, n, 1d array of m_prefs, 1d array of f_prefs
#output: m-elements 1d array, n-elements 1d array
#
function call_match(m, n, m_prefs, f_prefs)
    m != length(m_prefs) || n != length(f_prefs) && error("the size of the ")####
    m_pointers = ones(Int, m)
    f_pointers = zeros(Int, n)

    m_matched = falses(m)
    m_offers = zeros(Int, m)

    da_match(m, n, m_prefs, f_prefs, m_pointers, f_pointers, m_matched, m_offers)
end

function proceed_pointer(pointer_males)
    return pointer_males .+ 1
end

function male_pref(n, m_prefs, pointer_males, i)
    return pointer_males[i] > n ? 0 : m_prefs[i, pointer_males[i]]
end

function create_offers!(m, m_prefs, m_matched, m_pointers, m_offers)
    for i in 1:m
        if m_matched[i]
            m_offers[i] = 0
        else
            m_offers[i] = m_prefs[i, m_pointers[i]]
        end
    end
end

function decide_to_accept(f_pointers, m_offers)

function da_match(m, n, m_prefs, f_prefs, m_pointers, f_pointers, m_matched, m_offers)#m offers to f
    m_pointers = proceed_pointer!(m_pointers)
    create_offers!(m, m_prefs, m_matched, m_pointers, m_offers)

    new_temp_matched_males = choose_best_male(n, f_prefs, candidate_males, temp_matched_males)

    println("called:2")
    if new_temp_matched_males == temp_matched_males
        return temp_matched_males
    else
        da_match(m, n, m_prefs, f_prefs, pointer_males, new_temp_matched_males)
    end
end

function choose_best_male(n, f_prefs, candidate_males, temp_matched_males)##########
    new_temp_matched_males = copy(temp_matched_males)
    for j in 1:n
    for i in f_prefs[j]
        if i in candidate_males[:, j] &&  findfirst(f_prefs[j], temp_matched_males[j]) > i
            new_temp_matched_males[j] = i
            break
        end
    end
    new_temp_matched_males[j] = 0
    end
    return new_temp_matched_males
end

call_match(2, 2, Int[1 2; 1 2], Int[1 2; 2 1])
