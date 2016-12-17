module Multisets

import Base.show, Base.length, Base.getindex, Base.collect
import Base.union, Base.intersect
import Base.push!, Base.setindex!, Base.delete!, Base.hash
import Base.issubset, Base.==, Base.Set


export Multiset, set_short_show, set_julia_show, set_braces_show, clean!

"""
A `Multiset` is an unordered collection of things with repetition permitted.
A new `Multiset` container is created with `Multiset{T}()` where `T` is the
type of the objects held in the multiset. If `T` is omitted, it defaults
to `Any`.

A `Multiset` can be created from a collection `list` (such as a `Vector` or
`Set`) with `Multiset(list)`. If an element is repeated in `list` it has
the appropriate multiplicity.

A `Multiset` can also be created from a list of arguments:
`Multiset(a,b,c,...)`.
"""
type Multiset{T}
  data::Dict{T,Int}
  function Multiset()
    d = Dict{T,Int}()
    new(d)
  end
end
Multiset() = Multiset{Any}()

function Multiset{T,d}(list::AbstractArray{T,d})
  M = Multiset{T}()
  for x in list
    push!(M,x)
  end
  return M
end

function Multiset{T}(A::Base.AbstractSet{T})
  M = Multiset{T}()
  for x in A
    push!(M,x)
  end
  return M
end

function Multiset{T}(items::T...)
  M = Multiset{T}()
  for x in items
    push!(M,x)
  end
  return M
end

"""
`clean!(M)` removes elements of multiplicy 0 from the underlying data
structure supporting `M`.
"""
function clean!(M::Multiset)
  for x in keys(M.data)
    if M[x]==0
      delete!(M.data,x)
    end
  end
  nothing
end


"""
For a `M[t]` where `M` is a `Multiset` returns the
multiplicity of `t` in `M`. A value of `0` means that
`t` is not a member of `M`.
"""
function getindex{T}(M::Multiset{T}, x::T)::Int
  if haskey(M.data,x)
    return M.data[x]
  end
  return 0
end

"""
`push!(M,x,incr)` increases the multiplicity of `x` in `M`
by `incr` (which defaults to 1). `incr` can be negative, but
it is not possible to decrease the multiplicty below 0.
"""
function push!{T}(M::Multiset{T}, x::T, incr::Int=1)::Multiset{T}
  if haskey(M.data,x)
    M.data[x] += incr
  else
    M.data[x] = incr
  end
  if M.data[x] < 0
    M.data[x]=0
  end
  return M
end

function setindex!{T}(M::Multiset{T}, m::Int, x::T)
  M.data[x] = max(m,0)
end

function delete!(M::Multiset, x)
  if haskey(M.data,x)
    delete!(M.data,x)
  end
  return M
end

function length(M::Multiset)
  total = 0
  for v in values(M.data)
    total += v
  end
  return total
end

function collect{T}(M::Multiset{T})
  n = length(M)
  result = Vector{T}(n)
  i = 0
  for (k,v) in M.data
    for _=1:v
      i += 1
      result[i] = k
    end
  end
  try
    sort!(result)
  end
  return result
end

function braces_string{T}(M::Multiset{T})
  elts = collect(M)
  n = length(elts)
  str = "{"
  for k=1:n
    str *= string(elts[k])
    if k<n
      str *= ","
    end
  end
  str *= "}"
  return str
end

short_string{T}(M::Multiset{T}) = "Multiset{$T} with $(length(M)) elements"

function julia_string{T}(M::Multiset{T})
  elts = collect(M)
  n = length(elts)
  str = "Multiset($T["
  q = ""
  if T <: AbstractString
    q = "\""
  end
  for k=1:n
    str *= q*string(elts[k])*q
    if k<n
      str *= ","
    end
  end
  str *= "])"
  return str
end


# This variable controls printing:
# 0 -- {x,y,z}
# 1 -- Multiset{T} with n elements
# 2--  Multiset{T}(x,y,z)

multi_show_braces = 0
multi_show_short  = 1
multi_show_julia  = 2
multi_show_flag = multi_show_braces



"""
Set show display mode for multisets, like this:

`Multiset{Int64} with 7 elements`

See also `set_braces_show` and `set_julia_show`.
"""
set_short_show() = (global multi_show_flag = multi_show_short; nothing)

"""
Set braces display mode for multisets, like this:

`{1,2,2,3,3,3,3}`

See also `set_short_show` and `set_julia_show`.
"""
set_braces_show() = (global multi_show_flag = multi_show_braces; nothing)


"""
Set Julia style display mode for multisets, like this:

`Multiset(Int64[1,2,2,3,3,3,3])`

See also `set_short_show` and `set_braces_show`.
"""
set_julia_show()  = (global multi_show_flag = multi_show_julia; nothing)

function show(io::IO, M::Multiset)
  if multi_show_flag == multi_show_short
    print(io, short_string(M))
  end
  if multi_show_flag == multi_show_braces
    print(io, braces_string(M))
  end
  if multi_show_flag == multi_show_julia
    print(io, julia_string(M))
  end
end

"""
`union(A,B)` for multisets creates a new multiset in which the
multiplicity of `x` is `max(A[x],B[x])`.
"""
function union{S,T}(A::Multiset{S}, B::Multiset{T})
  ST = typejoin(S,T)
  M = Multiset{ST}()
  for (x,v) in A.data
    M[x] = max(v,B[x])
  end
  for (x,v) in B.data
    M[x] = max(A[x],v)
  end
  return M
end

"""
`intersect(A,B)` for multisets creates a new multiset in which the
multiplicity of `x` is `min(A[x],B[x])`.
"""
function intersect{S,T}(A::Multiset{S}, B::Multiset{T})
  ST = typejoin(S,T)
  M = Multiset{ST}()
  for (x,v) in A.data
    m = min(A[x],B[x])
    push!(M,x,m)
  end
  return M
end

function issubset(A::Multiset, B::Multiset)
  for (x,v) in A.data
    if v > B[x]
      return false
    end
  end
  return true
end

(==)(A::Multiset, B::Multiset) = (length(A)==length(B)) && issubset(A,B)

function hash(M::Multiset, h::UInt = UInt(0))
  clean!(M)
  return hash(M.data,h)
end


function Set{T}(M::Multiset{T})
  iter = (x for x in keys(M.data) if M.data[x]>0)
  return Set{T}(iter)
end

end #end of Module
