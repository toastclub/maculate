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

use darling::FromMeta;
use proc_macro::TokenStream;
use quote::quote;
use syn::{parse_macro_input, DeriveInput};

#[derive(Debug, FromMeta)]
struct ArgOptions {
    /// Name of the argument
    name: String,

    /// Description of the argument
    description: String,

    /// Whether the argument is required
    #[darling(default)]
    required: bool,
}

#[proc_macro_derive(ArgumentMetadata, attributes(arg))]
pub fn derive_argument_metadata(input: TokenStream) -> TokenStream {
    let input = parse_macro_input!(input as DeriveInput);

    let name = &input.ident;
    let fields = if let syn::Data::Struct(data) = &input.data {
        &data.fields
    } else {
        panic!("ArgumentMetadata can only be derived for structs");
    };

    let args: Vec<_> = fields
        .iter()
        .map(|field| {
            let ident = field.ident.as_ref().unwrap();
            let ty = &field.ty;

            let attr = field
                .attrs
                .iter()
                .find(|attr| attr.path.is_ident("arg"))
                .expect("Field must have #[arg] attribute");

            let options = attr
                .parse_args::<ArgOptions>()
                .expect("Invalid #[arg] format");
            let name = options.name;
            let description = options.description;
            let required = options.required;

            quote! {
                Argument {
                    name: #name.to_string(),
                    description: #description.to_string(),
                    required: #required,
                    value_type: stringify!(#ty).to_string(),
                }
            }
        })
        .collect();

    let expanded = quote! {
        impl ArgumentMetadata for #name {
            fn metadata() -> Vec<Argument> {
                vec![#(#args),*]
            }
        }
    };

    TokenStream::from(expanded)
}
