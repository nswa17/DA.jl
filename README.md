# DA.jl

julia implementation of Deferred Acceptance Algorithm

## Usage

### DA

module

### DA.deferred_acceptance

#### (prop_prefs::Vector{Vector{Int}}, resp_prefs::Vector{Vector{Int}}[, resp_caps::Vector{Int}[, prop_caps::Vector{Int}]]) -> prop_matched, resp_matched[, resp_indptr[, prop_indptr]]

call DA algorithm with given arguments

num_props, num_resps, sum(resp_caps), sum(prop_caps) must all be less than 2^16-1

### DA.generate_random_prefs

#### (num_props::Int, num_resps::Int) -> (prop_prefs, resp_prefs)

generates preference data

## Example

```julia
using DA

num_props, num_resps = 1000, 1000
prop_prefs, resp_prefs = generate_random_prefs(num_props, num_resps)

prop_matched, resp_matched = deferred_acceptance(prop_prefs, resp_prefs)
```

