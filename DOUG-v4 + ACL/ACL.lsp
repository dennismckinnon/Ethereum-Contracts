;ACL

;Default behaviour: If the permission name has been registered but the rule for a specific permission level
;					does not yet exist. The the permission is automatically rejected.
;					If the permission name does not exist then the request is automatically rejected
;					If the ACL does not have any rules for giving ACL permissions, then requested 
;					permissions are automatically granted.
;
;Use:				Requesting permissions work for any contract's permissions. Setting permissions requires
;					one to have already gotten the ACL permissions. Adding a permission rule similarly requires
;					Previously obtained permissions. Note that is a contract has these permissions they can do
;					a lot of damage without any controls on them. As such these permissions should probably only
;					be given to contracts and used through them.

;Future Directions: In the future it might be desirable to use internal firewalling of permissions so you can only
;					edit permissions of contracts if you have ACL permissions and target contract permissions. 
;					This won't be implemented in this iteration.

;API
;Check Permission 	- Permission needed: 0
;					- Form: "check" "Permission Name" <0xTargetAddress>
;					- Returns: Permission number requested
;
;Fetch 				- Permission needed: 0
; 					- Form: "fetch" #ofperms list["Permission name":#permission]
; 					- Returns: list[poll creation contract addresses]
;
;Request Permission - Permission needed: 0
;					- Form: "request" "Permission Name" #permission <0xTargetAddress>
;					- Returns: Nothing
;
;Request Permission - Permission needed: 0
; (Multiple) 		- Form: "request" "type" #ofperms list["Permission name":#permission] <0xTargetAddress>
;					- Returns: Nothing
;
;Set Permission 	- Permission needed: 1
;(give/change)		- Form: "set" "Permission Name" #permission <0xTargetAddress>
;					- Returns: 1(success), 0(failure)
;
;Add rule			- Permission needed: 2
;(replace rule)		- Form: "addrule" "Permission Name" #permission 0xRuleAddress
;					- Returns: 1(success), 0(failure)
;
;Add type 			- Permission needed: 2
; (replace type)	- Form: "addtype" "Type Name" 0xTypeAddress
; 					- Returns: 1(success), 0(failure)
;
;Permissions
;@Address bitstring 
;+1
;...
;
;@"permission name" row|start position
;+1 Address for permission 1
;+2 Address for permission 2
;...
;+7 Address for permission 7
;
;position number between 1-32 (5 bits)
;

{
	;Metadata Section
;	[[0x0]] 0x88554646AB						;metadata notifier
;	[[0x1]] (CALLER)							;contract creator
;	[[0x2]] "Dennis McKinnon"					;contract Author
;	[[0x3]] 0x07052014							;Date
;	[[0x4]] 0x001000000							;version XXX.XXX.XXX
;	[[0x5]] "ACL" 								;Name
;	[[0x6]] "12345678901234567890123456789012"	;Brief description (not past address 0xF)
;	[[0x6]] "The Access Control List (ACL) is"
;	[[0x7]] "a unified method by which to att"
;	[[0x8]] "ribute permission levels to user"
;	[[0x9]] "s and contracts and to store met"
;	[[0xA]] "hods by which those permissions "
;	[[0xB]] "may be allocated through the reg"
;	[[0xC]] "istration of various contracts w"
;	[[0xD]] "hich can be spawned to determine"
;	[[0xE]] "whether a permission is to be al"
;	[[0xF]] "located."	

	[[0x10]] 0xDOUGADDRESS	;Doug's Address
	[[0x11]] 0 				;Current allocation row
	[[0x12]] 3 				;Current allocation start position

	;Standard link list for the "type"s
	[[0x13]] 0x14	;Tail
	[[0x14]] 0x14 	;Head

	[["ACL"]]0 ;ACL permissions located at 0th root start position 0
	[[(CALLER)]]2 ;Give (CALLER) full ACL permissions to start
}
{
	;Doug Update
	[0x0]"check"
	[0x20]"doug"
	(call (- (GAS) 100) @@0x10 0 0x0 0x40 0x0 0x20)
	[[0x10]] @0x0

	[0x0](calldataload 0)


;--------------------------------------------------------------------------------
;Check Permission 	- Permission needed: 0
;					- Form: "check" "Permission Name" <0xTargetAddress>
;					- Returns: Permission number requested
; Checks what permission level the target address has for permission given by
;"Permission Name" if no target provided, Defaults to CALLER

	(when (= @0x0 "check")
		{
			;Check what permission target has. If Target not provided defaults to CALLER
			[0x20](calldataload 0x20) 		;Get Permission Name
			[0x40](calldataload 0x40) 		;Get Target (optional)
			(unless @0x40 [0x40](CALLER))	;If Target not sent default: CALLER
			[0x60] @@ @0x20 				;Get the permission names bit data
			[0x80](MOD @0x60 32) 			;Get start position
			[0xA0](DIV @0x60 32)	 		;Get Row permission located on.

			[0xC0](MOD (DIV @@(+ @0x40 @0xA0) (EXP 2 @0x80)) 8) 	;This is The permission value
			(return 0xC0 0x20) ;Return requested value
		}
	)


;---------------------------------------------------------------------
;Fetch 	- Permission needed: 0
; 		- Form: "fetch" #ofperms list["Permission name":#permission]
; 		- Returns: list[poll creation contract addresses]
;This takes in a list of permission name:permission level pairs and
;Returns a lost of the associated poll creation contracts.

	(when (= @0x0 "fetch")
		{
			;Fetch the Poll creation contracts and return as list of contract addresses
			[0x20](calldataload 0x20) ;Number of permissions requesting
			[0x60]0x100 ;Memory slot starting place
			[0x80]0x40 	;calldata pointer

			(for [0x40]0 (< @0x40 @0x20) [0x40](+ @0x40 1)
				{
					;Copy data over
					[0xA0](calldataload @0x80) ;Permission name
					[0xC0](calldataload (+ @0x80 0x20)) ;#permission
					
					;Time to process
					[@0x60]@@(+ @0xA0 @0xC0) ;This is the pollcreation contract address for this permission

					[0x80](+ @0x80 0x40)
					[0x60](+ @0x60 0x20) ;Increment both pointers
				}
			)
			(return 0x100 (- @0x60 0x100)) ;Return the list of poll creation contract addresses
		}
	)


;-----------------------------------------------------------------------------------------------------------
;Request Permission - Permission needed: 0
;					- Form: "request" "type" #ofperms list["Permission name":#permission] <0xTargetAddress>
;					- Returns: Nothing
;Opens up a request for the permissions provided by the the list to be attributed to the target address
;"type" provides the type of poll manager contract to use (by name). If no target address provided then
;Defaults to CALLER.

	(when (= @0x0 "request")
		{
			
			;Stage 1 - Create poll manager contract With ACL permissions

			[0x0](+ (calldataload 0x20) 200000)
			(unless (&& (calldataload 0x20) @@ @0x0) (STOP)) ;Don't allow empty names

			(call (- (GAS) 100) @0x0 0 0 0 0x0 0x20) ;Call PCMCC for type

			[[@0x0]](| @@ @0x0 0x1) ;Set the permissions for ACL to be 1

			;Stage 2 - Initialize the PCM
			[0x20](calldataload (+ (* (calldataload 0x60) 0x40) 0x60)) ;Get target address
			(CALLDATACOPY 0x40 0x20 (CALLDATASIZE))
			(unless @0x20 [(+ (CALLDATASIZE) 0x20)](CALLER)) ;If target not specified default to (CALLER)
			[0x40]"init" ;Modify command for passing data along
			(call (- (GAS) 100) @0x0 0 0x40 (+ (CALLDATASIZE) 0x40) 0x0 0x0) ;Initialize the PCM
		}
	)


;---------------------------------------------------------------------------------
;Set Permission 	- Permission needed: 1
;(give/change)		- Form: "set" "Permission Name" #permission <0xTargetAddress>
;					- Returns: 1(success), 0(failure)
;Sets the target address's permission level for "permission name" to the provided
;value. If target not provided defaults to CALLER

	(when (= @0x0 "set")
		{
			;Permission Check - Permission needed: 1 or 2
			[0x0]"check"
			[0x20]"ACL"
			(call (- (GAS) 100) (ADDRESS) 0 0x0 0x40 0x40 0x20)

			(unless (OR (= @0x40 1) (= @0x40 2)) (STOP)) ;If you do not have the required permissions stop

			;Set Permission. If Target not provided defaults to CALLER
			[0x20](calldataload 0x20) 		;Get Permission Name
			[0xA0](calldataload 0x40)		;Get The permission number to set
			[0x40](calldataload 0x60) 		;Get Target (optional)
			(unless @0x40 [0x40](CALLER))	;If Target not sent default: CALLER
			[0x40] @@ @0x20 				;Get the permission names bit data
			[0x60](MOD @0x20 32) 			;Get start position
			[0x80](DIV @0x20 32)	 		;Get Row permission located on.

			[0xC0](MOD (DIV @@(+ @0x40 @0x80) (EXP 2 @0x60)) 8) 	;This is The current permission value
			[0xE0](- @@(+ @0x40 @0x80) (* (EXP 2 @0x60) @0xC0))		;Subtract out all permissions at this slot
			[0xE0](+ @0xE0 (* (EXP 2 @0x60) @0xA0))					;Add in the new permissions at this slot
			[[(+ @0x20 @0x80)]]@0xE0								;Set
			[0x80]1
			(return 0x80 0x20)
		}
	)


;------------------------------------------------------------------------------------------------
;Add rule			- Permission needed: 2
;(replace rule)		- Form: "addrule" "Permission Name" #permission 0xRuleAddress
;					- Returns: 1(success), 0(failure)
;This sets the poll contract which determines whether or not a given permission can be given out
;The contract added here will create these polls and return the address of the created poll

	(when (= @0x0 "addrule")
		{
			;Permission Check - Permission needed: 2
			[0x0]"check"
			[0x20]"ACL"
			[0x40](CALLER)
			(call (- (GAS) 100) (ADDRESS) 0 0x0 0x60 0x60 0x20)

			(unless (= @0x60 2) (STOP)) ;If you do not have the required permissions stop

			;Add a permission rule contract.
			[0x20](calldataload 0x20) 	;Get Permission name this rule belongs to
			[0x40](calldataload 0x40) 	;Get Permission number this rule applies to
			(when (OR (= @0x40 0)(> @0x40 7)) (return 0x60 0x20)) ;Return fail if this is invalid value [1,7]

			(when (= @@ @0x20 0) ;This permission name does not yet exist
				{
					[[@0x20]] (+ (* @@0x11 32) @@0x12) ;Encode where this permission lies in bitstrings
					[[0x12]] (+ @@0x12 3) ;increment start postion
					(when (> @@0x12 252) 
						{
							[[0x12]]0 ;New slot
							[[0x11]](+ @@0x11 1) ;Increment row
						}
					)
				}
			)

			[0x60](calldataload 0x60) 	;Get Rule Address
			[[(+ @0x20 @0x40)]]@0x60	;Copy Rule address to proper slot (name+permission number)
			[0x80]1
			(return 0x80 0x20) ;If it got here return Success
		}
	)


;---------------------------------------------------------------
;Add type 			- Permission needed: 2
; (replace type)	- Form: "addtype" "Type Name" 0xTypeAddress
; 					- Returns: 1(success), 0(failure)
;Similar to Addrule. This Adds "type" of poll managers. The
;Contract listed is actually a poll contract manager - creation
;contract. (what a mouthful!)

	(when (= @0x0 "addtype")
		{
			;Permission Check - Permission needed: 2
			[0x0]"check"
			[0x20]"ACL"
			[0x40](CALLER)
			(call (- (GAS) 100) (ADDRESS) 0 0x0 0x60 0x60 0x20)

			(unless (= @0x60 2) (STOP)) ;If you do not have the required permissions stop

			(unless (calldataload 0x40) (STOP))
			[0x20](+ (calldataload 0x20) 0x200000) ;Get Type name (offset so avoid conflicts with other names)

			(when (= @@ @0x20 0)
				{
					[[@0x20]](calldataload 0x40) ;Copy 0xTypeAddress to type name
					[[(+ @@0x14 1)]]@0x20 ;Link this to the list
					[[@@0x14]]@0x20
				}
			)

		}
	)
}