{
	;Initialization
	[[0x0]] (caller) ;Admin!
	[[0x1]] 0x8 ;Where lotto tickets are
	[[0x2]] 100 ;Lotto difficulty (number of digits in a ticket
	[[0x3]] (NUMBER) ;Start of round
	[[0x4]] 0x5 ;how much ether per draw to pocket (if value is p you actually pocket jackpot/p therefore larger p=smaller reward)
	[[0x5]] 10 ;How often should the draw happen?
	[[0x6]] 0
	[0x0]:"Denny's Lotto" ;You can put a more specific name here
	(call 0x11d11764cd7f6ecda172e0b72370e6ea7f75f290 0 0 0 13 0 0) ;Register with name registration
}
{
	(if (calldatasize)
		{
			[0x0] (calldataload 0)
			(when (= (caller) @@0x0)
				(when (= @0x0 "kill") ;If the admin calls it with data "kill" deregister + suicide
					{
						(call 0x11d11764cd7f6ecda172e0b72370e6ea7f75f290 0 0 0 0 0 0)
						(suicide @@0x0)
					}
				)
			)

			(when (>= (callvalue) 2ether)
				{
					[[@@0x1]] (caller)
					[[(+ @@0x1 1)]] (MOD @0x0 @@0x2) ;Your ticket
					[[0x1]] (+ @@0x1 2) ;Increment ticket pointer
					[[0x6]] (+ @@0x6 (callvalue)) ;ADD to jackpot
				}
			)
		}
		{
			;Take it as a claim
			(call (caller) @@(caller) 0 0 0 0 0)
			[[(caller)]] 0x0; Clear out their balance
		}
	)

	(when (> (SUB (NUMBER) @@0x3) @@0x5) ;Has it been at least 16 blocks since draw?
		{
			[[0x3]] (+ (NUMBER) 1) ;start new round
			[0x20] (prevhash)
			[0x40] (coinbase)
			[0x60] (SHA3 0x20 0x40) ;Random lottery 
			[0x80] (MOD @0x3 @@0x2) ;DRAW!
			[0xA0] 0 ;Counter of number of winners
			[0xC0] 0x200 ;Storage location
			

			(for [0xE0]0x8 (< @0xE0 @@0x1) [0xE0](+ @0xE0 2) ;loop through all tickets 
				{
					[0x100](+ @0xE0 1) ;Second slot
					(when (= @0x80 @@ @0x100) ;ticket matches
						{
							[@0xC0] @@ @0xE0 ;Copy winner address
							[0xC0] (+ @0xC0 0x20) ;increment mem locator
							[0xA0](+ @0xA0 1) ;Increment counter
						}
					)
					;The second way to win!
					(when (= (MOD @0x80 10)(MOD @@ @0x100 10)) ;if the last digit matches
						{
							[[@@ @0xE0]] (+ @@ @ @0xE0 5ether) ;add 5 ether to their account
							[[0x6]] (- @@0x6 5ether)
						}
					)
					[[@0xE0]] 0
					[[@0x100]] 0 ;clear storage
				}
			)

			[[0x1]] 0x8

			;At this point the number of winners has been counted 0xC holds number of winners. Addresses of winners are located between 0x10 - 0x10+ @0xC
			[0xE0] 0
			[0x100] 0
			[0xC0] 0x200
			[0x80] 0

			(when (> @0xA0 0) ;when there are winners
				{
					[0x100] (DIV @@0x6 @@0x4) ;What is the admin's cut?
					[0x120] (DIV (SUB @@0x6 @0x100) @0xA0) ;Divide the ramainder among the winners
					[0xA0] (+ 0x200 (* @0xA0 0x20))
					(for [0xE0]0x200 (< @0xE0 @0xA0) [0xE0] (+ @0xE0 0x20) ;Loop the number of times there is a winner
						{
							[[@ @0xE0]] (+ @@ @ @0xE0 @0x120) ;Add the winnings to thier account
						}
					)
					[[0x6]] @0x100
				}
			)
		}
	)
}