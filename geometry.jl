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
	vals::Dict{Dof, Float64};
end

function Node(x::Float64, y::Float64, z::Float64)
	dofs = Set{Dof}([X::Dof, Y::Dof, Z::Dof]);
	vals = Dict{Dof, Float64}(X::Dof => 0.0, Y::Dof => 0.0, Z::Dof => 0.0);
	return Node(x, y, z, dofs, vals);
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
	points::Array{Array{Float64}};
	property::Property3D;
end

mutable struct Tet10Element <: TetElement
	nodes::Array{Node};
	points::Array{Array{Float64}};
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

function getStrainMatrix(self::Truss, p::Array{Float64})
	L = getLength(self);
	Der = getShapeDerMatrix(self, p);
	ndof = getDofNum(self);
	nnode = getNodeNum(self);
	B = zeros(Float64, 1, ndof);
	for i = 1 : nnode
		B[1, i * 3 - 2] = Der[1, i] * 2 / L;
	end
	return B;
end

function getStiffMatrix(self::Truss)
	nnode = getNodeNum(self);
	ndof = getDofNum(self);
	Ke = zeros(Float64, ndof, ndof);
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

function getShapeMatrix(self::Truss2, p::Array{Float64})
	(xi, w) = p;
	ndof = getDofNum(self);
	N = zeros(Float64, 3, ndof);
	N[1, 1] = (1 - xi) / 2;
	N[1, 4] = (1 + xi) / 2;
	return N;
end

function getShapeDerMatrix(self::Truss2, p::Array{Float64})
	nnode = getNodeNum(self);
	Der = zeros(Float64, 1, nnode);
	Der[1, 1] = -0.5;
	Der[1, 2] = 0.5;
	return Der;
end

function getCoord(self::Element3D)
	nnode = getNodeNum(self);
	coord = zeros(Float64, nnode, 3);
	i::Int32 = 1;
	for node in self.nodes
		coord[i, :] = Array{Float64}([node.x, node.y, node.z]);
		i += 1;
	end
	return coord;
end

function getJacobi(self::Element3D, p::Array{Float64})
	der = getShapeDerMatrix(self, p);
	coord = getCoord(self);
	return der * coord;
end

function getStrainMatrix(self::Element3D, p::Array{Float64})
	der = getShapeDerMatrix(self, p);
	J = getJacobi(self, p);
	Der = J^-1 * der;
	ndof = getDofNum(self);
	nnode = getNodeNum(self);
	B = zeros(Float64, 6, ndof);
	for i = 1 : nnode
		k = (i - 1) * 3 + 1;
		for j = 1 : 3
			B[j, (i - 1) * 3 + j] = Der[j, i];
		end
		B[4, k] = Der[2, i];
		B[4, k + 1] = Der[1, i];

		B[5, k + 1] = Der[3, i];
		B[5, k + 2] = Der[2, i];

		B[6, k] = Der[3, i];
		B[6, k + 2] = Der[1, i];
	end
	return B;
end

function getStiffMatrix(self::Element3D)
	ndof = getDofNum(self);
	Ke = zeros(Float64, ndof, ndof);
	D = getStressStrainMatrix(self);
	for p in self.points
		B = getStrainMatrix(self, p);
		J = getJacobi(self, p);
		Ke += B' * D * B * abs(det(J)) * last(p);
	end
	return Ke;
end

function getStressStrainMatrix(self::Element3D)
	D = zeros(Float64, 6, 6);
	E = self.property.M.E;
	nu = self.property.M.nu;
	D[1, 1] = 1 - nu;
	D[1, 2] = nu;
	D[1, 3] = nu;

	D[2, 1] = nu;
	D[2, 2] = 1 - nu;
	D[2, 3] = nu;

	D[3, 1] = nu;
	D[3, 2] = nu;
	D[3, 3] = 1 - nu;

	D[4, 4] = (1 - 2 * nu) / 2;
	D[5, 5] = (1 - 2 * nu) / 2;
	D[6, 6] = (1 - 2 * nu) / 2;

	D *= E / ((1 + nu) * (1 - 2 * nu));
end

function Tet4Element(nodes::Array{Node}, property::Property3D)
	return Tet4Element(nodes, [[0.25, 0.25, 0.25, 0.25, 1 / 6]], property);
end

function getTriangleArea(nodes::Array{Node})
	coord = Matrix{Float64}(undef, 3, 3);
	k::Int32 = 1;
	for node in nodes
		coord[k, :] = [node.x, node.y, node.z];
		k += 1;
	end
	A::Float64 = 0.0;
	M = ones(Float64, 3, 3);
	for i = 1 : 3
		j = i % 3 + 1;
		for k = 1 : 3
			M[1, k] = coord[k, i];
			M[2, k] = coord[k, j];
		end
		A += det(M)^2;
	end
	return 0.5 * sqrt(A);
end

function getShapeMatrix(self::Tet4Element, p::Array{Float64})
	(l1, l2, l3, l4, w) = p;
	ndof = getDofNum(self);
	nnode = getNodeNum(self);
	N = zeros(Float64, 3, ndof);
	for i = 1 : nnode
		for j = 1 : nnode
			N[j, (i - 1) * 3 + j] = p[i];
		end
	end
end

function getShapeDerMatrix(self::Tet4Element, p::Array{Float64})
	nnode = getNodeNum(self);
	der = zeros(Float64, 3, nnode);
	der[1, 1] = 1;
	der[2, 2] = 1;
	der[3, 3] = 1;
	der[1, 4] = -1;
	der[2, 4] = -1;
	der[3, 4] = -1;
	return der;
end

function Tet10Element(nodes::Array{Node}, property::Property3D)
	alpha = 0.58541020;
	beta = 0.13819660;
	return Tet10Element(nodes, [
		[alpha, beta, beta, beta, 1 / 24],
		[beta, alpha, beta, beta, 1 / 24],
		[beta, beta, alpha, beta, 1 / 24],
		[beta, beta, beta, alpha, 1 / 24]
	], property);
end

function getShapeMatrix(self::Tet10Element, p::Array{Float64})
	(l1, l2, l3, l4, w) = p;
	nnode = getNodeNum(self);
	ndof = getDofNum(self);
	Fun = zeros(Float64, nnode);
	Fun[1] = l1 * (2 * l1 - 1);
	Fun[2] = l2 * (2 * l2 - 1);
	Fun[3] = l3 * (2 * l3 - 1);
	Fun[4] = l4 * (2 * l4 - 1);
	Fun[5] = 4 * l1 * l2;
	Fun[6] = 4 * l2 * l3;
	Fun[7] = 4 * l1 * l3;
	Fun[8] = 4 * l1 * l4;
	Fun[9] = 4 * l2 * l4;
	Fun[10] = 4 * l3 * l4;
	N = zeros(Float64, 3, ndof);
	for i = 1 : nnode
		for j = 1 : 3
			N[j][(i - 1) * 3 + j] = Fun[i];
		end
	end
end

function getShapeDerMatrix(self::Tet10Element, p::Array{Float64})
	(l1, l2, l3, l4, w) = p;
	nnode = getNodeNum(self);
	Der = zeros(Float64, 3, nnode);
	for i = 1 : 3
		Der[i, i] = 4 * p[i] - 1;
		Der[i, 4] = 1 - 4 * l4;
	end

	Der[1, 5] = 4 * l2;
	Der[2, 5] = 4 * l1;

	Der[2, 6] = 4 * l3;
	Der[3, 6] = 4 * l2;

	Der[1, 7] = 4 * l3;
	Der[3, 7] = 4 * l1;

	Der[1, 8] = 4 * (l4 - l1);
	Der[2, 8] = -4 * l1;
	Der[3, 8] = -4 * l1;

	Der[1, 9] = -4 * l2;
	Der[2, 9] = 4 * (l4 - l2);
	Der[3, 9] = -4 * l2;

	Der[1, 10] = -4 * l3;
	Der[2, 10] = -4 * l3;
	Der[3, 10] = 4 * (l4 - l3);
	return Der;
end
