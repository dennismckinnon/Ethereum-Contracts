;Random Number generation DAO

;Method: Someone will request a random number and  (for now) a number of rounds until it gets returned to them
;(which requires a second call because ALARM is not implemented)
;Once a request has been added.
;
;A set of 5 people will be choosen for the draw

;request linked list structure NOTE: Linked list structure is only so JS interface can find ballots
;@SHA3(timestamp)
;s0 Requesting address
;s1 previous entry
;s2 next entry
;s3 return block
;s4 phase 1 block
;s5 number of participants
;s6 Person 1 address
;s7 Person 1 value
;etc.

;Active participants list structure
;@some slot (starting at @@0x13
;s1 Address

{

	[[0x10]] 0x17 ;current head
	[[0x11]]
	[[0x12]] 0 ;number of active participants.
	[[0x13]] 0x1A ;start of list
	[[0x14]] @@0x13 ; pointer to next free slot
	[[0x15]] 1ether ;Price per participant
	[[0x16]] 100ether ;Registration hostage

}
{
	;need to add in the phase switch time
	(when ( = (calldataload 0) "new") ;Requesting a new random number [Format: "new" #participants #block you want it by]
		{								;Participants less than 20 #blocks you want it by greater then 4
			[0x80](calldatload 0x20)
			[0xA0](calldatload 0x40)
			(unless (>= (CALLVALUE) (MUL @0x80 @@0x15)) (stop)) ;they didn't pay enough
			(when (< @0x80 4) [0x80]4) ;Set to soonest return time
			
			;Create new request entry (this needs to be in a linked list) (hash block number or something in order to get link list addresses
			[0x0] (TIMESTAMP)
			[0x0] (SHA3 0x0 0x20)
			[[@0x0]](CALLER) ;Store caller at first slot (s0)
			[[(+ @0x0 1)]] @@0x10 ;previous pointer
			[[(+ @@0x10 2)]]@0x0 ;Set previous pointer to this new entry
			[[(+ @0x0 3)]] (+ (NUMBER) @0x80) ;return block
			[[(+ @0x0 4)]] (+ (NUMBER) (DIV @0x80 2)) ;phase 1 start 
			[[(+ @0x0 4)]] @0xA0 ;number of participants
			[[0x10]]@0x0 ;Change current head tracker
			
			;Choose participants
			[0x40](+ (MOD (SHA3 0x0 0x20) @@0x12) @@0x13) ;Starting point in list of participants
			[0x100] (SHA3 0x0 0x60) ;Filter
			[0xE0](+ (MUL 3 @0x80) 6) ;limit
			(for [0x20]6 (< 0x20 @0xE0) [0x20](+ @0x20 3)
				{
					[0x60] 1 ;Flag
					(while @0x60
						{
							[0x100](SHA3 0x100 0x20) ;mix it up (EXPENSIVE! but ensures with higher probability that 5 will be found)
							(when (MOD @0x100 @@ @@ @0x40) ;Reputation is a number [1,2^255-1] lower is better. 1/rep is change you go
								{
									;Someone has been found
									[[(+ @0x0 @0x20)]]@@ @0x40 ;Copy person from participants list to linked list.
									[0x60]0 ;flip flag
								}
							)
							[0x40](+ @0x40 1) ;Increment pointer in user list
							(when (>= @0x40 @@0x14) [0x40]@@0x13) ; if they go off the end of the list. loop to start.
						}
					)
				}
			)
			(return 0x0 0x20) ;return the entry number (for future look up)
		}
	)
	
	(when (= (calldataload 0) "submit") ;Format ["submit" 0xrequestballot value]
		{
			[0x0](calldataload 0x20) ;request entry
			[0x20](calldataload 0x40) ;submitted value
			;get phase
			[0x40]@@(+ @0x0 3) ;Is is still running?
			(unless (<= (NUMBER) @0x40) (stop)) ;if the ballot does not exist this will fail always
			[0x40]@@(+ @0x0 4) ;phase 1?
			
			;find user in list
			[0x60]1
			[0x80]6
			[0xE0](+ (MUL 3 @@(+ @0x0 5)) 6) ;Get the upper bound to check
			(while (AND @0x60 (< 0x80 @0xE0)) 
				{
					;Search for user (if not found then stop)
					[0xA0] @@(+ @0x0 @0x80)
					(when (= (CALLER) @@ @0xA0) [0x60]0)
					[0x80](+ @0x80 3)
				}
			)
			(when @0xA0 (STOP)) ;They are not in this ballot
			[0xA0]@@(+ @0xA0 1)
			(if (<=(NUMBER) @0x40)
				{
					;Initial phase
					(unless @@ @0xA0 [[@@ @0xA0]]@0x40) ;Store the value
				}
				{
					[0xC0](SHA3 0x20 0x20)
					;Reveal phase
					(if (AND @@ @0xA0 (= @@ @0xA0 @0xC0)) ;non-zero entry in slot and the value sent hashes to previous commitment
						{
							;They have done everything correctly
							[[@0xA0]]@0x20 ;Copy value over
							[[(+ @0xA0 1)]] 1 ;set flag that they submitted hash
						}
						{
							;They messed up
							[[@0xA0]]0 
						}
					)
				}
			)
		}
	)
	
	(when (= (calldataload 0) "get") ;Format ["get" #request number]
		{
			;Claim your random number (it will take the first one in the list)
			;run through list. delete entry. return value
			[0x0](calldataload 0x20)
			(unless (AND (> (NUMBER) @@(+ @0x0 3)) (= @@ @ 0x0 (CALLER))) (stop)) ;Must be the request maker AND it must be ready
			
			;Process data and return
			[0x80]@@(+ @0x0 5) ;Number of participants
			[0xE0](+ (MUL 3 @0x80) 6) ;limit
			[0x100]0x120 ;pointer
			(for [0x20]6 (< 0x20 @0xE0) [0x20](+ @0x20 3)
				{
					[@0x100]@@(+ (+ @0x0 @0x20) 1) ;copy value into memory
					[0x100](+ @0x100 0x20) ;Increment pointer
					(if @@(+ (+ @0x0 @0x20) 2)
						{
							(when (> @@ @@(+ @0x0 @0x20) 1)
								[[@@(+ @0x0 @0x20)]](- @@ @@(+ @0x0 @0x20) 1) ;they failed they get a reputation boost
							)
							[[(+ @@(+ @0x0 @0x20) 2)]](+ @@(+ @@(+ @0x0 @0x20) 2) @@0x15) ;Increase the user's balance 
						}
						{
							[[@@(+ @0x0 @0x20)]](+ @@ @@(+ @0x0 @0x20) 1) ;they failed they get a reputation penalty
						}
					)
					;Delete values
					[[(+ @0x0 @0x20)]]0
					[[(+ (+ @0x0 @0x20) 1)]]0
					[[(+ (+ @0x0 @0x20) 2)]]0
				}
			)
			[0x100](SHA3 0x120 @0x100)
			;delete and relink
			[[(+ @@ (+ @0x0 1) 2)]]@@(+ @0x0 2) ;Set previous next to this next
			(when @@(+ @0x0 2) [[(+ @@ (+ @0x0 2) 1)]]@@(+ @0x0 1)) ;Set next previous to this previous
			[[@0x0]]0
			[[(+ @0x0 1)]]0
			[[(+ @0x0 2)]]0
			[[(+ @0x0 3)]]0
			[[(+ @0x0 4)]]0
			[[(+ @0x0 5)]]0 ;Clear out
			(return 0x100 0x20) ;Return the random number
		}
	)
	
	(when (= (calldataload 0) "register")
		{
			;register a new active participant (if they don't exist create them)
			(if @@CALLER
				{
					;Caller already exists, Add then to the active list directly
					[[@@0x14]](CALLER)
					[[(+ (CALLER) 1)]]@@0x14 ;pointer to where they are in the list
					[[0x14]](+ @0x14 1)
				}
				{
					;If they don't exist.. it costs 
					(when (< (CALLVALUE) @@0x16) (stop)) ;make sure they have the registration fee.
					
					[[(CALLER)]] 1 ;Initiate reputation (perfect to start)
					
					[[@@0x14]](CALLER)
					[[(+ (CALLER) 1)]]@@0x14 ;pointer to where they are in the list (for dereging
					[[0x14]](+ @0x14 1)
				}
			)
		}
	)
	
	(when (= (calldataload 0) "deregister")
		{
			;deregister an existing active participant
		}
	)
}