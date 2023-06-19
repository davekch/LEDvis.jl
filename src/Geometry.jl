module Geometry


export x, y, Shape, Circle, Rect, distance2
export anker, setanker!, radius, setradius!
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

anker(s::Shape) = [0, 0]

"""
    Circle(radius, anker::Vector)
"""
mutable struct Circle <: Shape
    radius::Number
    anker::Vector
end

"""
    *(radius)
"""
Circle(r) = Circle(r, [0, 0])
"""
    *(radius, x, y)
"""
Circle(r, x, y) = Circle(r, [x, y])

radius(c::Circle) = c.radius
anker(c::Circle) = c.anker
setradius!(c::Circle, r) = (c.radius = r)
setanker!(c::Circle, anker) = (c.anker = anker)

"""
    Rect(angle, width, height, anker::Vector)
"""
mutable struct Rect <: Shape
    angle::Number
    width::Number
    height::Number
    anker::Vector
end

"""
    *(width, height, x, y)
"""
Rect(w::Number, h::Number, x::Number, y::Number) = Rect(0, w, h, [x, y])
Rect(w::Number, h::Number, p::Vector) = Rect(0, w, h, p)

anker(r::Rect) = r.anker
setanker!(r::Rect, anker) = (r.anker = anker)
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

end # module geometry