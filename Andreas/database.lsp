; Database

; This contract is used to register entries into a database. Entries are stored in a linked list, and
; are given addresses in two different ways. If no entries has been deleted previously, it will just
; keep increasing an address counter (by the size of an entry), and give the new entry that space.
; If an entry has been previously deleted, it will be . The pool makes the list re-use the memory locations 
; of old deleted entries.
;
; Based on the database-v2.lsp by DennisMcKinnon
; (https://github.com/dennismckinnon/Ethereum-Contracts/blob/master/DOUG/Database-v2.lsp)

; Data format
;
; 0 - 31		Meta: address to tail (address, 1 seg)
; 32 - 63		Meta: address to head (address, 1 seg)
; 64 - 95: 		User nick (string, 1 seg)
; 96 - 127: 	Date of creation (string, 1 seg)
; 128 - 159:	Last update date (string, 1 seg)
; 160 - 223:	Title (string, 2 seg)
; 224 - 1247: 	Text (string, 32 segs (1024 bytes)).
;
; Total size: 39 segments (1,248 kb)

; API
;
; "insert" payload - insert a new database entry.
; "modify" payload - insert a new database entry.
; "delete" address - delete database entry at the given address.
; "kill" - kills the contract.
;
; payload should be the data in "insert" (starting with nick). It should be
; the data address + data in "modify", and just the data address in "delete"
;
; NOTE: None of the address pool stuff is (or needs to be) exposed to users.

;INIT
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
	[[0x7]] "store data."

	;For DOUG integration
	[[0x10]] 0x701f77d1566c687cc02883fb87be4f63bd9ebfb1 ;Doug Address

	;Pooled address section
	[[0x11]] 0x0   	;Size of pool list
	[[0x12]] 0x19	;Pointer to last added address (0x20 is the real start, 0x19 is "faux", and is never referenced)

	[[0x13]] 0x10020	;Current next address. If pool is empty, add new entries to this address.
						;this allows for 2^16 memory pool addresses (starting counting at 0x20).
	[[0x14]] 2			;Data contents offset from address (data and data + 1 contains meta stuff)
	;Data section
	[[0x15]] 39			;Size of a data element (in storage addresses).
	[[0x16]] 0x0		;Number of data entries
	[[0x17]] 0x0		;Current tail
	[[0x18]] 0x0		;Current head
	
	[0x0] "reg"
	[0x20] "database5"
	(call @@0x10 0 0 0x0 0x40 0x0 0x20) ;Register with DOUG

}
;BODY
{
	; Call doug to get the address to the user level.
	[0x40] "req"
	[0x60] "userdata"
	; Store the address of "userdata" in 0x80
	(call @@0x10 0 0 0x40 0x40 0x80 0x20)

	;If there's at least one argument, we try and register. Store the name string at memory address 0x20
	[0x0] (calldataload 0)	;This is the command
	[0x20] (calldataload 32)	;This is the nickname, or sometimes an address.

	(when (AND (= @0x0 "kill") (= (CALLER) @@0x1) ) (suicide (CALLER)) ) ;Kill option
	
	(when (AND (= @0x0 "insert") (> @0x20 0) ) ;When inserting an entry.
		{
			;Call the nick contract to get the user nick.	
			[0x100] "getnick"
			[0x120] (caller)
			(call @0x80 0 0 0x100 0x40 0x140 0x20)
			
			(unless (> @0x140 0) (stop) ) ;If caller does not have registered nick, they can't add data.

			; TODO add checks here to ensure the time data etc. is valid.

			;Check if the address pool has any addresses in it that we can use.
			(if (> @@0x11 0) ; If pool list has elements in it
				{
					[0x200] @@ @@0x12 ;The address where this entry will be put.
					[0x220] (calldataload 20)
					;Decrease pointer and size
					[[0x12]] (- @@0x12 1) 
					[[0x11]] (- @@0x11 1) 					
				}
				{
					;If there are no pooled addresses, assign from 0x13 and increment by the size of a data entry.
					[0x200] @@0x13
					[[0x13]] (+ @@0x13 @@0x15)
				}
			)

			;The address [0x200] is now assigned to this data.

			[0x220] (+ @0x200 2) ;Use this as a variable, initialize with the slot for nick.

			[[@0x220]] @0x20 					; Add the nick.
			[0x220] (+ @0x220 1)				; Increment pointer

			[0x300] 64 ;calldataload number
			 copy calldataload to storage
			(for [0x320]0 (< @0x320 37) [0x320](+ @0x320 1)
				{
					[[@0x220]] (calldataload @0x300) ; grab from calldataload
					;Increment
					[0x220] (+ @0x220 1)
					[0x300] (+ @0x300 32)
				}
			)
			
			;Add this element as the current head to the data list.

			(if @@0x16 ; If the list of data is non-empty
				{
					;Update the list. First set the 'next' of the current head to be this one.
					[[(+ @@0x18 2)]] @0x200
					;Now set the current head as this ones 'previous'.
					[[(+ @0x200 1)]] @@0x18
					;And set this as the new head.
					[[0x18]] @0x200
					;Increase the list size by one.
					[[0x16]] (+ @@0x16 1)
					;Return the value 1 for a successful register
					[0x0] 1
					(return 0x0 0x20)
				}
				{
					;If the data list is empty, add this as current head and tail.
					[[0x17]] @0x200
					[[0x18]] @0x200
					[[0x16]] 1
				}
			)
		} ;end body of when
	); end when

	
	(when (AND (= @0x0 "modify") (> @0x20 0) ) ;When modifying an entry.
		{
			; [0x20] is now the address of the data entry.
			; See if there is data at that address (a nick in the nick slot).

			[0x60] @@(+ @0x20 (* @0x14 32) )
			(unless  @0x60 (stop) )   

			;Call the userdata contract to get the user nick.
			[0x100] "getnick"
			[0x120] (caller)
			(call @0x80 0 0 0x100 0x40 0x80 0x20)
			
			(unless (= @0x60 @0x80) (stop) ) ;If user nick isn't the nick of the data owner, abort.

			; TODO add checks here to ensure the time data etc. is valid.

			[0x200] @0x20 ;Just to be consistent with the loop used in "insert" (copy/paste...)

			;The address [0x200] is now assigned to this data.

			[0x220] (+ @0x200 2) ; Use this as a variable, initialize with the slot for nick.
			
			[0x300] 64 ;calldataload number

			; copy calldataload to storage
			(for [0x320]0 (< @0x320 37) [0x320](+ @0x320 1)
				{
					[[@0x220]] (calldataload @0x300) ; grab from calldataload
					;Increment
					[0x220] (+ @0x220 1)
					[0x300] (+ @0x300 1)
				}
			)
			
		} ;end body of when
	); end when


	(when (AND (= @0x0 "delete") (> @0x20 0x20) ) ; When deleting a post.
		{
			
			; [0x20] is now the address of the data entry.
			; See if there is data at that address (a nick in the nick slot).

			[0x60] @@(+ @0x20 (* @0x14 32) )
			(unless  @0x60 (stop) )   

			;Call the userdata contract to get the user nick.
			[0x100] "getnick"
			[0x120] (caller)
			(call @0x80 0 0 0x100 0x40 0x80 0x20)
			
			;Call the userdata contract to get user permissions
			[0x100] "getpriv"
			[0x120] @0x80
			(call @0x80 0 0 0x100 0x40 0x100 0x20)
			
			; If caller nick is not the poster nick, and caller is not an admin - abort.
			(when (!= @0x60 @0x80) 
				{
					(unless (> @0x100 1) (stop))
				} 
			)

			[0x200] @0x20 ;Just to be consistent with the loop used in "insert" (copy/paste...)

			;The address [0x200] is now assigned to this data.

			[0x220] (+ @0x200 2); Use this as a variable, initialize with the slot for nick.

			; clear the data
			(for [0x320]0 (< @0x320 37) [0x320](+ @0x320 1)
				{
					[[@0x220]] 0;
					;Increment
					[0x220] (+ @0x220 1)
				}
			)

			; Now clear the data from the data list.

			[0x40] @@ @0x200 ; Here we store the this ones 'previous'.
			[0x60] @@(+ @0x200 1) ; And next
			
			(if (AND (= @0x40 0) (= @0x60 0)) ;If this is the only element in the list.
				{
					; Clear the list completely.
					[[0x17]] 0
					[[0x18]] 0 
				}
				{
					;Change previous elements 'next' to this ones 'next', if this one has a next (this could be the head..)
					(if @0x60
						{
							;Change next elements 'previous' to this ones 'previous'.
							[[@0x60]] @0x40
							
							(when @0x40 
								{
									;Change previous elements 'next' to this ones 'next'.
									[[(+ @0x40 1)]] @0x60
								}
							)
							;Don't change the head, as this cannot have been the head.
						}
						;If this element is the head - unset 'next' for the previous element making it the head.
						{
							(when @0x40 
								{
									[[(+ @0x40 1)]] 0
									;Set previous as head
									[[0x18]] @0x40
								}
							)
						}
					)
				}
			)

			;Decrease the size counter
			[[0x16]] (- @@0x16 1)

			;Clear out this element fully, and add its address to the address pool, and increase address pool size.

			[0xB0] @@0x12 ;This would be a 0x20+ address, containing the current last added free address.
			[0xD0] (+ @@0x12 1) ;The next address.
			[[@0xD0]] @0x200 ;Set the contents of the next address to be this address
			[[0x12]] @0xD0  ;Set the latest added address to be next.
			[[0x11]] (+ @@0x16 1) ;Increment the size of the memory pool.
			
			[[@0x20]] 0			;The address (containing 'previous')
			[[(+ @0x20 1)]] 0	;The address for its 'next'
			
			[0x0] 1
			(return 0x0 0x20)

		} ; end when body
	) ;end when
	
};end of program

