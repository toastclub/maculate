use rug::Float;

use crate::{
    function::*,
    math_structure::{MathStructure, MathStructureWithUnits, VecMathStructureHelpers},
};

pub struct Product {}

impl Function for Product {
    fn execute(&self, args: Vec<MathStructure>) -> Result<ExecuteOK, String> {
        let groups = args.extract_constants();
        let mut structure: Vec<MathStructure> = vec![];
        for (unit, group) in groups {
            let product = group.iter().fold(Float::new(1), |acc, x| acc * x);
            match unit {
                Some(unit) => structure.push(MathStructure::WithUnits(MathStructureWithUnits {
                    units: vec![unit],
                    structure: Box::new(MathStructure::Numeric(product)),
                })),
                None => structure.push(MathStructure::Numeric(product)),
            }
        }
        Ok(ExecuteOK {
            outputs: structure,
            infos: None,
            warnings: None,
        })
    }
}

pub struct Sum {}

impl
