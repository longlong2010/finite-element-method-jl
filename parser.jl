import Base.parse;

mutable struct NastranParser
end

function parse(self::NastranParser, file::String)
	data = [];
	bdf = Dict();
	for line in eachline(file)
		if line[1] == '$'
			continue;
		end
		local len = length(line);
		local n = len ÷ 8 + 1;
		local row = [];
		if n <= 1
			continue;
		end
		for i = 1 : n
			push!(row, String(strip(line[(i - 1) * 8 + 1 : min(i * 8, len)])));
		end

		if row[1] == ""
			append!(data, row[2:length(row)]);
		else
			if length(data) > 0
				id = parse(Int32, String(data[2]));
				name = String(data[1]);
				if name == "SPC1" || name == "PLOAD4"
					if !haskey(bdf, name)
						bdf[name] = [];
					end
					push!(bdf[name], data);
				else 
					if !haskey(bdf, name)
						bdf[name] = Dict();	
					end
					bdf[name][id] = data;
				end
			end
			data = row;
		end
	end

	materials = Dict{Int32, Material}();
	for (id, card) in bdf["MAT1"]
		local E = parse(Float64, card[3]);
		local mu = parse(Float64, card[5]);
		local rho = parse(Float64, replace(card[6], "-" => "e-"));
		materials[id] = Material(E, mu, rho);
	end
	properties = Dict{Int32, Property3D}();
	for (id, card) in bdf["PSOLID"]
		local mid = parse(Int32, card[3]);
		material = materials[mid];
		property = Property3D(material);
		properties[id] = property;
	end
	nodes = Dict{Int32, Node}();
	for (id, card) in bdf["GRID"]
		local x = parse(Float64, card[4]);
		local y = parse(Float64, card[5]);
		local z = parse(Float64, card[6]);
		node = Node(x, y ,z);
		nodes[id] = node;
	end
	model = Model();
	elements = Dict{Int32, Element}();
	for (id, card) in bdf["CTETRA"]
		local _nodes::Array{Node} = [];
		for i = 4 : 13
			local nid = parse(Int32, card[i]);
			node = nodes[nid];
			push!(_nodes, node);
		end
		local pid = parse(Int32, card[3])
		property = properties[pid];
		element = Tet10Element(_nodes, property);
		elements[id] = element;
		addElement(model, element);
	end
	for card in bdf["SPC1"]
		local spc = SPC();
		local dof = card[3];
		for j = 1 : length(dof)
			if dof[j] == '1'
				addConstraint(spc, X::Dof);
			elseif dof[j] == '2'
				addConstraint(spc, Y::Dof);
			elseif  dof[j] == '3'
				addConstraint(spc, Z::Dof);
			end
		end
		if card[5] == "THRU"
			local m = parse(Int32, card[4]);
			local n = parse(Int32, card[6]);
			for i = m : n
				node = nodes[i];
				addNode(spc, node);
			end
		else
			for i = 4 : length(card)
				local nid = parse(Int32, card[i]);
				node = nodes[nid];
				addNode(spc, node);
			end
		end
		addConstraint(model, spc)
	end
	for card in bdf["PLOAD4"]
		local eid = parse(Int32, card[3]);
		local p = parse(Float64, card[4]);
		local g1 = parse(Int32, card[8]);
		local g34 = parse(Int32, card[9]);

		n1 = nodes[g1];
		n2 = nodes[g34];

		local vx = parse(Float64, card[11]);
		local vy = parse(Float64, card[12]);
		local vz = parse(Float64, card[13]);

	end
	return model;
end