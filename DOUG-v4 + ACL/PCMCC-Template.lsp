{
	[[0x0]]"name"
}
{
	;Create contract

	[0x0](LLL
		{
			;Insert Poll manager code here

		}
		0x20
	)

	[0x0](CREATE 0 0x20 @0x0) ;Create the poll manager code and store address at 0x0

	;Stage 2 - Initialize the PCM
	(CALLDATACOPY 0x20 0x0 (CALLDATASIZE))
	[0x20]"init" ;Modify command for passing data along
	(call (- (GAS) 100) @0x0 0 0x20 (+ (CALLDATASIZE) 0x20) 0x0 0x0) ;Initialize the PCM

	(return 0x0 0x20) ;Return the PCM address so it can be given permissions
}