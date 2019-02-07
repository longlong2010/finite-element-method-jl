using LinearAlgebra;

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
	property::Property3D;
end

mutable struct Tet10Element <: TetElement
	nodes::Array{Node};
	property::Property3D;
end

mutable struct Truss2 <: Truss
	nodes::Array{Node};
	points::Array{Array{Float64}};
	property::Property1D;
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

function getStressStrainMatrix(self::Truss)
	return self.property.M.E;
end

function getStrainMatrix(self::Truss, p)
	L = getLength(self);
	Der = getShapeDerMatrix(self, p);
	ndof = getDofNum(self);
	nnode = getNodeNum(self);
	B = Matrix{Float64}(undef, 1, ndof);
	for i = 1 : nnode
		B[1, i * 3 - 2] = Der[1, i] * 2 / L;
	end
	return B;
end

function getStiffMatrix(self::Truss)
	nnode = getNodeNum(self);
	ndof = getDofNum(self);
	Ke = Matrix{Float64}(undef, ndof, ndof);
	D = getStressStrainMatrix(self);
	A = self.property.A;
	n1 = self.nodes[1];
	n2 = last(self.nodes);
	n = Vector{Float64}([n2.x - n1.x, n2.y - n1.y, n2.z - n1.z]);
	L = norm(n);
	n = n / L;
	for p in self.points
		B = getStrainMatrix(self, p);
		Ke += B' * D * B * A * L * last(p);
	end
	T = Matrix{Float64}(undef, ndof, ndof);
	for i = 1 : nnode
		T[i * 3 - 2, i * 3 - 2 : i * 3] = n';
	end
	return T' * Ke * T;
end

function Truss2(nodes::Array{Node}, property::Property1D)
	return Truss2(nodes, [[0, 1]], property);
end

function getShapeMatrix(self::Truss2, p)
	(xi, w) = p;
	ndof = getDofNum(self);
	N = Matrix{Float64}(undef, 3, ndof);
	N[1, 1] = (1 - xi) / 2;
	N[1, 4] = (1 + xi) / 2;
	return N;
end

function getShapeDerMatrix(self::Truss2, p)
	nnode = getNodeNum(self);
	Der = Matrix{Float64}(undef, 1, nnode);
	Der[1, 1] = -0.5;
	Der[1, 2] = 0.5;
	return Der;
end
