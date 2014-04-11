{
	;Initialization
	[[0x0]] (caller) ;Admin!
	[[0x1]] 0x8 ;Where lotto tickets are
	[[0x2]] (EXP 0x10 (SUB 64 2)) ;Lotto difficulty (number of hex digits in a ticke
	[[0x3]] (NUMBER) ;Start of round
	[[0x4]] 4 ;how much ether per draw to pocket (if value is p you actually pocket jackpot/p therefore larger p=smaller reward)
	[[0x5]] 0x10 ;How often should the draw happen?
	[[0x6]] 0
	[0x0]:"Denny's Lotto" ;You can put a more specific name here
	(call 0x11d11764cd7f6ecda172e0b72370e6ea7f75f290 0 0 0 13 0 0) ;Register with name registration
}
{
	(if (calldatasize)
		{
			[0x0] (calldataload 0)
			[[0x42]] (calldataload 0)
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
					[[(+ @@0x1 1)]] (DIV @0x0 @@0x2) ;Your ticket
					[[0x1]] (+ @@0x1 2) ;Increment ticket pointer
					[[0x6]] (+ @@0x6 2) ;ADD to jackpot
				}
			)
		}
		{
			;Take it as a claim
			(call (caller) @@(caller) 0 0 0 0 0)
			[[(caller)]] 0x0; Clear out their balance
		}
	)

	[0x1] (prevhash)
	[0x2] (timestamp)
	[0x3] (SHA3 0x1 1)
	[[500]] @0x3
	(when (> (SUB (NUMBER) @@0x3) 10) ;Random chance on every ticket purchase for a draw to occur (hard draw at 10 blocks)
		{
			[0x1] (prevhash)
			[0x2] (coinbase)
			[0x3] (SHA3 0x1 1) ;Random lottery 
			[0x4] (MOD @0x3 @@0x2) ;DRAW!
			["j"] 0x8
			[[0x3]] (+ (NUMBER) 1) ;start new round
			;Loop through and copy winners to memory slots
			(for ["i"]0x8 (< @"i" @@0x1) ["i"](+ @"i" 2)
				{
					(when (= (+ @@ @"i" @0x4) ;when they have a winning ticket
						{
							[@"j"] @@"i" ;copy winner's address over
							["j"] (+ @"j" 1) ;add one to the counter (mem tracker)
						}
					)
					[[@"i"]] 0x0
					[[(+ @"i" 1)]] 0x0 ;Clear storage
				}
			) 
			[[0x1]] 0x8; resent ticket pointer

			;Now Pay the winners
			[0x5] (- @"j" 0x8) ;Number of winners
			[0x6] (DIV @@0x5 @@0x4) ;Amount to steal
			[0x7] (DIV (- @@0x5 @0x6) @0x5) ;Winnings per player

			(if (> @0x5 0) ;If there are winners
				{
					(for ["i"]0x8 (< @"i" @"j") ["i"](+ @"i" 1)
						[[@ @"i"]] (+ @@ @ @"i" @0x7) ;Attribute winnings to winners
					)
					[[@@0x0]] (+ @@ @@0x0 @0x6) ;Send the admin their cut
					[[0x6]] 0 ;Empty out jackpot
				}
				{
					(call @@0x0 @0x6 0 0 0 0 0) ;Nobody wins admin gets the jackpot rollover (Admin gets his cut)
				}
			)
		}
	)
}