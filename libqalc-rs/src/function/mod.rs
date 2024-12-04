use crate::math_structure::MathStructure;
mod impls;

pub struct ExecuteOK {
    outputs: Vec<MathStructure>,
    infos: Option<Vec<String>>,
    warnings: Option<Vec<String>>,
}

pub trait Function {
    const DISPLAY_NAME: &'static str;
    const ALIASES: &'static [&'static str] = &[];

    /// - `product.execute(N(5), N(10), Var(x))` → `product(N(50), Var(x))`
    /// - `product.execute(N(5), N(10))` → `Var(50)`
    fn execute(&self, args: Vec<MathStructure>) -> Result<ExecuteOK, String>;
    fn integrate(&self, args: Vec<MathStructure>) -> Option<MathStructure> {
        None
    }
    fn derive(&self, args: Vec<MathStructure>) -> Option<MathStructure> {
        None
    }
}
