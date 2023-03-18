class S7_GM_Variable {
	private uint id;

	static S7_GM_Variable internalCreate(uint curId) {
		let ret = new();
		ret.id = curId;
		return ret;
	}

	uint getId() { return self.id; }
}
class S7_GM_VariableHasher : S7_GM_Hasher {
	override uint hash(Object o) { return S7_GM_Variable(o).getId(); }
	override bool eq(Object o0, Object o1) {
		return S7_GM_Variable(o0).getId() == S7_GM_Variable(o1).getId();
	}
}

struct S7_GM_VariableManager {
	private uint curId;

	S7_GM_Variable createVariable() {
		let ret = S7_GM_Variable.internalCreate(self.curId);
		self.curId += 1;
		return ret;
	}
}

class S7_GM_Term {
	S7_GM_Variable variable;
	double coefficient;

	static S7_GM_Term create(S7_GM_Variable variable, double coefficient) {
		let ret = new();
		ret.variable = variable;
		ret.coefficient = coefficient;
		return ret;
	}
}

class S7_GM_Expr {
	Array<S7_GM_Term> terms;
	double constant;

	static S7_GM_Expr fromConstant(double v) {
		let ret = new();
		ret.constant = v;
		return ret;
	}
	static S7_GM_Expr c(double v) { return S7_GM_Expr.fromConstant(v); }

	static S7_GM_Expr fromTerm(S7_GM_Term term) {
		let ret = new();
		ret.terms.push(term);
		return ret;
	}

	static S7_GM_Expr fromVariable(S7_GM_Variable variable) {
		let ret = new();
		ret.terms.push(S7_GM_Term.create(variable, 1.0));
		return ret;
	}
	static S7_GM_Expr v(S7_GM_Variable variable) { return S7_GM_Expr.fromVariable(variable); }

	static S7_GM_Expr create() {
		let ret = new();
		return ret;
	}

	void negate() {
		self.constant = -self.constant;
		for (let i = 0u; i < self.terms.size(); i++) {
			let t = self.terms[i];
			t.coefficient = -t.coefficient;
		}
	}

	S7_GM_Expr addAssignVariable(S7_GM_Variable variable, double coefficient = 1.0) {
		self.terms.push(S7_GM_Term.create(variable, coefficient));
		return self;
	}
	S7_GM_Expr addAssignConstant(double constant) {
		self.constant += constant;
		return self;
	}
	S7_GM_Expr addAssignExpression(S7_GM_Expr e) {
		for (let i = 0u; i < e.terms.size(); i++) {
			self.terms.push(e.terms[i]);
		}
		self.constant += e.constant;
		return self;
	}
	S7_GM_Expr mulAssign(double coeff) {
		for (let i = 0u; i < self.terms.size(); i++) {
			self.terms[i].coefficient *= coeff;
		}
		self.constant *= coeff;
		return self;
	}
}

struct S7_GM_Strength {
	static double create(double a, double b, double c, double w) {
		return
			clamp(a * w, 0.0, 1000.0) * 1000000.0 +
			clamp(b * w, 0.0, 1000.0) * 1000.0 +
			clamp(c * w, 0.0, 1000.0);
	}

	const REQUIRED = 1001001000.0;
	const STRONG = 1000000.0;
	const MEDIUM = 1000.0;
	const WEAK = 1.0;

	static double clip(double s) {
		return clamp(s, 0.0, REQUIRED);
	}
}

enum S7_GM_Rel {
	S7_GM_Rel_LEq,
	S7_GM_Rel_Eq,
	S7_GM_Rel_GEq,
}

struct S7_GM_ConstraintManager {
	private uint curId;

	S7_GM_Constraint createConstraint(S7_GM_Expr e, S7_GM_Rel op, double strength) {
		let ret = S7_GM_Constraint.internalCreate(e, op, strength, self.curId);
		self.curId += 1;
		return ret;
	}
}

class S7_GM_Constraint {
	private S7_GM_Expr expression;
	private double strength;
	private S7_GM_Rel op;
	private uint id;

	static S7_GM_Constraint internalCreate(S7_GM_Expr e, S7_GM_Rel op, double strength, uint curId) {
		let ret = new();
		ret.expression = e;
		ret.op = op;
		ret.strength = strength;
		ret.id = curId;
		return ret;
	}

	S7_GM_Expr getExpr() { return self.expression; }
	S7_GM_Rel getOp() { return self.op; }
	double getStrength() { return self.strength; }
	uint getId() { return self.id; }
}
class S7_GM_ConstraintHasher : S7_GM_Hasher {
	override uint hash(Object o) { return S7_GM_Constraint(o).getId(); }
	override bool eq(Object o0, Object o1) {
		return S7_GM_Constraint(o0).getId() == S7_GM_Constraint(o1).getId();
	}
}

class S7_GM_ConstraintBuilderWithRhs {
	S7_GM_Expr lhs;
	S7_GM_Expr rhs;
	S7_GM_Rel rel;
	double strength;
}

enum S7_GM_SymbolKind {
	S7_GM_SymbolKind_Invalid,
	S7_GM_SymbolKind_External,
	S7_GM_SymbolKind_Slack,
	S7_GM_SymbolKind_Error,
	S7_GM_SymbolKind_Dummy,
}

class S7_GM_Symbol {
	uint id;
	S7_GM_SymbolKind kind;

	static S7_GM_Symbol invalid() {
		let ret = new();
		ret.id = 0;
		ret.kind = S7_GM_SymbolKind_Invalid;
		return ret;
	}

	static S7_GM_Symbol create(uint id, S7_GM_SymbolKind kind) {
		let ret = new();
		ret.id = id;
		ret.kind = kind;
		return ret;
	}

	S7_GM_Symbol clone() {
		let ret = new();
		ret.id = self.id;
		ret.kind = self.kind;
		return ret;
	}

	String repr() {
		let ret = "Symbol(";
		ret.appendFormat("%d, ", self.id);
		switch (self.kind) {
			case S7_GM_SymbolKind_Invalid:  ret.appendFormat("Invalid"); break;
			case S7_GM_SymbolKind_External: ret.appendFormat("External"); break;
			case S7_GM_SymbolKind_Slack:    ret.appendFormat("Slack"); break;
			case S7_GM_SymbolKind_Error:    ret.appendFormat("Error"); break;
			case S7_GM_SymbolKind_Dummy:    ret.appendFormat("Dummy"); break;
		}
		ret.appendFormat(")");
		return ret;
	}
}

class S7_GM_SymbolHasher : S7_GM_Hasher {
	override uint hash(Object o) {
		let o = S7_GM_Symbol(o);
		let seed = o.id;
		hashCombine(seed, o.kind);
		return seed;
	}
	override bool eq(Object o0, Object o1) {
		let o0 = S7_GM_Symbol(o0);
		let o1 = S7_GM_Symbol(o1);

		return
			o0.id == o1.id &&
			o0.kind == o1.kind;
	}
}

class S7_GM_Row {
	S7_GM_HashMap/*<Symbol, BoxedDouble>*/ cells;
	double constant;

	static S7_GM_Row create(double constant) {
		let ret = new();
		ret.cells = S7_GM_HashMap.create(new("S7_GM_SymbolHasher"));
		ret.constant = constant;
		return ret;
	}

	S7_GM_Row clone() {
		let ret = new();
		ret.cells = S7_GM_HashMap.create(new("S7_GM_SymbolHasher"));
		let iter = self.cells.iter();
		while (true) {
			Object ko, vo;
			[ko, vo] = iter.next();
			if (ko is "S7_GM_HashUnoccupied") { break; }

			let k = S7_GM_Symbol(ko);
			let v = S7_GM_BoxedDouble(vo);

			ret.cells.insert(k.clone(), v.clone());
		}
		ret.constant = self.constant;
		return ret;
	}

	double add(double v) {
		self.constant += v;
		return self.constant;
	}

	void insertSymbol(S7_GM_Symbol s, double coefficient) {
		let g = self.cells.get(s);
		if (g is "S7_GM_HashUnoccupied") {
			if (!S7_GM_GlobalMaths.nearZero(coefficient)) {
				self.cells.insert(s, S7_GM_BoxedDouble.create(coefficient));
			}
		} else {
			let g = S7_GM_BoxedDouble(g);
			g.val += coefficient;
			if (S7_GM_GlobalMaths.nearZero(g.val)) {
				self.cells.remove(s);
			}
		}
	}

	bool insertRow(S7_GM_Row other, double coefficient) {
		let constantDiff = other.constant * coefficient;
		self.constant += constantDiff;
		let iter = other.cells.iter();
		while (true) {
			Object ko, vo;
			[ko, vo] = iter.next();
			if (ko is "S7_GM_HashUnoccupied") { break; }

			let s = S7_GM_Symbol(ko);
			let v = S7_GM_BoxedDouble(vo).val;

			self.insertSymbol(s, v * coefficient);
		}
		return constantDiff != 0.0;
	}

	void remove(S7_GM_Symbol s) {
		self.cells.remove(s);
	}

	void reverseSign() {
		self.constant = -self.constant;
		let iter = self.cells.iter();
		while (true) {
			Object ko, vo;
			[ko, vo] = iter.next();
			if (ko is "S7_GM_HashUnoccupied") { break; }
			let v = S7_GM_BoxedDouble(vo);
			v.val = -v.val;
		}
	}

	void solveForSymbol(S7_GM_Symbol s) {
		let e = S7_GM_BoxedDouble(self.cells.remove(s)).val;
		let coeff = -1.0 / e;
		self.constant *= coeff;
		let iter = self.cells.iter();
		while (true) {
			Object ko, vo;
			[ko, vo] = iter.next();
			if (ko is "S7_GM_HashUnoccupied") { break; }
			let v = S7_GM_BoxedDouble(vo);
			v.val *= coeff;
		}
	}

	void solveForSymbols(S7_GM_Symbol lhs, S7_GM_Symbol rhs) {
		self.insertSymbol(lhs, -1.0);
		self.solveForSymbol(rhs);
	}

	double coefficientFor(S7_GM_Symbol s) {
		let v = self.cells.get(s);
		return (!(v is "S7_GM_HashUnoccupied")) ? S7_GM_BoxedDouble(v).val : 0.0;
	}

	bool substitute(S7_GM_Symbol s, S7_GM_Row row) {
		let e = self.cells.remove(s);
		if (!(e is "S7_GM_HashUnoccupied")) {
			let coeff = S7_GM_BoxedDouble(e).val;
			return self.insertRow(row, coeff);
		} else {
			return false;
		}
	}
}

enum S7_GM_AddConstraintError {
	S7_GM_AddConstraintError_None,
	S7_GM_AddConstraintError_DuplicateConstraint,
	S7_GM_AddConstraintError_UnsatisfiableConstraint,
}

enum S7_GM_RemoveConstraintError {
	S7_GM_RemoveConstraintError_None,
	S7_GM_RemoveConstraintError_UnknownConstraint,
}

enum S7_GM_AddEditVariableError {
	S7_GM_AddEditVariableError_None,
	S7_GM_AddEditVariableError_DuplicateEditVariable,
	S7_GM_AddEditVariableError_BadRequiredStrength,
}

enum S7_GM_RemoveEditVariableError {
	S7_GM_RemoveEditVariableError_None,
	S7_GM_RemoveEditVariableError_UnknownEditVariable,
}

enum S7_GM_SuggestValueError {
	S7_GM_SuggestValueError_None,
	S7_GM_SuggestValueError_UnknownEditVariable,
}

class S7_GM_Tag {
	S7_GM_Symbol marker;
	S7_GM_Symbol other;

	static S7_GM_Tag create(S7_GM_Symbol marker = NULL, S7_GM_Symbol other = NULL) {
		let ret = new();
		ret.marker = marker;
		ret.other = other;
		return ret;
	}
}

class S7_GM_EditInfo {
	S7_GM_Tag tag;
	S7_GM_Constraint constraint;
	double constant;

	static S7_GM_EditInfo create(S7_GM_Tag tag, S7_GM_Constraint constraint, double constant) {
		let ret = new();
		ret.tag = tag;
		ret.constraint = constraint;
		ret.constant = constant;
		return ret;
	}
}

class S7_GM_VarDataEntry {
	double value;
	S7_GM_Symbol symbol;
	uint count;

	static S7_GM_VarDataEntry create(double value, S7_GM_Symbol symbol, uint count) {
		let ret = new();
		ret.value = value;
		ret.symbol = symbol;
		ret.count = count;
		return ret;
	}
}

class S7_GM_PublicChangesEntry {
	S7_GM_Variable variable;
	double value;

	static S7_GM_PublicChangesEntry create(S7_GM_Variable variable, double value) {
		let ret = new();
		ret.variable = variable;
		ret.value = value;
		return ret;
	}
}

class S7_GM_Solver {
	private S7_GM_HashMap/*<Constraint, Tag>*/ cns;
	private S7_GM_HashMap/*<Variable, VarDataEntry>*/ varData;
	private S7_GM_HashMap/*<Symbol, Variable>*/ varForSymbol;
	private Array<S7_GM_PublicChangesEntry> publicChanges;
	private S7_GM_HashSet/*<Variable>*/ changed;
	private bool shouldClearChanges;
	private S7_GM_HashMap/*<Symbol, Row>*/ rows;
	private S7_GM_HashMap/*<Variable, EditInfo>*/ edits;
	private Array<S7_GM_Symbol> infeasibleRows;
	private S7_GM_Row objective;
	private /* Nullable */ S7_GM_Row artificial;
	private uint idTick;

	private S7_GM_VariableManager variableManager;
	private S7_GM_ConstraintManager constraintManager;

	static S7_GM_Solver create() {
		let constraintHasher = new("S7_GM_ConstraintHasher");
		let variableHasher = new("S7_GM_VariableHasher");
		let symbolHasher = new("S7_GM_SymbolHasher");

		let ret = new();
		ret.cns = S7_GM_HashMap.create(constraintHasher);
		ret.varData = S7_GM_HashMap.create(variableHasher);
		ret.varForSymbol = S7_GM_HashMap.create(symbolHasher);
		/* ret.publicChanges = default; */
		ret.changed = S7_GM_HashSet.create(variableHasher);
		ret.shouldClearChanges = false;
		ret.rows = S7_GM_HashMap.create(symbolHasher);
		ret.edits = S7_GM_HashMap.create(variableHasher);
		/* ret.infeasibleRows = default; */
		ret.objective = S7_GM_Row.create(0.0);
		ret.artificial = NULL;
		ret.idTick = 1;

		return ret;
	}

	S7_GM_Variable createVariable() {
		return self.variableManager.createVariable();
	}

	S7_GM_AddConstraintError, S7_GM_Constraint addConstraintFromRelation(
		S7_GM_Expr lhs,
		Name op,
		S7_GM_Expr rhs,
		double strength = S7_GM_Strength.REQUIRED
	) {
		rhs.negate();
		lhs.addAssignExpression(rhs);
		if (op != '==' && op != '<=' && op != '>=') {
			throwAbortException("invalid op string '%s'", op);
		}
		let op = (op == '==') ? S7_GM_Rel_Eq : (op == '<=') ? S7_GM_Rel_Leq : S7_GM_Rel_Geq;
		let constraint = self.constraintManager.createConstraint(lhs, op, strength);
		return self.addConstraint(constraint), constraint;
	}

	S7_GM_AddConstraintError addConstraint(S7_GM_Constraint constraint) {
		if (self.cns.containsKey(constraint)) {
			return S7_GM_AddConstraintError_DuplicateConstraint;
		}

		S7_GM_Row row; S7_GM_Tag tag;
		[row, tag] = self.createRow(constraint);
		let subject = chooseSubject(row, tag);

		if (subject.kind == S7_GM_SymbolKind_Invalid && allDummies(row)) {
			if (!S7_GM_GlobalMaths.nearZero(row.constant)) {
				return S7_GM_AddConstraintError_UnsatisfiableConstraint;
			} else {
				subject = tag.marker;
			}
		}
		if (subject.kind == S7_GM_SymbolKind_Invalid) {
			if (!self.addWithArtificialVariable(row)) {
				return S7_GM_AddConstraintError_UnsatisfiableConstraint;
			}
		} else {
			row.solveForSymbol(subject);
			self.substitute(subject, row);

			if (subject.kind == S7_GM_SymbolKind_External && row.constant != 0.0) {
				let v = S7_GM_Variable(self.varForSymbol.get(subject));
				self.varChanged(v);
			}
			self.rows.insert(subject, row);
		}

		self.cns.insert(constraint, tag);

		let objective = self.objective;
		self.optimise(objective);

		return S7_GM_AddConstraintError_None;
	}

	S7_GM_RemoveConstraintError removeConstraint(S7_GM_Constraint constraint) {
		let t = self.cns.remove(constraint);
		if (t is "S7_GM_HashUnoccupied") {
			return S7_GM_RemoveConstraintError_UnknownConstraint;
		}
		let tag = S7_GM_Tag(t);

		self.removeConstraintEffects(constraint, tag);

		if (self.rows.remove(tag.marker) is "S7_GM_HashUnoccupied") {
			S7_GM_Symbol leaving; S7_GM_Row row;
			[leaving, row] = self.getMarkerLeavingRow(tag.marker);
			row.solveForSymbols(leaving, tag.marker);
			self.substitute(tag.marker, row);
		}

		let objective = self.objective;
		self.optimise(objective);

		let cexpr = constraint.getExpr();
		for (let i = 0u; i < cexpr.terms.size(); i++) {
			let term = cexpr.terms[i];
			if (!S7_GM_GlobalMaths.nearZero(term.coefficient)) {
				let shouldRemove = false;
				let v = self.varData.get(term.variable);
				if (!(v is "S7_GM_HashUnoccupied")) {
					let v = S7_GM_VarDataEntry(v);
					v.count -= 1;
					shouldRemove = v.count == 0;
				}
				if (shouldRemove) {
					self.varForSymbol.remove(S7_GM_VarDataEntry(self.varData.get(term.variable)).symbol);
					self.varData.remove(term.variable);
				}
			}
		}

		return S7_GM_RemoveConstraintError_None;
	}

	bool hasConstraint(S7_GM_Constraint constraint) {
		return self.cns.containsKey(constraint);
	}

	S7_GM_AddEditVariableError addEditVariable(S7_GM_Variable v, double strength) {
		if (self.edits.containsKey(v)) {
			return S7_GM_AddEditVariableError_DuplicateEditVariable;
		}
		let strength = S7_GM_Strength.clip(strength);
		if (strength == S7_GM_Strength.REQUIRED) {
			return S7_GM_AddEditVariableError_BadRequiredStrength;
		}
		let cn = self.constraintManager.createConstraint(
			S7_GM_Expr.fromTerm(S7_GM_Term.create(v, 1.0)),
			S7_GM_Rel_Eq,
			strength
		);
		{
			let err = self.addConstraint(cn);
			if (err != 0) { throwAbortException("shouldn't happen"); }
		}
		self.edits.insert(
			v,
			S7_GM_EditInfo.create(
				S7_GM_Tag(self.cns.get(cn)),
				cn,
				0.0
			)
		);

		return S7_GM_AddEditVariableError_None;
	}

	S7_GM_RemoveEditVariableError removeEditVariable(S7_GM_Variable v) {
		let e = self.edits.remove(v);
		if (!(e is "S7_GM_HashUnoccupied")) {
			let constraint = S7_GM_EditInfo(e).constraint;
			let err = self.removeConstraint(constraint);
			if (err == S7_GM_RemoveConstraintError_UnknownConstraint) {
				throwAbortException("Edit constraint not in system.");
			}
			return S7_GM_RemoveEditVariableError_None;
		} else {
			return S7_GM_RemoveEditVariableError_UnknownEditVariable;
		}
	}

	bool hasEditVariable(S7_GM_Variable v) {
		return self.edits.containsKey(v);
	}

	S7_GM_SuggestValueError suggestValue(S7_GM_Variable variable, double value) {
		let i = self.edits.get(variable);
		if (i is "S7_GM_HashUnoccupied") {
			return S7_GM_SuggestValueError_UnknownEditVariable;
		}
		let info = S7_GM_EditInfo(i);
		let infoTagMarker = info.tag.marker;
		let infoTagOther = info.tag.other;
		let delta = value - info.constant;
		info.constant = value;

		{
			let rm = self.rows.get(infoTagMarker);
			let ro = self.rows.get(infoTagOther);
			if (!(rm is "S7_GM_HashUnoccupied")) {
				let row = S7_GM_Row(rm);
				if (row.add(-delta) < 0.0) {
					infeasibleRows.push(infoTagMarker);
				}
			} else if (!(ro is "S7_GM_HashUnoccupied")) {
				let row = S7_GM_Row(ro);
				if (row.add(delta) < 0.0) {
					infeasibleRows.push(infoTagOther);
				}
			} else {
				let iter = self.rows.iter();
				while (true) {
					Object ko, vo;
					[ko, vo] = iter.next();
					if (ko is "S7_GM_HashUnoccupied") { break; }

					let symbol = S7_GM_Symbol(ko);
					let row = S7_GM_Row(vo);

					let coeff = row.coefficientFor(infoTagMarker);
					let diff = delta * coeff;
					if (diff != 0.0 && symbol.kind == S7_GM_SymbolKind_External) {
						let v = S7_GM_Variable(self.varForSymbol.get(symbol));
						if (self.shouldClearChanges) {
							self.changed.clear();
							self.shouldClearChanges = false;
						}
						self.changed.insert(v);
					}
					if (
						coeff != 0.0 &&
						row.add(diff) < 0.0 &&
						symbol.kind != S7_GM_SymbolKind_External
					) {
						infeasibleRows.push(symbol);
					}
				}
			}
		}

		self.dualOptimise();

		return S7_GM_SuggestValueError_None;
	}

	private void varChanged(S7_GM_Variable v) {
		if (self.shouldClearChanges) {
			self.changed.clear();
			self.shouldClearChanges = false;
		}
		self.changed.insert(v);
	}

	void fetchChanges(out Array<S7_GM_PublicChangesEntry> ret) {
		if (self.shouldClearChanges) {
			self.changed.clear();
			self.shouldClearChanges = false;
		} else {
			self.shouldClearChanges = true;
		}
		self.publicChanges.clear();

		let iter = self.changed.iter();
		while (true) {
			let vo = iter.next();
			if (vo is "S7_GM_HashUnoccupied") { break; }
			let v = S7_GM_Variable(vo);
			
			let vd = self.varData.get(v);
			if (!(vd is "S7_GM_HashUnoccupied")) {
				let varData = S7_GM_VarDataEntry(vd);
				let r = self.rows.get(varData.symbol);
				let newValue = 0.0;
				if (!(r is "S7_GM_HashUnoccupied")) {
					newValue = S7_GM_Row(r).constant;
				}
				let oldValue = varData.value;
				if (oldValue != newValue) {
					self.publicChanges.push(
						S7_GM_PublicChangesEntry.create(v, newValue)
					);
					varData.value = newValue;
				}
			}
		}

		ret.copy(self.publicChanges);
	}

	void reset() {
		self.rows.clear();
		self.cns.clear();
		self.varData.clear();
		self.varForSymbol.clear();
		self.changed.clear();
		self.shouldClearChanges = false;
		self.edits.clear();
		self.infeasibleRows.clear();
		self.objective = S7_GM_Row.create(0.0);
		self.artificial = NULL;
		self.idTick = 1;
	}

	private S7_GM_Symbol getVarSymbol(S7_GM_Variable v) {
		S7_GM_VarDataEntry value;
		let vd = self.varData.get(v);
		if (!(vd is "S7_GM_HashUnoccupied")) {
			value = S7_GM_VarDataEntry(vd);
		} else {
			let s = S7_GM_Symbol.create(self.idTick, S7_GM_SymbolKind_External);
			self.varForSymbol.insert(s, v);
			self.idTick += 1;
			value = S7_GM_VarDataEntry.create(double.NAN, s, 0);
			self.varData.insert(v, value);
		}
		value.count += 1;
		return value.symbol;
	}

	private S7_GM_Row, S7_GM_Tag createRow(S7_GM_Constraint constraint) {
		let expr = constraint.getExpr();
		let row = S7_GM_Row.create(expr.constant);
		for (let i = 0u; i < expr.terms.size(); i++) {
			let term = expr.terms[i]; 
			if (!S7_GM_GlobalMaths.nearZero(term.coefficient)) {
				let symbol = self.getVarSymbol(term.variable);
				let o = self.rows.get(symbol);
				if (!(o is "S7_GM_HashUnoccupied")) {
					let otherRow = S7_GM_Row(o);
					row.insertRow(otherRow, term.coefficient);
				} else {
					row.insertSymbol(symbol, term.coefficient);
				}
			}
		}

		let objective = self.objective;

		S7_GM_Tag tag;
		let constraintOp = constraint.getOp();
		switch (constraintOp) {
		case S7_GM_Rel_Geq:
		case S7_GM_Rel_Leq: {
			let coeff = (constraintOp == S7_GM_Rel_Leq) ? 1.0 : -1.0;
			let slack = S7_GM_Symbol.create(self.idTick, S7_GM_SymbolKind_Slack);
			self.idTick += 1;
			row.insertSymbol(slack, coeff);
			let constraintStrength = constraint.getStrength();
			if (constraintStrength < S7_GM_Strength.REQUIRED) {
				let error = S7_GM_Symbol.create(self.idTick, S7_GM_SymbolKind_Error);
				self.idTick += 1;
				row.insertSymbol(error, -coeff);
				objective.insertSymbol(error, constraintStrength);
				tag = S7_GM_Tag.create(
					marker: slack,
					other: error
				);
			} else {
				tag = S7_GM_Tag.create(
					marker: slack,
					other: S7_GM_Symbol.invalid()
				);
			}
			break;
		}
		case S7_GM_Rel_Eq: {
			let constraintStrength = constraint.getStrength();
			if (constraintStrength < S7_GM_Strength.REQUIRED) {
				let errplus = S7_GM_Symbol.create(self.idTick, S7_GM_SymbolKind_Error);
				self.idTick += 1;
				let errminus = S7_GM_Symbol.create(self.idTick, S7_GM_SymbolKind_Error);
				self.idTick += 1;
				row.insertSymbol(errplus,  -1.0);
				row.insertSymbol(errminus,  1.0);
				objective.insertSymbol(errplus, constraintStrength);
				objective.insertSymbol(errminus, constraintStrength);
				tag = S7_GM_Tag.create(
					marker: errplus,
					other: errminus
				);
			} else {
				let dummy = S7_GM_Symbol.create(self.idTick, S7_GM_SymbolKind_Dummy);
				self.idTick += 1;
				row.insertSymbol(dummy, 1.0);
				tag = S7_GM_Tag.create(
					marker: dummy,
					other: S7_GM_Symbol.invalid()
				);
			}
			break;
		}
		default:
			throwAbortException("shouldn't happen");
		}

		if (row.constant < 0.0) {
			row.reverseSign();
		}
		return row, tag;
	}

	static private S7_GM_Symbol chooseSubject(S7_GM_Row row, S7_GM_Tag tag) {
		let iter = row.cells.iter();
		while (true) {
			let ko = iter.next();
			if (ko is "S7_GM_HashUnoccupied") { break; }
			let s = S7_GM_Symbol(ko);

			if (s.kind == S7_GM_SymbolKind_External) {
				return s;
			}
		}
		if (tag.marker.kind == S7_GM_SymbolKind_Slack || tag.marker.kind == S7_GM_SymbolKind_Error) {
			if (row.coefficientFor(tag.marker) < 0.0) {
				return tag.marker;
			}
		}
		if (tag.other.kind == S7_GM_SymbolKind_Slack || tag.other.kind == S7_GM_SymbolKind_Error) {
			if (row.coefficientFor(tag.other) < 0.0) {
				return tag.other;
			}
		}
		return S7_GM_Symbol.invalid();
	}

	private bool addWithArtificialVariable(S7_GM_Row row) {
		let art = S7_GM_Symbol.create(self.idTick, S7_GM_SymbolKind_Slack);
		self.idTick += 1;
		self.rows.insert(art, row.clone());
		self.artificial = row.clone();

		let artificial = self.artificial;
		self.optimise(artificial);
		let success = S7_GM_GlobalMaths.nearZero(artificial.constant);
		self.artificial = NULL;

		let r = self.rows.remove(art);
		if (!(r is "S7_GM_HashUnoccupied")) {
			let row = S7_GM_Row(r);
			if (row.cells.isEmpty()) {
				return success;
			}
			let entering = anyPivotableSymbol(row);
			if (entering.kind == S7_GM_SymbolKind_Invalid) {
				return false;
			}
			row.solveForSymbols(art, entering);
			self.substitute(entering, row);
			self.rows.insert(entering, row);
		}

		let iter = self.rows.iter();
		while (true) {
			Object ko, vo;
			[ko, vo] = iter.next();
			if (ko is "S7_GM_HashUnoccupied") { break; }

			let row = S7_GM_Row(vo);

			row.remove(art);
		}
		self.objective.remove(art);
		return success;
	}

	private void substitute(S7_GM_Symbol symbol, S7_GM_Row row) {
		let iter = self.rows.iter();
		while (true) {
			Object ko, vo;
			[ko, vo] = iter.next();
			if (ko is "S7_GM_HashUnoccupied") { break; }

			let otherSymbol = S7_GM_Symbol(ko);
			let otherRow = S7_GM_Row(vo);

			let constantChanged = otherRow.substitute(symbol, row);
			if (otherSymbol.kind == S7_GM_SymbolKind_External && constantChanged) {
				let v = S7_GM_Variable(self.varForSymbol.get(otherSymbol));
				if (self.shouldClearChanges) {
					self.changed.clear();
					self.shouldClearChanges = false;
				}
				self.changed.insert(v);
			}
			if (otherSymbol.kind != S7_GM_SymbolKind_External && otherRow.constant < 0.0) {
				self.infeasibleRows.push(otherSymbol);
			}
		}
		self.objective.substitute(symbol, row);
		if (self.artificial != NULL) {
			let artificial = self.artificial;
			artificial.substitute(symbol, row);
		}
	}

	private void optimise(S7_GM_Row objective) {
		while (true) {
			let entering = getEnteringSymbol(objective);
			if (entering.kind == S7_GM_SymbolKind_Invalid) {
				return;
			}
			S7_GM_Symbol leaving;
			S7_GM_Row row;
			[leaving, row] = self.getLeavingRow(entering);
			if (leaving == NULL) {
				throwAbortException("internal solver error: the objective is unbounded");
			}
			row.solveForSymbols(leaving, entering);
			self.substitute(entering, row);
			if (entering.kind == S7_GM_SymbolKind_External && row.constant != 0.0) {
				let v = S7_GM_Variable(self.varForSymbol.get(entering));
				self.varChanged(v);
			}
			self.rows.insert(entering, row);
		}
	}

	private void dualOptimise() {
		while (self.infeasibleRows.size() != 0u) {
			let leaving = self.infeasibleRows[self.infeasibleRows.size() - 1];
			self.infeasibleRows.pop();

			S7_GM_Row row;
			let e = self.rows.get(leaving);
			if (!(e is "S7_GM_HashUnoccupied")) {
				let entry = S7_GM_Row(e);
				if (entry.constant < 0.0) {
					row = entry;
					self.rows.remove(leaving);
				} else {
					row = NULL;
				}
			} else {
				row = NULL;
			}
			if (row != NULL) {
				let entering = self.getDualEnteringSymbol(row);
				if (entering.kind == S7_GM_SymbolKind_Invalid) {
					throwAbortException("internal solver error: dual optimise failed");
				}
				row.solveForSymbols(leaving, entering);
				self.substitute(entering, row);
				if (entering.kind == S7_GM_SymbolKind_External && row.constant != 0.0) {
					let v = S7_GM_Variable(self.varForSymbol.get(entering));
					self.varChanged(v);
				}
				self.rows.insert(entering, row);
			}
		}
	}

	private S7_GM_Symbol getEnteringSymbol(S7_GM_Row objective) {
		let iter = objective.cells.iter();
		while (true) {
			Object ko, vo;
			[ko, vo] = iter.next();
			if (ko is "S7_GM_HashUnoccupied") { break; }

			let symbol = S7_GM_Symbol(ko);
			let value = S7_GM_BoxedDouble(vo).val;

			if (symbol.kind != S7_GM_SymbolKind_Dummy && value < 0.0) {
				return symbol;
			}
		}
		return S7_GM_Symbol.invalid();
	}

	private S7_GM_Symbol getDualEnteringSymbol(S7_GM_Row row) {
		let entering = S7_GM_Symbol.invalid();
		let ratio = double.INFINITY;
		let objective = self.objective;
		let iter = row.cells.iter();
		while (true) {
			Object ko, vo;
			[ko, vo] = iter.next();
			if (ko is "S7_GM_HashUnoccupied") { break; }

			let symbol = S7_GM_Symbol(ko);
			let value = S7_GM_BoxedDouble(vo).val;

			if (value > 0.0 && symbol.kind != S7_GM_SymbolKind_Dummy) {
				let coeff = objective.coefficientFor(symbol);
				let r = coeff / value;
				if (r < ratio) {
					ratio = r;
					entering = symbol;
				}
			}
		}
		return entering;
	}

	private static S7_GM_Symbol anyPivotableSymbol(S7_GM_Row row) {
		let iter = row.cells.iter();
		while (true) {
			Object ko, vo;
			[ko, vo] = iter.next();
			if (ko is "S7_GM_HashUnoccupied") { break; }

			let symbol = S7_GM_Symbol(ko);

			if (symbol.kind == S7_GM_SymbolKind_Slack || symbol.kind == S7_GM_SymbolKind_Error) {
				return symbol;
			}
		}
		return S7_GM_Symbol.invalid();
	}

	private S7_GM_Symbol, S7_GM_Row getLeavingRow(S7_GM_Symbol entering) {
		let ratio = double.INFINITY;
		S7_GM_Symbol found = NULL;
		let iter = self.rows.iter();
		while (true) {
			Object ko, vo;
			[ko, vo] = iter.next();
			if (ko is "S7_GM_HashUnoccupied") { break; }

			let symbol = S7_GM_Symbol(ko);
			let row = S7_GM_Row(vo);

			if (symbol.kind != S7_GM_SymbolKind_External) {
				let temp = row.coefficientFor(entering);
				if (temp < 0.0) {
					let tempRatio = -row.constant / temp;
					if (tempRatio < ratio) {
						ratio = tempRatio;
						found = symbol;
					}
				}
			}
		}
		if (found != NULL) {
			return found, S7_GM_Row(self.rows.remove(found));
		} else {
			return NULL, NULL;
		}
	}

	private S7_GM_Symbol, S7_GM_Row getMarkerLeavingRow(S7_GM_Symbol marker) {
		let r1 = double.INFINITY;
		let r2 = r1;
		S7_GM_Symbol first = NULL;
		S7_GM_Symbol second = NULL;
		S7_GM_Symbol third = NULL;
		let iter = self.rows.iter();
		while (true) {
			Object ko, vo;
			[ko, vo] = iter.next();
			if (ko is "S7_GM_HashUnoccupied") { break; }

			let symbol = S7_GM_Symbol(ko);
			let row = S7_GM_Row(vo);

			let c = row.coefficientFor(marker);
			if (c == 0.0) {
				continue;
			}
			if (symbol.kind == S7_GM_SymbolKind_External) {
				third = symbol;
			} else if (c < 0.0) {
				let r = -row.constant / c;
				if (r < r1) {
					r1 = r;
					first = symbol;
				}
			} else {
				let r = row.constant / c;
				if (r < r2) {
					r2 = r;
					second = symbol;
				}
			}
		}
		let s =
			(first != NULL)
			? first
			: (second != NULL)
			  ? second
			  : third;
		if (s != NULL) {
			if (s.kind == S7_GM_SymbolKind_External && S7_GM_Row(self.rows.get(s)).constant != 0.0) {
				let v = S7_GM_Variable(self.varForSymbol.get(s));
				self.varChanged(v);
			}
			let r = self.rows.remove(s);
			if (!(r is "S7_GM_HashUnoccupied")) {
				return s, S7_GM_Row(r);
			} else {
				return NULL, NULL;
			}
		} else {
			return NULL, NULL;
		}
	}

	private void removeConstraintEffects(S7_GM_Constraint cn, S7_GM_Tag tag) {
		if (tag.marker.kind == S7_GM_SymbolKind_Error) {
			self.removeMarkerEffects(tag.marker, cn.getStrength());
		} else if (tag.other.kind == S7_GM_SymbolKind_Error) {
			self.removeMarkerEffects(tag.other, cn.getStrength());
		}
	}

	private void removeMarkerEffects(S7_GM_Symbol marker, double strength) {
		let r = self.rows.get(marker);
		if (!(r is "S7_GM_HashUnoccupied")) {
			let row = S7_GM_Row(r);
			self.objective.insertRow(row, -strength);
		} else {
			self.objective.insertSymbol(marker, -strength);
		}
	}

	private static bool allDummies(S7_GM_Row row) {
		let iter = row.cells.iter();
		while (true) {
			let ko = iter.next();
			if (ko is "S7_GM_HashUnoccupied") { break; }
			let s = S7_GM_Symbol(ko);

			if (s.kind != S7_GM_SymbolKind_Dummy) {
				return false;
			}
		}
		return true;
	}

	static void printRow(S7_GM_Row row) {
		let ret = "row = Row {\n    cells: {\n";

		let iter = row.cells.iter();
		while (true) {
			Object ko, vo;
			[ko, vo] = iter.next();
			if (ko is "S7_GM_HashUnoccupied") { break; }

			let symbol = S7_GM_Symbol(ko);
			let val = S7_GM_BoxedDouble(vo).val;

			ret.appendFormat("        %s: %f,\n", symbol.repr(), val);
		}
		ret.appendFormat("    },\n    constant: %f,\n}", row.constant);
		Console.printf(ret);
	}

	private void printRows() {
		let ret = "self.rows = {\n";
		let iter = self.rows.iter();
		while (true) {
			Object ko, vo;
			[ko, vo] = iter.next();
			if (ko is "S7_GM_HashUnoccupied") { break; }

			let symbol = S7_GM_Symbol(ko);
			let row = S7_GM_Row(vo);

			ret.appendFormat("    %s: Row {\n        cells: {\n", symbol.repr());

			let iter = row.cells.iter();
			while (true) {
				Object ko, vo;
				[ko, vo] = iter.next();
				if (ko is "S7_GM_HashUnoccupied") { break; }

				let symbol = S7_GM_Symbol(ko);
				let val = S7_GM_BoxedDouble(vo).val;

				ret.appendFormat("            %s: %f,\n", symbol.repr(), val);
			}
			ret.appendFormat("        },\n        constant: %f,\n    },\n", row.constant);
		}
		ret.appendFormat("}");
		Console.printf(ret);
	}
}
