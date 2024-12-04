use std::collections::HashMap;

use rug::Float;

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
    Numeric(Float),
}
pub trait VecMathStructureHelpers {
    /// - `5,5` → `None: [5,5]`
    /// - `5kg,10` → `kg: [5], None: [10]`
    fn extract_constants(&self) -> HashMap<Option<Unit>, Vec<Float>>;
}

impl VecMathStructureHelpers for Vec<MathStructure> {
    fn extract_constants(&self) -> HashMap<Option<Unit>, Vec<Float>> {
        let mut constants = HashMap::new();
        for arg in self {
            match arg {
                MathStructure::WithUnits(wu) => {
                    for unit in &wu.units {
                        constants
                            .entry(Some(unit.clone()))
                            .or_insert_with(Vec::new)
                            .push(Float::new(1));
                    }
                }
                MathStructure::Numeric(n) => {
                    constants
                        .entry(None)
                        .or_insert_with(Vec::new)
                        .push(n.clone());
                }
                _ => {}
            }
        }
        constants
    }
}
