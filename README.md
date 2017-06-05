# DA.jl
julia implementation of Deferred Acceptance Algorithm

## Usage

### DA

module

### DA.deferred_acceptance

```(m_prefs, f_prefs[, caps]) ->
 matched_males_list, matched_females_list[, indptr]```

call DA algorithm with given arguments

```m_prefs``` -- 1-d array of arrays

```f_prefs``` -- 1-d array of arrays

### DA.generate_random_prefs

```(m, n) -> (m_prefs, f_prefs)```

generates preference data

```m``` -- number of males

```n``` -- number of females

## Example

```

using DA

m, n = 100, 100
m_prefs, f_prefs = generate_random_prefs(m, n)

m_matched, f_matched = deferred_acceptance(m_prefs, f_prefs)

```
