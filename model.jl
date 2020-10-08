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
    local ndof::Int32 = 0;
    for node in self.nodes
        ndof += getDofNum(node);
    end
    return ndof;
end

function solve(self::Model)
    local ndof = getDofNum(self);
    local R = zeros(Float64, ndof, 1);
    local idof::Int32 = 1;
    local mnode::Dict{Node, Int32} = Dict{Node, Int32}();
    for node in self.nodes
        mnode[node] = idof;
        idof += getDofNum(node);
    end

    local c = Channel();

    local N = length(self.elements);
    local n = min(N, Sys.CPU_THREADS);
    local m = div(N, n);
    local f = function (n1, n2)
        local t1 = time();
        local I = Array{Int64}([]);
        local J = Array{Int64}([]);
        local V = Array{Float64}([]);
        for k = n1 : n2
            local element = self.elements[k];
            local dofn::Int32 = 1;
            local minode::Dict{Int32, Int32} = Dict{Int32, Int32}();
            for node in element.nodes
                idof = mnode[node];
                for i = 1 : getDofNum(node)
                    minode[dofn] = idof + i - 1;
                    dofn += 1;
                end
            end
            local Ke = getStiffMatrix(element);
            local (m, n) = size(Ke);
            for i = 1 : m
                mi = minode[i];
                for j = 1 : n
                    mj = minode[j];
                    if Ke[i, j] != 0
                        push!(I, mi);
                        push!(J, mj);
                        push!(V, Ke[i, j]);
                    end
                end
            end
        end
        println(time() - t1);
        return sparse(I, J, V, ndof, ndof);
    end

    Threads.@threads for i = 1 : min(N, n)
        @async put!(c, f((i - 1) * m + 1, min(i * m, N)));
    end
    
    local I = Array{Int64}([]);
    local J = Array{Int64}([]);
    local V = Array{Float64}([]);
    local K = sparse(I, J, V, ndof, ndof);
    for i = 1 : min(N, n)
        K += take!(c);
    end

    for load in self.loads
        for node in load.nodes
            local idof = mnode[node];
            local dofn::Int32 = 1;
            for d in instances(Dof)
                local v = load.values[d];
                R[idof + dofn - 1] = v;
                dofn += 1;
            end
        end
    end

    for constraint in self.constraints
        for node in constraint.nodes
            local idof = mnode[node];
            local dofn::Int32 = 1;
            for d in instances(Dof)
                if haskey(constraint.values, d)
                    local v = constraint.values[d];
                    K[idof + dofn - 1, idof + dofn - 1] += 1e20;
                    R[idof + dofn - 1] = v * K[idof + dofn - 1, idof + dofn - 1];
                end
                dofn += 1;
            end
        end
    end
    #local K = sparse(I, J, V, ndof, ndof);
    local result = K \ R;
    #display(result);
    #println();
end

function Model()
    return Model(Array{Node}([]), Array{Element}([]), Array{Load}([]), Array{Constraint}([]));
end
