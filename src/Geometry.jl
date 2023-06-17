"""
module for basic shapes and 2D geometry
"""
module Geometry


export Vec2D, +, Shape, anker, Circle, distance2, radius


struct Vec2D{T<:Number}
    x::T
    y::T
end

Vector(v::Vec2D) = [v.x, v.y]

function Base.:+(v1::Vec2D, v2::Vec2D)
    Vec2D(v1.x + v2.x, v1.y + v2.y)
end

function Base.:-(v1::Vec2D, v2::Vec2D)
    Vec2D(v1.x - v2.x, v1.y - v2.y)
end

function distance2(v1::Vec2D, v2::Vec2D)
    sum((Vector(v1) - Vector(v2)) .^ 2)
end


abstract type Shape end

anker(s::Shape) = Vec2D(0, 0)


mutable struct Circle <: Shape
    radius::Number
    anker::Vec2D
end

Circle(r) = Circle(r, Vec2D(0, 0))
Circle(r, x, y) = Circle(r, Vec2D(x, y))

radius(c::Circle) = c.radius
anker(c::Circle) = c.anker


end # module geometry