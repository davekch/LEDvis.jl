module Geometry


export x, y, Shape, Circle, Rect, Glow, distance2
export anker, setanker!, radius, setradius!, transparency, settransparency!, inner
export width, setwidth!, height, setheight!, angle, setangle!, edges

import LinearAlgebra: inv

x(v::Vector) = v[1]
y(v::Vector) = v[2]

distance2(v1::Vector, v2::Vector) = sum((v1 - v2) .^ 2)

"""
    rotate(point, angle)

rotate `point` by `angle`
"""
function rotate(point::Vector, a::Number)
    [cos(a) -sin(a); sin(a) cos(a)] * point
end

"""
    *(point, angle, origin)

rotate `point` around `origin` by `angle`
"""
function rotate(point, a, origin)
    point = [point..., 1]
    # translation
    T = [1 0 origin[1]; 0 1 origin[2]; 0 0 1]
    R = [cos(a) -sin(a) 0; sin(a) cos(a) 0; 0 0 1]
    point = T * R * inv(T) * point
    return point[1:2]
end

"""
    *(angle, origin)

get a function that will rotate a point around `origin` by `angle`
"""
rotate(a::Number, origin::Vector) = point -> rotate(point, a, origin)


abstract type Shape end

anker(s::Shape) = s.anker
setanker!(s::Shape, anker) = (s.anker = anker)
transparency(s::Shape) = s.transparency
settransparency!(s::Shape, t) = (s.transparency = t)

"""
    Circle(radius, anker::Vector, transparency=1.0)
"""
@kwdef mutable struct Circle <: Shape
    radius::Number
    anker::Vector
    transparency::Float64 = 1.0
end

"""
    *(radius, anker::Vector)
"""
Circle(r, anker::Vector) = Circle(radius=r, anker=anker)
"""
    *(radius, x, y)
"""
Circle(r::Number, x::Number, y::Number) = Circle(r, [x, y])

radius(c::Circle) = c.radius
setradius!(c::Circle, r) = (c.radius = r)

"""
    Rect(angle, width, height, anker::Vector, transparency=1.0)
"""
@kwdef mutable struct Rect <: Shape
    angle::Number
    width::Number
    height::Number
    anker::Vector
    transparency::Float64 = 1.0
end

"""
    *(width, height, x, y)
"""
Rect(w::Number, h::Number, x::Number, y::Number) = Rect(angle=0, width=w, height=h, anker=[x, y])
Rect(w::Number, h::Number, p::Vector) = Rect(angle=0, width=w, height=h, anker=p)

angle(r::Rect) = r.angle
setangle!(r::Rect, a) = (r.angle = a)
width(r::Rect) = r.width
setwidth!(r::Rect, w) = (r.width = w)
height(r::Rect) = r.height
setheight!(r::Rect, h) = (r.height = h)

"""
    edges(rect::Rect)

get the points of the edges of `rect`
"""
function edges(rect::Rect)
    a = anker(rect)
    w2 = width(rect) / 2
    h2 = height(rect) / 2
    # angle = 0
    p1 = a + [-w2, -h2]
    p2 = a + [+w2, -h2]
    p3 = a + [+w2, +h2]
    p4 = a + [-w2, +h2]
    map(rotate(angle(rect), a), [p1, p2, p3, p4])
end


@kwdef mutable struct Glow <: Shape
    inner::Shape
    t::Number
    transparency::Float64 = 1.0
end

Glow(inner::Shape, t::Number) = Glow(inner=inner, t=t)

inner(g::Glow) = g.inner
anker(g::Glow) = anker(g.inner)
setanker!(g::Glow, anker) = setanker!(g.inner, anker)
angle(g::Glow) = angle(g.inner)
setangle!(g::Glow, a) = setangle!(g.inner, a)
radius(g::Glow) = radius(g.inner)
setradius!(g::Glow, r) = setradius!(g.inner, r)

end # module geometry

