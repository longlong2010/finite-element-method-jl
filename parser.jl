import Base.parse;

mutable struct BDFCard
	name::String;
	id::Int32;
	data::Array{String};
end

mutable struct NastranParser
	Elements::Dict{Int32, BDFCard};
	Nodes::Dict{Int32, BDFCard};
	Loads::Dict{Int32, BDFCard};
	Constraints::Dict{Int32, BDFCard};
	Properties::Dict{Int32, BDFCard};
	Materials::Dict{Int32, BDFCard};
end

function NastranParser()
	return NastranParser(Dict{Int32, BDFCard}(), Dict{Int32, BDFCard}(), Dict{Int32, BDFCard}(), Dict{Int32, BDFCard}(), Dict{Int32, BDFCard}(), Dict{Int32, BDFCard}());
end

function parse(parser::NastranParser, file::String)
	data = [];
	for line in eachline(file)
		if line[1] == '$'
			continue;
		end
		row = split(line, r"\s+");
		if row[1] == ""
			append!(data, row[2:length(row)]);		
		else
			if length(data) > 0
				if data[1] == "MAT1"
					card = BDFCard(data[1], parse(Int32, String(data[2])), data[3:length(data)]);
					parser.Materials[card.id] = card;
				elseif data[1] == "GRID"
					card = BDFCard(data[1], parse(Int32, String(data[2])), data[3:length(data)]);
					parser.Nodes[card.id] = card;
				elseif data[1] == "CTETRA"
					card = BDFCard(data[1], parse(Int32, String(data[2])), data[3:length(data)]);
					parser.Elements[card.id] = card;
				elseif data[1] == "SPC1"
					card = BDFCard(data[1], parse(Int32, String(data[2])), data[3:length(data)]);
				elseif data[1] == "PLOAD4"
					card = BDFCard(data[1], parse(Int32, String(data[2])), data[3:length(data)]);
					parser.Loads[card.id] = card;
				end
			end
			data = row;
		end
	end
end
