use std::collections::HashMap;

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
trait VecMathStructureHelpers {
    /// - `5,5` → `None: [5,5]`
    /// - `5kg,10` → `kg: [5], None: [10]`
    fn extract_constants(&self) -> HashMap<Option<Unit>, Vec<f64>>;
}

impl VecMathStructureHelpers for Vec<MathStructure> {
    fn extract_constants(&self) -> HashMap<Option<Unit>, Vec<f64>> {
        let mut constants = HashMap::new();
        for ms in self {
            match ms {
                MathStructure::WithUnits(mswu) => {
                    let units = mswu.units.clone();
                    let structure = mswu.structure.as_ref();
                    let entry = constants
                        .entry(Some(units[0].clone()))
                        .or_insert_with(Vec::new);
                    match structure {
                        MathStructure::Numeric(n) => {
                            entry.push(*n);
                        }
                        _ => {}
                    }
                }
                MathStructure::Numeric(n) => {
                    let entry = constants.entry(None).or_insert_with(Vec::new);
                    entry.push(*n);
                }
                _ => {}
            }
        }
        constants
    }
}
