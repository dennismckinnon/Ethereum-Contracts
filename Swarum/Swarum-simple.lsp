;API
;
; New Thread 	- Permission Required: 0 (Can set to 1 if we want to restrict posting)
;				- Form: "newt" "Title"
;				- Returns: 0/1 (fail/succeed)
;
; New Post 		- Permission Required: 0 (Can set to 1 if we want to restrict posting)
; 				- Form: "newp" 0xThreadIdentifier #TorrentSha1
;				- Returns: 0/1 (fail/succeed)
;


;0xThreadIdentifier = Sha3(CALLER:NUMBER:TITLE) (Should this value be invalid)
;0xPostIdentifier = Sha3(CALLER:NUMBER:CALLDATA)


;Structure
;
;Threads Linked list
;
;@@0xThreadIdentifier : 0xCreatorAddress
;+1 : 0xPreviousThread
;+2 : Title[0,1F]
;+3 : Title[20,3F] (Title can be a max of 64 Bytes)
;+4 : number of posts
;+5 : Pointer to newest post
; More info can be added here If we need it

;@@0xPostIdentifier : 0xOlderPost
;+1 : 0xCreatorAddress
;+2 : Sha1 value for torrent
;+3 : cont.


{
	[[0x11]] 0x16 ;Threads list start
	[[0x12]] 0    ;Number of threads

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
					  (= @@(+ @0x0 4) 0) (= @@(+ @0x0 5) 0)) (STOP)) ; Check there is space

			;Create thread entry
			[[@0x0]](CALLER)
			[[(+ @0x0 1)]]@@0x12 ;Pointer to next newest thread
			[[(+ @0x0 2)]](calldataload 0x20)
			[[(+ @0x0 3)]](calldataload 0x40) ;Title

			;Link to list
			[[0x11]]@0x0 ;Set newest pointer to this entry 
			[[0x12]](+ @0x12 1) ;Increment number of threads counting

			[0x20]1
			(return 0x20 0x20) ;Return that it succeeded
		}
	)

;---------------------------------------------------------------------------------------
; New Post 		- Permission Required: 0 (Can set to 1 if we want to restrict posting)
; 				- Form: "newp" 0xThreadIdentifier TorrentSha1
;				- Returns: 0/1 (fail/succeed)
	(when (= (calldataload 0) "newp")
		{
			(unless (&& (calldataload 0x20) @@(calldataload 0x20) (= (MOD (calldataload 0x20) @@0x13) 0)) (STOP)) ;0xThread must be provided and valid

			[0x0](CALLER)
			[0x20](NUMBER)
			(calldatacopy 0x40 0x0 (CALLDATASIZE))
			[0x0](ADD (MUL (DIV (SHA3 0x0 (+ (CALLDATASIZE) 0x40)) @@0x13) @@0x13) @@0x14) ;Construct 0xPostAddress

			(unless (&& (= @@ @0x0 0) (= @@(+ @0x0 1) 0) (= @@(+ @0x0 2) 0) (= @@(+ @0x0 3) 0)) (STOP)) ;Free Space checking

			;Fill in Post entry
			[[@0x0]]@@(+ (calldataload 0x20) 6) ;Point to previous newest
			[[(+ @0x0 1)]](CALLER)
			[[(+ @0x0 2)]](calldataload 0x40) ;Store the torrent data
			[[(+ @0x0 3)]](calldataload 0x60)

			;Link post
			[[(+ (calldataload 0x20) 5)]]@0x0 ;set this as newest
			[[(+ (calldataload 0x60) 4)]](+ @@(+ (calldataload 0x20) 4) 1) ;Increment number of posts in thread

			[0x0]1
			(return 0x0 0x20)
		}
	)
}