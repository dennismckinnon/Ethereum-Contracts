;Random Number generation DAO

;Method: Someone will request a random number and  (for now) a number of rounds until it gets returned to them
;(which requires a second call because ALARM is not implemented)
;Once a request has been added.
;
;A set of 5 people will be choosen for the draw

;request linked list structure
;@SHA3(timestamp)
;s0 Requesting address
;s1 next entry
;s2 return time
;s3 initiate block
;s4 phase [0 - accepting hashed values, 1 - accepting true values
;s5 Person 1 address
;s6 Person 1 value
;s7 person has submitted correct second piece
;etc.

;Active participants list structure
;@some slot (starting at @@0x13
;s1 Address

{

	[[0x10]] 0x17 ;current head
	[[0x11]]
	[[0x12]] 0 ;number of active participants.
	[[0x13]] 0x19 ;start of list
	[[0x14]] 0x19 ; pointer to next free slot
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
			[0x0] SHA3(TIMESTAMP) ;WRONG
			[[(+ @@0x10 1)]]@0x0 ;Set previous pointer to this new entry
			[[@0x0]](CALLER) ;Store caller at first slot (s0)
			
			;Choose participants
			[0x40](+ (MOD (SHA3 0x0 0x20) @@0x12) @@0x13) ;Starting point in list of participants
			[0x0] (SHA3 0x0 0x60) ;Filter
			[0xE0](+ (MUL 2 @0x80) 6) ;limit
			(for [0x20]6 (< 0x20 @0xE0) [0x20](+ @0x20 2)
				{
					[0x60] 1 ;Flag
					(while @0x60
						{
							[0x0](SHA3 0x0 0x20) ;mix it up (EXPENSIVE! but ensures with higher probability that 5 will be found)
							(when (MOD @0x0 @@ @@ @0x40) ;Reputation is a number [1,2^255-1] lower is better. 1/rep is change you go
								{
									;Someone has been found
									[[(+ @0x0 @0x20)]]@@ @0x40 ;Copy person from participants list to linked list.
									[0x60]0 ;flip flag
								}
							)
							[0x40](+ @0x40 2) ;Increment pointer in user list
							(when (>= @0x40 @@0x14) [0x40]@@0x13) ; if they go off the end of the list. loop to start.
						}
					)
				}
			)
		}
	)
	
	(when (= (calldataload 0) "submit")
		{
		
		}
	)
	
	(when (= (calldataload 0) "get")
		{
			;Claim your random number (it will take the first one in the list)
			;run through list. delete entry. return value
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
					[[(+ (CALLER) 1)]]@@0x14 ;pointer to where they are in the list
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