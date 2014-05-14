;PCM - ANY
;This PCM will add permissions as it gets approval. Agreement on all is not necessary

;Linked list structure
;@poll Address "Permission name"
;+1 previous
;+2 next
;+3 #permission

{
	[[0x0]]"ANY"
}
{
	;Create contract

	[0x0](LLL
		{
			;[[0x0]]0x9c0182658c9d57928b06d3ee20bb2b619a9cbf7b
			[[0x0]]0x1234567890123456789012345678901234567890123456789012345678901234
			 ;Placholder for the ACL address (should be 0x1)
			[[0x1]] 0x6 ;Tail
			[[0x2]] 0x6 ;Head
			[[0x3]] 0 	;Target Address
			[[0x4]] 0   ;Initialized

			[0x0](LLL
				{
					[0x0](calldataload 0) ;Get command (vote/init)

					(when (&& (= @0x0 "vote")(= @@0x4 1))
						{
							[0x20](calldataload 0x20)
							[0x40]@@(+ @@0x1 2)
							(while @0x40
								{ 	
									[0x100]1 ;Run flag
									[0x60]0 ;clear
									(call (- (GAS) 100) @0x40 0 0x0 0x40 0x60 0x20)
									(when (= @0x60 1)
										{
											;Failure of this request -> Delete
											[[(+ @@(+ @0x40 1) 2)]]@@(+ @0x40 2) ;Set prev next to this next
											[[(+ @@(+ @0x40 2) 1)]]@@(+ @0x40 1) ;Set next prev to this prev (when next !=0)
											[[@0x40]]0
											[[(+ @0x40 1)]]0
											[[(+ @0x40 2)]]0
											[[(+ @0x40 3)]]0 ;Clear out data
											[0x80]"kill"
											(call (- (GAS) 100) @0x40 0 0x80 0x20 0 0)
										}
									)
									(when (= @0x60 2)
										{
											;Acceptance of this request -> Set permission
											[0x80]"set"
											[0xA0]@@ @0x40 ;Permission name
											[0xC0]@@(+ @0x40 3) ;#permission
											[0xE0]@@0x3 ;Target Address
											(call (- (GAS) 100) @@0x0 0 0x80 0x80 0x0 0x0) ;Set the permission in the ACL

											;Delete (No Longer needed)
											[[(+ @@(+ @0x40 1) 2)]]@@(+ @0x40 2) ;Set prev next to this next
											[[(+ @@(+ @0x40 2) 1)]]@@(+ @0x40 1) ;Set next prev to this prev
											[[@0x40]]0
											[[(+ @0x40 1)]]0
											[[(+ @0x40 2)]]0
											[[(+ @0x40 3)]]0 ;Clear out data
											[0x80]"kill"
											(call (- (GAS) 100) @0x40 0 0x80 0x20 0 0)	
										}
									)
									[0x40]@@(+ @0x40 2)
								}
							)
							(when (= @0x100 0) (suicide @@0x0)) ;No polls left
						}
					)

					;(unless (= @@0x0 (CALLER)) (STOP)) ;Beyond here only ACL can command
					(when (= @0x0 "init") ;Form: "init" #ofPerms list["Permission name":#permission] 0xTargetAddress
						{
							;
							[0x20](calldataload 0x20) ;Number of items
							(CALLDATACOPY 0x100 0x0 (CALLDATASIZE))
							[[0x3]]@(+ 0xE0 (CALLDATASIZE)) ;Store Target address
							(unless @@0x3 (SUICIDE @@0x0)) ;If target is not set suicide to ACL

							[0x100]"fetch"
							(call (- (GAS) 100) @@0x0 0 0x100 (- (CALLDATASIZE) 0x20) 0x100 (* @0x20 0x20)) ;Translate into poll creation contracts

							[0x60] 0x100 ;mem pointer
							[0x80] 0x40  ;calldatapointer
							(for [0x40]0 (< @0x40 @0x20) [0x40](+ @0x40 1)
								{
									(when @ @0x60 ;only add non-zero ones
										{
											(Call (- (GAS) 100) @ @0x60 0 0 0 0xA0 0x20) ;Create contract
											;Create linked list entry
											[[(+ @@0x2 2)]] @0xA0 ;point prevhead to here
											[[(+ @0xA0 1)]] @@0x2 ;point here's prev to prevhead
											[[0x2]]@0xA0
											[[@0xA0]](calldataload @0x80) ;Store permission name here
											[[(+ @0xA0 3)]](calldataload (+ @0x80 0x20)) ;Store #permission
										}
									)
									[0x60](+ @0x60 0x20)
									[0x80](+ @0x80 0x40)
								}
							)
							[[0x4]]1 ;Initialized flag
						}
					)
				}
				0x20
			)
			(return 0x20 @0x0)

		}
		0x20
	)

	;Overwrite with ACL address
	[0x21](CALLER)

	[0x0](CREATE 0 0x20 @0x0) ;Create the poll manager code and store address at 0x0

	(return 0x0 0x20) ;Return the PCM address so it can be given permissions
}