using Test, Fracciones

@testset "Constructores" begin
    @test Fraccion(true, 0x0f) === Fraccion{UInt8}(1, 15) # comprobar tipos
    @test Fraccion(0x00, 5) === Fraccion(0, 1) # ok aunque 0x00 == typemin(UInt8)
    @test Fraccion(2, 0) === Fraccion(1, 0)
    @test Fraccion(-2, 0) === Fraccion(-1, 0)
    # inválidos
    @test_throws ArgumentError Fraccion(0, 0)
    @test_throws ArgumentError Fraccion(Int8(-128), Int8(5))
    @test_throws ArgumentError Fraccion(Int8(5), Int8(-128))
    # otros constructores
    @test Fraccion{Int}(1.0, 2.0) === Fraccion(1,2)
    @test Fraccion{UInt8}(1, 2) === Fraccion(0x01, 0x02)
    @test Fraccion{UInt8}(Fraccion(1,2)) === Fraccion(0x01, 0x02)
    @test Fraccion(0) === Fraccion(0,1)
    @test Fraccion(2) === Fraccion(2,1)
    @test Fraccion{UInt8}(2.0) === Fraccion(0x02,0x01)
    @test Fraccion(2.0) === Fraccion(2,1)
    @test Fraccion(Inf) === Fraccion(1,0)
    @test Fraccion(-Inf) === Fraccion(-1,0)
    @test Fraccion(1,2) === Fraccion(Fraccion(1,2))
end

@testset "Conversiones" begin
    @test Int(Fraccion(4,2)) === 2
    @test float(Fraccion(1,4)) == 0.25
    @test Float64[Fraccion(1,2), Fraccion(1,4)] == [0.5, 0.25]
end

@testset "Signos" begin
    @test Fraccion(5, -2) == Fraccion(-5, 2) == -Fraccion(5,2)
    @test numerador(Fraccion(5,-2)) < 0
    @test denominador(Fraccion(5,-2)) > 0
end

@testset "Propiedades y generadores" begin
    @test numerador(Fraccion(2,4)) == 1
    @test denominador(Fraccion(2,4)) == 2
    @test numerador(Fraccion(3,0)) == 1
    @test reciproco(Fraccion(2, 6)) == 3
    @test reciproco(3) == Fraccion(1, 3)
    @test sign(Fraccion(1,2)) == 1
    @test sign(Fraccion(-1,2)) == -1
    @test sign(Fraccion(0)) == 0
    @test abs(Fraccion(-1,2)) == Fraccion(1,2)
    @test one(Fraccion{UInt8}) === Fraccion(0x01)
    @test one(Fraccion) === Fraccion(1)
    @test zero(Fraccion{UInt8}) === Fraccion(0x00)
    @test zero(Fraccion) === Fraccion(0)
    @test zeros(Fraccion, 2) == Fraccion[0, 0]
    @test ones(Fraccion, 2) == Fraccion.([1, 1])
    @test typemin(Fraccion{Int}) === Fraccion(-1,0)
    @test typemin(Fraccion{UInt8}) === Fraccion(0x00)
    @test typemin(Fraccion{Bool}) === Fraccion(false)
    @test typemax(Fraccion{Int}) === Fraccion(1,0)
    @test typemax(Fraccion{UInt8}) === Fraccion(0x01,0x00)
    @test typemax(Fraccion{Bool}) === Fraccion(true,false)
end

@testset "Operaciones algebraicas" begin
    @test Fraccion(1, 12) + Fraccion(5, 3) == Fraccion(7, 4)
    @test Fraccion(2, 3) - Fraccion(1, 5) == Fraccion(7, 15)
    # con infinitos
    @test Fraccion(1, 0) + Fraccion(1,2) === Fraccion(1, 0)
    @test Fraccion(1, 0) + 3 == Fraccion(1, 0)
    @test Fraccion(1, 3) * Fraccion(3, 4) == Fraccion(1, 4)
    @test Fraccion(1, 2) / Fraccion(3, 4) == Fraccion(2, 3)
    @test_throws ArgumentError Fraccion(0, 1) * Fraccion(-1, 0)

    @test Fraccion(2,3)^-2 == Fraccion(9,4)
    @test Fraccion(2,3)^3 == Fraccion(8,27)
    @test Fraccion(1,3)^0 == 1
    # combinar con otros tipos de números
    @test Fraccion(1,3) + 2 == 2 + Fraccion(1,3) == Fraccion(7,3)
    @test Fraccion(1,3) + 0 == Fraccion(1,3)
    @test 2 - Fraccion(1,0) == Fraccion(-1,0)
    @test Fraccion(1,3) * 2 == 2 * Fraccion(1,3) == Fraccion(2,3)
    @test Fraccion(1,3) * 0 == Fraccion(0,1)
    @test 2 * Fraccion(1,0) == Fraccion(1,0)
    @test Fraccion(1,3) / 2 == Fraccion(1,6)
    @test 2 / Fraccion(1,3) == Fraccion(6)
    @test Fraccion(1,6) / 0 == Fraccion(1,0)
    @test 0 / Fraccion(1,0) == Fraccion(0,1)
end

@testset "Comparaciones" begin
    for (menor, mayor) = (
        (Fraccion(1,4), Fraccion(1,2)), (0.25, Fraccion(1,2)), (Fraccion(1,4), 0.5),
        (Fraccion(0), Fraccion(1,2)), (0, Fraccion(1,2)), (Fraccion(0), 0.5),
        (Fraccion(-1,4), Fraccion(0)), (-0.25, Fraccion(0)), (Fraccion(-1,4), 0),
        (Fraccion(0), Fraccion(1,0)), (0, Fraccion(1,0)), (Fraccion(0), Inf),
        (Fraccion(-1,0), Fraccion(0)), (-Inf, Fraccion(0)), (Fraccion(-1,0), 0),
        (Fraccion(-1,0), Fraccion(1,0)), (-Inf, Fraccion(1,0)), (Fraccion(-1,0), Inf)
    )
        @test menor < mayor
        @test -menor > -mayor
        @test menor ≤ mayor
        @test mayor ≥ menor
        @test menor == menor
        @test mayor == mayor
    end
end

@testset "Función y macro `fraccion`" begin
    @test fraccion(3, Fraccion(5,2)) == Fraccion(6,5)
    @test fraccion(Fraccion(5,2), 3) == Fraccion(5,6)
    @test (@fraccion 3/4) == Fraccion(3, 4)
    @test (@fraccion (3 + (4/3))/5^2) == Fraccion(13, 75) == 13/75
end
