;DOUG

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
;Fetch: Format: "fetch" #number
;Fetch will return the [name:Contract ID] pair for the item located in  
;
;when the upgrades name is empty Doug will by default accept all registrations
;
;Structure
;
;Upgrades must always register for slot "conc"
;
{
	;Metadata  section
;	[[0x0]] 0x88554646AB						;metadata notifier
;	[[0x1]] (CALLER)							;contract creator
;	[[0x2]] "Dennis McKinnon"					;contract Author
;	[[0x3]] 0x18042014							;Date
;	[[0x4]] 0x001002000							;version XXX.XXX.XXX
;	[[0x5]] "doug" 								;Name
;	[[0x6]] "12345678901234567890123456789012"	;Brief description (not past address 0xF)
;	[[0x6]] "Doug is a Decentralized Organiza"
;	[[0x7]] "tion Upgrade Guy. His purpose is"
;	[[0x8]] "to serve a recursive register fo"
;;	[[0x9]] "r contracts belonging to a DAO s"
;	[[0xA]] "other contracts can find out whi"
;	[[0xB]] "ch addresses to reference withou"
;	[[0xC]] "hardcoding. It also allows any c"
;	[[0xD]] "contract to be swapped out inclu"
;	[[0xE]] "ding DOUG himself."

	;Initialization
	[[0x10]] 0x11d11764cd7f6ecda172e0b72370e6ea7f75f290 ;NameReg address
	[[0x11]] 0x20 			; Name list start
	[[0x12]] (+ @@0x11 1) 	; name list pointer (next free slot)
	[[0x13]] 0 				; Allow double register? (i think its best to avoid this)
	[[0x14]] 0xFFFF			; The smallest name allowed to be registered  

	[[0x20]]"doug"			; Add doug as first in name list (for consistancy) 
	[["doug"]](ADDRESS)		; Register doug with doug
	[0x0]"Doug - Reloaded"
	(call @@0x10 0 0 0x0 0x20 0 0) ;Register the name DOUG
}
{

;	(when @@"conc"
;		{
;			[0x0] 1;
;			(while @0x0
;				{
;					[0x80] "check"
;					(call @@"conc" 0 0 0x80 0x20 0x0 0x40) ;Call CC (returns [2-Acc/1-rej/0-nothing to report : Contract address])
;					(when (= @0x20 2)
;						{
;							[[@@ @0x40]] @0x40 ;At the name (stored at contract address) store contract address
;
;							[0x20] "inlist"
;							[0x40] @@ @0x40 ;copy the name
;							(call (ADDRESS) 0 0 0x20 0x40 0x0 0x20)
;							(when (= @0x0 0) ;name not in list add it
;								{
;									[[@@0x12]]@0x40
;									[[0x12]](+ @@0x12 1);increment list pointer
;								}
;							)
;
;							(when (= @0x40 "doug")
;								{
;									(call @@0x10 0 0 0 0 0 0) ;clear the name registration
;									[0x1A0] "claim"
;									(call @@"doug" 0 0 0x1A0 0x20 0 0) ;Call new doug to tell him to claim name
;								}
;							)
;							(when @@0x13 [[@0x20]] 0) ;Second registration?
;						}
;					)
;				}
;			)
;		}
;	)

	;Body
	[0x20] (calldataload 0) ;Get the first argument

	(when (= @0x20 "kill")(suicide (CALLER))) ;kill line

	(when (= @0x20 "inlist") ;get passed a name checks if its in the list
		{
			[0x0] 0; Return data (0 if not in list)
			[0x40](calldataload 0x20)
			(for [0x100]@@0x11 (< @0x100 @@0x12) [0x100](+ @0x100 1)
				{
					(when (= @@ @0x100 @0x40) [0x0]@0x100)
				}
			)
			(return 0x0 0x20) ;Returns
		}
	)


	(when (= @0x20 "req") ;Request made
		{
			[0x40] (calldataload 0x20) ;Get the requested name
			[0x60] @@ @0x40 ;Get the registered contracts address
			(return 0x60 0x20) ;return the address
		}
	)

	(when (=@0x20 "fetch") ;Fetch from list
		{
			[0x40](calldataload 0x20) ;Get the requested number
			[0x0] (+ @@0x11 @0x40)
			(if (AND (>= @0x0 @@0x11)(< @0x0 @@0x12))
				{
					;Get the [name:contractID] pair
					[0x60]@@ @0x0 ;Get name
					[0x80]@@ @0x60 ;Get registered contract ID
					(return 0x60 0x40) ;send back
				}
				{
					;If not in range return [0:0]
					(return 0x60 0x40)
				}
			)
		}
	)

	(when (=@0x20 "dump") ;Dump the list in pairs 
		{
			[0x120] 0x200
			[0x140] 0
			(for [0x100] @@0x11 (< @0x100 @@0x12) [0x100](+ @0x100 1) ;loop through all names
				{
					[@0x120] @@ @0x100 ;Copy name
					[(+ @0x120 1)] @@ @@ @0x100 ;Copy contract Address
					[0x120](+ @0x120 2)
					[0x140](+ @0x140 0x40)
				}
			)
			(return 0x200 @0x140) ;Dump return
		}
	)

	(when (= @0x20 "getlistsize")
		{
			[0x40](- @@0x12 @@0x11) ;Get the current size of list
			(return 0x40 0x20)
		}
	)

	;Register
	;This can only happen if This Doug is top of the doug chain. Otherwise this doug simpley serves
	;To alert new contracts to the new doug.
	(when (AND (=@0x20 "reg") (= @@"doug" (ADDRESS)))
		{
			[0x40](calldataload 0x20) ;Get the name they are requesting
			(when (< @0x40 @@0x14)
				{
					[0x0]0 ;failure to register. Name too low
					(return 0x0 0x20)
				} 
			)
			(when (= @@(CALLER) 0) ;This restricts it so a contract can not be requesting two names at once
				{
					[[(CALLER)]] @0x40 ;Store the requested name
					(if (= @@"conc" 0)
						{
							;The upgrades contract has not beenregistered yet. Automatic acceptance of contracts
							[[@0x40]] (CALLER);			;Register contract address

							[0x20]"inlist"
							(call (ADDRESS) 0 0 0x20 0x40 0x0 0x20)
							(when (= @0x0 0) ;name not in list add it
								{
									[[@@0x12]]@0x40
									[[0x12]](+ @@0x12 1);increment list pointer
								}
							)

							(when @@0x13 [[@0x20]] 0) 	;Second registration?
							[0x0] 1 ;Successful registration
							(return 0x0 0x20)
						}
						{
							;Consensus Contract registered. Call it.
							[0x20] "create"
							[0x60](CALLER)
							(call @@"conc" 0 0 0x20 0x60 0x80 0x40) ; Call the consensus contract return the value to [0x80]
							;Concensus contract returns [Accepted(2)/rejected(1)/undecided(0) : Contract Address]
							(when (= @0x80 2)
								{
									;Already accepted
									[[@0x40]](CALLER) ;Set contract at name
									[0x20]"inlist"
									(call (ADDRESS) 0 0 0x20 0x40 0x0 0x20)
									(when (= @0x0 0) ;name not in list add it
										{
											[[@@0x12]]@0x40
											[[0x12]](+ @@0x12 1);increment list pointer
										}
									)

									(when (= @0x40 "doug")
										{
											(call @@0x10 0 0 0 0 0 0) ;clear the name registration
										}
									)
									(when @@0x13 [[@0x20]] 0) ;Second registration?
									[0x0] 1 ;Successful registration
									(return 0x0 0x20)
								}
							)
						}
					)
				}
			)
		}
	)
}