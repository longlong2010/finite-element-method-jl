module Geometry

@enum Dof begin
	X
	Y
	Z
end

struct Node
	x::Float64;
	y::Float64;
	z::Float64;
	dofs::Set{Dof};
end

function Node(x::Float64, y::Float64, z::Float64)
	dofs = Set{Dof}([X::Dof, Y::Dof, Z::Dof]);
	return Node(x, y, z, dofs);
end

function getDofNum(self::Node)
	return length(self.dofs);
end

abstract type Element end;
abstract type Element1D <: Element end;
abstract type Element3D <: Element end;
abstract type Truss <: Element1D end;
abstract type TetElement <: Element3D end;

mutable struct Tet4Element <: TetElement
	nodes::Array{Node};
end

mutable struct Tet10Element <: TetElement
	nodes::Array{Node};
end

mutable struct Truss2 <: Truss
	nodes::Array{Node};
end

function getNodeNum(self::Element)
	length(self.nodes);
end

function getDofNum(self::Element)
	ndof::Int32 = 0;
	for node in self.nodes
		ndof += getDofNum(node);
	end
	return ndof;
end

function getLength(self::Element1D)
	n1 = self.nodes[1];
	n2 = last(self.nodes);
	return sqrt((n1.x - n2.x)^2 + (n1.y - n2.y)^2 + (n1.z - n2.z)^2);
end

end
