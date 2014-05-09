;Infohash-Based Database manager
;
;This Contract maintains a database of a small amount of information tied to an infohash (expected to be 20 bytes long)
;which identifies it. All database manipulations (additions deletions) use this infohash to reference the database 
;entry. For every Infohash a total of 32 storage addresses are allocated. One for the infohash and one for the creator
;(tracking the creator is optional but useful) The other 30 slots can be allocated freely however there is build in
;structure that can be used. A database entry has the following form:

;Infohash 		(1 Slot)
;Creator 		(1 Slot)
;Uploader 		(1 Slot)
;File Type 		(1 Slot)
;File quality 	(1 Slot)
;Title 			(2 Slots)
;Description 	(25 Slots)

;1 Slot stores 32 bytes so each of the first 5 fields can store 32 characters each Title can store 64 characters and
;800 characters are allotacted to the description. (creator is not optional and the infohash is tied to this entry 
;so those fields are not actually manipulatable)

;The Add/edit function has the handle "moddbe" (modify database entry) th format for making an addition or edit is:
;Data: "moddbe" 0xInfoHash 0xIndicator <"Uploader","Filetype","File Quality","Title","Description">
;
;0xIndicator provides information as to which the following sequence of data entries are provided (oder must be maintained)
;
;For example and Indicator of 0x10100 would indicate the information being passed is for slots File Quality and Description
;the data for this transaction would have the form:
;"moddbe" 0xInfohash 0x10100 "FileQuality" "Description"
;
;Notice the most significant hex digit corresponds to the latest in the list.
;
;In order to make an addition or and edit you must be at least a normal user as indicated by the user permission manager
;Which is requested from Doug (initially hard coded and then after first run it will be updated dynamically)
;
;There is a modular structure to add/edit which should make it easy to edit the structure of a database entry with ease
;In order to edit an entry which already exists. You must be either that entry's creator or an admin
;
;The other main function is Delete. "deldbe" 0xinfohash will delete all current records associated with that entry.
;Neither of these function are particularly efficient. In future versions a linked list type structure would probably be
;ideal. This is proof of concept so this was not included

;This contract is intended to be part of a Doug-Cluster and gets all permissions from a contract doug identifies as user
;In other words:
;Dependancies:
;-Doug ("doug")
;-User permission manager ("user")

{
	;Metadata  section
	[[0x0]] 0x88554646AB						;metadata notifier
	[[0x1]] (CALLER)							;contract creator
	[[0x2]] "Dennis McKinnon"					;contract Author
	[[0x3]] 0x18042014							;Date
	[[0x4]] 0x001000000							;version XXX.XXX.XXX
	[[0x5]] "Infohash Database Manager"			;Name
	[[0x6]] "12345678901234567890123456789012"	;Brief description (not past address 0xF)
	[[0x6]] "This Is a Database Contract whic"
	[[0x7]] "h stores a limited amount of inf"
	[[0x8]] "ormation tied to the infohash pr"
	[[0x9]] "ovided upon entry creation"


	[[0x10]] 0x9e4d58a9f74d7a5752c712210a9ffbe612f2609f		;Hardcode in a first DOUG
	[[0x11]] 0x20 											;Start of infohash list
	[[0x12]] @@0x11											;infohash list pointer
	[[0x13]] 32						 						;Number of segments per item
	[[0x14]] (* (EXP 0x100 21) @@0x13)					 	;Where to start the inforhash look up. 20 bytes hence 21
	[[0x15]] 0 												;count number of entries
	

	[0x0] "reg"
	[0x20] "magdb"
	(call (- (GAS) 100) @@0x10 0 0x0 0x40 0 0x20) ;Register for name "magdb" with doug
}
{
	;Get doug from doug
	[0x0]"req"
	[0x20] "doug"
	(call (- (GAS) 100) @@0x10 0 0x0 0x40 0x0 0x20)
	[[0x10]]@0x0 ;Copy new doug over

	;Update the User Permissions manager (UPM)
	[0x0] "req"
	[0x20] "user"
	(call (- (GAS) 100) @@0x10 0 0x0 0x40 0x0 0x20)
	[[0x16]]@0x0 ;Copy new UPM over

	[0x40] "check"
	[0x60] (CALLER)
	(call (- (GAS) 100) @@0x16 0 0x40 0x40 0x0 0x20) ;Call user manager and find out if the caller has permissions (0x0)
	(unless @0x0 (stop)) ;Not a member stop

	[0x0](MOD(DIV @0x0 2)2);Second Digit (if they are an admin = 1)

	[0x20] (calldataload 0) ;First argument is txtype
	(unless @0x20 (stop)) ;No first argument stop


	;Admin suicide (Format: "kill")
	(when (AND (= @0x20 "kill") (= @0x0 1)) ;Admin and say kill suicide + deregister
		{
;			(call (- (GAS) 100) 0x11d11764cd7f6ecda172e0b72370e6ea7f75f290 0 0 0 0 0); INSTEAD OF NAME REGISTER DEREGISTER from DOUG (very complicated)
			(suicide @@0x10)
		}
	)

	;Add/edit Magnet link (Format: "moddbe" 0xINFOHASH 0xIndicator (5 hex digits) "filetype" "quality" "title" "description") - See top
	(when (= @0x20 "moddbe")
		{
			[0x20] (calldataload 32) ;This is the infohash. It is required! (20 bytes)
			[0xA0] (+ @0x20 @@0x14) ;Offset position for name look up
			[0x40] (calldataload 64) ;Data telling which parts are available.

			(if (= @@ @0xA0 0)
				{
					;If its new then the locator is the pointer set new flag
					[0x60] @@0x12
					[[@0xA0]] @@0x12 ;set the locator
					[[0x12]](+ @@0x12 @@0x13) ;increment pointer
					[[0x15]](+ @@0x15 1) ;increment counter
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
			[0x40] (calldataload 32) ;This is the infohash. It is required! (20 bytes)
			[0xA0] (+ @0x40 @@0x14) ;Offset position for name look up

			(when (= @@ @0xA0 0) (stop)) ;If it doesn't exist stop

			[0x60] @@ @0xA0 ;Fetch Locator
			[0x80] (- @@0x12 @@0x13) ;Locator for item to move over

			[[@0xA0]] 0; Clear out

			[0xC0] (+ @@ @0x80 @@0x14) ;This is the address the infohash pointer
			;If they are the same we need to completely clear it out
			(if (= @0x60 @0x80)
				{
					(for [0x100] 0 (< @0x100 @@0x13) [0x100](+ @0x100 1)
						{
							;Loop through and copy data from last data chunk to this one
							[[(+ @0x60 @0x100)]] 0; Delete old data
						}
					)
					[[0x12]] @0x80 ;Change the data pointer
					[[0x15]] 0;Decrement counter
				}
				{
					[[@0xC0]] @0x60 ;Copy the new locator for this item

					(for [0x100] 0 (< @0x100 @@0x13) [0x100](+ @0x100 1)
						{
							;Loop through and copy data from last data chunk to this one
							[[(+ @0x60 @0x100)]] @@(+ @0x80 @0x100)
							[[(+ @0x80 @0x100)]] 0; Delete old data
						}
					)
					[[0x12]] @0x80 ;Change the data pointer
					[[0x15]](- @@0x15 1);Decrement counter
				}
			)
		}
	)
}