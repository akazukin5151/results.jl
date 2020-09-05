using Test

using results
using results: map, bind, join, ≻


@testset "Mathematical laws" begin
    # Right identity: m >>= return = m
    # Bind doesn't recognise constructors as functions
    @test (Ok(2) ≻ (x) -> Ok(x)) == Ok(2)
    @test (Err(2) ≻ (x) -> Err(x)) == Err(2)

    # Left identity: return x >>= f = f x
    h(x) = Ok(x + 1)
    @test (Ok(2) ≻ h) == h(2) == Ok(3)
    @test (Err(2) ≻ h) == h(2) == Ok(3)

    # Associativity
    f1(x) = Ok(x + 10)
    g1(x) = Ok(x * 10)
    #         (m >>= f) >>= g  =    m  >>= (\x -> f x >>= g)
    @test ((Ok(2) ≻ f1) ≻ g1) == (Ok(2) ≻ (x) -> (f1(x) ≻ g1))

    # Functor law: fmap id = id
    id(x) = x
    @test map(id, Ok(2)) == fmap(id, Ok(2)) == Ok(2)
    @test map(id, Err(2)) == fmap(id, Err(2)) == Err(2)

    # Functor law: fmap (f . g) x = fmap f (fmap g x)
    f(x) = x + 10
    g(x) = x * 10
    @test map(f∘g, Ok(2)) == map(f, map(g, Ok(2)))
    @test map(f∘g, Err(2)) == map(f, map(g, Err(2)))
    @test fmap(f∘g, Ok(2)) == fmap(f, fmap(g, Ok(2)))
    @test fmap(f∘g, Err(2)) == fmap(f, fmap(g, Err(2)))

    # Defining fmap in terms of bind
    # fmap f x = x >>= (return . f)
    @test fmap(f, Ok(2)) == (Ok(2) ≻ Ok∘f)
    @test fmap(f, Err(2)) == (Err(2) ≻ Err∘f)

    # Defining join with bind
    # join x = x >>= id
    @test join(Ok(Ok(2))) == (Ok(Ok(2)) ≻ id)
    # join (fmap g m) = m >>= g
    @test join(map(h, Ok(2))) == (Ok(2) ≻ h)
end

@testset "Identities" begin
    v = Ok(2)
    @test v |> is_ok
    @test ! (v |> is_err)

    e = Err(3)
    @test !is_ok(e)
    @test is_err(e)
end

@testset "Map" begin
    v = Ok(2)
    @test map(v) do x
        x + 10
    end == Ok(12)
    @test map_or(v, 11) do x
        x * 3
    end == 6
    @test map_or_do(v, v -> v^2, e -> e - 1) == 4

    e = Err(3)
    @test map(e) do x
        x + 10
    end == Err(3)
    @test map_or(e, 11) do x
        x * 3
    end == 11
    @test map_or_do(e, v -> v^2, e -> e - 1) == 2
end

@testset "Bind" begin
    v = Ok(2)
    @test bind(v) do x
        Ok(x * 2)
    end == Ok(4)
    @test bind(v) do x
        Err(x * 2)
    end == Err(4)

    e = Err(3)
    @test bind(e) do x
        Ok(x * 2)
    end == Ok(6)
    @test bind(e) do x
        Err(x * 2)
    end == Err(6)
end

@testset "Join" begin
    v = Ok(2)
    @test join(Ok(v)) == v

    e = Err(3)
    @test join(Err(e)) == e
end

@testset "And" begin
    v = Ok(2)
    @test and(v, Ok(20)) == Ok(20)
    @test and(v, Err(4)) == and(Err(4), v) == Err(4)
    @test and(Err(3), Err(4)) == Err(3)
end

@testset "Or" begin
    v = Ok(2)
    e = Err(3)
    @test or(v, e) == or(e,v) == v
    @test or(v, Ok(3)) == v
    @test or(e, Err(5)) == Err(5)
end

@testset "Unwraps" begin
    v = Ok(2)
    @test unwrap(v) == 2
    @test_throws Exception unwrap_err(v)
    @test unwrap_or(v, 10) == 2
    @test unwrap_or_do(v) do x
        x + 1
    end == 2

    e = Err(3)
    @test_throws Exception unwrap(e)
    @test unwrap_err(e) == 3
    @test unwrap_or(e, 10) == 10
    @test unwrap_or_do(e) do x
        x + 1
    end == 4
end

@testset "Expect" begin
    @test expect(Ok(2), "Panic!") == 2
    @test_throws Exception expect(Err(2), "Panic!")
end

@testset "Alter" begin
    @test alter(Ok(2)) do e
        e + 1
    end == Ok(2)
    @test alter(Err(3)) do e
        e + 1
    end == Err(4)
end

@testset "Safe" begin
    # In julia, dividing by zero returns infinity,
    # but we just want an example of a function that can raise
    reciprocal(x) = x == 0 ? error("Divide by zero") : 1 / x

    @test safe(reciprocal)(2) == Ok(0.5)
    @test safe(reciprocal)(0) |> is_err
    @test alter(safe(reciprocal)(0)) do e; e.msg end == Err("Divide by zero")
end
