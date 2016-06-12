# da.jl
julia code for DA Algorithm

## usage

DA
    : module

DA.call_match
    : (m, n, m_prefs, f_prefs[, rec]) -> matched_males_list, matched_females_list

DA.check_data
    : (m, n, m_prefs, f_prefs) -> throw an error if any

DA.generate_random_preference_data
    : (m, n) -> (m_prefs, f_prefs)

## an example

```

include("da.jl")

m, n = 100, 100
m_prefs, f_prefs = DA.generate_random_preference_data(m, n)

DA.check_data(m, n, m_prefs, f_prefs)

m_f, f_m = call_match(m, n, m_prefs, f_prefs)

DA.check_results(m_f, f_m)

```
