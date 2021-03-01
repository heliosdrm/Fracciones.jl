using MacroTools

"""
    Fraccion{T<:Integer}(num, den) <: Real
    Fraccion(num, den)
    
Crea una `Fraccion` con numerador `num` y denominador `den`.
Si se especifica el parámetro `T`, el numerador y el denominador se transforman
a números enteros de ese tipo; si no se especifica, `T` viene determinado
por el más amplio de los tipos de `num` y `den`, que habrán de ser enteros.

Se puede usar la función [`fraccion`](@ref) o la macro [`@fraccion`](@ref)
para crear fracciones a partir de otros conjuntos de valores.

# Valores del numerador y denominador

Al crear una fracción, los valores del numerador y el denominador siempre se
reducen a los de su forma canónica equivalente --
p.ej. `Fraccion(2,4)` se reduce a `Fraccion(1,2)`.

Se permite la definición de las fracciones `Fraccion(1, 0)` y `Fraccion(-1, 0)` --
equivalentes a ± infinito, pero no la de valor indefinido `Fraccion(0, 0).

Al ser el numerador y el denominador números de tipo `Integer`, sus valores
están sujetos a posibles errores por desbordamiento aritmético, si superan
(en valor absoluto) el límite de `typemax(T)`.

---

    Fraccion{T<:Integer}(x)
    Fraccion(x)
    
Transforma el número `x` en una fracción equivalente. 
"""
struct Fraccion{T<:Integer} <: Real
    num::T
    den::T
    
    function Fraccion{T}(n, d) where {T<:Integer}
        num = convert(T, n)
        den = convert(T, d)
        # 0/0 no permitido
        iszero(num) && iszero(den) && throw(ArgumentError("fracción inválida: cero entre cero"))
        # reducir a fracción mínima
        mcd = gcd(num, den)
        num = div(num, mcd)
        den = div(den, mcd)
        # fracciones con typemin(T) no permitidas
        if T<:Signed && (num === typemin(T) || den === typemin(T))
            throw(ArgumentError("fracción inválida: no se puede usar typemin($T)"))
        end
        # denominador negativo
        if den < zero(T)
            num = -num
            den = -den
        end
        new{T}(num, den)
    end
end

# Sin parametrizar
function Fraccion(num::N, den::D) where {N<:Integer, D<:Integer}
    T = promote_type(N, D)
    Fraccion{T}(num, den)
end

"""
    numerador(x)
    
Extrae el numerador de `x`.
"""
numerador(x::Fraccion)   = x.num
numerador(x::Integer) = x

"""
    denominador(x)
    
Extrae el denominador de `x`.
"""
denominador(x::Fraccion) = x.den
denominador(x::T) where {T<:Integer} = one(T)

# Constructores con un solo argumento
Fraccion{T}(x) where T = Fraccion{T}(numerador(x), denominador(x))
Fraccion(x) = Fraccion(numerador(x), denominador(x))
Fraccion{T}(x::Fraccion{T}) where T = x # evitar ambiguedad con T(x::T) where {T<:Number}
Fraccion(x::Fraccion) = x

# Constructores de otros tipos
function (::Type{T})(x::Fraccion) where {T<:Integer}
    if x.den == 1
        convert(T, x.num)
    else
        throw(InexactError(nameof(T), T, x))
    end
end

function (::Type{T})(x::Fraccion{S}) where {T<:AbstractFloat, S}
    P = promote_type(T, S)
    convert(T, convert(P,x.num)/convert(P,x.den))
end

# Reglas de promoción
Base.promote_rule(::Type{Fraccion{T}}, ::Type{<:Integer}) where T = Fraccion{T}
Base.promote_rule(::Type{<:Fraccion}, ::Type{T}) where {T<:AbstractFloat} = T

# Representación
Base.show(io::IO, x::Fraccion) = print(io, "Fraccion($(x.num), $(x.den))")


# Propiedades y funciones numéricas elementales
Base.sign(x::Fraccion) = sign(x.num)
Base.abs(x::Fraccion) = Fraccion(abs(x.num), x.den)
Base.one(::Type{Fraccion{T}}) where T = Fraccion(one(T))
Base.zero(::Type{Fraccion{T}}) where T = Fraccion(zero(T))
Base.typemin(::Type{Fraccion{T}}) where T = Fraccion(-one(T), zero(T))
Base.typemax(::Type{Fraccion{T}}) where T = Fraccion{T}(one(T), zero(T))
Base.typemin(::Type{Fraccion{T}}) where {T<:Union{Unsigned, Bool}} = zero(Fraccion{T})

# Algebra
Base.:+(x::Fraccion) = Fraccion(+x.num, x.den)
Base.:-(x::Fraccion) = Fraccion(-x.num, x.den)
Base.:-(x::Fraccion{<:Unsigned}) = throw(TypeError(:-, Signed, x))

"""
    reciproco(x)
    
Calcula la fracción recíproca de `x`.
"""
reciproco(x::Fraccion) = Fraccion(x.den, x.num)   
reciproco(x) = reciproco(Fraccion(x)) 

function Base.:+(x::Fraccion{Tx}, y::Fraccion{Ty}) where {Tx<:Integer, Ty<:Integer}
    if x.den == 0 == y.den
        if sign(x) ≠ sign(y)
            throw(ArgumentError("resultado indefinido"))
        else
            T = promote_type(Tx, Ty)
            return Fraccion(x.num * y.num, zero(T))
        end
    end
    mcd = gcd(x.den, y.den)
    xfactor = div(y.den, mcd)
    yfactor = div(x.den, mcd)
    den = xfactor * yfactor * mcd
    return Fraccion(x.num * xfactor + y.num * yfactor, den)
end

Base.:-(x::Fraccion, y::Fraccion) = x + -y

function Base.:*(x::Fraccion, y::Fraccion)
    f1 = Fraccion(x.num, y.den)
    f2 = Fraccion(y.num, x.den)
    Fraccion(f1.num * f2.num, f1.den * f2.den)
end

Base.:/(x::Fraccion, y::Fraccion) = x * reciproco(y)

function Base.:^(x::Fraccion, n::Integer)
    if n ≥ 0
        return Fraccion(x.num^n,  x.den^n)
    else
        return Fraccion(x.den^(-n), x.num^(-n))
    end
end

# Comparaciones

Base.:(==)(x::Fraccion, y::Fraccion) = (x.num == y.num) && (x.den == y.den)

function Base.:<(x::Fraccion, y::Fraccion)
    (x.num == 0 == y.num) && return false
    (x.den == 0 == y.den) && return (x.num == -1 && y.num == 1)
    xsig = sign(x)
    ysig = sign(y)
    if xsig == ysig
        f = x/y
        return (xsig == 1) ⊻ (f.num > f.den)
    else
        return xsig < ysig
    end
end

Base.:<=(x::Fraccion, y::Fraccion) = (x < y) | (x == y) # necesario por ser Fraccion <:Real

# Otros generadores
"""
    fraccion(x, y)
    
Crea una fracción equivalente a dividir `x` entre `y`.

Los valores introducidos han de ser interpretables como números enteros o fracciones.

```jldoctest
julia> fraccion(Fraccion(5,2), 3)
Fraccion(5, 6)
```
"""
fraccion(x, y) = Fraccion(x) / Fraccion(y)

"""
    @fraccion x/y
    
Crea una fracción equivalente la expresión `x/y`.

Si las partes de la expresión `x` e `y` contienen otras divisiones,
estas se interpretan también como fracciones.

```jldoctest
julia> @fraccion (1+(5/2))/3
Fraccion(7, 6)
```
"""
macro fraccion(ex)
    MacroTools.postwalk(ex) do subex
        hayfraccion = @capture(subex, num_ / den_)
        if hayfraccion
            return :(fraccion($num, $den))
        else
            return subex
        end
    end
end


