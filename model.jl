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
	K = zeros(Float64, ndof, ndof);
	R = zeros(Float64, ndof, 1);
	k::Int32 = 0;
	for element in self.elements
		l::Int32 = 1;
		m::Dict{Int32, Int32} = Dict{Int32, Int32}();
		for node in element.nodes
			k = (findfirst(isequal(node), self.nodes) - 1) * getDofNum(node);
			for i = 1 : getDofNum(node)
				m[l] = k + i;
				l += 1;
			end
		end
		Ke = getStiffMatrix(element);
		(n, ) = size(Ke);
		for i = 1 : n
			mi = m[i];
			for j = 1 : n
				mj = m[j];
				#if haskey(K, (mi, mj))
				#	K[(mi, mj)] += Ke[i, j];
				#else
				#	K[(mi, mj)] = Ke[i, j];
				#end
				K[mi, mj] += Ke[i, j];
			end
		end
	end

	for load in self.loads
		for node in load.nodes
			k = (findfirst(isequal(node), self.nodes) - 1) * getDofNum(node);
			dofn::Int32 = 1;
			for d in instances(Dof)
				v = load.values[d];
				R[k + dofn] = v;
				dofn += 1;
			end
		end
	end

	for constraint in self.constraints
		for node in constraint.nodes
			k = (findfirst(isequal(node), self.nodes) - 1) * getDofNum(node);
			dofn::Int32 = 1;
			for d in instances(Dof)
				if haskey(constraint.values, d)
					v = constraint.values[d];
					K[k + dofn, k + dofn] += 1e20;
					R[k + dofn] = v * K[k + dofn, k + dofn];
				end
				dofn += 1;
			end
		end
	end
	display(K \ R);
	println();
end

function Model()
	return Model(Array{Node}([]), Array{Element}([]), Array{Load}([]), Array{Constraint}([]));
end
