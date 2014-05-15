;API
;
; New Thread 	- Permission Required: 0 (Can set to 1 if we want to restrict posting)
;				- Form: "newt" "Title"
;				- Returns: 0/1 (fail/succeed)
;
; New Post 		- Permission Required: 0 (Can set to 1 if we want to restrict posting)
; 				- Form: "newp" 0xThreadIdentifier | Other data
;				- Returns: 0/1 (fail/succeed)
;

;Having second thoughts about these ones. Maybe we want to implement something more
;interesting. After all just because you delink the entry from the list doesn't mean
;people HAVE to delete the file. Infact the conversation can continue anyways.
;you could delete the header which would make it impossible for the thread to continue
;We can discuss this in more detail. Maybe Admins simply function to clean out spam
;In which case we could implement an admin's ignore list. Not mandatory to ignore
;but you won't download them automatically unless you really want to.
;################################################################################
; Delete Thread - Permission Required: 2 or original Creator
; 				- Form: "delt" 0xThreadIdentifier
; 				- Returns: 0/1 (fail/succeed)
;
; Delete Post 	- Permission Required: 2 or original creator
; 				- Form: "delp" 0xPostIdentifier
; 				- Returns: 0/1 (fail/succeed)
;################################################################################

;0xThreadIdentifier = Sha3(CALLER:NUMBER:TITLE) (Should this value be invalid)
;0xPostIdentifier = Sha3(CALLER:NUMBER:CALLDATA)

;Structure
;
;Threads Linked list
;The threads linked list starts @@0x13, @@0x11 stores starting point, @@0x12 stores current end
;Format for a threads entry is:
;
;@@0xThreadIdentifier : 0xCreatorAddress
;+1 : 0xPreviousThread
;+2 : 0xNextThread
;+3 : Title[0,1F]
;+4 : Title[20,3F] (Title can be a max of 64 Bytes)
;+5 : Pointer to first post
;+6 : Pointer to last post
; More info can be added here If we need it

;@@0xPostIdentifier : 0xCreatorAddress
;+1 : 0xPreviousPost
;+2 : 0xNextPost
;... Store torent data here

;TODO
;Properly structure post entries for torent data
;Use offsets to avoid conflicts

{
	;[[0x10]] 0xDougaddress ;Doug's address for later
	[[0x11]] 0x13 ;Threads Tail
	[[0x12]] 0x13 ;Threads head

	[[0x13]] 0x100000
	[[0x14]] 0x10000


}
{


;-------------------------------------------------------------------------------------
; New Thread 	- Permission Required: 0 (Can set to 1 if we want to restrict posting)
;				- Form: "newt" "Title(64B)"
;				- Returns: 0/1 (fail/succeed)

	(when (= (calldataload 0) "newt")
		{
			[0x0](CALLER)
			[0x20](NUMBER)
			[0x40](calldataload 0x20)
			[0x60](calldataload 0x40)
			[0x0](MUL (DIV (SHA3 0x0 0x80) @@0x13) @@0x13) ;Construct 0xThreadIdentifier

			(unless (&& (= @@ @0x0 0) (= @@(+ @0x0 1) 0)
					 (= @@(+ @0x0 2) 0) (= @@(+ @0x0 3) 0)
					  (= @@(+ @0x0 4) 0) (= @@(+ @0x0 5) 0)
					   (= @@(+ @0x0 6) 0)) (STOP)) ; Check there is space

			;Create thread entry
			[[@0x0]](CALLER)
			[[(+ @0x0 1)]]@@0x12 ;Previous is current head
			[[(+ @0x0 3)]](calldataload 0x20)
			[[(+ @0x0 4)]](calldataload 0x40) ;Title
			[[(+ @0x0 5)]](+ @0x0 4)

			;Link to list
			[[(+ @@0x12 2)]]@0x0 ;Set the previous thread's next pointer to here
			[[0x12]]@0x0 ;Set head to here

			[0x20]1
			(return 0x20 0x20) ;Return that it succeeded
		}
	)

;---------------------------------------------------------------------------------------
; New Post 		- Permission Required: 0 (Can set to 1 if we want to restrict posting)
; 				- Form: "newp" 0xThreadIdentifier | Other data
;				- Returns: 0/1 (fail/succeed)
	(when (= (calldataload 0) "newp")
		{
			(unless (&& (calldataload 0x20) @@(calldataload 0x20) (= (MOD (calldataload 0x20) @@0x13) 0)) (STOP)) ;0xThread must be provided and valid

			[0x0](CALLER)
			[0x20](NUMBER)
			(calldatacopy 0x40 0x0 (CALLDATASIZE))
			[0x0](ADD (MUL (DIV (SHA3 0x0 (+ (CALLDATASIZE) 0x40)) @@0x13) @@0x13) @@0x14) ;Construct 0xPostAddress

			[0x20](+ (DIV (CALLDATASIZE) 0x20) 5) ;Number of addresses to check (this can swapped out for hardcoding later)
			(for [0x40]0 (<= @0x40 @0x20) [0x40](+ @0x40 1) ;check if there is enough space
				{
					(unless (= @@(+ @0x0 @0x40) 0) (STOP))
				}
			)

			;Fill in Post entry
			[[@0x0]](CALLER)
			[[(+ @0x0 1)]]@@(+ (calldataload 0x20) 6) ;Point to current head
			[[(+ @0x0 3)]]@0x20 ;how many dataslots are being used
			[0x60]0x60
			(for [0x40]4 (<= @0x40 @0x20) [0x40](+ @0x40 1)
				{
					[[(+ @0x0 @0x4)]](calldataload @0x60) ;copy over calldata
					[0x60](+ @0x60 0x20) ;increment pointer
				}
			)

			;Link post
			[[(+ @@(+ (calldataload 0x20) 6) 2)]]@0x0 ;set previous next to here
			[[(+ (calldataload 0x20) 6)]]@0x0 ;set head to here

			[0x0]1
			(return 0x0 0x20)
		}
	)

}