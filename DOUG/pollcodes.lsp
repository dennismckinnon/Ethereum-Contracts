;pollcodes

;THis is a helper contract for Doug-v3 which has special properties
;It creates polls for doug when doug wishes to know if a name should be given to a new contract
;This role will be assumed by the ACL in DOUG-v4 and will be more general
;but what can you do?

{
	[[0x1]] 0xDOUGADDRESS ;Doug's Address NOTE: If you change DOUGADDRESS here you also have to edit it below.(until i figure out how to overwrite specific chunks)

	;Doug Update (JIC)
	[0x0]"req"
	[0x20]"doug"
	(call (- (GAS) 100) @@0x0 0 0x0 0x40 0x0 0x40)
	[[0x0]]@0x0

	;DOUG registration
	[0x0]"reg"
	[0x20]"pollcodes"
	(call (- (GAS) 100) @@0x0 0 0x0 0x40 0x0 0x0)
}
{
	[0x0](calldataload 0)
	(when (= @0x0 "create")
		{
			[0x0](calldataload 0x20)
			(when (= @0x0 "poll1")
				{
					;This is poll for if name already exists
					[0x0](LLL
						{
							;init section
							[[0x10]] 0xDOUGADDRESS ;Doug's Address (every spawned contract knows this doug but will immediately search for a newer one.)
							[0x0]"req"
							[0x20] "doug"
							(call (- (GAS) 100) @@0x10 0 0x0 0x40 0x0 0x20)
							[[0x10]]@0x0 ;Copy new doug over

							;body section
							[0x0](LLL
								{
									;Check doug again
									[0x0]"req"
									[0x20] "doug"
									(call (- (GAS) 100) @@0x10 0 0x0 0x40 0x0 0x20)
									[[0x10]]@0x0 ;Copy new doug over

									[0x0] "req"
									[0x20] "user"
									(call (- (GAS) 100) @@0x10 0 0x0 0x40 0x40 0x20)

									(when (AND (= @0xE0 (CALLER)) (= (calldataload 0) "kill")) ;clean up
										(suicide (CALLER))
									)

									(when (> @@0x11 0) (stop)) ;Already been passed

									[0x60] "check"
									[0x80] (calldataload 0x20)
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
			)
			(when (= @0x0 "poll2")
				{
					;If the name has not been taken
					[0x0](LLL
						{
							[0x0](LLL
								{
									[0x0]2 ;Auto Accept
									(return 0x0 0x20)
								}
								0x20
							)
							(return 0x20 @0x0)
						}
						0x20
					)
					[0x0](CREATE 0 0x20 @0x0)
					(return 0x0 0x20)
				}
			)
		}
	)
}