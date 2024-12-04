use rug::Float;

use crate::{
    function::*,
    math_structure::{MathStructure, MathStructureWithUnits, VecMathStructureHelpers},
};

pub struct Product;

impl Function for Product {
    const DISPLAY_NAME: &'static str = "product";
    fn execute(&self, args: Vec<MathStructure>) -> Result<ExecuteOK, String> {
        execute_basic_operation(args, |acc, x| acc * x, Float::new(1))
    }
}

pub struct Sum;

impl Function for Sum {
    const DISPLAY_NAME: &'static str = "sum";
    fn execute(&self, args: Vec<MathStructure>) -> Result<ExecuteOK, String> {
        execute_basic_operation(args, |acc, x| acc + x, Float::new(0))
    }
}

pub struct Divide;

impl Function for Divide {
    const DISPLAY_NAME: &'static str = "divide";
    fn execute(&self, args: Vec<MathStructure>) -> Result<ExecuteOK, String> {
        execute_basic_operation(args, |acc, x| acc / x, Float::new(1))
    }
}

pub struct Subtract;

impl Function for Subtract {
    const DISPLAY_NAME: &'static str = "subtract";
    fn execute(&self, args: Vec<MathStructure>) -> Result<ExecuteOK, String> {
        execute_basic_operation(args, |acc, x| acc - x, Float::new(0))
    }
}

pub struct Power;

fn execute_basic_operation<F>(
    args: Vec<MathStructure>,
    op: F,
    init: Float,
) -> Result<ExecuteOK, String>
where
    F: Fn(Float, &Float) -> Float,
{
    let groups = args.extract_constants();
    let mut structure: Vec<MathStructure> = vec![];
    for (unit, group) in groups {
        let result = group.iter().fold(init.clone(), &op);
        match unit {
            Some(unit) => structure.push(MathStructure::WithUnits(MathStructureWithUnits {
                units: vec![unit],
                structure: Box::new(MathStructure::Numeric(result)),
            })),
            None => structure.push(MathStructure::Numeric(result)),
        }
    }
    Ok(ExecuteOK {
        outputs: structure,
        infos: None,
        warnings: None,
    })
}
