include("property.jl");
include("geometry.jl");
include("load.jl");
include("model.jl");
include("parser.jl");
push!(LOAD_PATH, ".");
begin
	local m = Material(1, 0.3, 1);
	local property = Property1D(m, 1);

	local n1 = Node(0.0, 0.0, 0.0);
	local n2 = Node(1.0, 0.0, 0.0);
	local n3 = Node(0.0, 1.0, 0.0);
	local n4 = Node(0.0, 0.0, 1.0);

	local e1 = Truss2([n1, n2], property);
	local e2 = Truss2([n1, n3], property);
	local e3 = Truss2([n1, n4], property);

	local spc = SPC();
	addConstraint(spc, X::Dof);
	addConstraint(spc, Y::Dof);
	addConstraint(spc, Z::Dof);
	addNode(spc, n2);
	addNode(spc, n3);
	addNode(spc, n4);

	local load = Load(1.0, 1.0, 1.0);
	addNode(load, n1);

	local model = Model();
	addElement(model, e1);
	addElement(model, e2);
	addElement(model, e3);
	addConstraint(model, spc);
	addLoad(model, load);
	@timev solve(model);


	local p2 = Property3D(m);
	local e = Tet4Element([n1, n2, n3, n4], p2);
	display(getStiffMatrix(e));
	println();

	println(getTriangleArea([n1, n2, n3]));
	parser = NastranParser();
	parse(parser, "A4.bdf");
end
