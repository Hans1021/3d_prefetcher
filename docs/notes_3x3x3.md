# Notes

Assuming a 3 x 3 x 3 cube with addresses 0-26 first. Using (x,y,z) coordinates:

## z = 0

`0  1  2`
`3  4  5`
`6  7  8`

## z = 1

`9  10 11`
`12 13 14`
`15 16 17`

## z = 2

`18 19 20`
`21 22 23`
`24 25 26`

## Neighbors

`x neighbors: +/- 1`

`y neighbors: +/- 3`

`z neighbors: +/- 9`

## To get coordinates from address

`x = addr % 3`

`y = addr / 3 % 3`

`z = addr / 9`

## Boundary checks

`X_MINUS valid if x > 0`

`X_PLUS valid if x < 2`

`Y_MINUS valid if y > 0`

`Y_PLUS valid if y < 2`

`Z_MINUS valid if z > 0`

`Z_PLUS valid if z < 2`

## Design

Check for boundaries, then go through all possible neighbors in an FSM:

`IDLE -> X_MINUS -> X_PLUS -> Y_MINUS -> Y_PLUS -> Z_MINUS -> Z_PLUS -> IDLE`

If direction is invalid then skip the state.
