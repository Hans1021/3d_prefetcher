# Notes

Parameterized version for an `X_SIZE x Y_SIZE x Z_SIZE` prism

Addresses range from: `0` to `X_SIZE \* Y_SIZE \* Z_SIZE - 1`

## Neighbors

`x neighbors: +/- 1`

`y neighbors: +/- X_SIZE`

`z neighbors: +/- (X_SIZE * Y_SIZE)`

## To get coordinates from address

`x = addr % X_SIZE`

`y = (addr / X_SIZE) % Y_SIZE`

`z = addr / (X_SIZE * Y_SIZE)`

Coordinate widths are based on dimension sizes:

`X_BITS = ceil(log2(X_SIZE))`
`Y_BITS = ceil(log2(Y_SIZE))`
`Z_BITS = ceil(log2(Z_SIZE))`

## Boundary checks

`X_MINUS valid if x > 0`

`X_PLUS valid if x < X_SIZE - 1`

`Y_MINUS valid if y > 0`

`Y_PLUS valid if y < Y_SIZE - 1`

`Z_MINUS valid if z > 0`

`Z_PLUS valid if z < Z_SIZE - 1`

## Address range

If address is out of bounds:

`address_i >= X_SIZE * Y_SIZE * Z_SIZE`

Stay in `IDLE` and `ready = 0`
