;DOUG Version 3

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
;
{
	;Metadata  section
	[[0x0]] 0x88554646AB						;metadata notifier
	[[0x1]] (CALLER)							;contract creator
	[[0x2]] "Dennis McKinnon"					;contract Author
	[[0x3]] 0x18042014							;Date
	[[0x4]] 0x001003000							;version XXX.XXX.XXX
	[[0x5]] "doug" 								;Name
	[[0x6]] "12345678901234567890123456789012"	;Brief description (not past address 0xF)
	[[0x6]] "Doug is a Decentralized Organiza"
	[[0x7]] "tion Upgrade Guy. His purpose is"
	[[0x8]] "to serve a recursive register fo"
	[[0x9]] "r contracts belonging to a DAO s"
	[[0xA]] "other contracts can find out whi"
	[[0xB]] "ch addresses to reference withou"
	[[0xC]] "hardcoding. It also allows any c"
	[[0xD]] "contract to be swapped out inclu"
	[[0xE]] "ding DOUG himself."

	;Initialization
	[[0x10]] 0x11d11764cd7f6ecda172e0b72370e6ea7f75f290 ;NameReg address
	[[0x11]] 0x20 			; Name list start
	[[0x12]] (+ @@0x11 1) 	; name list pointer (next free slot)
	[[0x14]] 0xFFFF			; The smallest name allowed to be registered  

	[[0x20]]"doug"			; Add doug as first in name list (for consistancy) 
	[["doug"]](ADDRESS)		; Register doug with doug
	[0x0]"Doug - Revolution"
;	(call @@0x10 0 0 0x0 0x11 0 0) ;Register the name DOUG

	;Linked list
	[[0x15]] 0x17 ; Set tail
	[[0x16]] 0x17 ;	Set head

}
{
	
;Major structure change is that DOUG handles poll contracts himself in a linked list structure
;The reason for this is to reduce the risk caused by mallfunctioning poll or concensus contracts
;
;The structure of the linked list is as follows
;@0xPOLLADDRESS 0xCONTRACTADDRESS
;@0xPOLLADDRESS+1 0xNEXTPOLLADDRESS
;
;The reason for no previous pointer is because the list will always be searched in one direction so the previous pointer can be stored in memory
;
;The contract of interest now is "pollcodes" - Stores the code and creates poll contracts when requested and return poll address
;If a poll contract does not respond properly there needs to be some recovery mechanism


	;Body
	[0x20] (calldataload 0) ;Get the first argument

	;NOTE THIS CHECK HAPPENS BEFORE THE UPDATE BECAUSE THE UPDATE CALLS IT AND WE DON'T WANT AN INFINITE RECURSION LOOP
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

	(when @@"pollcodes"
		{
			[0x60](+ @@0x15 1) ;previous pointer address
			[0x0] @@ @0x60 ;current position
			(while (> @0x0 0) ;Loop until head is reached or the next pointer = 0
				{
					;Loop until the current position is 0 (previous pointer pointed to 0)
					;check each poll if it has closed and what the result is
					[0x20]"check"
					(call @0x0 0 0 0x20 0x20 0x40 0x20)


					[0x80] @@(+ @0x0 1) ;get next address from curren next pointer

					(when (= @0x40 1)
						{
							;Delete link
							[[@0x0]]0
							[[(+ @0x0 1)]]0  ;Delete link, Copy next address to previous pointer and move to next slot (= 0 at end)
							[[@0x60]]@0x80

							(when (= @0x80 0)
								[[0x16]](- @0x60 1) ;Set previous as new head
							)
							
						}
					)

					(when (= @0x40 2)
						{
							;Add to list... then delete link
							[0x20] "inlist"
							[0x40] @@ @@ @0x0 ;copy the name (name is stored at the address of the contract in question at 0x0)
							(call @@"doug" 0 0 0x20 0x40 0xC0 0x20)

							[[@0x40]] (CALLER);			;Register contract address

							(when (= @0xC0 0) ;name not in list add it
								{
									[[@@0x12]]@0x40
									[[0x12]](+ @@0x12 1);increment list pointer
								}
							)

							(when (= @0x40 "doug")
								{
									(call @@0x10 0 0 0 0 0 0) ;clear the name registration
									[0x1A0] "claim"
									(call @@"doug" 0 0 0x1A0 0x20 0 0) ;Call new doug to tell him to claim name (It doesn't matter if new doug responds to this)
								}
							)

							[[@0x0]]0
							[[(+ @0x0 1)]]0  ;Delete link, Copy next address to previous pointer and move to next slot (= 0 at end)
							[[@0x60]]@0x80

							(when (= @0x80 0)
								[[0x16]](- @0x60 1) ;Set previous as new head
							)
						}
					)
					(when (= @0x40 0) ;If the link is not removed then move previous pointer address (otherwise leave it there)
						[0x60] (+ @0x0 1) ;change the previous pointer address to current pointer address
					)
					
					[0x0] @0x80 ;change current to next
				}
			)
		}
	)


	(when (= @0x20 "req") ;Request made
		{
			[0x40] (calldataload 0x20) ;Get the requested name
			(if (= @@"doug" (ADDRESS))
				{
					[0x60] @@ @0x40 ;Get the registered contracts address
					[0x80](ADDRESS) ;Send back current doug too
					(return 0x60 0x40) ;return the address
				}
				{	;If this doug is not the head of the doug chain pass the request forward to doug
					(call @@"doug" 0 0 0x20 0x40 0x60 0x40) ;Get the answer from Doug
					(return 0x60 0x40) ;Return
				}
			)
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
					[(+ @0x120 0x20)] @@ @@ @0x100 ;Copy contract Address
					[0x120](+ @0x120 0x40)
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
	;This can only happen if This Doug is top of the doug chain. Otherwise this doug simply serves
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
					(if (= @@"pollcodes" 0)
						{
							;The pollcodes contract has not beenregistered yet. Automatic acceptance of contracts
							[[@0x40]] (CALLER);			;Register contract address

							[0x20]"inlist"
							(call (ADDRESS) 0 0 0x20 0x40 0x0 0x20)
							(when (= @0x0 0) ;name not in list add it
								{
									[[@@0x12]]@0x40
									[[0x12]](+ @@0x12 1);increment list pointer
								}
							)

							[0x0] 1 ;Successful registration
							(return 0x0 0x20)
						}
						{
							;Pollcodes Contract registered. Call it.
							[0x20]"inlist"
							(call @@"doug" 0 0 0x20 0x40 0 0x20

							[0x100]"create"
							(if (= @0x0 0) ;If there is no contract registered to that name
								[0x120]"poll1" ;ask for polltype 1 ;Default. Always should have a default for contracts with names you don't recognize
								[0x120]"poll2" ;ask for polltype 2 
							)
							[0x80]0 ;Safety measure in case something goes wrong
							(call @@"pollcodes" 0 0 0x100 0x40 0x80 0x20) ; Call the pollcodes contract returns address of requested poll to [0x80]

							;Construct linked list entry
							[[@0x80]](CALLER) ;Stick contract in first slot
							[[(+ @@0x16 1)]] @0x80 ;Set previous head to point here
							[[0x16]]@0x80 ;Set the new head to point here
						}
					)
				}
			)
		}
	)
}