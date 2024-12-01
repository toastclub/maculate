use crate::{function::Function, unit::Unit, variables::Variable};

/// Stores a Function and the arguments that were past to said function
pub struct MathStructureFunction {
    pub fun: Box<dyn Function>,
    pub args: Vec<MathStructure>,
}

/// Attaches at least one Unit to a MathStructure
pub struct MathStructureWithUnits {
    pub units: Vec<Unit>,
    pub structure: Box<MathStructure>,
}

/// A MathStructure is the basic instance of a formula.
/// Basically, it represents the AST.
pub enum MathStructure {
    Function(MathStructureFunction),
    WithUnits(MathStructureWithUnits),
    Variable(Variable),
    Numeric(f64),
}
