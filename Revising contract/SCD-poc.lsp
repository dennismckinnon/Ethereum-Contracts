;Single Contract Doug (SCD)
;
;Purpose of a SCD is to have a single contract system which is capable of updating itself
;for the purposes of this proof of concept to to have a basic template for a contract 
;created between two parties such that in order for the contract to become active one
;party must create the contract and the other party muct activate it. (sign it)
;
;The contract must also be capable of transfering (pointing) to a new version of the contract
;If one is created and both parties of the original contract agree to the change (once
;again one part creates and submits the proposed new contract and the second party must
;activate it)


{
	[[0x10]] (ADDRESS)	;Who this contract thinks is the successor (set to himself for now)
	[[0x11]] (CALLER)	;Party 1
	[[CALLER]] 0x12 	;makes things easier
	[[0x12]] 0x0 		;Party 2 (not filled until activated)
	[[0x14]] 1 			;Tranfered flag (0 when another contract superceeds this one)
	[[0x15]] 0x0 		;Contract to try and superceed
	(when @@0x15
		[0x0]"superceed"
		(call @@0x15 0 0 0x0 0x20 0 0) ;Tell old contract you want to superceed it
	)

}
{

	[0x20](calldataload 0)
	(when (AND(= (CALLER) @@0x15)(= @0x20 "conceed")
		{
			[[0x11]](calldataload 0x20) ;set party 1 (even if someone other then party one created this contract)
			[[0x12]](calldataload 0x40) ;set party 2 
		}
	)

	(when (AND (= @@0x12 0)(= @0x20 "I agree to the terms")) ;Just so you can't argue that they didn't know what they were doing preston :P
		[[0x12]](CALLER) ;Second party now set
	)

	(unless @@0x12 (stop)) ;If the second party has not agreed you may go no further in the contract

	(when (= @0x20 "superceed")
		{
			[[0x10]](CALLER)
			(stop)
		}
	)

	(when (AND(NOT(= @@0x10 (ADDRESS)))@@0x14)
		{
			(if (= @0x20 "I agree to the new contract")
				{
					[[(+ @@(CALLER) 0x5)]]1 ;Set approval for that party
					(when (AND @@0x16 @@0x17) ;When both parties have confirmed the change
						{
							;send the new contract confirmation of superceedance
							[0x40]"conceed"
							[0x60] @@0x11
							[0x80] @@0x12
							(call @@0x10 0 0 0x40 0x60 0 0) ;send the conceed message (you should also send any data which is required for transfer)
							[[0x14]]0 ;Transfered over
						}
					)
				}
				{
					;Anything else is considered rejection
					[[0x10]](ADDRESS)
				}
			)
		}
	)
	(unless @@0x14 (stop)) ;Contract has been superceeded. Stop

	;This is where you would write the terms of the contract and program in any operations.




}