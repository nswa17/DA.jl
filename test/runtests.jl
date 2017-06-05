using DA
using Base.Test

const _deferred_acceptance = deferred_acceptance

function mat2vecs{T<:Integer}(prefs::Matrix{T})
    return [prefs[1:findfirst(prefs[:, j], 0)-1, j] for j in 1:size(prefs, 2)]
end

@testset "Testing deferred acceptance" begin
    matchings_one_to_one = Array{Dict, 1}()

    # Test case: one-to-one
    m, n = 4, 3
    # Males' preference orders over females [1, 2, 3] and unmatched 0
    m_prefs = [1 3 2 3;
               2 1 3 1;
               3 2 1 2;
               0 0 0 0]
    # Females' preference orders over males [1, 2, 3, 4] and unmatched 0
    f_prefs = [3 1 3;
               1 2 0;
               2 3 2;
               4 4 1;
               0 0 4]
    # Unique stable matching
    m_matches_m_opt = m_matches_f_opt = [1, 2, 3, 0]
    f_matches_m_opt = f_matches_f_opt = [1, 2, 3]
    d = Dict(
        "m_prefs" => m_prefs,
        "f_prefs" => f_prefs,
        "m_matches_m_opt" => m_matches_m_opt,
        "f_matches_m_opt" => f_matches_m_opt,
        "m_matches_f_opt" => m_matches_f_opt,
        "f_matches_f_opt" => f_matches_f_opt,
    )
    push!(matchings_one_to_one, d)

    # Test case: one-to-one; from Roth and Sotomayor Example 2.9
    m, n = 5, 4
    m_prefs = [
        1, 2, 3, 4, 0,
        4, 2, 3, 1, 0,
        4, 3, 1, 2, 0,
        1, 4, 3, 2, 0,
        1, 2, 4, 0, 3,
    ]
    m_prefs = reshape(m_prefs, n+1, m)
    f_prefs = [
        2, 3, 1, 4, 5, 0,
        3, 1, 2, 4, 5, 0,
        5, 4, 1, 2, 3, 0,
        1, 4, 5, 2, 3, 0,
    ]
    f_prefs = reshape(f_prefs, m+1, n)
    m_matches_m_opt, f_matches_m_opt = [1, 2, 3, 4, 0], [1, 2, 3, 4]
    m_matches_f_opt, f_matches_f_opt = [4, 1, 2, 3, 0], [2, 3, 4, 1]
    d = Dict(
        "m_prefs" => m_prefs,
        "f_prefs" => f_prefs,
        "m_matches_m_opt" => m_matches_m_opt,
        "f_matches_m_opt" => f_matches_m_opt,
        "m_matches_f_opt" => m_matches_f_opt,
        "f_matches_f_opt" => f_matches_f_opt,
    )
    push!(matchings_one_to_one, d)

    # Test case: one-to-one; from Roth and Sotomayor Example 2.17
    m = n = 4
    m_prefs = [
        1, 2, 3, 4, 0,
        2, 1, 4, 3, 0,
        3, 4, 1, 2, 0,
        4, 3, 2, 1, 0,
    ]
    m_prefs = reshape(m_prefs, n+1, m)
    f_prefs = [
        4, 3, 2, 1, 0,
        3, 4, 1, 2, 0,
        2, 1, 4, 3, 0,
        1, 2, 3, 4, 0,
    ]
    f_prefs = reshape(f_prefs, m+1, n)
    m_matches_m_opt = f_matches_m_opt = [1, 2, 3, 4]
    m_matches_f_opt = f_matches_f_opt = [4, 3, 2, 1]
    d = Dict(
        "m_prefs" => m_prefs,
        "f_prefs" => f_prefs,
        "m_matches_m_opt" => m_matches_m_opt,
        "f_matches_m_opt" => f_matches_m_opt,
        "m_matches_f_opt" => m_matches_f_opt,
        "f_matches_f_opt" => f_matches_f_opt,
    )
    push!(matchings_one_to_one, d)

    @testset "one-to-one: Vector of Vectors" begin
        for d in matchings_one_to_one
            # Convert Matrix to Vector{Vector}
            m_prefs, f_prefs = mat2vecs.([d["m_prefs"], d["f_prefs"]])

            # Male proposal
            m_matches, f_matches = _deferred_acceptance(m_prefs, f_prefs)
            @test m_matches == d["m_matches_m_opt"]
            @test f_matches == d["f_matches_m_opt"]

            # Female proposal
            f_matches, m_matches = _deferred_acceptance(f_prefs, m_prefs)
            @test m_matches == d["m_matches_f_opt"]
            @test f_matches == d["f_matches_f_opt"]
        end
    end
end
