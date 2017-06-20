# WHAT IF caps[i] = 0
module DA
    export deferred_acceptance, generate_random_prefs

using DataStructures: binary_maxheap

type FixedSizeBinaryMaxHeap
    heap::Array{Int}
    ind::Int
    max_length::Int
    FixedSizeBinaryMaxHeap(m_max::Int) = new(Array(Int, m_max), 0, m_max)
end

function Base.length(bmh::FixedSizeBinaryMaxHeap)
    return bmh.ind
end

function isfull(bmh::FixedSizeBinaryMaxHeap)
    if bmh.max_length == bmh.ind
        return true
    else
        return false
    end
end

function Base.push!(bmh::FixedSizeBinaryMaxHeap, value::Int)
    bmh.ind += 1
    bmh.heap[bmh.ind] = value
    reshape_up!(bmh)
end

function top(bmh::FixedSizeBinaryMaxHeap)
    if bmh.ind == 0
        return 0
    else
        return bmh.heap[1]
    end
end

function exchange!(bmh::FixedSizeBinaryMaxHeap, priority::Int)
    bmh.heap[1] = priority
    reshape_down!(bmh)
end

function Base.pop!(bmh::FixedSizeBinaryMaxHeap)
    ret_val = bmh.heap[1]
    bmh.heap[1] = bmh.heap[bmh.ind]
    bmh.ind -= 1
    reshape_down!(bmh)
    return ret_val
end

function Base.getindex(bmh::FixedSizeBinaryMaxHeap, ind::Int)
    return bmh.heap[ind]
end

function reshape_down!(bmh::FixedSizeBinaryMaxHeap)
    current_ind = 1
    while true
        c1, c2 = current_ind * 2, current_ind * 2 + 1
        if c1 > bmh.ind
            break
        elseif c2 > bmh.ind
            c = c1
        else
            c = bmh.heap[c1] < bmh.heap[c2] ? c2 : c1
        end
        if bmh.heap[current_ind] < bmh.heap[c]
            bmh.heap[c], bmh.heap[current_ind] = bmh.heap[current_ind], bmh.heap[c]
            current_ind = c
        else
            break
        end
    end
end

function reshape_up!(bmh::FixedSizeBinaryMaxHeap)
    current_ind = bmh.ind
    while true
        par = current_ind >> 1
        if par == 0 || bmh.heap[current_ind] <= bmh.heap[par]
            break
        else
            bmh.heap[current_ind], bmh.heap[par] = bmh.heap[par], bmh.heap[current_ind]
        end
        current_ind = par
    end
end

function create_ranks!(m::Int, n::Int, prefs::Vector{Vector{Int}}, ranks::Array{Int, 2})
    for j in 1:n
        for (r, i) in enumerate(prefs[j])
            @inbounds ranks[i, j] = r
        end
    end
    ranks[m+1, :] = m + 1
end

function adjust_matched!(m_matched::Vector{Int}, f_matched::Vector{Int})
    m::Int = length(m_matched)

    for (j, i) in enumerate(f_matched)
        if i == m + 1
            f_matched[j] = 0
        else
            m_matched[i] = j
        end
    end
end

function deferred_acceptance(m_prefs::Vector{Vector{Int}}, f_prefs::Vector{Vector{Int}})
    # Set Up
    m = length(m_prefs)
    n = length(f_prefs)

    f_ranks = zeros(Int, m+1, n)
    create_ranks!(m, n, f_prefs, f_ranks)

    m_pointers = ones(Int, m)
    f_matched = fill(m+1, n)
    m_matched = zeros(Int, m)
    m_searching = Array(Int, m)
    for i in 1:m
        m_searching[i] = i
    end
    remaining::Int = m

    # Main Loop
    while remaining > 0
        i = m_searching[remaining]
        if m_pointers[i] > length(m_prefs[i])
            remaining -= 1
            continue
        end
        f_proposed = m_prefs[i][m_pointers[i]]
        current_m_of_f = f_matched[f_proposed]

        if 0 < f_ranks[i, f_proposed] < f_ranks[current_m_of_f, f_proposed]
            f_matched[f_proposed] = i
            remaining -= 1
            if current_m_of_f != m + 1
                remaining += 1
                m_searching[remaining] = current_m_of_f
                m_pointers[current_m_of_f] += 1
            end
        else
            m_pointers[i] += 1
        end
    end

    adjust_matched!(m_matched, f_matched)
    return m_matched, f_matched
end

function create_ranks_rev!(prefs::Vector{Vector{Int}}, ranks::Array{Int, 2})
    n::Int = length(prefs)
    for j in 1:n
        for (r, i) in enumerate(prefs[j])
            @inbounds ranks[i, j] = r
        end
    end
end

function adjust_matched_rev!(resp_prefs::Vector{Vector{Int}}, prop_matched::Vector{Int}, resp_matched::Vector{Int}, resp_matched_ranks::Vector{FixedSizeBinaryMaxHeap}, caps::Vector{Int})
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
end

deferred_acceptance_rev(prop_prefs::Vector{Vector{Int}}, resp_prefs::Vector{Vector{Int}}) = deferred_acceptance_rev(prop_prefs, resp_prefs, ones(Int, length(resp_prefs)))

function deferred_acceptance_rev(prop_prefs::Vector{Vector{Int}}, resp_prefs::Vector{Vector{Int}}, caps::Vector{Int})
    # Set Up
    num_props = length(prop_prefs)
    num_resps = length(resp_prefs)

    resp_ranks = zeros(Int, num_props, num_resps)
    create_ranks_rev!(resp_prefs, resp_ranks)

    prop_ptrs = ones(Int, num_props)
    resp_matched_ranks = [FixedSizeBinaryMaxHeap(caps[j]) for j in 1:num_resps]
    prop_matched = Array(Int, num_props)
    resp_matched = Array(Int, sum(caps))
    prop_unmatched = Array(Int, num_props)
    for i in 1:num_props
        prop_unmatched[i] = i
    end
    remaining::Int = num_props

    # Main Loop
    while remaining > 0
        p = prop_unmatched[remaining]
        if prop_ptrs[p] > length(prop_prefs[p])#p no longer wants to find a partner
            remaining -= 1
            continue
        end
        r = prop_prefs[p][prop_ptrs[p]]
        least_p_rank = top(resp_matched_ranks[r])
        p_rank = resp_ranks[p, r]
        if p_rank == 0
            prop_ptrs[p] += 1
        elseif !isfull(resp_matched_ranks[r])
            push!(resp_matched_ranks[r], p_rank)
            remaining -= 1
        elseif least_p_rank > p_rank
            pop!(resp_matched_ranks[r])
            push!(resp_matched_ranks[r], p_rank)
            least_p = resp_prefs[r][least_p_rank]
            prop_ptrs[least_p] += 1
        else
            prop_ptrs[p] += 1
        end
    end

    adjust_matched_rev!(resp_prefs, prop_matched, resp_matched, resp_matched_ranks, caps)
    indptr = Array(Int, num_resps+1)
    indptr[1] = 1
    for j in 1:num_resps
        indptr[j+1] = indptr[j] + caps[j]
    end
    return prop_matched, resp_matched, indptr
end

function deferred_acceptance(m_prefs::Vector{Vector{Int}}, f_prefs::Vector{Vector{Int}}, caps::Vector{Int})
    m::Int = length(m_prefs)
    n::Int = length(f_prefs)
    m_prefs_2d = zeros(Int, n+1, m)
    f_prefs_2d = zeros(Int, m+1, n)
    for i in 1:m
        for c in 1:length(m_prefs[i])
            m_prefs_2d[c, i] = m_prefs[i][c]
        end
    end
    for j in 1:n
        for c in 1:length(f_prefs[j])
            f_prefs_2d[c, j] = f_prefs[j][c]
        end
    end
    return call_match(m_prefs_2d, f_prefs_2d, caps)
end


function call_match{T <: Integer}(m_prefs::Array{T, 2}, f_prefs::Array{T, 2}, caps::Array{T, 1})
    m::Int = size(m_prefs, 2)
    n::Int = size(f_prefs, 2)

    f_ranks = get_ranks(f_prefs)
    m_pointers = zeros(Int, m)
    f_pointers = [binary_maxheap(Int) for j in 1:n] ### f_pointers :: (m x n) matrix

    m_matched_tf = falses(m)
    m_offers = zeros(Int, 2, m+1)
    m_offers[1, 1] = 1

    da_match(m, n, f_ranks, m_prefs, f_prefs, m_pointers, f_pointers, m_matched_tf, m_offers, caps)
    return convert_pointer_to_list(m, n, f_pointers, f_prefs, caps)
end

@inbounds function get_ranks{T <: Integer}(prefs::Array{T, 2})
    ranks = Array(eltype(prefs), size(prefs))
    for j in 1:size(prefs, 2)
        for (r, i) in enumerate(prefs[:, j])
            if i != 0
                ranks[i, j] = r
            else
                ranks[end, j] = r
            end
        end
    end
    return ranks
end

function convert_pointer_to_list(m::Int, n::Int, f_pointers, f_prefs, caps)
    f_matched = zeros(Int, sum(caps))
    m_matched = zeros(Int, m)
    indptr = Array(Int, n+1)
    i::Int = 0
    indptr[1] = 1
    for i in 1:n
        indptr[i+1] = indptr[i] + caps[i]
    end

    total = 1
    for j in 1:n
        for c in 1:caps[j]
            if isempty(f_pointers[j])
                f_matched[total] = 0
            else
                i = pop!(f_pointers[j])
                f_matched[total] = f_prefs[i, j]
                m_matched[f_prefs[i, j]] = j
            end
            total += 1
        end
    end

    return m_matched, f_matched, indptr
end

@inbounds function proceed_pointer!{T <: Integer}(m::Int, n::Int, m_pointers::Array{T, 1}, m_matched_tf, m_prefs)
    for i in 1:m
        if m_pointers[i] > n
            m_matched_tf[i] = true
        else
            if !m_matched_tf[i]
                m_pointers[i] += 1
                if m_prefs[m_pointers[i], i] == 0
                    m_matched_tf[i] = true
                end
            end
        end
    end
end

@inbounds function create_offers!{T <: Integer}(m::Int, m_prefs::Array{T, 2}, m_matched_tf, m_pointers::Array{T, 1}, m_offers)
    c::Int = 1
    for i in 1:m
        if !m_matched_tf[i] && m_prefs[m_pointers[i], i] != 0
            m_offers[1, c] = i
            m_offers[2, c] = m_prefs[m_pointers[i], i]
            c += 1
        end
    end
    m_offers[1, c] = 0
    m_offers[2, c] = 0
end

@inbounds function decide_to_accept!{T <: Integer}(f_pointers, f_ranks::Array{T, 2}, f_prefs::Array{T, 2}, m_offers, m_matched_tf, caps::Array{T, 1})
    for k in 1:length(m_offers)
        m_offers[1, k] == 0 && break
        i = m_offers[1, k]
        j = m_offers[2, k]
        if f_ranks[end, j] > f_ranks[i, j]
            push!(f_pointers[j], f_ranks[i, j])
            m_matched_tf[i] = true
            if caps[j] < length(f_pointers[j])# if f's matching male reaches to the cap
                m_matched_tf[f_prefs[pop!(f_pointers[j]), j]] = false
            end
        end
    end
end

function da_match{T <: Integer}(m::Int, n::Int, f_ranks::Array{T, 2}, m_prefs::Array{T, 2}, f_prefs::Array{T, 2}, m_pointers::Array{T, 1}, f_pointers, m_matched_tf, m_offers, caps::Array{T, 1})
    while m_offers[1, 1] != 0
        proceed_pointer!(m, n, m_pointers, m_matched_tf, m_prefs)
        create_offers!(m, m_prefs, m_matched_tf, m_pointers, m_offers)
        decide_to_accept!(f_pointers, f_ranks, f_prefs, m_offers, m_matched_tf, caps)
    end
end

function generate_random_prefs{T <: Integer}(m::T, n::T)
    m_prefs = Array(Vector{Int}, m)
    f_prefs = Array(Vector{Int}, n)
    for i in 1:m
        m_prefs[i] = shuffle(collect(1:n))
    end
    for j in 1:n
        f_prefs[j] = shuffle(collect(1:m))
    end
    return m_prefs, f_prefs
end

end
