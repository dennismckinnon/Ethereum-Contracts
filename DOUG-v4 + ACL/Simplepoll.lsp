;Simple Poll

;Stupid poll for testing purposes. Anyone can vote. A single vote determines the outcome

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

					(when (= @0x20 "check")
						{
							[0x40]@@0x11
							(return 0x40 0x20) ;return the value in storage
						}
					)

					(when @@0x11 (stop)) ;Already been passed

					[0x20](calldataload 0) ;Command
					(when (= @0x20 "vote")
						{
							[[0x11]](calldataload 0x20) ;Store whatever they voted
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
