;Nickname generator

;This contract is used to register a nickname with a ethereum address. The nick is registered
;at 0xADDRESS, and the address is registered at the address corresponding to the name string.
;There is a linked list system connecting user names, to make it possible to list all currently
;registered names.


; LINKED LIST MECHANICS
; 0x11 contains the size of the list.
; 0x12 contains a reference to the current tail.
; 0x13 contains a reference to the current head.
; 
; Each list element contains three addresses - the first one is the element address,
; which is based on the name. The second one is the address + 1, which contains a
; reference to the previous element. The third one is address + 2, which contains
; a reference to the head.

;API
;
;"reg" "name" - register nickname  "name" to sender if possible
;"dereg" "name" - deregister the nickname
;"kill" - kills the contract 

;Structure
;Admin list
;address:permission value

{
	;Metadata  section
	[[0x0]] 0x88554646AB								;metadata notifier
	[[0x1]] (CALLER)									;contract creator
	[[0x2]] "Andreas Olofsson"							;contract Author
	[[0x3]] 0x20042014									;Date
	[[0x4]] 0x000001000									;version XXX.XXX.XXX
	[[0x5]] "Nickname Contract"							;Name
	[[0x6]] "12345678901234567890123456789012"			;Brief description (not past address 0xF)
	[[0x6]] "This Contract allows people to"
	[[0x7]] "create a nickname for himself,"
	[[0x8]] "to use in a DAO."

	[[0x10]] 0x6207fbebac090bab3c91d4de0f4264b3338982b9 ;Doug Address
	[[0x11]] 0x0										;Size of list
	[[0x12]] 0x0										;Tail address
	[[0x13]] 0x0										;Head address
	
	;[0x0] "reg"
	;[0x20] "nick"
	;(call @@0x10 0 0 0x0 0x40 0x0 0x20) ;Register with DOUG

	;Create a 'dummy' nick to use as permanent list tail. It never goes away, which means we never have
	;to check if the list is empty when adding or removing elements (which saves us some processing). 
	;This permanent tail is the nick made from the address of the contract itself.
	[0x40] "NickContract"
	[[@0x40]] (ADDRESS)
	[[(ADDRESS)]] @0x40
	[[0x11]] 1				;Set list size to 1.
	[[0x12]] @0x40 			;Set head and tail to the address corresponding to the hard coded contract nick.
	[[0x13]] @0x40
}
{
	;If there's at least one argument, we try and register. Store the name string at memory address 0x20
	[0x0] (calldataload 0)		;This is the command
	[0x20] (calldataload 0x20)	;This is the name

	(when (AND (= @0x20 "kill")(= (CALLER) @@0x1)) (suicide (CALLER))) ;Kill option

	(when (AND (= @0x0 "reg") (> @0x20 0x20)) ;Command "reg" and make sure it won't overwrite important data 
		{
			;Stop if the caller already has a nick.
			(when @@(caller) (stop))
			;Stop if the name address is non-empty (nick already taken)
			(when @@ @0x20 (stop))
			;Stop if the name address + 1 is non-empty
			(when @@(+ @0x20 1) (stop)
			;Stop if the name address + 2 is non-empty
			(when @@(+ @0x20 2) (stop)

			;Store sender at name, and name at sender.
			[[@0x20]] (caller)
			[[(caller)]] @0x20

			;Update the list. First set the "next" of the current head to be this name address.
			[[(+ @@0x13 2)]] @0x20
			;Now set the current list head as previous element in the 'previous' memory slot.     	
			[[@0x20 + 1]] @@0x13 
			;And set this as the current head
			[[0x13]] @0x20
			;This element is now the head. Increase the list size by one.
			[[0x11]] (+ @@0x11 1)

			[0x0] 1
			(return 0x0 0x20) ;Return the value 1 for a successful register

		} ;end body of block if there is an argument
	)

	(when (AND (= @0x0 "dereg")(> @0x20 0x20)) ;When they want to deregister and the nick is ins appropiate range
		{
			[0x0] 0
			; Otherwise, just de-register any name sender has, if they are registered.
			(when @@(caller)
				{
	    	
					[0x60] @@(+ @@(caller) 1) ; Here we store the address of 'previous', which always exists.
				
					;Change previous elements 'next' to this ones 'next', if this one has a next (this could be the head..)
					(if @@(+ @@(caller) 2)
						{
						;Change next elements 'previous' to this ones 'previous'.
						[0x80] @@(+ @@(caller) 2)
						[[(+ @0x80 1)]] @0x60
						[[(+ @0x60 2)]] @0x80
						;Don't change the head, as we removed a middle element.
						}
						;If this element is the head - unset 'next' for the previous element making it the head.
						{
						[[(+ @0x60 2)]] 0

						;Set previous as head
						[[0x13]] @0x20
						}
					)
		    		

					;Now clear out this element and all its associated data.

					[[@@(caller)]] 0		;The address of the name
					[[(+ @@(caller) 1)]] 0	;The address for its 'previous'
					[[(+ @@(caller) 2)]] 0	;The address for its 'next'
					[[(caller)]] 0			;The actual address
		      	
					;Decrease the size counter
					[[0x11]] (- @@0x11 1)
					[0x0] 1
		    	}
	    	) ;end when body
	    	(return 0x0 0x20) ;Return the result
	  	} ;end body of no argument block
	) ;end if block
	
};end of program





