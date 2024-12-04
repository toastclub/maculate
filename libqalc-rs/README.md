# libqalculate ported to rust

Libqalculate has an incredibly messy codebase, I suspect it is at least one order of magnitude larger than it needs to be, and it concerns itself with things that it should not (for instance, fetching currencies should be delegated to the consumer, and the vast majority of graphing as well). It's quite difficult to implement applications on top of it for this reason. The _problem_ is that a rewrite would _still_ likely clock in at over 10kloc, and by miracle libqalculate is mostly bug free. Thus, I'm not sure this rewrite will ever be completed, I'm just doing pieces here and there on the side.

## Zero to symbolic evaluation

The theories I am operating under as I construct this library

### Functions

Fundimental mathematical functions are "blackboxes", that is to say, the implementation in terms of other primitives would be so insurmountably complex that it is not worth it. A nice example of this is the `product` function. It is worth executing in code, instead of expanding, and likewise the derivative of the product function is best defined as the product rule, not with some sort of expanded equation.

But many functions aren't that deep, they are just constructed from other functions. For instance, secant is just 1/cosine, and the derivative can be inferred easily enough.
x
