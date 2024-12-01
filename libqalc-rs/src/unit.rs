/// A unit itself holds no value. Its primary use is in conversion.
///
/// Eg: What is a USD? Well, it is 1.04 EUR, and what is a EUR?
/// Well I think you see the problem.
pub struct Unit {
    pub primary_name: String,
    pub aliases: Vec<String>,
    pub categories: Vec<String>,
    pub parent: Option<Box<UnitParent>>,
}

pub struct UnitParent {
    pub parent: Unit,
    pub factor: f64,
}
