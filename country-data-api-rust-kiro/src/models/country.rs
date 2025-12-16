use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Country {
    pub name: String,
    pub capital: String,
    pub population: i64,
    pub region: String,
    pub languages: Vec<String>,
}

impl Country {
    pub fn validate(&self) -> bool {
        !self.name.trim().is_empty()
            && self.population >= 0
            && self.languages.iter().all(|lang| !lang.is_empty())
    }
}
