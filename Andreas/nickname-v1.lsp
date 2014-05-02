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
;"reg" "name" - register nickname "name" to sender if possible. Returns 1 if successful.
;"dereg" - deregister the nickname held by the caller (if any).
;"dereg" "name" - deregister the nickname "name". This is ADMIN ONLY, and can only be done to non-admin nicks. Returns 1 if successful.
;"getnick" address - returns the nick belonging to the provided address, if any.
;"getaddr" "nick" - returns the address belonging to the given nick.
;"kill" - kills the contract 
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
	;For DOUG integration
	[[0x10]] 0xfc87f9b92b37b9b6133a22ff3352f72996de77eb ;Doug Address
	;List data section
	[[0x11]] 0x0										;Size of list
	[[0x12]] 0x0										;Tail address
	[[0x13]] 0x0										;Head address
	
	[0x0] "reg"
	[0x20] "nick"
	(call @@0x10 0 0 0x0 0x40 0x0 0x20) ;Register with DOUG

	;Create a 'dummy' nick to use as permanent list tail. It never goes away, which means we never have
	;to check if the list is empty when adding or removing elements (saves some processing). 
	;This permanent tail is the nick made from the address of the contract itself.
	[0x40] "NickContract"
	[[@0x40]] (ADDRESS)
	[[(ADDRESS)]] @0x40
	[[0x11]] 1				;Set list size to 1.
	[[0x12]] @0x40 			;Set head and tail to the address corresponding to the hard coded contract nick.
	[[0x13]] @0x40
}
{

	[0x0]"req"
	[0x20] "doug"
	(call @@0x10 0 0 0x0 0x40 0x0 0x20)
	[[0x10]]@0x0 ;Copy new doug over

	; Call doug to get the address to the user level.
	[0x40] "req"
	[0x60] "user"
	; Store the address of "user" in 0x80
	(call @@0x10 0 0 0x40 0x40 0x80 0x20)

	;If there's at least one argument, we try and register. Store the name string at memory address 0x20
	[0x0] (calldataload 0)	;This is the command
	[0x20] (calldataload 0x20)	;This is the name

	(when (AND (= @0x0 "kill") (= (CALLER) @@0x1) ) (suicide (CALLER)) ) ;Kill option
	
	(when (AND (= @0x0 "reg") (> @0x20 0x20)) ;Command "reg" and make sure it won't overwrite important data 
		{
			; Don't let people register their address as their user name. That's just weird.
			(when (= (CALLER) @0x20 ) (stop) )
			;Stop if the caller already has a nick.
			(when @@(caller) (stop))
			;Stop if the name address is non-empty (nick already taken)
			(when @@ @0x20 (stop))
			;Stop if the name address + 1 is non-empty
			(when @@(+ @0x20 1) (stop))
			;Stop if the name address + 2 is non-empty
			(when @@(+ @0x20 2) (stop))

			;Store sender at name, and name at sender.
			[[@0x20]] (caller)
			[[(caller)]] @0x20

			;Update the list. First set the 'next' of the current head to be this one.
			[[(+ @@0x13 2)]] @0x20
			;Now set the current head as this ones 'previous'.
			[[(+ @0x20 1)]] @@0x13
			;And set this as the new head.
			[[0x13]] @0x20
			;Increase the list size by one.
			[[0x11]] (+ @@0x11 1)
			
			; Call user contract to check if the caller address is already registered as a user.
			[0x40] "check"
			[0x60] (CALLER)
			; Store the permission level of caller in 0x40
			(call @0x80 0 0 0x40 0x40 0x40 0x20)
			
			; If user is not registered - add him as a normal member, otherwise do nothing.
			(when (= @0x40 0) 
				{
					[0x40] "regmem"
					[0x60] (CALLER)
					(call @0x80 0 0 0x40 0x40 0x0 0x20)
				}
			)
			;Return the value 1 for a successful register
			[0x0] 1
			(return 0x0 0x20)
		} ;end body of when
	); end when

	(when (AND (= @0x0 "dereg") (= @0x20 0) )  ;When de-regging a users own nick (no nick param).
		{

			(when @@(caller)
				{
    	
					[0x20] @@(+ @@(caller) 1) ; Here we store the address contained in this ones 'previous'.
					[0x40] @@(+ @@(caller) 2) ; And the address to 'next'.
					;Change previous elements 'next' to this ones 'next', if this one has a next (this could be the head..)
					(if @0x40
						{
							;Change next elements 'previous' to this ones 'previous'.
							[[(+ @0x40 1)]] @0x20
							;Change previous elements 'next' to this ones 'next'.
							[[(+ @0x20 2)]] @0x40
							;Don't change the head, as this cannot have been the head.
						}
						;If this element is the head - unset 'next' for the previous element making it the head.
						{
							[[(+ @0x20 2)]] 0
							;Set previous as head
							[[0x13]] @0x20
						}
					)

					;Now clear out this element and all its associated data.
					[0x80] @@(caller)	;Temp storage for caller name
					[[@0x80]] 0			;The address of the name
					[[(+ @0x80 1)]] 0	;The address for its 'previous'
					[[(+ @0x80 2)]] 0	;The address for its 'next'
					[[(caller)]] 0		;The actual address
      				

					;We now deregister the caller from the user contract.
                    [0x40] "delmem"
					[0x60] (CALLER)
					(call @0x80 0 0 0x40 0x40 0x0 0x20)
					
					;Decrease the size counter
					[[0x11]] (- @@0x11 1)
					[0x0] 1
					(return 0x0 0x20)

				} ; end when body
			) ;end when 

			(stop)
		
  		} ;end body of when
	) ;end when

	(when (AND (= @0x0 "dereg") (> @0x20 0x20) ) ; When de-regging by name.
		{
			;First we make sure that the user owning the nick is not an admin,
			;then we make sure that the deleter (caller) is an admin.

            [0x40] "check"
			[0x60] @@ @0x20
			(call @0x80 0 0 0x40 0x40 0x100 0x20)

			(unless (< @0x100 3) (stop) )

			[0x40] "check"
			[0x60] (caller)
			(call @0x80 0 0 0x40 0x40 0x100 0x20)

			(unless (> @0x100 1) (stop) )
			

			[0x40] @@(+ @0x20 1) ; Here we store the this ones 'previous' (which always exists).
			[0x60] @@(+ @0x20 2) ; And next
		
			;Change previous elements 'next' to this ones 'next', if this one has a next (this could be the head..)
			(if @0x60
				{
					;Change next elements 'previous' to this ones 'previous'.
					[[(+ @0x60 1)]] @0x40
					;Change previous elements 'next' to this ones 'next'.
					[[(+ @0x40 2)]] @0x60
					;Don't change the head, as this cannot have been the head.
				}
				;If this element is the head - unset 'next' for the previous element making it the head.
				{
					[[(+ @0x40 2)]] 0
					;Set previous as head
					[[0x13]] @0x40
				}
			)

			;Now clear out this element and all its associated data.
			
			[[@@ @0x20]] 0		;The actual address
			[[@0x20]] 0			;The address of the name
			[[(+ @0x20 1)]] 0	;The address for its 'previous'
			[[(+ @0x20 2)]] 0	;The address for its 'next'
      			

			;We now deregister the nick owner from the user contract.
            [0x40] "delmem"
			[0x60] @0x20
			(call @0x80 0 0 0x40 0x40 0x0 0x20)
					
			;Decrease the size counter
			[[0x11]] (- @@0x11 1)
			[0x0] 1
			(return 0x0 0x20)

		} ; end when body
	) ;end when
	
};end of program

