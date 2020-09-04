module results

export Result, Ok, Err
export is_ok,
       is_err,
       map,
       fmap,
       bind,
       join,
       and,
       or,
       unwrap,
       unwrap_or,
       unwrap_or_do,
       unwrap_err,
       expect,
       alter,
       map_or,
       map_or_do,
       safe


abstract type Result end

struct Ok{T} <: Result
    value::T
end

struct Err{E} <: Result
    err::E
end

# `unit` (called `return` in Haskell) is just Ok(T) and Err(E)

# Not recommended to use these methods, consider `unwrap_or` or `expect`.
is_ok(r::Ok)::Bool = true
is_ok(r::Err)::Bool = false
is_err(r::Result)::Bool = !is_ok(r)

# Like rust's map, it does not touch an Err
# Ok{T}, fn{T -> U} -> Ok{U}
# Err{E}, _ -> Err{E}
map(r::Ok, fn::Function)::Result = Ok(fn(r.value))
map(r::Err, fn::Function)::Result = r

# This is a true functor map that applies for both Ok and Err
# Result{T, E}, fn{T -> U} -> Result{U, E}
fmap(r::Ok, fn::Function)::Result = Ok(fn(r.value))
fmap(r::Err, fn::Function)::Result = Err(fn(r.err))

# Monadic bind
# Result{T, E}, fn{T -> Result{U, E}} -> Result{U, E}
bind(r::Ok, fn::Function)::Result = fn(r.value)
bind(r::Err, fn::Function)::Result = fn(r.err)
(≻)(r::Ok, fn::Function)::Result = bind(r, fn)
(≻)(r::Err, fn::Function)::Result = bind(r, fn)

# Result{Result{T, E}, E} -> Result{T, E}
# Called `flatten` in Rust
# Flattens a nested Result into a single Result
join(nested_r::Result)::Result = bind(nested_r, (x) -> x)

# If both results are Ok, return the other one
# Otherwise, return the first error
# Same as Rust
and(r::Ok, other::Ok)::Ok = other
and(r::Result, other::Result)::Err = is_err(r) ? r : other

# If either results is `Ok`, return that one. Otherwise, return the second Err
# Same as Rust
or(r::Ok, other::Result)::Ok = r
or(r::Err, other::Ok)::Ok = other
or(r::Err, other::Err)::Err = other

# Same as Rust
# Ok{T} -> T
unwrap(r::Ok) = r.value
unwrap(r::Err) = error("Unwrapping on an Err but expecting Ok!")

# Same as Rust
# Use this if you want to get the value or use a given default
# Ok{T}, _ -> T
# Err{E}, U -> U
unwrap_or(r::Ok, default) = r.value
unwrap_or(r::Err, default) = default

# Called `unwrap_or_else` in Rust
# Use this if the default comes from a function
# Ok{T}, _ -> T
# Err{E}, fn{E -> F} -> F
unwrap_or_do(r::Ok, fn::Function) = r.value
unwrap_or_do(r::Err, fn::Function) = fn(r.err)

# Same as Rust
# Take the error value
# Err{E} -> E
unwrap_err(r::Ok) = error("Unwrapping on an Ok but expecting Err!")
unwrap_err(r::Err) = r.err

# Slightly different from Rust: function is only called on panic
# See: https://rust-lang.github.io/rust-clippy/master/index.html#expect_fun_call
# Use this if you want to get the value inside an `Ok`, and fail fast on an Err
# Ok{T} -> T
expect(r::Ok, msg::AbstractString) = r.value
expect(r::Err, msg::AbstractString) = error(msg)

# Called `map_err` in Rust
# Result{T, E}, fn{E -> F} -> Result{T, F}
# Ok{T}, _ -> T
# Err{E}, fn{E -> F} -> Err{F}
alter(r::Ok, fn::Function)::Ok = r
alter(r::Err, fn::Function)::Err = Err(fn(r.err))

# Applies function to value if Ok, else return default
# Ok{T}, _, fn{T -> U} -> U
# Err{E}, F, _ -> F
map_or(r::Ok, default, fn::Function) = fn(r.value)
map_or(r::Err, default, fn::Function) = default

# Applies first function to value if Ok, else apply second function to error
# Called `map_or_else` in Rust
# Ok{T}, fn{T -> U}, _ -> T
# Err{E}, _, fn{E -> F} -> F
map_or_do(r::Ok, ok_fn::Function, err_fn::Function) = ok_fn(r.value)
map_or_do(r::Err, ok_fn::Function, err_fn::Function) = err_fn(r.err)


# Wraps a function that might raise an exception to prevent it from doing so
# Returns Ok(...) on success, else return the exception inside Err(...)
function safe(unsafe_fn::Function)
    function wrapper(args...)
        try
            return Ok(unsafe_fn(args...))
        catch e
            return Err(e)  # Or e.msg?
        end
    end
    return wrapper
end

end # module
