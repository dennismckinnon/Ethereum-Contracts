;Infohash Database manager with Membership structure

{
	[[0x0]](caller) ;Set admin
	[[0x1]] 32 ;Number of segments per item
	[[0x2]] 0x10 ;infohash list pointer
	[[0x3]] 0 ;0xADDRESS OF WILL
	[[0x4]] 0 ;0xADDRESS OF DOUG
	[[0x5]] 0 ;0xADDRESS OF USER MANAGER - ONE of these must be filled in or the admin must set it before anything will happen
	[[0x6]] (* (EXP 0x100 21) @@0x1) ;Where to start the inforhash look up. 20 bytes hence 21
	[[0x7]] 1 ;count number of entries
;	[0x0] "A"
;	(call 0x11d11764cd7f6ecda172e0b72370e6ea7f75f290 0 0 0 1 0 0)
}
{
	[0x20] (calldataload 0) ;First argument is txtype
	(unless @0x20 (stop)) ;No first argument stop

;	(when (AND (= @0x20 "set")(= (CALLER) @@0x0)
;		{
;			[0x40](calldataload 32) ;Get type
;			(when (= @0x40 "WILL") [[0x3]](calldataload 64))
;			(when (= @0x40 "DOUG") [[0x3]](calldataload 64))
;			(when (= @0x40 "USER") [[0x3]](calldataload 64))
;		}
;	)
;
;	(unless (OR(OR @0x3 @0x4) @0x5) (stop)) ;One of the fields must be filled out before proceeding
;	(when @@0x3 ;when Will is registered use him to get doug
;		{
;			(call @0x3 0 0 0 0 0x100 0x20) ;Call WILL no argument means tell me DOUG
;			[[0x4]]@0x100 ;Copy DOUG in
;		}
;	)
;	(when @@0x4 ;when DOUG is registered use him to get USER (and WILL)
;		{
;			(call ) ;Call DOUG get USER 
;		}
;	)
;
;	[0x40] "check"
;	[0x60] (CALLER)
;	(call @0x120 0 0 0x40 0x40 0x0 0x20) ;Call user manager and find out if the caller has permissions (0x0)
;	(unless @0x0 (stop)) ;Not a member stop

;	[0x0](MOD(DIV @0x0 2)2);Second Digit (if they are an admin = 1)

;HARDCODED
	[0x0]1 ;ADMIN

	;Admin suicide (Format: "kill")
	(when (AND (= @0x20 "kill") (= @0x0 1)) ;Admin and say kill suicide + deregister
		{
;			(call 0x11d11764cd7f6ecda172e0b72370e6ea7f75f290 0 0 0 0 0 0); INSTEAD OF NAME REGISTER DEREGISTER from DOUG (very complicated)
			(suicide @@0x10)
		}
	)

	;Add/edit Magnet link (Format: "moddbe" 0xINFOHASH 0xIndicator (5 hex digits) "filetype" "quality" "title" "description") - See top
	(when (= @0x20 "moddbe")
		{
			[0x20] (calldataload 32) ;This is the infohash. It is required! (20 bytes)
			[0xA0] (+ @0x20 @@0x6) ;Offset position for name look up
			[0x40] (calldataload 64) ;Data telling which parts are available.

			(if (= @@ @0xA0 0)
				{
					;If its new then the locator is the pointer set new flag
					[0x60] @@0x2
					[[@0xA0]] @@0x2 ;set the locator
					[[0x2]](+ @@0x2 @@0x1) ;increment pointer
					[[0x7]](+ @@0x7 1) ;increment counter
					[[@0x60]] @0x20 ;Copy over the infohash
					[[(+ @0x60 1)]] (CALLER); Can be removed for anonymous creation
					[0x60](+ @0x60 2) ;Increment the storage pointer 2
				}
				{
					;If its old then fetch the locator
					[0x60] (+ @@ @0xA0 2) ;+2 skip infohash and caller fields
				}
			)

			;The Locator points to the start of the Relevant datablock

			[0x140] 96 ;Calldata pointer


			;UPLOADER (1 Seg) 
			[0x160] 1;Data field size in data segments
			[0x120] (MOD @0x40 0x10)
			[0x40] (DIV @0x40 0x10) ;Copy out the new last digit
			(for [0xE0]0 (< @0xE0 @0x160) [0xE0](+ @0xE0 1)
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
			(for [0xE0]0 (< @0xE0 @0x160) [0xE0](+ @0xE0 1)
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
			(for [0xE0]0 (< @0xE0 @0x160) [0xE0](+ @0xE0 1)
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
			[0x160] 2;Data field size in data segments
			[0x120] (MOD @0x40 0x10)
			[0x40] (DIV @0x40 0x10) ;Copy out the new last digit
			(for [0xE0]0 (< @0xE0 @0x160) [0xE0](+ @0xE0 1)
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
			[0x160] 25;Data field size in data segments
			[0x120] (MOD @0x40 0x10)
			[0x40] (DIV @0x40 0x10) ;Copy out the new last digit
			(for [0xE0]0 (< @0xE0 @0x160) [0xE0](+ @0xE0 1)
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
	(when (= @0x20 "deldbe")
		{
			[0x20] (calldataload 32) ;This is the infohash. It is required! (20 bytes)
			[0xA0] (+ @0x20 @@0x6) ;Offset position for name look up

			(unless (= @@0xA0 0) (stop)) ;If it doesn't exist stop

			[0x60] @@ @0xA0 ;Fetch Locator
			[0x80] (- @@0x2 1) ;Locator for item to move over

			[[@0xA0]] 0; Clear out

			[0xA0] (+ @@ @0x80 @@0x6) ;This is the address the infohash pointer
			(unless (= @0x60 @0x80)
				[[@0xA0]] @0x60 ;Copy the new locator for this item
			)
			
			(for [0x100]0 (< @0x100 @@0x1) [0x100](+ @0x100 1)
				{
					;Loop through and copy data from last data chunk to this one
					[[(+ @0x60 @0x100)]] @@(+ @0x80 @0x100)
					[[(+ @0x80 @0x100)]] 0; Delete old data
				}
			)
			[[0x1]] @0x80 ;Change the data pointer
			[[0x7]](- @@0x7 1);Decrement counter
		}
	)
}