using SparseArrays;

mutable struct Model
	nodes::Array{Node};
	elements::Array{Element};
	loads::Array{Load};
	constraints::Array{Constraint};
end

function addElement(self::Model, e::Element)
	for node in e.nodes
		if !(node in self.nodes)
			push!(self.nodes, node);
		end
	end
	if !(e in self.elements)
		push!(self.elements, e);
	end
end

function addLoad(self::Model, l::Load)
	push!(self.loads, l);
end

function addConstraint(self::Model, c::Constraint)
	push!(self.constraints, c);
end

function getDofNum(self::Model)
	ndof::Int32 = 0;
	for node in self.nodes
		ndof += getDofNum(node);
	end
	return ndof;
end

function solve(self::Model)
	ndof = getDofNum(self);
	R = zeros(Float64, ndof, 1);
	idof::Int32 = 1;
	mnode::Dict{Node, Int32} = Dict{Node, Int32}();
	for node in self.nodes
		mnode[node] = idof;
		idof += getDofNum(node);
	end

	I = Array{Int64}([]);
	J = Array{Int64}([]);
	V = Array{Float64}([]);
	D = zeros(Float64, ndof, 1);
	for element in self.elements
		dofn::Int32 = 1;
		minode::Dict{Int32, Int32} = Dict{Int32, Int32}();
		for node in element.nodes
			idof = mnode[node];
			for i = 1 : getDofNum(node)
				minode[dofn] = idof + i - 1;
				dofn += 1;
			end
		end
		Ke = getStiffMatrix(element);
		(m, n) = size(Ke);
		for i = 1 : m
			mi = minode[i];
			for j = 1 : n
				mj = minode[j];
				if Ke[i, j] != 0
					push!(I, mi);
					push!(J, mj);
					push!(V, Ke[i, j]);
					if i == j
						D[i] += Ke[i, j];
					end
				end
			end
		end
	end

	for load in self.loads
		for node in load.nodes
			idof = mnode[node];
			dofn::Int32 = 1;
			for d in instances(Dof)
				v = load.values[d];
				R[idof + dofn - 1] = v;
				dofn += 1;
			end
		end
	end

	for constraint in self.constraints
		for node in constraint.nodes
			idof = mnode[node];
			dofn::Int32 = 1;
			for d in instances(Dof)
				if haskey(constraint.values, d)
					v = constraint.values[d];
					push!(I, idof + dofn - 1);
					push!(J, idof + dofn - 1);
					push!(V, 1e20);
					D[idof + dofn - 1] += 1e20;
					R[idof + dofn - 1] = v * D[idof + dofn - 1];
				end
				dofn += 1;
			end
		end
	end
	local K = sparse(I, J, V, ndof, ndof);

	local result = K \ R;
	#display(result);
	#println();
end

function Model()
	return Model(Array{Node}([]), Array{Element}([]), Array{Load}([]), Array{Constraint}([]));
end
