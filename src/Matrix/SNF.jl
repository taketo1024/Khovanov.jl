using AbstractAlgebra
using SparseArrays: blockdiag

export SNF, snf

# SNF

struct SNF{R<:RingElement}
    factors::Vector{R}
    T::Transform{SparseMatrix{R}}
end

function Base.iterate(S::SNF{R}, i = 0) where {R}
    if i == 0
        S.factors, 1
    elseif i == 1
        S.T.P, 2
    elseif i == 2
        S.T.P⁻¹, 3
    elseif i == 3
        S.T.Q, 4
    elseif i == 4
        S.T.Q⁻¹, 5
    else
        nothing
    end
end

function snf(A::SparseMatrix{R}; preprocess=true, flags=(false, false, false, false)) :: SNF{R} where {R<:RingElement}
    d_threshold = 0.75

    if iszero(A)
        SNF(R[], identity_transform(SparseMatrix{R}, size(A); flags=flags))
    elseif preprocess && density(A) < d_threshold
        _snf_preprocess(A, flags)
    else
        _snf_dense(A, flags)
    end
end

function _snf_preprocess(A::SparseMatrix{R}, flags) :: SNF{R} where {R}
    piv = pivot(A)
    npivots(piv) == 0 && return _snf_dense(A, flags)

    (r, S, T) = schur_complement(A, piv; flags=flags)

    if min(size(S)...) > 0 
        next = snf(S; flags=flags)
        _snf_compose(r, T, next, flags)
    else
        d = fill(one(R), r)
        SNF(d, T)
    end
end

function _snf_compose(r, T1, next::SNF{R}, flags) where {R} 
    I(k) = sparse_identity_matrix(R, k)

    d = vcat(fill(one(R), r), next.factors)
    I = identity_transform(SparseMatrix{R}, (r, r); flags=flags)
    T2 = block_diagonal(I, next.T)
    T = compose(T1, T2)

    SNF(d, T)
end

function _snf_dense(A::SparseMatrix{R}, flags) :: SNF{R} where {R}
    I(k) = sparse_identity_matrix(R, k)
    (m, n) = size(A)

    rows = Set{Int}()
    cols = Set{Int}()

    for (i, j) in zip(findnz(A)...)
        push!(rows, i)
        push!(cols, j)
    end

    (k, l) = (length(rows), length(cols))

    if (k, l) == (m, n)
        _snf_dense_sorted(A, flags)
    else
        p = permutation(collect(rows), m)
        q = permutation(collect(cols), n)
        B = permute(A, p, q)[1:k, 1:l]

        F = _snf_dense_sorted(B, flags)

        d = F.factors
        I = identity_transform(SparseMatrix{R}, (m - k, n - l); flags=flags)
        T2 = block_diagonal(F.T, I)
        T = permute(T2, p, q)
    
        SNF(d, T)
    end
end

function _snf_dense_sorted(A::SparseMatrix{R}, flags) :: SNF{R} where {R<:RingElement}
    (m, n) = size(A)
    r = min(m, n)

    Aᵈ = _toDense(A)
    (Sᵈ, Pᵈ, Pinvᵈ, Qᵈ, Qinvᵈ) = snf_x(Aᵈ, flags=flags) # PAQ = S

    d = filter(!iszero, map( i -> Sᵈ[i, i], 1 : r ))
    isempty(d) && (d = R[])

    T = Transform{SparseMatrix{R}}(
        isnothing(Pᵈ) ?  nothing : _toSparse(Pᵈ),
        isnothing(Pinvᵈ) ?  nothing : _toSparse(Pinvᵈ),
        isnothing(Qᵈ) ?  nothing : _toSparse(Qᵈ),
        isnothing(Qinvᵈ) ?  nothing : _toSparse(Qinvᵈ)
    )

    SNF(d, T)
end