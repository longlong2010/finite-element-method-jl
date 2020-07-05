import Base.parse;

mutable struct BDFCard
	name::String;
	id::Int32;
	data::Array{String};
end

mutable struct NastranParser
	elements::Dict{Int32, BDFCard};
	nodes::Dict{Int32, BDFCard};
	loads::Dict{Int32, BDFCard};
	constraints::Dict{Int32, BDFCard};
	properties::Dict{Int32, BDFCard};
	materials::Dict{Int32, BDFCard};
end

function NastranParser()
	return NastranParser(Dict{Int32, BDFCard}(), Dict{Int32, BDFCard}(), Dict{Int32, BDFCard}(), Dict{Int32, BDFCard}(), Dict{Int32, BDFCard}(), Dict{Int32, BDFCard}());
end

function parse(self::NastranParser, file::String)
	data = [];
	for line in eachline(file)
		local len = length(line);
		if len < 8
			continue;
		end
		local n = len ÷ 8 + 1;
		local row = [];
		for i = 1 : n - 1
			push!(row, String(strip(line[(i - 1) * 8 + 1 : i * 8])));
		end
		push!(row, String(strip(line[(n - 1) * 8 + 1 : len])));
		if row[1] == ""
			append!(data, row[2:length(row)]);
		else
			if length(data) > 0
				if data[1] == "MAT1"
					card = BDFCard(data[1], parse(Int32, String(data[2])), data[3:length(data)]);
					self.materials[card.id] = card;
				elseif data[1] == "PSOLID"
					card = BDFCard(data[1], parse(Int32, String(data[2])), data[3:length(data)]);
					self.properties[card.id] = card;
				elseif data[1] == "GRID"
					card = BDFCard(data[1], parse(Int32, String(data[2])), data[4:length(data)]);
					self.nodes[card.id] = card;
				elseif data[1] == "CTETRA"
					card = BDFCard(data[1], parse(Int32, String(data[2])), data[3:length(data)]);
					self.elements[card.id] = card;
				elseif data[1] == "SPC1"
					card = BDFCard(data[1], parse(Int32, String(data[2])), data[3:length(data)]);
					self.constraints[card.id] = card;
				elseif data[1] == "PLOAD4"
					card = BDFCard(data[1], parse(Int32, String(data[2])), data[3:length(data)]);
					self.loads[card.id] = card;
				end
			end
			data = row;
		end
	end
	materials = Dict{Int32, Material}();
	for (id, card) in self.materials
		if card.name == "MAT1"
			local E = parse(Float64, card.data[1]);
			local mu = parse(Float64, card.data[3]);
			local rho = parse(Float64, replace(card.data[4], "-" => "e-"));
			materials[id] = Material(E, mu, rho);
		end
	end
	nodes = Dict{Int32, Node}();
	for (id, card) in self.nodes
		local x = parse(Float64, card.data[1]);
		local y = parse(Float64, card.data[2]);
		local z = parse(Float64, card.data[3]);
		node = Node(x, y ,z);
		nodes[id] = node;
	end
	for (id, card) in self.elements
		if card.name == "CTETRA"
			for i = 2 : 11
				id = parse(Int32, card.data[i]);
			end
		end
	end
end
