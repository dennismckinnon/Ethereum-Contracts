;Infohash Database manager with Membership structure

{
	[[0x0]](caller) ;Set admin
	[[0x1]] 30 ;Number of segments per item
	[[0x2]] 0x10 ;infohash list pointer
	[[0x3]] 0 ;0xADDRESS OF WILL
	[[0x4]] 0 ;0xADDRESS OF DOUG
	[[0x5]] 0 ;0xADDRESS OF USER MANAGER - ONE of these must be filled in or the admin must set it before anything will happen
	[[0x6]] (* (EXP 0x10 21) @@0x0) ;Where to start the inforhash look up. 20 bytes hence 21
	[0x0] "A"
	(call 0x11d11764cd7f6ecda172e0b72370e6ea7f75f290 0 0 0 1 0 0)
}
{
	[txtype] (calldataload 0) ;First argument is txtype
	(unless @txtype (stop)) ;No first argument stop

	(when (AND (= @txtype "set")(= (CALLER) @@0x0)
		{
			[setype](calldataload 32) ;Get type
			(when (= @setype "WILL") [[0x3]](calldataload 64))
			(when (= @setype "DOUG") [[0x3]](calldataload 64))
			(when (= @setype "USER") [[0x3]](calldataload 64))
		}
	)

	(unless (OR(OR @@0x3 @@0x4) @@0x5) (stop)) ;One of the fields must be filled out before proceeding
	(when @@0x3 ;when Will is registered use him to get doug
		{
			(call @@0x3 0 0 0 0 retval 0x20) ;Call WILL no argument means tell me DOUG
			[[0x4]]@retval ;Copy DOUG in
		}
	)
	(when @@0x4 ;when DOUG is registered use him to get USER (and WILL)
		{
			(call ) ;Call DOUG get USER
			[[0x5]]retval ;copy user over
		}
	)

	[txtype] "check"
	[data2] (CALLER)
	(call @0x120 0 0 0x40 0x40 perm 0x20) ;Call user manager and find out if the caller has permissions (0x0)
	(unless @0x0 (stop)) ;Not a member stop

	[0x0](MOD(DIV @0x0 2)2);Second Digit (if they are an admin = 1)


	;Admin suicide (Format: "kill")
	(when (&& (= @0x20 "kill") (= @0x0 1)) ;Admin and say kill suicide + deregister
		{
;			(call 0x11d11764cd7f6ecda172e0b72370e6ea7f75f290 0 0 0 0 0 0); INSTEAD OF NAME REGISTER DEREGISTER from DOUG (very complicated)
			(suicide @@0x10)
		}
	)

	;Add/edit Magnet link (Format: "modmag" 0xINFOHASH 0xIndicator (4 hex digits) "filetype" "quality" "title" "description") - See top
	(when (= @0x20 "moddbe")
		{
			[0x20] (calldataload 32) ;This is the infohash. It is required! (20 bytes)
			[0xA0] (+ @0x20 @@0x0) ;Offset position for name look up
			[0x40] (calldataload 64) ;Data telling which parts are available.

			(if (= @@0xA0 0)
				{
					;If its new then the locator is the pointer set new flag
					[0x60] @@0x2
					[[@@0xA0]] @@0x2 ;set the locator
					[[0x2]](+ @@0x2 @@0x1) ;increment pointer
					[0x100] 1
				}
				{
					;If its old then fetch the locator
					[0x60] @@0xA0
				}
			)

			;The Locator points to the start of the Relevant datablock

			[0x140] 96 ;Calldata pointer



			;INFOHASH (1 Seg) ;STORE THE INFOHASH
			[0x160] 1;Data field size in data segments
			[0x120] (MOD @0x40 0x10)
			[0x40] (DIV @0x40 0x10) ;Copy out the new last digit
			(for [0xE0]0 (> @0xE0 @0x160) [0xE0](+ @0xE0 1)
				{
					(when @0x120
						{
							[0x80] (calldataload @0x140) ;Get the next data segment
							[[@0x60]] @0x80 ;Copy data over
							[0x140] (+ @0x140 0x20) ;Increment dataload pointer
						}
					)
					[0x60] (+ @0x60 1) ;Increment storage pointer		
				}
			)

			;ENTRY MAKER (1 Seg) ;STORE THE (CALLER) (This can be removed for anonymity)
			(when @0x100
				{
					[[@0x60]](CALLER) ;If this is being created then copy caller into first Data slot	
				}
			)
			[0x60](+ @0x60 1);increment Storage pointer


			;UPLOADER (1 Seg) 
			[0x160] 1;Data field size in data segments
			[0x120] (MOD @0x40 0x10)
			[0x40] (DIV @0x40 0x10) ;Copy out the new last digit
			(for [0xE0]0 (> @0xE0 @0x160) [0xE0](+ @0xE0 1)
				{
					(when @0x120
						{
							[0x80] (calldataload @0x140) ;Get the next data segment
							[[@0x60]] @0x80 ;Copy data over
							[0x140] (+ @0x140 0x20) ;Increment dataload pointer
						}
					)
					[0x60] (+ @0x60 1) ;Increment storage pointer		
				}
			)


			;FILETYPE (1 Seg) 
			[0x160] 1;Data field size in data segments
			[0x120] (MOD @0x40 0x10)
			[0x40] (DIV @0x40 0x10) ;Copy out the new last digit
			(for [0xE0]0 (> @0xE0 @0x160) [0xE0](+ @0xE0 1)
				{
					(when @0x120
						{
							[0x80] (calldataload @0x140) ;Get the next data segment
							[[@0x60]] @0x80 ;Copy data over
							[0x140] (+ @0x140 0x20) ;Increment dataload pointer
						}
					)
					[0x60] (+ @0x60 1) ;Increment storage pointer		
				}
			)

			;FILEQUALITY (1 Seg) 
			[0x160] 1;Data field size in data segments
			[0x120] (MOD @0x40 0x10)
			[0x40] (DIV @0x40 0x10) ;Copy out the new last digit
			(for [0xE0]0 (> @0xE0 @0x160) [0xE0](+ @0xE0 1)
				{
					(when @0x120
						{
							[0x80] (calldataload @0x140) ;Get the next data segment
							[[@0x60]] @0x80 ;Copy data over
							[0x140] (+ @0x140 0x20) ;Increment dataload pointer
						}
					)
					[0x60] (+ @0x60 1) ;Increment storage pointer		
				}
			)

			;TITLE (2 Seg) 
			[0x160] 1;Data field size in data segments
			[0x120] (MOD @0x40 0x10)
			[0x40] (DIV @0x40 0x10) ;Copy out the new last digit
			(for [0xE0]0 (> @0xE0 @0x160) [0xE0](+ @0xE0 1)
				{
					(when @0x120
						{
							[0x80] (calldataload @0x140) ;Get the next data segment
							[[@0x60]] @0x80 ;Copy data over
							[0x140] (+ @0x140 0x20) ;Increment dataload pointer
						}
					)
					[0x60] (+ @0x60 1) ;Increment storage pointer		
				}
			)

			;DESCRIPTION (25 Seg) 
			[0x160] 1;Data field size in data segments
			[0x120] (MOD @0x40 0x10)
			[0x40] (DIV @0x40 0x10) ;Copy out the new last digit
			(for [0xE0]0 (> @0xE0 @0x160) [0xE0](+ @0xE0 1)
				{
					(when @0x120
						{
							[0x80] (calldataload @0x140) ;Get the next data segment
							[[@0x60]] @0x80 ;Copy data over
							[0x140] (+ @0x140 0x20) ;Increment dataload pointer
						}
					)
					[0x60] (+ @0x60 1) ;Increment storage pointer		
				}
			)

			(stop)
		}
	)

	;Delete magnet link and data (Format: "delmag" 0xinfohash) ??ADMIN priveleges needed?
	(when (= @0x20 "delmag")
		{
			[0x20] (calldataload 32) ;This is the infohash. It is required! (20 bytes)
			[0xA0] (+ @0x20 @@0x0) ;Offset position for name look up

			(unless (= @@0xA0 0) (stop)) ;If it doesn't exist stop

			[0x60] @@0xA0 ;Fetch Locator
			[0x80] (- @@0x2 @@0x1) ;Locator for item to move over

			[0xA0] (+ @@ @0x80 @@0x6) ;This is the address the infohash pointer
			[[@0xA0]] @0x60 ;Copy the new locator for this item

			(for [0x100]0 (< @0x100 @@0x1) [0x100](+ @0x100 1)
				{
					;Loop through and copy data from last data chunk to this one
					[[(+ @0x60 @0x100)]] @@(+ @0x80 @0x100)
					[[(+ @0x80 @0x100)]] 0; Delete old data
				}
			)
			[[0x1]] @0x80 ;Change the data pointer
		}
	)
}