mutable struct Model
	nodes::Array{Node};
	elements::Array{Element};
end

function addElement(self::Model, e::Element)
	for n in e.nodes
	end
end

function getDofNum(self::Model)
	ndof::Int32 = 0;
	for node in self.nodes
		ndof += getDofNum(node);
	end
	return ndof;
end
