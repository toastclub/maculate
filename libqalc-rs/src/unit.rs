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
