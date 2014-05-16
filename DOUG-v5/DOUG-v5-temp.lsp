;Doug-v5
;
;Default Behaviour: If a name has not been registered before, Automatically accept

;Usage:		

;TODO have automatic call to 0xtarget for permission "execute" it can be ignored but its nice for automation?


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
;Check Name 	- Permission needed: 0
; 				- Form: "check" "Name"
;				- Returns: 0 (DNE), 0xContractAddress

;Get DB Size 	- Permission needed: 0
;				- Form: "dbsize"
;				- Returns: # of entries

;Data Dump 		- Permission needed: 0
;				- Form: "dump"
;				- Returns: list["Name":0xContractAddress]

;In list? 	 	- Permission needed: 0
; (Known names)	- Form: "known" "Name"
;				- Returns: 1 (Is Known), 0 (Not)

;Register Name 	- Permission needed: 1
;				- Form: "register" "Name" <0xTargetAddress>
;				- Returns: 1 (Success), 0 (Failure)

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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

;Structure
;=========

;Names List
;----------
;The Names list is implemented as a linked list for future proofability
;At some point in the future it might be desirable to be able to edit 
;And store some data tied to a contract name. This is not currently used
;But would be easy to add in slots "name"+i>2. This linked list is
;Bi-Directional in order to future proof incase deletions are someday 
;wanted.
; 
;@@"name" 0xContractAddress
;+1 "previous name"
;+2 "next name"

;Name History
;------------
;This version of Doug will store a history of every contract which has
;Been registered to Doug for each nameover the course of his existance.
;It is implemented as a uni-directional linked list starting at "name"
;
;@0xContractforname 0xPreviouscontractforname

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

;Permissions for address
;@Address bitstring 
;+1
;...
;
;Permission storage by name (internal offset of 0x100000)
;@"permission name"+0x100000 row|start position
;+1 Address for permission 1
;+2 Address for permission 2
;...
;+7 Address for permission 7
;
;position number between 1-32 (5 bits)
;
;PCM storage by name (internal offset of 0x200000)
;@"type name" + 0x200000 0xPCMCCAddress


;======================================================================
;

;TODO
;Allow permissions to be created without adding a rule

{
	;METADATA SECTION
	[[0x0]] 0x88554646AB						;metadata notifier
	[[0x1]] (CALLER)							;contract creator
	[[0x2]] "Dennis McKinnon"					;contract Author
	[[0x3]] 0x013052014							;Date
	[[0x4]] 0x001005000							;version XXX.XXX.XXX
	[[0x5]] "doug" 								;Name
	[[0x6]] "12345678901234567890123456789012"	;Brief description (not past address 0xF)
	[[0x6]] "Doug is a Decentralized Organiza"
	[[0x7]] "tion Upgrade Guy. His purpose is"
	[[0x8]] "to serve a recursive register fo"
	[[0x9]] "r contracts belonging to a DAO s"
	[[0xA]] "other contracts can find out whi"
	[[0xB]] "ch addresses to reference withou"
	[[0xC]] "hardcoding. It also allows any c"
	[[0xD]] "contract to be swapped out inclu"
	[[0xE]] "ding DOUG himself."

	;INITIALIZATION
	[[0x10]] 0x11d11764cd7f6ecda172e0b72370e6ea7f75f290 ;NameReg address
	[[0x11]] 1  			; Number of registered names

	[[0x12]] 0x1000000 ;Good form zeros
	[[0x13]] 0x100000  ;Offset

	[[0x14]] 3 	;Next free bit location
	[[0x15]] 0 	;Permission row

	;Name Linked list
	[[0x16]] 0x17 ; Set tail
	[[0x17]] "doug" ;	Set head

	[[0x19]]"doug"	    	; Add doug as first in name list (for consistancy) 
	[["doug"]](ADDRESS)		; Register doug with doug
	[[(+ "doug" 1)]]0x17 	; Set previous to tail

;	NAME REGISTRATION
;	[0x0]"Doug - Revolution"
;	(call (- (GAS) 100) @@0x10 0 0x0 0x11 0 0) ;Register the name DOUG

	[["DOUG"]]0 ;DOUG permissions located at 0th root start position 0
	[[(CALLER)]]1 ;Give (CALLER) full DOUG permissions to start

}
{

;DOUG Functions
;=================================================================================

;-----------------------------------------------------
;Check Name 	- Permission needed: 0
; 				- Form: "checkname" "Name"
;				- Returns: 0 (DNE), 0xContractAddress
;Get the Contract Address currently associated with "name"

	[0x0](calldataload 0) ;Get command
	(when (= @0x0 "checkname")
		{
			(unless (= (MOD (calldataload 0x20) @@0x12) 0) (STOP)) ;name must be of good form
			[0x20]@@(calldataload 0x20) ;Get address associated with "name"
			(return 0x20 0x20) ; Return the Address
		}
	)

;--------------------------------------
;Get DB Size 	- Permission needed: 0
;				- Form: "dbsize"
;				- Returns: # of entries

	(when (= @0x0 "dbsize")
		{
			[0x20]@@0x11 	;Fetch the list size from storage (slot 0x11)
			(return 0x20 0x20) 	;Return the result
		}
	)

;--------------------------------------------------------
;Data Dump 		- Permission needed: 0
;				- Form: "dump"
;				- Returns: list["Name":0xContractAddress]
	
	(when (= @0x0 "dump")
		{
			;Start at Tail
			[0x20] @@(+ @@0x16 2)
			[0x40]0x100
			(while @0x20 ;Loop until end is found
				{
					;
					[@0x40]@0x20 				; @0x20 is "name"
					[(+ @0x40 0x20)]@@ @0x20 	; @@ @0x20 is contract address
					[0x20]@@(+ @0x20 2)			; "name"+2 is pointer to next name in list (0 if at end)
					[0x40](+ @0x40 0x40)		; Increment memory pointer
				}
			)
			;All Stored in memory now return it
			(return 0x100 (- @0x40 0x100))
		}
	)

;-----------------------------------------------
;In list? 	 	- Permission needed: 0
; (Known names)	- Form: "known" "Name"
;				- Returns: 1 (Is Known), 0 (Not)
;This is a largely unecessary function which
;returns 1 if a name is in the registered list
;and 0 otherwise

	(when (= @0x0 "known")
		{
			(unless (= (MOD (calldataload 0x20) @@0x12) 0) (STOP)) ;if name is not of good form return 0
			[0x20](calldataload 0x20) ;Get "name"
			[0x40]0
			(when @@ @0x20 [0x40]1) ;When there is a Contract listed at Name
			(return 0x40 0x20)	;Return result
		}
	)

	(unless (= @@"doug" (ADDRESS)) (STOP)) ;If no longer "doug" do not allow any of the further functions

;-----------------------------------------------------------
;Register Name 	- Permission needed: 1
;				- Form: "register" "Name" <0xTargetAddress>
;				- Returns: 1 (Success), 0 (Failure)

	(when (= @0x0 "register")
		{
			[0x20] (calldataload 0x20) 		; Get "name"
			[0x40] (calldataload 0x40)		; Get Target address
			(unless @0x40 [0x40](CALLER))	; If Target address not provided Default: (CALLER)

			(unless (&& (> @0x20 0x20) (> @0x40 0x20) (= (MOD @0x40 @@0x12) 0)) (STOP)); Prevent out of bounds registrations

			[0x60] 0 	;where permission will be stored (cleared out just to be safe)
			(if @@ @0x20 ;If the name is taken
				{
					[0x80]"checkperm"
					[0xA0]"doug"
					[0xC0](CALLER) 
					(call (- (GAS) 100) (ADDRESS) 0 0x80 0x60 0x60 0x20)
				}
				{
					[0x60]1
				}
			)

			(unless (= @0x60 1) (STOP)) ;If permissions are not 1 then stop

			
			(if (= @@ @0x20 0) ;name does not exist yet
				{
					;Perform appending to list
					[[@0x20]] @0x40 ;Store target at name
					[[(+ @0x20 1)]] @@0x17 	;Set previous to value in head
					[[(+ @@0x17 2)]] @0x20 	;Set head's next to current name
					[[0x17]]@0x20 			;Set Head to current name
					[[0x11]](+ @@0x11 1) 	;Increment names counter
				}
				{
					;Don't append but push name history down
					(unless (= @@ @0x40 0) (STOP)) ;Ensure writing to target won't overwrite anything
					[[@0x40]] @@ @0x20 	;Copy previous contract to pointer of new contract
					[[@0x20]] @0x40 	;Register target to name
					(when (= @0x20 "doug")
						{
							;Deregister from Namereg
							(call (- (GAS) 100) @@0x1 0 0 0 0 0)
						}
					)
				}
			)
			[0xC0]1
			(return 0xC0 0x20)
		}
	)


;Permissions Functions
;==================================================================================================

;--------------------------------------------------------------------------------
;Check Permission 	- Permission needed: 0
;					- Form: "checkperm" "Permission Name" <0xTargetAddress>
;					- Returns: Permission number requested
; Checks what permission level the target address has for permission given by
;"Permission Name" if no target provided, Defaults to CALLER

	(when (= @0x0 "checkperm")
		{
			;Check what permission target has. If Target not provided defaults to CALLER
			(unless (= (MOD (calldataload 0x20) @@0x12) 0) (STOP)) ;Permission name should be of good form
			[0x20](+ (calldataload 0x20) @@0x13) 	;Get Permission Name
			(unless (|| @@ @0x20 (= (calldataload 0x20) "doug")) (STOP)) ;Stop if permission does not exist

			[0x40](calldataload 0x40) 		;Get Target (optional argument)
			(unless @0x40 [0x40](CALLER))	;If Target not sent default: CALLER
			[0x60] @@ @0x20 				;Get the permission names bit data
			[0x80](MOD @0x60 256) 			;Get start position (first 8 bits)
			[0xA0](DIV @0x60 256)	 		;Get Row permission located on. (whatever is left)

			[0x0](MOD (DIV @@(+ @0x40 @0xA0) (EXP 2 @0x80)) 8) 	;This is The permission value
			(return 0x0 0x20) ;Return requested value
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
			[0x20](calldataload 0x20) ;Number of permissions fetching
			[0x60]0x100 ;Memory slot starting place
			[0x80]0x40 	;calldata pointer

			(for [0x40]0 (< @0x40 @0x20) [0x40](+ @0x40 1)
				{
					;Copy data over
					[0xA0](+ (calldataload @0x80) @@0x13) ;Permission name
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

			[0x0](+ (calldataload 0x20) (MUL 2 @@0x13)) ;Type name +offset
			(unless (&& (calldataload 0x20) @@ @0x0 (= (MOD (calldataload 0x20) @@0x12) 0)) (STOP)) ;Don't allow empty names and must be of good form

			(call (- (GAS) 100) @@ @0x0 0 0 0 0x0 0x20) ;Call PCMCC for type

			[[@0x0]](| @@ @0x0 0x1) ;Set the permissions for DOUG to be 1 (PCM can modify doug)

			;Stage 2 - Initialize the PCM
			[0x20](calldataload (+ (* (calldataload 0x40) 0x40) 0x60)) ;Get target address
			(CALLDATACOPY 0x40 0x20 (CALLDATASIZE))
			[0x40]"init" ;Modify command for passing data along
			(if @0x20 ;initialize PCM
				{
					(call (- (GAS) 100) @0x0 0 0x40 (- (CALLDATASIZE) 0x20) 0x0 0x0)
				}
				{
					[(+ (CALLDATASIZE) 0x20)](CALLER) ;If target not specified default to (CALLER)
					(call (- (GAS) 100) @0x0 0 0x40 (CALLDATASIZE) 0x0 0x0)
				}
			)
			(STOP)
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
			;Permission Check - Permission needed: 1
			[0x0]"checkperm"
			[0x20]"doug"
			[0x40](CALLER)
			(call (- (GAS) 100) (ADDRESS) 0 0x0 0x60 0x40 0x20)

			(unless (= @0x40 1) (STOP)) ;If you do not have the required permissions stop

			;Set Permission. If Target not provided defaults to CALLER
			(unless (= (MOD (calldataload 0x20) @@0x12) 0) (STOP)) ;Permission name must be of good form
			[0x20](+ (calldataload 0x20) @@0x13) 		;Get Permission Name (offset)
			[0xA0](MOD (calldataload 0x40) 8)	;Get The permission number to set
			[0x40](calldataload 0x60) 			;Get Target (optional argument)
			(unless @0x40 [0x40](CALLER))		;If Target not sent default: CALLER
			[0x20] @@ @0x20 				;Get the permission names bit data
			[0x60](MOD @0x20 256) 			;Get start position
			[0x80](DIV @0x20 256)	 		;Get Row permission located on.

			[0xC0](MOD (DIV @@(+ @0x40 @0x80) (EXP 2 @0x60)) 8) 	;This is The current permission value
			[0xE0](- @@(+ @0x40 @0x80) (* (EXP 2 @0x60) @0xC0))		;Subtract out all permissions at this slot
			[0xE0](+ @0xE0 (* (EXP 2 @0x60) @0xA0))					;Add in the new permissions at this slot
			[[(+ @0x40 @0x80)]]@0xE0								;Set
			[0x80]1
			(return 0x80 0x20)
		}
	)


;------------------------------------------------------------------------------------------------
;Add rule			- Permission needed: 1
;(replace rule)		- Form: "addrule" "Permission Name" #permission 0xRuleAddress
;					- Returns: 1(success), 0(failure)
;This sets the poll contract which determines whether or not a given permission can be given out
;The contract added here will create these polls and return the address of the created poll

	(when (= @0x0 "addrule")
		{
			;Permission Check - Permission needed: 1
			[0x0]"checkperm"
			[0x20]"doug"
			[0x40](CALLER)
			(call (- (GAS) 100) (ADDRESS) 0 0x0 0x60 0x60 0x20)

			;Security Checks
			(unless (= @0x60 1) (STOP)) ;If you do not have the required permissions stop
			(unless (calldataload 0x60) (STOP)) ;Type address must be provided
			(unless (AND (> (calldataload 0x20) 0x20) (= (MOD (calldataload 0x20) @@0x12)) 0) (STOP)) ;name in range and name of "good form"

			;Add a permission rule contract.
			[0x20](+ (calldataload 0x20) @@0x13) 	;Get Permission name this rule belongs to (offset)
			[0x40](calldataload 0x40) 	;Get Permission number this rule applies to
			(when (OR (= @0x40 0)(> @0x40 7)) (STOP)) ;Return fail if this is invalid value [1,7]

			(when (= @@ @0x20 0) ;This permission name does not yet exist
				{
					[[@0x20]] (+ (* @@0x15 256) @@0x14) ;Encode where this permission lies in bitstrings
					[[0x14]] (+ @@0x14 3) ;increment start postion
					(when (> @@0x14 252) 
						{
							[[0x14]]0 ;New slot
							[[0x15]](+ @@0x15 1) ;Increment row
						}
					)
				}
			)

			[[(+ @0x20 @0x40)]](calldataload 0x60)	;Copy Rule address to proper slot (name+permission number)
			[0x80]1
			(return 0x80 0x20) ;If it got here return Success
		}
	)


;---------------------------------------------------------------
;Add type 			- Permission needed: 1
; (replace type)	- Form: "addtype" "Type Name" 0xTypeAddress
; 					- Returns: 1(success), 0(failure)
;Similar to Addrule. This Adds "type" of poll managers. The
;Contract listed is actually a poll contract manager - creation
;contract. (what a mouthful!)

	(when (= @0x0 "addtype")
		{
			;Permission Check - Permission needed: 1
			[0x0]"checkperm"
			[0x20]"doug"
			[0x40](CALLER)
			(call (- (GAS) 100) (ADDRESS) 0 0x0 0x60 0x60 0x20)

			;Security Checks
			(unless (= @0x60 1) (STOP)) ;If you do not have the required permissions stop
			(unless (calldataload 0x40) (STOP)) ;Type address provided
			(unless (AND (> (calldataload 0x20) 0x20) (= (MOD (calldataload 0x20) @@0x12)) 0) (STOP)) ;name in range and name of "good form"

			[0x20](+ (calldataload 0x20) (MUL 2 @@0x13)) ;Get Type name (offset so avoid conflicts with other names)
			[[@0x20]](calldataload 0x40) ;Copy 0xTypeAddress to type name
			(STOP)
		}
	)

;-----------------------------------------------------------------
;Add Permission 	- Permission needed: 1
;					- Form: "addperm" "Permission Name"
; 					- Returns: 1(success), 0(failure)
;This adds a permission without requiring you to add a rule for any
;of its permission levels. (Useful for the case where you want the
;permission only obtainable through set)
	(when (= @0x0 "addtype")
		{
			;Permission Check - Permission needed: 1
			[0x0]"checkperm"
			[0x20]"doug"
			[0x40](CALLER)
			(call (- (GAS) 100) (ADDRESS) 0 0x0 0x60 0x60 0x20)

			;Security Checks
			(unless (= @0x60 1) (STOP)) ;If you do not have the required permissions stop
			(unless (AND (> (calldataload 0x20) 0x20) (= (MOD (calldataload 0x20) @@0x12)) 0) (STOP)) ;name in range and name of "good form"

			[0x20](+ (calldataload 0x20) @@0x13) 	;Get Permission name this rule belongs to (offset)

			(when (OR @@ @0x20 (= (calldataload 0x20) "doug")) (STOP)) ;Can't add a permission which already exists 

			[[@0x20]] (+ (* @@0x15 256) @@0x14) ;Encode where this permission lies in bitstrings
			[[0x14]] (+ @@0x14 3) ;increment start postion
			(when (> @@0x14 252) 
				{
					[[0x14]]0 ;New slot
					[[0x15]](+ @@0x15 1) ;Increment row
				}
			)
		}
	)
}

