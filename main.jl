
include("property.jl");
include("geometry.jl");
include("load.jl");
include("model.jl");

push!(LOAD_PATH, ".");

m = Material(1, 1, 1);
property = Property1D(m, 1);

n1 = Node(0.0, 0.0, 0.0);
n2 = Node(1.0, 1.0, 0.0);

e = Truss2([n1, n2], property);
display(getStiffMatrix(e));
print("\n");
