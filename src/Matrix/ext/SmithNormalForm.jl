# `SmithNormalForm.jl` (modified, see history)
# https://github.com/wildart/SmithNormalForm.jl

module SmithNormalForm_x

using LinearAlgebra
using SparseArrays
using Base.CoreLogging
using ...Extensions: isunit, normalizing_unit

# U D V = M, Uinv M Vinv = D

function snf(M::AbstractMatrix{R}; inverse=true) where {R}
    (U, V, D, Uinv, Vinv) = init(M, inverse=inverse)

    _snf_step1(U, V, D, Uinv, Vinv; inverse=inverse)
    _snf_step2(U, V, D, Uinv, Vinv; inverse=inverse)
    _snf_step3(U, V, D, Uinv, Vinv; inverse=inverse)

    (U, V, D, Uinv, Vinv)
end

function bezout(a::R, b::R) where {R}
    (g, s, t) = gcdx(a, b)

    if g == a
        s = one(R)
        t = zero(R)
    elseif g == -a
        s = -one(R)
        t = zero(R)
    end
    
    (s, t, g)
end

function divisable(y::R, x::R) where {R}
    x == zero(R) && return y == zero(R)
    return iszero(y % x)
end

function divide(y::R, x::R) where {R}
    if x != -one(R)
        return div(y, x)
    else
        return y * x
    end
end

function rcountnz(X::AbstractMatrix{R}, j::Int) where {R}
    c = 0
    z = zero(R)
    @inbounds for row in eachrow(X)
        if row[j] != z
            c += 1
        end
    end
    return c
end

function ccountnz(X::AbstractMatrix{R}, i::Int) where {R}
    c = 0
    z = zero(R)
    @inbounds for col in eachcol(X)
        if col[i] != z
            c += 1
        end
    end
    return c
end

function rswap!(M::AbstractMatrix, r1::Int, r2::Int)
    r1 == r2 && return M
    @inbounds for col in eachcol(M)
        col[r1], col[r2] = col[r2], col[r1]
    end
    return M
end

function cswap!(M::AbstractMatrix, c1::Int, c2::Int)
    c1 == c2 && return M
    @inbounds for row in eachrow(M)
        row[c1], row[c2] = row[c2], row[c1]
    end
    return M
end

function rowelimination(D::AbstractMatrix{R}, a::R, b::R, c::R, d::R, i::Int, j::Int) where {R}
    @inbounds for col in eachcol(D)
        t = col[i]
        s = col[j]
        col[i] = a * t + b * s
        col[j] = c * t + d * s
    end
    return D
end

function colelimination(D::AbstractMatrix{R}, a::R, b::R, c::R, d::R, i::Int, j::Int) where {R}
    @inbounds for row in eachrow(D)
        t = row[i]
        s = row[j]
        row[i] = a * t + b * s
        row[j] = c * t + d * s
    end
    return D
end

function select_pivot(D::AbstractMatrix{R}, t::Int, j::Int) :: Int where {R}
    # Good pivot row for j-th column is the one
    # that have a smallest number of elements
    rows = size(D)[1]
    prow = 0
    rsize = typemax(Int)
    for i in t:rows
        iszero(D[i, j]) && continue
        c = count(!iszero, view(D, i, :))
        if c < rsize
            rsize = c
            prow = i
        end
    end
    (prow > 0) ? prow : error()
end

function rmul(X::AbstractMatrix{R}, i::Int, a::R) where {R}
    @views X[i, :] .*= a
end

function cmul(X::AbstractMatrix{R}, j::Int, a::R) where {R}
    @views X[:, j] .*= a
end

function rowpivot(U::AbstractMatrix{R},
    Uinv::AbstractMatrix{R},
    D::AbstractMatrix{R},
    i, j; inverse=true) where {R}
    for k in reverse!(findall(!iszero, view(D, :, j)))
        a = D[i, j]
        b = D[k, j]

        i == k && continue

        s, t, g = bezout(a, b)
        x = divide(a, g)
        y = divide(b, g)

        rowelimination(D, s, t, -y, x, i, k)
        inverse && rowelimination(Uinv, s, t, -y, x, i, k)
        colelimination(U, x, y, -t, s, i, k)
    end
end

function colpivot(V::AbstractMatrix{R},
    Vinv::AbstractMatrix{R},
    D::AbstractMatrix{R},
    i, j; inverse=true) where {R}
    for k in reverse!(findall(!iszero, view(D, i, :)))
        a = D[i, j]
        b = D[i, k]

        j == k && continue

        s, t, g = bezout(a, b)
        x = divide(a, g)
        y = divide(b, g)

        colelimination(D, s, t, -y, x, j, k)
        inverse && colelimination(Vinv, s, t, -y, x, j, k)
        rowelimination(V, x, y, -t, s, j, k)
    end
end

function smithpivot(U::AbstractMatrix{R},
    Uinv::AbstractMatrix{R},
    V::AbstractMatrix{R},
    Vinv::AbstractMatrix{R},
    D::AbstractMatrix{R},
    i, j; inverse=true) where {R}

    pivot = D[i, j]
    @assert pivot != zero(R) "Pivot cannot be zero"
    while ccountnz(D, i) > 1 || rcountnz(D, j) > 1
        colpivot(V, Vinv, D, i, j, inverse=inverse)
        rowpivot(U, Uinv, D, i, j, inverse=inverse)
    end
end

function init(M::AbstractSparseMatrix{R,Ti}; inverse=true) where {R,Ti}
    D = copy(M)
    rows, cols = size(M)

    U = spzeros(R, rows, rows)
    for i in 1:rows
        U[i, i] = one(R)
    end
    Uinv = inverse ? copy(U) : spzeros(R, 0, 0)

    V = spzeros(R, cols, cols)
    for i in 1:cols
        V[i, i] = one(R)
    end
    Vinv = inverse ? copy(V) : spzeros(R, 0, 0)

    return U, V, D, Uinv, Vinv
end

function init(M::AbstractMatrix{R}; inverse=true) where {R}
    D = copy(M)
    rows, cols = size(M)

    U = zeros(R, rows, rows)
    for i in 1:rows
        U[i, i] = one(R)
    end
    Uinv = inverse ? copy(U) : zeros(R, 0, 0)

    V = zeros(R, cols, cols)
    for i in 1:cols
        V[i, i] = one(R)
    end
    Vinv = inverse ? copy(V) : zeros(R, 0, 0)

    return U, V, D, Uinv, Vinv
end

formatmtx(M) = size(M, 1) == 0 ? "[]" : repr(collect(M); context=IOContext(stdout, :compact => true))

function _snf_step1(U::AbstractMatrix{R},
    V::AbstractMatrix{R},
    D::AbstractMatrix{R},
    Uinv::AbstractMatrix{R},
    Vinv::AbstractMatrix{R}
    ; inverse=true) where {R}

    cols = size(D)[2]
    t = 1

    for j in 1:cols
        @debug "Working on column $j out of $cols" D = formatmtx(D)

        rcountnz(D, j) == 0 && continue

        prow = select_pivot(D, t, j)

        @debug "Pivot Row selected: t = $t, pivot = $prow" D = formatmtx(D)

        # swap rows
        rswap!(D, t, prow)
        inverse && rswap!(Uinv, t, prow)
        cswap!(U, t, prow)

        # swap cols
        cswap!(D, t, j)
        inverse && cswap!(Vinv, t, j)
        rswap!(V, t, j)

        # normalize
        (u, uinv) = normalizing_unit(D[t, t])
        if !isone(u)
            cmul(D, t, u)
            rmul(V, t, uinv)
            inverse && cmul(Vinv, t, u)
        end

        @debug "Performing the pivot step at (i=$t, j=$t)" D = formatmtx(D)
        smithpivot(U, Uinv, V, Vinv, D, t, t, inverse=inverse)

        t += 1

        @logmsg (Base.CoreLogging.Debug - 1) "Factorization" D = formatmtx(D) U = formatmtx(U) V = formatmtx(V) U⁻¹ = formatmtx(Uinv) V⁻¹ = formatmtx(Vinv)
    end
end

function _snf_step2(U::AbstractMatrix{R},
    V::AbstractMatrix{R},
    D::AbstractMatrix{R},
    Uinv::AbstractMatrix{R},
    Vinv::AbstractMatrix{R}
    ; inverse=true) where {R}

    # Make sure that d_i is divisible be d_{i+1}.
    r = minimum(size(D))
    pass = true
    while pass
        pass = false
        for i in 1:r-1
            divisable(D[i+1, i+1], D[i, i]) && continue
            pass = true
            D[i+1, i] = D[i+1, i+1]

            colelimination(Vinv, one(R), one(R), zero(R), one(R), i, i + 1)
            rowelimination(V, one(R), zero(R), -one(R), one(R), i, i + 1)

            smithpivot(U, Uinv, V, Vinv, D, i, i, inverse=inverse)
        end
    end
end

function _snf_step3(U::AbstractMatrix{R},
    V::AbstractMatrix{R},
    D::AbstractMatrix{R},
    Uinv::AbstractMatrix{R},
    Vinv::AbstractMatrix{R}
    ; inverse=true) where {R}

    rows, cols = size(D)

    # To guarantee SNFⱼ = Λⱼ ≥ 0 we absorb the sign of Λ into T and T⁻¹, s.t.
    #    Λ′ = Λ*sign(Λ),   T′ = sign(Λ)*T,    and    T⁻¹′ = T⁻¹*sign(Λ),
    # with the convention that sign(0) = 1. Then we still have that X = SΛT = SΛ′T′
    # and also that Λ = S⁻¹XT⁻¹ ⇒ Λ′ = S⁻¹XT⁻¹′.
    for j in 1:rows
        j > cols && break
        d = D[j, j]

        (u, uinv) = normalizing_unit(d)
        isone(u) && continue

        D[j, j] *= u
        rmul(V, j, uinv)
        inverse && cmul(Vinv, j, u)
    end
    @logmsg (Base.CoreLogging.Debug - 1) "Factorization" D = formatmtx(D) U = formatmtx(U) V = formatmtx(V) U⁻¹ = formatmtx(Uinv) V⁻¹ = formatmtx(Vinv)

    if issparse(D)
        return dropzeros!(U), dropzeros!(V), dropzeros!(D), dropzeros!(Uinv), dropzeros!(Vinv)
    else
        return U, V, D, Uinv, Vinv
    end
end

end