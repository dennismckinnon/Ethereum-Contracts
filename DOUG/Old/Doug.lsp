;Transactions
;Register: Format: "reg" "name" (maybe name is hexadecimal?)
;DOUG will record name requested at the address of request and create a confirmation request of consensus contract
;When a concensus contract has reached criteria for a successful concensus (or maybe doug will ask everytime he is called)
;in either case once doug recieves the go ahead he will make the swap (this involves changing the address located at name)
;
;Request: Format: "req" "name"
;Request asks Doug for the contract address currently associated with "name" and doug will return it or return 0 if no such 
;name is registered.
;
;when the upgrades name is empty Doug will by default accept all registrations
;
;Structure
;Pending flag: Determines if Doug needs to check it there are updgrades to do (upgrades will keep track of which ones are pending)
;Upgrades flag
;
;Upgrades must always register for slot 0x100

{
	;Initialization
	[[0x0]] 0; Will's Address
	[[0x1]] 0; Pending flag
	[[0x2]] 0; Allow double register? (i think its best to avoid this)
	[["doug"]](ADDRESS);Register doug with doug
}
{
	;start up sequence:
	;1) Ask Doug for all records? (maybe this is an optional thing?)

	(when @@0x100
		{
			[0x0] 1;
			(while @0x0
				{
					(call @0x100 0 0 0 0 0x0 0x40) ;Call CC (returns [2-Acc/1-rej/0-nothing to report : Contract address])
					(when (= @0x0 2)
						{
							[[@@ @0x20]]@0x20 ;At the name (stored at contract address) store contract address
							(when @@0x2 [[@0x20]] 0) ;Second registration?
						}
					)
				}
			)
		}
	)

	;Body
	[0x20] (calldataload 0) ;Get the first argument
	(when (= @0x20 "req") ;Request made
		{
			[0x40] (calldataload 0x20) ;Get the requested name
			[0x60] @@0x40 ;Get the registered contracts address
			(return 0x60 0x20) ;return the address
		}
	)
	
	(when (=@0x20 "reg") ;Register
		{
			[0x40](calldataload 0x20) ;Get the name they are requesting
			(when (= (CALLER) 0) ;This restricts it so a contract can not be requesting two names at once
				{
					[[(CALLER)]] @0x40 ;Store the requested name
					(if (= @@0x100 0)
						{
							;The upgrades contract has not beenregistered yet. Automatic acceptance of contracts
							[[@0x40]] (CALLER);
							(when @@0x2 [[@0x20]] 0) ;Second registration?
						}
						{
							;Consensus Contract registered. Call it.
							[0x60](CALLER)
							(call @@0x100 0 0 0x40 0x40 0x80 0x40) ; Call the consensus contract return the value to [0x80]
							;Concensus contract returns [Accepted(2)/rejected(1)/undecided(0) : Contract Address]
							(when (= @0xA0 2)
								{
									;Already accepted
									[[@0x40]](CALLER)
									(when @@0x2 [[@0x20]] 0) ;Second registration?
								}
							)
						}
					)
				}
			)
		}
	)
}