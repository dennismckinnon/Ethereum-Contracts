;ACL

;Default behaviour: If the Contract name has been registered but the rule for a specific permission level
;					does not yet exist. The the permission is automatically rejected.
;					If the contract name does not exist then the request is automatically rejected
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
;Request Permission - Permission needed: 0
;					- Form: "request" "Permission Name" #permission <0xTargetAddress>
;					- Returns: Nothing
;
;Set Permission 	- Permission needed: 1
;(give/change)		- Form: "set" "Permission Name" #permission <0xTargetAddress>
;					- Returns: 1(success), 0(failure)
;
;Add rule			- Permission needed: 2
;(replace rule)		- Form: "add" "Permission Name" #permission 0xRuleAddress
;					- Returns: 1(success), 0(failure)
;
;
;Permissions
;@Address bitstring 
;+1
;...
;
;@"contract name" row|start position
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
	[[0x12]] 0 				;Current allocation start position
}
{
	;Doug Update
	[0x0]"check"
	[0x20]"doug"
	(call (- (GAS) 100) @@0x10 0 0x0 0x40 0x0 0x20)
	[[0x10]] @0x0

	[0x0](calldataload 0)
	(when (= @0x0 "check") 		;Form: "check" 0xTargetAddress "Permission name"
		{
			;Check what permission target has. If Target not provided defaults to CALLER
			[0x20](calldataload 0x20) 		;Get Permission Name
			[0x40](calldataload 0x40) 		;Get Target (optional)
			(unless @0x40 [0x40](CALLER))	;If Target not sent default: CALLER
			[0x40] @@ @0x20 				;Get the permission names bit data
			[0x60](MOD @0x20 32) 			;Get start position
			[0x80](DIV @0x20 32)	 		;Get Row permission located on.

			[0xA0](MOD (DIV @@(+ @0x40 @0x80) (EXP 2 @0x60)) 8) 	;This is The permission value
			(return 0xA0 0x20) ;Return requested value
		}
	)

	(when (= @0x0 "request") 	;Form: "req" "Permission Name" #permission <0xTargetAddress>
		{
			;Request the permission. If Target not provided defaults to CALLER
		}
	)

	(when (= @0x0 "set")		;Form: "set" "Permission Name" #permission <0xTargetAddress>
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

	(when (= @0x0 "add") 		;Form: "add" "Permission Name" #permission 0xRuleAddress
		{
			;Permission Check - Permission needed: 2
			[0x0]"check"
			[0x20]"ACL"
			(call (- (GAS) 100) (ADDRESS) 0 0x0 0x40 0x40 0x20)

			(unless (= @0x40 2) (STOP)) ;If you do not have the required permissions stop

			;Add a permission rule contract.
			[0x20](calldataload 0x20) 	;Get Permission name this rule belongs to
			[0x40](calldataload 0x40) 	;Get Permission number this rule applies to
			(when (OR (= @0x40 0)(> @0x40 7)) (return 0x60 0x20)) ;Return fail if this is invalid value [1,7]
			[0x60](calldataload 0x60) 	;Get Rule Address
			[[(+ @0x20 @0x40)]]@0x60	;Copy Rule address to proper slot (name+permission number)
			[0x80]1
			(return 0x80 0x20) ;If it got here return Success
		}
	)
}





















