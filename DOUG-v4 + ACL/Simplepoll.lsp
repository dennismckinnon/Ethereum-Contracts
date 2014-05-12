;pollcodes

;THis is a helper contract for Doug-v3 which has special properties
;It creates polls for doug when doug wishes to know if a name should be given to a new contract
;This role will be assumed by the ACL in DOUG-v4 and will be more general
;but what can you do?

{
	[[0x0]] 0xDEADBEEF ;overwrite canary
}
{
	;This is poll for if name already exists
	[0x0](LLL
		{
			;body section
			[0x0](LLL
				{
					(when (= (calldataload 0) "kill") ;clean up (only Doug can kill this contract)
						(suicide (CALLER))
					)

					(when @@0x11 (stop)) ;Already been passed

					[0x60] "check"
					[0x80] (CALLER)
					(call (- (GAS) 100) @0x40 0 0x60 0x40 0x0 0x20) ;Call user manager and find out if the caller has permissions (0x0)
					
					[0x0](MOD(DIV @0x0 2)2);Second Digit (if they are an admin = 1) ;standard admin check
					
					(unless @0x0 (stop)) ;Not an admin stop

					[0x20](calldataload 0) ;Command
					(when (= @0x20 "vote")
						{
							[[0x11]](calldataload 0x20) ;Store whatever they voted
						}
					)

					(when (= @0x20 "check")
						{
							[0x40]@@0x11
							(return 0x40 0x20) ;return the value in storage
						}
					)
				}
				0x20
			)
			(return 0x20 @0x0) ;Return body
		}
		0x20
	)
	[0x0](CREATE 0 0x20 @0x0)
	(return 0x0 0x20) ;Return the address of the poll
}
