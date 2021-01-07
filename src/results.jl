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


abstract type Result{T, E} end

struct Ok{T} <: Result{T, nothing}
    value::T
end

struct Err{E} <: Result{nothing, E}
    err::E
end

# `unit` (called `return` in Haskell) is just Ok(T) and Err(E)

"Not recommended to use these methods, consider `unwrap_or` or `expect`."
is_ok(r::Ok)::Bool = true
is_ok(r::Err)::Bool = false
is_err(r::Result)::Bool = !is_ok(r)

"""Applies a function to an Ok value. Like rust's map, it ignores Err
fn{T -> U}, Ok{T} -> Ok{U}
_, Err{E} -> Err{E}"""
map(fn::Function, r::Ok)::Ok = Ok(fn(r.value))
map(fn::Function, r::Err)::Err = r

"""A functor map that applies for both Ok and Err
fn{T -> U}, Result{T, E} -> Result{U, E}"""
fmap(fn::Function, r::Ok)::Ok = Ok(fn(r.value))
fmap(fn::Function, r::Err)::Err = Err(fn(r.err))

"""Monadic bind. The word form adheres to Julia conventions by having the function as the
first argument so the `do` notation can be used.
The operator form adheres to Haskell conventions by having the function as the
second argument. The operator can be used as an infix operator, however note that
precedence is low and should always be surrounded by brackets.

fn{T -> Result{U, E}}, Result{T, E} -> Result{U, E}
Result{T, E}, fn{T -> Result{U, E}} -> Result{U, E}
"""
bind(fn::Function, r::Ok)::Result = fn(r.value)
bind(fn::Function, r::Err)::Result = fn(r.err)
(≻)(r::Ok, fn::Function)::Result = bind(fn, r)
(≻)(r::Err, fn::Function)::Result = bind(fn, r)

"""Flattens a nested Result into a single Result. Called `flatten` in Rust
Result{Result{T, E}, E} -> Result{T, E}"""
join(nested_r::Result)::Result = bind((x) -> x, nested_r)

"""If both results are Ok, return the other one. Otherwise, return the first error."""
and(r::Ok, other::Ok)::Ok = other
and(r::Result, other::Result)::Err = is_err(r) ? r : other

"""If either results is `Ok`, return that one. Otherwise, return the second Err."""
or(r::Ok, other::Result)::Ok = r
or(r::Err, other::Ok)::Ok = other
or(r::Err, other::Err)::Err = other

"""Get the wrapped value inside an Ok, or raise on an Err.
Ok{T} -> T"""
unwrap(r::Ok) = r.value
unwrap(r::Err) = error("Unwrapping on an Err but expecting Ok!")

"""Get the wrapped value inside an Ok, or use a given default on an Err.
Ok{T}, _ -> T
Err{E}, U -> U"""
unwrap_or(r::Ok, default) = r.value
unwrap_or(r::Err, default) = default

"""Get the wrapped value inside an Ok, or call a function with the Err.
Called `unwrap_or_else` in Rust.

_, Ok{T} -> T
fn{E -> F}, Err{E} -> F"""
unwrap_or_do(fn::Function, r::Ok) = r.value
unwrap_or_do(fn::Function, r::Err) = fn(r.err)

"""Get the wrapped value inside an Err, or raise on an Ok.
Err{E} -> E"""
unwrap_err(r::Ok) = error("Unwrapping on an Ok but expecting Err!")
unwrap_err(r::Err) = r.err

"""Get the wrapped value inside an `Ok`, and raise on an Err with a custom message
Slightly different from Rust: function is only called on Err
See: https://rust-lang.github.io/rust-clippy/master/index.html#expect_fun_call

Ok{T} -> T"""
expect(r::Ok, msg::AbstractString) = r.value
expect(r::Err, msg::AbstractString) = error(msg)

"""Alter the wrapped value inside an Err, ignoring an Ok. Called `map_err` in Rust.
_, Ok{T} -> T
fn{E -> F}, Err{E} -> Err{F}"""
alter(fn::Function, r::Ok)::Ok = r
alter(fn::Function, r::Err)::Err = Err(fn(r.err))

"""Applies function to wrapped value inside an Ok, else return given default.
fn{T -> U}, Ok{T}, _ -> U
_, Err{E}, F, -> F"""
map_or(fn::Function, r::Ok, default) = fn(r.value)
map_or(fn::Function, r::Err, default) = default

"""Applies first function to wrapped value inside Ok, else apply second function to
wrapped value inside Err. Called `map_or_else` in Rust.
Note that the two function arguments are not the first, contrary to Julia conventions

Ok{T}, fn{T -> U}, _ -> T
Err{E}, _, fn{E -> F} -> F"""
map_or_do(r::Ok, ok_fn::Function, err_fn::Function) = ok_fn(r.value)
map_or_do(r::Err, ok_fn::Function, err_fn::Function) = err_fn(r.err)


"""Wraps a function that might raise an exception to prevent it from doing so
Returns Ok(...) on success, else return the exception inside Err(...)"""
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

"""Wraps an expression that might raise an exception to prevent it from doing so
Returns Ok(...) on success, else return the exception inside Err(...)"""
macro safe(ex)
   quote
       try
           Ok($(esc(ex)))
       catch e
           Err(e)
       end
   end
end

end # module
