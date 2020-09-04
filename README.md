# results.jl

> A functional Result monad to handle failures and exceptions without crashing

Inspired by Rust's `Result<T, E>` [type](https://doc.rust-lang.org/std/result/enum.Result.html) and the [returns](https://github.com/dry-python/returns) python library.

With only 141 lines, the source code is very minimal and easy to read. Every function/method is documented. In fact, the 'mathematical laws' section in the tests might be harder to understand than the source!

## Features

* Obeys mathematical monadic and functor laws
* Map
* Bind
* Join
* And
* Or
* Unwrap
* Expect
* Alter
* Safe (wrapper for functions that might raise)


## Installation

1. In the Julia REPL, press `]` to go to pkg mode
2. `add https://github.com/twenty5151/results.jl`

There are no dependencies, but you may want to use Lazy.jl for better piping.

## Developing / install from source

1. Git clone
2. In the Julia REPL, hit `]` to go to pkg mode
3. `activate .`
4. Test with `test` (in pkg mode)

## Examples

```jl
julia> using results
julia> using results: map, bind, ≻
julia> might_fail(x) = x > 3 ? Err("Value too large!") : Ok(x + 1)

julia> v = might_fail(1)
Ok{Int64}(2)

julia> e = might_fail(10)
Err{String}("Value too large!")

julia> map(v, x -> x * 2)
Ok{Int64}(4)

julia> bind(e, x -> Ok(length(x)))  # Fixing the error
Ok{Int64}(16)

julia> e ≻ x -> Err(string(x, " hello world"))  # Fancy bind operator
Err{String}("Value too large! hello world")

julia> unwrap(v)
2

julia> unwrap(e)
ERROR: Unwrapping on an Err but expecting Ok!
```

Read the 141-line source code and tests for more.

The `safe` function catches any exceptions and returns the Exception wrapped in an `Err`.

```jl
# In julia, dividing by zero returns infinity,
# but we just want an example of a function that can raise

julia> using results
julia> reciprocal(x) = x == 0 ? error("Divide by zero") : 1 / x

julia> safe(reciprocal)(2)
Ok{Float64}(0.5)

julia> res = safe(reciprocal)(0)
Err{ErrorException}(ErrorException("Divide by zero"))

julia> alter(res, e -> e.msg)
Err{String}("Divide by zero")
```
