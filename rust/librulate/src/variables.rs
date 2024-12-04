use crate::math_structure::MathStructure;

/// A variable holds a reusable reference to a MathStructure.
pub struct Variable {
    pub primary_name: String,
    pub aliases: Vec<String>,
    pub categories: Vec<String>,
    /// if `definition` is `None`, it should be assumed that
    /// this variable is a placeholder.
    pub definition: Option<Box<MathStructure>>,
}
