# Some General Notes About Maculate & Qalculate Usage

In general, the [Qalculate documentation](https://qalculate.github.io/manual/index.html) is quite robust, this guide serves to give a "60 second" overview of how to use Qalculate, and how to use Maculate.

## Variables

Variables can be assigned like so:

```
v1 = 5
v1 := 5
```

### Gatchas

Unlike most calculators, variables should be descriptive, and not single letters. This is because Qalculate has units, so single letters could be ambiguous.

#### Attempts to solve for x with variables

If the variable is on the left side, it is assumed you are trying to assign it, not solve for it, check equality, ect.

In general, you can work around this by either wrapping the equation in `()`, or putting the variable on the right side.

## Solving Equations

Equations can be solved in terms of x, simply by writing an implicit equation:

x^2 + 2x + 1 = 0

Or, you can solve for x explicitly:

solve(x^2 + 2x + 1 = 0, x)

Assignment can be confusing:

v1 = 5
v1 = 3x

To avoid this, use the solve function,

You can solve for two variables at once:

multisolve([3x+4y=5, 2x−3y=−8];[x,y]) = [-1,2]
