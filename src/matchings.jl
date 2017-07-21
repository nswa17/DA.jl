include("tools.jl")
import .DATools: FixedSizeBinaryMaxHeap, length, pop!, push!, top, getindex

function create_resp_ranks(num_props::Int, num_resps::Int, resp_prefs::Vector{Vector{Int}})
    resp_ranks = zeros(UInt16, num_props, num_resps)
    for j in 1:num_resps
        for (r, i) in enumerate(resp_prefs[j])
            @inbounds resp_ranks[i, j] = r
        end
    end
    return resp_ranks
end

function convert_into_matched(num_props::Int,
                              resp_prefs::Vector{Vector{Int}},
                              resp_matched_ranks::Vector{FixedSizeBinaryMaxHeap},
                              caps::Vector{Int})
    prop_matched = zeros(Int, num_props)
    resp_matched = Vector{Int}(sum(caps))
    ctr = 1
    for j in 1:length(resp_matched_ranks)
        for k in 1:caps[j]
            if k <= length(resp_matched_ranks[j])
                p = resp_prefs[j][resp_matched_ranks[j][k]]
                prop_matched[p] = j
                resp_matched[ctr] = p
            else
                resp_matched[ctr] = 0
            end
            ctr += 1
        end
    end
    return prop_matched, resp_matched
end

function deferred_acceptance(prop_prefs::Vector{Vector{Int}}, resp_prefs::Vector{Vector{Int}})
    prop_matched, resp_matched, _ = deferred_acceptance(prop_prefs, resp_prefs, ones(Int, length(resp_prefs)))
    return prop_matched, resp_matched
end

function deferred_acceptance(prop_prefs::Vector{Vector{Int}},
                             resp_prefs::Vector{Vector{Int}},
                             caps::Vector{Int})
    # Set Up
    num_props = length(prop_prefs)
    num_resps = length(resp_prefs)

    resp_ranks = create_resp_ranks(num_props, num_resps, resp_prefs)

    prop_ptrs = ones(UInt16, num_props)
    resp_matched_ranks = FixedSizeBinaryMaxHeap[FixedSizeBinaryMaxHeap(caps[j]) for j in 1:num_resps]
    prop_unmatched = Vector{Int}(num_props)
    for i in 1:num_props
        prop_unmatched[i] = i
    end
    remaining::Int = num_props
    p::Int = 0
    p_rank::UInt16 = 0
    least_p::Int = 0
    least_p_rank::UInt16 = 0
    r::Int = 0

    # Main Loop
    while remaining > 0
        p = prop_unmatched[remaining]
        if prop_ptrs[p] > length(prop_prefs[p])#p no longer wants to find a partner
            remaining -= 1
            continue
        end
        r = prop_prefs[p][prop_ptrs[p]]
        resp_matched_rank = resp_matched_ranks[r]
        least_p_rank = top(resp_matched_rank)
        p_rank = resp_ranks[p, r]
        if p_rank == 0
            prop_ptrs[p] += 1
        elseif length(resp_matched_rank) < caps[r]
            push!(resp_matched_rank, p_rank)
            remaining -= 1
        elseif least_p_rank > p_rank
            pop!(resp_matched_rank)
            push!(resp_matched_rank, p_rank)
            least_p = resp_prefs[r][least_p_rank]
            prop_unmatched[remaining] = least_p
            prop_ptrs[least_p] += 1
        else
            prop_ptrs[p] += 1
        end
    end

    prop_matched, resp_matched = convert_into_matched(num_props, resp_prefs, resp_matched_ranks, caps)
    indptr = Vector{Int}(num_resps+1)
    indptr[1] = 1
    for j in 1:num_resps
        indptr[j+1] = indptr[j] + caps[j]
    end
    return prop_matched, resp_matched, indptr
end

function deferred_acceptance(prop_prefs::Vector{Vector{Int}},
                             resp_prefs::Vector{Vector{Int}},
                             resp_caps::Vector{Int},
                             prop_caps::Vector{Int})
    v_num_props = sum(prop_caps)# number of virtual props
    num_props = length(prop_prefs)
    refs = Vector{Vector{Int}}(v_num_props)
    refs_rev = Vector{Int}(v_num_props)
    prop_indptr = Vector{Int}(num_props+1)

    prop_indptr[1] = 1
    for i in 1:num_props
        prop_indptr[i+1] = prop_indptr[i] + prop_caps[i]
    end

    for (i, prop_cap) in enumerate(prop_caps)
        refs[i] = collect(prop_indptr[i]:prop_indptr[i+1]-1)
        refs_rev[prop_indptr[i]:prop_indptr[i+1]-1] = i
    end

    v_prop_prefs = Vector{Vector{Int}}(v_num_props)
    for (i, prop_pref) in enumerate(prop_prefs)
        for v_i in refs[i]
            v_prop_prefs[v_i] = prop_pref
        end
    end

    v_resp_prefs = deepcopy(resp_prefs)
    for j in 1:length(resp_prefs)
        for ind in length(resp_prefs[j]):-1:1
            i = resp_prefs[j][ind]
            v_is = refs[i]
            splice!(v_resp_prefs[j], ind, v_is)
        end
    end

    prop_matched, resp_matched, resp_indptr = deferred_acceptance(v_prop_prefs, v_resp_prefs, resp_caps)

    for k in 1:length(resp_matched)
        if resp_matched[k] != 0
            resp_matched[k] = refs_rev[resp_matched[k]]
        end
    end

    return prop_matched, resp_matched, resp_indptr, prop_indptr
end

function generate_random_prefs{T <: Integer}(num_props::T, num_resps::T; max_prop_pref::Int=num_resps, max_resp_pref::Int=num_props)
    prop_prefs = Vector{Vector{Int}}(num_props)
    resp_prefs = Vector{Vector{Int}}(num_resps)
    for i in 1:num_props
        prop_prefs[i] = collect(Iterators.take(shuffle(collect(1:num_resps)), max_prop_pref))
    end
    for j in 1:num_resps
        resp_prefs[j] = collect(Iterators.take(shuffle(collect(1:num_props)), max_resp_pref))
    end
    return prop_prefs, resp_prefs
end
