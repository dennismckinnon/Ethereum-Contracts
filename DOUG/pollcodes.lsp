;pollcodes
{
	[[0x1]] 0xDOUG'S ADDRESS ;Doug's Address

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
							[[0x10]] 0x6207fbebac090bab3c91d4de0f4264b3338982b9 ;Doug's Address (every spawned contract knows this doug but will immediately search for a newer one.)
							[0x0]"req"
							[0x20] "doug"
							(call 0 @@0x10 0 0x0 0x40 0x0 0x20)
							[[0x10]]@0x0 ;Copy new doug over

							;body section
							[0x0](LLL
								{
									;Check doug again
									[0x0]"req"
									[0x20] "doug"
									(call 0 @@0x10 0 0x0 0x40 0x0 0x20)
									[[0x10]]@0x0 ;Copy new doug over

									[0x0] "req"
									[0x20] "user"
									(call 0 @@0x10 0 0x0 0x40 0x40 0x20)

									(when (AND (= @0xE0 (CALLER)) (= (calldataload 0) "kill")) ;clean up
										(suicide (CALLER))
									)

									(when (> @@0x11 0) (stop)) ;Already been passed

									[0x60] "check"
									[0x80] (calldataload 0x20)
									(call 0 @0x40 0 0x60 0x40 0x0 0x20) ;Call user manager and find out if the caller has permissions (0x0)
									
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