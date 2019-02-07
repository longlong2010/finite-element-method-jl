abstract type Constraint end;

struct SPC <: Constraint
	values::Dict{Dof, Float64};
end

struct MPC <: Constraint

end

struct Load
	values::Dict{Dof, Float64};
end

function addConstraint(self::SPC, dof::Dof)
	addConstraint(self, dof, 0.0);
end

function addConstraint(self::SPC, dof::Dof, val::Float64)
	self.values[dof] = val;
end

function SPC()
	return SPC(Dict{Dof, Float64}());
end

function Load(lx::Float64, ly::Float64, lz::Float64)
	return Load(Dict{Dof, Float64}(X::Dof => lx, Y::Dof => ly, Z::Dof => lz));
end
