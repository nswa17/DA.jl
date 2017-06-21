# DA.jl

julia implementation of Deferred Acceptance Algorithm

## Usage

### DA

module

### DA.deferred_acceptance

#### (prop_prefs::Vector{Vector{Int}}, resp_prefs::Vector{Vector{Int}}[, resp_caps::Vector{Int}[, prop_caps::Vector{Int}]]) -> prop_matched, resp_matched[, resp_indptr[, prop_indptr]]

call DA algorithm with given arguments

### DA.generate_random_prefs

#### (num_props::Int, num_resps::Int) -> (prop_prefs, resp_prefs)

generates preference data

## Example

```julia
using DA

num_props, num_resps = 100, 100
prop_prefs, resp_prefs = generate_random_prefs(num_props, num_resps)

prop_matched, resp_matched = deferred_acceptance(prop_prefs, resp_prefs)
```

num_props, num_resps must be less than 2^16-1
