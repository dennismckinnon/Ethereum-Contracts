{
	[[0x0]] (Caller) ; Initial admin
	[[0x1]] 0 ;Permissions address (can be hardcoded of admin can set it)
	[[0x2]] 0x100 ;Database start location
	[[0x3]] 32 ;Block Size Set at database creation
	[[0x4]] 0; Number of entries 
}
{

	(if (= @@0x0 (CALLER))
		{
			[0x0]1 ;Admin
		}
		{
			[0x200] (CALLER)
			(when @@0x1 (call @@0x1 0 0 0x200 32 0 32)) ;When a permissions address has been given call it and return permission level of caller
		}
	)

	(unless @0x0 (stop)) ;If not admin then don't allow them to do anything to the database (the dump if implemented would need to be before this)

	[0x0](calldataload 0)

	;Add Permissions contract (Format: "setperm" 0xPERMISSIONSADDR)
	(when (= @0x0 "setperm")
		[[0x1]] (calldataload 32)
	)

	(when (= @0x0 "kill")
		(suicide (CALLER))
	)
	
	;Add/edit Database entry link (Format: "moddbe" #locator 0xIndicator (6 hex digits) 0xinfohash "filetype" "quality" "title" "description") - See top
	(when (= @0x0 "moddbe")
		{
			[0x60] (calldataload 32) ;#locator! very important
			(when (> @0x60 @@0x4) [[0x4]]@0x60) ;If the locator is greater then the current entry number
			[0x40] (calldataload 64) ;Data telling which parts are available.
			[0x20] (calldataload 96) ;This is the infohash. It is required!

			[0x110] 138 ;Calldata pointer

			[0x60] (+ (* @0x60 @@0x3) @@0x2) ;Find the starting location of this data entry

			;INFOHASH (1 Seg) ;I STORE THE INFOHASH TO MAKE THE USER MANAGER SIMPLER (and this is the point where i realized i made this too difficult)
			[0x140] 1;Data field size in data segments
			[0x100] (MOD @0x40 0x10)
			[0x40] (DIV @0x40 0x10) ;Copy out the new last digit
			(for [0xE0]0 (> @0xE0 @0x140) [0xE0](+ @0xE0 1)
				{
					(when @0x100
						{
							[0x80] (calldataload @0x110) ;Get the next data segment
							[[@0x60]] @0x80 ;Copy data over
							[0x110] (+ @0x110 0x20) ;Increment dataload pointer
						}
					)
					[0x60] (+ @0x60 1) ;Increment storage pointer		
				}
			)


			;UPLOADER (1 Seg)
			[0x140] 1;Data field size in data segments
			[0x100] (MOD @0x40 0x10)
			[0x40] (DIV @0x40 0x10) ;Copy out the new last digit
			(for [0xE0]0 (> @0xE0 @0x140) [0xE0](+ @0xE0 1)
				{
					(when @0x100
						{
							[0x80] (calldataload @0x110) ;Get the next data segment
							[[@0x60]] @0x80 ;Copy data over
							[0x110] (+ @0x110 0x20) ;Increment dataload pointer
						}
					)
					[0x60] (+ @0x60 1) ;Increment storage pointer		
				}
			)

			;FILE TYPE (1 Seg)
			[0x140] 1;Data field size in data segments
			[0x100] (MOD @0x40 0x10)
			[0x40] (DIV @0x40 0x10) ;Copy out the new last digit
			(for [0xE0]0 (> @0xE0 @0x140) [0xE0](+ @0xE0 1)
				{
					(when @0x100
						{
							[0x80] (calldataload @0x110) ;Get the next data segment
							[[@0x60]] @0x80 ;Copy data over
							[0x110] (+ @0x110 0x20) ;Increment dataload pointer
						}
					)
					[0x60] (+ @0x60 1) ;Increment storage pointer		
				}
			)

			;FILE QUALITY (1 Seg)
			[0x140] 1;Data field size in data segments
			[0x100] (MOD @0x40 0x10)
			[0x40] (DIV @0x40 0x10) ;Copy out the new last digit
			(for [0xE0]0 (> @0xE0 @0x140) [0xE0](+ @0xE0 1)
				{
					(when @0x100
						{
							[0x80] (calldataload @0x110) ;Get the next data segment
							[[@0x60]] @0x80 ;Copy data over
							[0x110] (+ @0x110 0x20) ;Increment dataload pointer
						}
					)
					[0x60] (+ @0x60 1) ;Increment storage pointer		
				}
			)

			;TITLE (2 Seg)
			[0x140] 2;Data field size in data segments
			[0x100] (MOD @0x40 0x10)
			[0x40] (DIV @0x40 0x10) ;Copy out the new last digit
			(for [0xE0]0 (> @0xE0 @0x140) [0xE0](+ @0xE0 1)
				{
					(when @0x100
						{
							[0x80] (calldataload @0x110) ;Get the next data segment
							[[@0x60]] @0x80 ;Copy data over
							[0x110] (+ @0x110 0x20) ;Increment dataload pointer
						}
					)
					[0x60] (+ @0x60 1) ;Increment storage pointer		
				}
			)

			;DESCRIPTION (25 Seg)
			[0x140] 25;Data field size in data segments
			[0x100] (MOD @0x40 0x10)
			[0x40] (DIV @0x40 0x10) ;Copy out the new last digit
			(for [0xE0]0 (> @0xE0 @0x140) [0xE0](+ @0xE0 1)
				{
					(when @0x100
						{
							[0x80] (calldataload @0x110) ;Get the next data segment
							[[@0x60]] @0x80 ;Copy data over
							[0x110] (+ @0x110 0x20) ;Increment dataload pointer
						}
					)
					[0x60] (+ @0x60 1) ;Increment storage pointer		
				}
			)

			(stop)
		}
	)

	;Delete magnet link and data (Format: "deldbe" #locator)
	(when (= @0x0 "deldbe")
		{
			[0x20] (calldataload 32) ;Get #locator
			[0x40] (+ (* @0x20 @@0x3) @@0x2) ;Initial storage location of this entry
			[0x200] @0x40 ;copy this location
			(for [0x60]0 (< @0x60 @@0x3) [0x60](+ @0x60 1)
				{
					[0x80](+ (* @0x20 @@0x3) @@0x2) ;Start point for the last entry (for copy over)

					[[@0x40]] @@ @0x80; perform copy
					[[@0x80]] 0 ;Delete
					[0x40](+ @0x40 1)
					[0x80](+ @0x80 1);increment to next slot

					[[0x4]](- @@0x4 1) ;reduce the entry count
				}
			)
			[0x200] @@ @0x40 ;This is the new infohash (to send back)
			(return 0x200 32) ;Sends it back
		}
	)

	;Database Dump (Format: "dumpdb" 0xDUMPADDRESS) (no reason to protect this since the information is public anyways)
	;This is likely extremely expensive it might be better to do this using external methods (hence commented out)
;	(when (= @0x0 "dumpdb")
;		{
;			[0x20](calldataload 32)
;			[0x40](* (+ @0x60 1) @@0x3) ;Length of database
;			[0xE0] 0x100
;			(for [0x60]@@0x2 (> @0x60 (+ @0x40 @@0x2)) [0x60](+ @0x60 1)
;				{
;					[@0xE0]@@ @0x60 ;Copy to memory
;					[0xE0](+ @0xE0 0x20) ;Move mem pointer
;				}
;			)
;			(call @0x20 0 0 0x100 (* @0x40 0x20) 0 0) ;Send all the data away
;			(stop)
;		}
;	)

}