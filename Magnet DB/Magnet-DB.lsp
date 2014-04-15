;Infohash Database manager with Membership structure

{
	[[0x0]] 0x11 ;Admin member pointer
	[[0x1]] 30 ;Number of segments per item
	[[0x2]] 0x200 ;Member pointer
	[[0x3]] 0x0 ;Number of members
	[[0x4]] 0x1000 ;infohash list pointer
	[[0x10]](caller) ;Set admin
	[0x0] "A"
	(call 0x11d11764cd7f6ecda172e0b72370e6ea7f75f290 0 0 0 1 0 0)
}
{
	;You can't do anything if you aren't a member so check that first
	(for ["i"] 0x10 (< @"i" @@0x0) ["i"](+ @"i" 1)
		{
			(when (= @@ @"i" (caller))
				[0x0] 1 ;Admin
			)
		}
	)
	(unless @0x0 
		(for ["i"] 0x200 (< @"i" @@0x200) ["i"](+ @"i" 1)
			{
				(when (= @@ @"i" (caller))
					[0x0] 2 ;Normal member
				)
			}
		)
	)
	(unless @0x0 (stop)) ;Not a member stop

	[0x20] (calldataload 0) ;First argument is txtype
	(unless @0x20 (stop)) ;No first argument stop

	;Admin suicide (Format: "kill")
	(when (&& (= @0x20 "kill") (= @0x20 1)) ;Admin and say kill suicide + deregister
		{
			(call 0x11d11764cd7f6ecda172e0b72370e6ea7f75f290 0 0 0 0 0 0)
			(suicide @@0x10)
		}
	)

	;Register new admin (Format: "regadm" 0xMemberaddress)
	(when (&& (= @0x20 "regadm") (= @0x20 1))
		{
			[0x40] (calldataload 32) ;Get second data argument
			(when @0x40
				{
					[[@@0x0]] @0x40 ;Store the new member in then next admin slot
					[[0x0]] (+ @@0x0 1) ;Increment admin pointer 
				}
			)
			(stop)
		}
	)

	;Register new member (Format: "regmem" 0xMemberaddress)
	(when (= @0x20 "regmem") 
		{
			[0x40] (calldataload 32) ;Get second data argument
			(when @0x40
				{
					[[@@0x2]] @0x40 ;Store the new member in then next admin slot
					[[0x2]] (+ @@0x2 1) ;Increment admin pointer 
				}
			)
			(stop)
		}
	)

	;Delete normal member (must be an admin) (Format: "delmem" 0xMemberaddress)
	(when (= @0x20 "delmem")
		{
			[0x40] (calldataload 32) ;Get second data argument
			(when @0x40
				{
					(for ["i"] 0x200 (< @"i" @@0x2) ["i"](+ @"i" 1)
						{
							(when (= @@ @"i" @0x40) ;delete and shuffle
								{
									[[0x2]] (- @@0x2 1)
									[[@"i"]] @@ @@0x2
									[[@@ @@0x2]] 0
									(stop) ;don't need to do any more
								}
							)
						}
					)
				}
			)
		}
	)

	;Delete Admin member (must be an admin that is higher then the member you re deleting) (Format: "deladm" 0xMemberaddress)
	;Note: This is REALLY costly since order must be maintained
	(when (= @0x20 "deladm")
		{
			[0x40] (calldataload 32) ;Get second data argument
			(when @0x40
				{
					[0x60] 0 ;Flag for if caller appears before attempted deletee
					[0x80] 0 ;Flag for finding deletee AFTER your number
					(for ["i"]0x10 (< @"i" @@0x0) ["i"](+ @"i" 1)
						{
							(when (&& (= @@ @"i" @0x40)(= @0x60 1)) [0x80]1) ;Flip ok to delete flag (if the line comes after the next you can delete yourself) 
							(when (= @@ @"i" (caller)) [0x60] 1) ;If caller was found flip flag
							
							(when (= @0x80 1) ;delete and shuffle
								[[@"i"]] @@ (+ @"i" 1)
							)
						}
					)
					(when (= @0x80 1) ;If deletion has occured
						{
							[[0x0]] (- @@0x0 1) ;Decrement admin pointer
							[[@@0x0]] 0 ;Delete the last (duplicated guy)
						}
					)
				}
			)
		}
	)


	;Add/edit Magnet link (Format: "modmag" 0xIndicator (4 hex digits) 0xinfohash "filetype" "quality" "title" "description") - See top
	(when (= @0x20 "modmag")
		{
			[0x40] (calldataload 32) ;Data telling which parts are available.
			[0x60] (calldataload 64) ;This is the infohash. It is required!
			(when (> @0x60 0xFFFFF) ;(not only must it exist but it has to be valid)
				{
					[0x110] 96 ;Calldata pointer

					(unless @@ @0x60 ;If this hash hasn't been added yet add to list !!!This works because creator is 
						{
							[[@@0x4]] @0x60 ;Copy infohash into list
							[[0x4]] (+ @@0x4 1) ;Increment infohash pointer
						
							;Special: Magnet link creator address
							[[@0x60]] (caller) ;Copy data over (if you don't want to track this change to a constant)
						}
					)
					[0x60] (+ @0x60 0x20) ;Increment storage pointer (logic is that this will need to skip over creator regardless)
					
					;FILETYPE (1 Seg)
					[0x100] (MOD @0x40 0x10)
					[0x40] (DIV @0x40 0x10) ;Copy out the new last digit
					(when @0x100
						{
							[0x500] 1;Data field size in data segments
							(for ["i"]0 (> @"i" @0x500) ["i"](+ @"i" 1)
								{
									[0x80] (calldataload @0x110) ;Get the next data segment
									[[@0x60]] @0x80 ;Copy data over
									[0x60] (+ @0x60 0x20) ;Increment storage pointer
									[0x110] (+ @0x110 0x20) ;Increment dataload pointer
								}
							)
						}
					)

					;FILE QUALITY (1 Seg)
					[0x100] (MOD @0x40 0x10)
					[0x40] (DIV @0x40 0x10) ;Copy out the new last digit
					(when @0x100
						{ 
							[0x500] 1;Data field size in data segments
							(for ["i"]0 (> @"i" @0x500) ["i"](+ @"i" 1)
								{
									[0x80] (calldataload @0x110) ;Get the next data segment
									[[@0x60]] @0x80 ;Copy data over
									[0x60] (+ @0x60 0x20) ;Increment storage pointer
									[0x110] (+ @0x110 0x20) ;Increment dataload pointer
								}
							)
						}
					)

					;FILE TITLE (2 Segs)
					[0x100] (MOD @0x40 0x10)
					[0x40] (DIV @0x40 0x10) ;Copy out the new last digit
					(when @0x100
						{
							[0x500] 2 ;Data field size in data segments
							(for ["i"]0 (> @"i" @0x500) ["i"](+ @"i" 1)
								{
									[0x80] (calldataload @0x110) ;Get the next data segment
									[[@0x60]] @0x80 ;Copy data over
									[0x60] (+ @0x60 0x20) ;Increment storage pointer
									[0x110] (+ @0x110 0x20) ;Increment dataload pointer
								}
							)
						}
					)

					;FILE DESCRIPTION (25 Segs)
					[0x100] (MOD @0x40 0x10)
					[0x40] (DIV @0x40 0x10) ;Copy out the new last digit
					(when @0x100
						{
							[0x500] 25 ;Data field size in data segments
							(for ["i"]0 (> @"i" @0x500) ["i"](+ @"i" 1)
								{
									[0x80] (calldataload @0x110) ;Get the next data segment
									[[@0x60]] @0x80 ;Copy data over
									[0x60] (+ @0x60 0x20) ;Increment storage pointer
									[0x110] (+ @0x110 0x20) ;Increment dataload pointer
								}
							)
						}
					)
				}
			)
			(stop)
		}
	)

	;Delete magnet link and data (Format: "delmag" 0xinfohash) ??ADMIN priveleges needed?
	(when (= @0x20 "delmag")
		{
			[0x40] (calldataload 32) ;Get second data argument
			(when @0x40
				{
					(for ["i"] 0x1000 (< @"i" @@0x4) ["i"](+ @"i" 1)
						{
							(when (= @@ @"i" @0x40) ;delete and shuffle
								{
									[[0x4]] (- @@0x4 1)
									[[@"i"]] @@ @@0x4
									[[@@ @@0x4]] 0

									(for ["j"]0 (< @"j" @@0x1) ["j"](+ @"j" 1)
										{
											[[@0x40]]0
											[0x40] (+ @0x40 0x20) increment to next data slot
										}
									)
									(stop) ;don't need to do any more
								}
							)
						}
					)
				}
			)
		}
	)
}