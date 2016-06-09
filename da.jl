#DA algorythm
#todo: @time to compare recursive version and normal version
#    : test function
#    : make code readable

#recursive version
#
#input: m, n, 1d array of m_prefs, 1d array of f_prefs
#output: m-elements 1d array, n-elements 1d array
#
function call_match(m, n, m_prefs, f_prefs)
    males = 1:m
    females = 1:n

    pointer_males = ones(Int, m)
    temp_matched_males = zeros(Int, n)

    println("called:1")
    da_match(m, n, m_prefs, f_prefs, pointer_males, temp_matched_males)
end

function tuples2list(m, n, candidate_arrays)##########change algorithm to reduce memory cost
    #println(candidate_tuples)
    candidate_males = [Int[] for i in 1:n]
    for candidate_array in candidate_arrays
    if candidate_array[2] != 0
        #println(tuple)
        push!(candidate_males[candidate_array[2]], candidate_array[1])
    end
    end
    println(candidate_males)########needs to be fixed
    return hcat(candidate_males...)
end

function proceed_pointer!(pointer_males)
    return pointer_males .+ 1
end

function male_pref(n, m_prefs, pointer_males, i)
    return pointer_males[i] > n ? 0 : m_prefs[i, pointer_males[i]]
end

function da_match(m, n, m_prefs, f_prefs, pointer_males, temp_matched_males)#m offers to f
    candidate_tuples = [[i, male_pref(n, m_prefs, pointer_males, i)] for i in 1:m]
    pointer_males = proceed_pointer!(pointer_males)
    #println(candidate_tuples)
    println("called:3")

    candidate_males = tuples2list(m, n, candidate_tuples)
    println("called:4")
    println(candidate_males)
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
