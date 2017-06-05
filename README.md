# DA.jl
julia code for DA Algorithm

## Usage

### DA

: module

### DA.main

: ```(m_prefs, f_prefs[, caps]) ->
 matched_males_list, matched_females_list[, indptr]```

: call DA algorithm with given argument

```m_prefs``` -- 2 dimensional array of size ```(n + 1) * m```

```f_prefs``` -- 2 dimensional array of size ```(m + 1) * n```

```caps``` -- 1 dimensional array of length ```n```

### DA.generate_random_prefs

: ```(m, n) -> (m_prefs, f_prefs)```

: generates preference data

```m``` -- number of males

```n``` -- number of females

## Example

```

include("da.jl")

m, n = 100, 100
m_prefs, f_prefs = DA.generate_random_prefs(m, n)

m_matched, f_matched = DA.main(m_prefs, f_prefs) # matches males and females

```
