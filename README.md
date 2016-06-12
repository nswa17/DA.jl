# da.jl
julia code for DA Algorithm

## Usage

### DA

: module

### DA.call_match

: ```(m_prefs, f_prefs[, rec, m_first]) ->
 matched_males_list, matched_females_list```

: call DA algorithm with given argument

```m_prefs``` -- 2 dimensional array of size ```(n + 1) * m```

```f_prefs``` -- 2 dimensional array of size ```(m + 1) * n```

```rec``` -- false by defalt, an optional argument to call recursive DA algorithm

```m_first``` -- true by default, an optional argument to decide which gender offers to the other

### DA.check_data

: ```(m_prefs, f_prefs) -> throw an error if any```

: checks given argument to safely conduct matching

### DA.generate_random_preference_data

: ```(m, n) -> (m_prefs, f_prefs)```

: generates preference data

```m``` -- number of males

```n``` -- number of females


### DA.check_results(m_matched, f_matched)

: ```(m_matched, f_matched) -> throw an error if any```

: checks results of matching

## Example

```

include("da.jl")

m, n = 100, 100
m_prefs, f_prefs = DA.generate_random_preference_data(m, n)

DA.check_data(m, n, m_prefs, f_prefs) # checks data before conducting matching

m_matched, f_matched = call_match(m, n, m_prefs, f_prefs) # matches males and females

DA.check_results(m_matched, f_matched)  # checks whether results fit

```
