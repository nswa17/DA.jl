#DA algorythm

#recursive version
function call_match(m, n, m_prefs, f_prefs)
  males = 1:m
  females = 1:n

  pointer_males = ones(m)
  temp_matched_males = zeros(n)

  da_match(m, n, m_prefs, f_prefs, pointer_males, temp_matched_males)
end

function da_match(m, n, m_prefs, f_prefs, pointer_males, temp_matched_males)#m offers to f
  candidate_males = Array(Int32, m, n)
  for i in 1:m
    push!(candidate_males[m_prefs[i, pointer_males[i]]], i)
  end

  choose_best_male!(n, f_prefs, candidate_males, temp_matched_males)
  if all(pointer_males .== n)
    return temp_matched_males
  else
    da_match(m, n, m_prefs, f_prefs, pointer_males, temp_matched_males)
  end
end

function choose_best_male(n, f_prefs, candidate_males, temp_matched_males)
  for j in 1:n
    for i in f_prefs[j]
      if i in candidate_males[:, j]
        temp_matched_males[j] = i
        break
      end
    end
    temp_matched_males[j] = 0
  end
end

call_match(2, 2, [1 2; 2 1], [1 2; 2 1])
