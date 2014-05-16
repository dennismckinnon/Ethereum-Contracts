;API
;
; New Thread 	- Permission Required: 0 (Can set to 1 if we want to restrict posting)
;				- Form: "newt" "Title"
;				- Returns: 0/1 (fail/succeed)
;
; New Post 		- Permission Required: 0 (Can set to 1 if we want to restrict posting)
; 				- Form: "newp" 0xThreadIdentifier 0xData(64Bytes)
;				- Returns: 0/1 (fail/succeed)
;


;0xThreadIdentifier = Sha3(CALLER:NUMBER:TITLE) (Should this value be invalid)
;0xPostIdentifier = Sha3(CALLER:NUMBER:CALLDATA)
;0xPostIdentifier = [dn(20 Bytes),btih(10 Bytes),0000]


;Structure
;
;Threads Linked list
;
;The Threads linked list starts @@0x11 an pushes downward. So the newest thread will always
;be at the start of the list.
;
;Posts linked list
;The Posts linked list is attached to a Thread header which points to the newest post in the
;Thread. Similar to the threads linked list, further down the list = older posts.
;
;@@0xThreadIdentifier : 0xCreatorAddress
;+1 : 0xOlderThread
;+2 : 0xNewerThread
;+3 : Title[0,1F]
;+4 : Title[20,3F] (Title can be a max of 64 Bytes)
;+5 : number of posts
;+6 : Pointer to newest post
; More info can be added here If we need it

;@@0xData[0:30]0000 : 0xData[30:62]
;+1 : 0xOlderPost
;+2 : 0xCreator

;TODO:
;Reorder threads list to have the latest modified thread on top?

{
	[[0x11]] 0x16 ;This is an empty thread just to start the list. You can't post to it because its not good form
	[[0x12]] 0    ;Number of threads

	[[0x13]] 0x10000
	[[0x14]] 0x1000
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
			[[(+ @0x0 1)]]@@0x11 ;Pointer to next newest thread
			[[(+ @0x0 3)]](calldataload 0x20)
			[[(+ @0x0 4)]](calldataload 0x40) ;Title

			;Link to list
			[[(+ @@0x11 2)]]@0x0 ;set old's newer
			[[0x11]]@0x0 ;Set newest pointer to this entry 
			[[0x12]](+ @@0x12 1) ;Increment number of threads counting

			[0x20]1
			(return 0x20 0x20) ;Return that it succeeded
		}
	)

;---------------------------------------------------------------------------------------
; New Post 		- Permission Required: 0 (Can set to 1 if we want to restrict posting)
; 				- Form: "newp" 0xThreadIdentifier 0xDATA 64 bytes for btih and dn
;				- Returns: 0/1 (fail/succeed)
	(when (= (calldataload 0) "newp")
		{
			(unless (&& (calldataload 0x20) @@(calldataload 0x20) (= (MOD (calldataload 0x20) @@0x13) 0)) (STOP)) ;0xThread must be provided and valid

			[0x0](+ (MUL (DIV (calldataload 0x40) @@0x13) @@0x13) @@0x14) ;0xPostAddress

			(unless (&& (= @@ @0x0 0) (= @@(+ @0x0 1) 0) (= @@(+ @0x0 2) 0)) (STOP)) ;Free Space checking

			;Fill in Post entry
			[[@0x0]] (calldataload 0x5E) ;remainder of btih
			[[(+ @0x0 1)]]@@(+ (calldataload 0x20) 6)
			[[(+ @0x0 2)]](CALLER)

			;Link post
			[[(+ (calldataload 0x20) 6)]]@0x0 ;set this as newest
			[[(+ (calldataload 0x20) 5)]](+ @@(+ (calldataload 0x20) 5) 1) ;Increment number of posts in thread
			
			(unless (= @@0x11 (calldataload 0x20)) ;When this thread is not already at the top of the list, move it there 
				{
					[[(+ @@(+ (calldataload 0x60) 2) 1)]]@@(+ (calldataload 0x60) 1) ;set newer's older to this' older
					[[(+ @@(+ (calldataload 0x60) 1) 2)]]@@(+ (calldataload 0x60) 2) ;set older's newer to this' newer
					[[(+ (calldataload 0x20) 2)]]0 ;No newer
					[[(+ @@0x11 2)]](calldataload 0x20) ;set old's newer
					[[0x11]](calldataload 0x20) ;Set newest pointer to this entry
				}
			)
			[0x0]1
			(return 0x0 0x20)
		}
	)
}
