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
	#K = Dict{Tuple{Int32, Int32}, Float64}();
	K = Matrix{Float64}(undef, ndof, ndof);
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

	R = Vector{Float64}(undef, ndof);
	for load in self.loads
		for d in instances(Dof)
			load.values[d];
		end
	end

	for constraint in self.constraints
		for d in instances(Dof)
			if haskey(constraint.values, d)
				constraint.values[d];
			end
		end
	end

end

function Model()
	return Model(Array{Node}([]), Array{Element}([]), Array{Load}([]), Array{Constraint}([]));
end
