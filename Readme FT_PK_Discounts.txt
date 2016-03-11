Log - 15742
- PROCEDURE DO_DISCOUNTS1
	- Logic changed to check for FOC deliveries check against Delprice < 0.009  and .DELFREEOFCHG = 1 this stops the issue of deliveries changed to zero quantity not altering the discount amount
- FIND_ITECHG
	- Exception TOO_MANY_ROWS dded to catch when duplicate Itechg records are written (shouldn't happen) if the exception is thrown all tof the itechg records are deleted and false is returned so that the itechg will be rewritten
