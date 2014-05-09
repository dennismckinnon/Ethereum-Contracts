;User Permissions Manager

;This is a first generation permissions contract Its purpose is to return a value corresponding to the permissions an address has.
;The contract has three types of permissions, Normal members, Admins, and Super-Admins. The first two are distinguished by
;the permissions value they have at address [[userAddress]]. If the first bit is 1 then they have normal member priveleges
;if the second bit is a 1 then they have admin privileges. This contract assumes that if they are an admin they are also a normal
;member. However in general this is not necessary and in the future you can have more bits to represent other priveleges either
;for this contract of for others (once you design a secure API for other contract control of specific bits)

;The Admins have additional structure for them. Admins are placed in a list starting at address 0x20 and growing towards higher
;addresses. If you are lower on the list (or higher if you think of low addresses as being higher up) then you have power over
;admin located in the list at a higher address. (priority much like Reddit Mods). You can not affect an admin that has a lower
;position then you in the list. (You can affect up to and including your level so you can say replace yourself with another
;person lower down)

;A downside to maintaining this additional list structure is that order must be maintained at all times which requires 
;an excessive amount of looping in order to do so. Implementing a better linked list kind of structure would be something to look
;into for future versions. As a quick and dirty solution though this functions fine. (it just might be very expensive to
;manipulate admins later on)

;Super-Admins are distinguish by being on the list at a position less then the "Super admins level" Currently there are no
;additional powers granted to super admins except to modify the super admin level. This feature was left in as a concept
;option. Similarly Normal members have no priveleges in this contract what so ever but since this is intended to be part of a
;DOUG cluster another contract may require require membership to perform actions

;One nice feature of this contract is it is recursive. It will call itself to check permissions of users when modifications are
;to be done 

;API
;
;ANYONE
;Check permissions 		(Format: "check" 0xADDRESS)
;Get Admin position 	(Format: "getadm" 0xADDRESS)
;
;ADMINS
;##suicide (Format: "kill")## commented out
;Register new admin 			(Format: "regadm" 0xMemberaddress)
;Register new member 			(Format: "regmem" 0xMemberaddress)
;Delete member 					(Format: "delmem" 0xMemberaddress)
;Modify super-admin level 		(Format: "modsal" #position)

;

;Structure
;Admin list
;address:permission value

{
	;Metadata  section
	[[0x0]] 0x88554646AB						;metadata notifier
	[[0x1]] (CALLER)							;contract creator
	[[0x2]] "Dennis McKinnon"					;contract Author
	[[0x3]] 0x18042014							;Date
	[[0x4]] 0x000001000							;version XXX.XXX.XXX
	[[0x5]] "User Permissions Contract"			;Name
	[[0x6]] "12345678901234567890123456789012"	;Brief description (not past address 0xF)
	[[0x6]] "This Contract manages user permi"
	[[0x7]] "ssions both for itself (recursiv"
	[[0x8]] "ely and for any contracts reques"
	[[0x9]] "ting from it."

	[[0x10]] 0x9e4d58a9f74d7a5752c712210a9ffbe612f2609f 	;Doug's address
	[[0x11]] 0x23 		;Admin member pointer
	[[0x12]] 0x22		;this is the end position for the list of SUPER-admins
	[[0x13]] 0x20 		;admin list start
	[[0x20]] (ADDRESS)	;Contract is supreme admin over itself
	[[(ADDRESS)]]3 		;Admin+normal
	[[0x21]] 0 			;reserved for Nick
	[[0x22]] (CALLER) 	;Set Caller as first admin
	[[(CALLER)]] 3 		;Admin+normal
	[0x0] "reg"
	[0x20] "user"
	(call (- (GAS) 100) @@0x10 0 0x0 0x40 0x0 0x20); Register with DOUG
}
{
	;Despite the fact that this contract has no dependancies Going to keep DOUG updated regardless
	[0x0]"req"
	[0x20] "doug"
	(call (- (GAS) 100) @@0x10 0 0x0 0x40 0x0 0x20)
	[[0x10]]@0x0 ;Copy new doug over

	[0x0] "req"
	[0x20] "nick"
	(call (- (GAS) 100) @@0x10 0 0x0 0x40 0x0 0x20)
	(unless (|| (= @0x0 @@0x21)(= @@0x21 0))
		[[@@0x21]]0 ;remove old nick permissions
	)
	[[0x21]]@0x0 ;Copy nick into admin over
	[[@@0x21]] 3 ;Nick gets admin rights

	;AND NOW BACK TO YOUR REGULARLY SCHEDULED PROGRAMMING (hehe pun)
	[0x20] (calldataload 0) ;First argument is txtype
	(unless @0x20 (stop)) ;No first argument stop
	
	;Check if a request has been made (check or getadm)
	;if not then assume they want to apply the operation to this contract.
	;Recusively get their permissions before moving on to processing their command

	(if (|| (= @0x20 "check")(= @0x20 "getadm"))
		{
			(if (= @0x20 "check") 	;Get user permissions values
				{
					[0x0] @@(calldataload 32) 	;Permission value at that user
					(return 0x0 0x20) 			;Return the permisions of the user
				}
				{
					;Retrieve Admin Number (position in list)
					[0x60] (calldataload 32) ;Address to check
					(for [0x200] @@0x13 (< @0x200 @@0x11) [0x200](+ @0x200 1) ;Loop to find the 
						{
							(when (= @@ @0x200 @0x60) (return 0x200 0x20)) ;Return the admin number
						}
					)
					[0x0] (- 0 1)
					(return 0 0x20) ;Failure to find admin (send back maximum)
				}
			)
		}
		{
			[0x40] "check"
			[0x60] (CALLER)
			(call (- (GAS) 100) (ADDRESS) 0 0x40 0x40 0 0x20) ;Recusive permissions for this contract!
			(when (= @0x0 0) (stop)) ;if it returns 0 no permissions
		}
	)

	;Process the member number that gets sent. First bit is normal member. Second bit is Admin
	;(In the future this will need to have some simple way to determine when a contract can add permissions to a user!) 

	[0x100](MOD @0x0 2) 		;First bit in this contract refers to normal user
	[0x120](MOD(DIV @0x0 2)2) 	;Second bit is Admin user.
	(when @0x120 				;When they are an admin... get their admin number
		{
			[0x40] "getadm"
			[0x60] (CALLER)
			(call (- (GAS) 100) (ADDRESS) 0 0x40 0x40 0x140 0x20) ;Get Admin number
		}
	)


;Onto Commands

;Removed because no longer necessary
;	;Admin suicide (Format: "kill")
;	(when (&& (= @0x20 "kill") (<= @0x140 @@0x12)) ;SUPER-Admin and say kill suicide + deregister
;		{
;			(suicide @@0x21)
;		}
;	)

	;Admin modify superadmins level (Format: "modsal" #value)
	(when (&& (= @0x20 "modsal") (<= @0x140 @@0x12)) ;SUPER-Admin and send modsal = modify super admin level
		{
			[0x40](calldataload 32)
			[0x20]0
			(when (<= @0x140 0x40) 
				{
					[[0x12]] @0x40
					[0x20] 1
				}
			)
			(return 0x20 0x20)
		}
	)


	;Make normal member (works for admin demotions too!) (Format: "regmem" 0xMemberaddress)
	;Note: This is REALLY (for admins) costly since order must be maintained
	(when (&& (= @0x20 "regmem") (= @0x120 1))
		{
			[0x20] 0 ;Clear for return value
			[0x40] "check"
			[0x60] (calldataload 32) ;Get second data argument
			(call (- (GAS) 100) (ADDRESS) 0 0x40 0x40 0x160 0x20) ;
			(if (= (MOD(DIV @0x160 2)2) 1) ;If the target is an admin
				{
					[0x40] "getadm"
					(call (- (GAS) 100) (ADDRESS) 0 0x40 0x40 0x160 0x20) ;Get the target's admin number (put at 0x160)
					(when (<= @0x140 @0x160) ;If you are a higher Admin then the target
						{
							(for [0x200](+ @@0x13 @0x160) (< @0x200 @@0x11) [0x200](+ @0x200 1) ;Start at admins location and do delete and shuffle
								{ 
									[[@0x200]] @@ (+ @0x200 1)
								}
							)
							
							[[0x11]] (- @@0x11 1) ;Decrement admin pointer
							[[@0x60]] 1 ;Set Target to normal user
							(when (<= @0x160 @@0x12);When the deleted admin was less then the super admin level
								[[0x12]] (- @@0x12 1) ;Decrement the number of SUPER-admins (so someone doesn't get hightened powers)
							)
							[0x20] 1
							
						}
					)
				}
				{
					;If they are not an admin it becomes simple
					(when @0x60
						{
							[[@0x60]] 1; Make them a normal user
							[0x20] 1
						}
					)
				}
			)			
			(return 0x20 0x20) ;Return code
		}
	)


	;Delete Admin member (must be an admin that is higher then the member you re deleting) (Format: "deladm" 0xMemberaddress)
	;Note: This is REALLY costly since order must be maintained

	[0x60] (calldataload 32) ;Get 0xMemberAddress
	(when (&& (= @0x20 "delmem") (|| (= @0x120 1) (= @0x60 (CALLER))))
		{
			[0x20] 0 ;Clear for return value
			[0x40] "check"
			
			(call (- (GAS) 100) (ADDRESS) 0 0x40 0x40 0x160 0x20) ;
			(if (= (MOD(DIV @0x160 2)2) 1) ;If the target is an admin
				{
					[0x40] "getadm"
					(call (- (GAS) 100) (ADDRESS) 0 0x40 0x40 0x160 0x20) ;Get the target's admin number (put at 0x160)
					(when (<= @0x140 @0x160) ;If you are a higher Admin then the target
						{
							(for [0x200]@0x160 (< @0x200 @@0x11) [0x200](+ @0x200 1) ;Start at admins location and do delete and shuffle
								{ 
									[[@0x200]] @@ (+ @0x200 1)
								}
							)
							
							[[0x11]] (- @@0x11 1) ;Decrement admin pointer
							[[@0x60]] 0 ;Delete the guy
							(when (<= @0x160 @@0x12);When the deleted admin was less then the super admin level
								[[0x12]] (- @@0x12 1) ;Decrement the number of SUPER-admins (so someone doesn't get hightened powers)
							)
							[0x20] 1
							
						}
					)
				}
				{
					;If they are not an admin it becomes simple
					(when @0x60
						{
							[[@0x60]]0 ;Delete user
							[0x20] 1
						}
					)
				}
			)			
			(return 0x20 0x20) ;Return code
		}
	)

	;Add/promote admin  (Format: "promem" 0xMemberaddress <position>) (empty postion means put at end of the list)
	;This can promote any user to an admin position <= to the original caller
	(when (&& (= @0x20 "regadm")(= @0x120 1)) ;Admin priveleges required
		{
			[0x40] "check"
			[0x60] (calldataload 32) ;Get second data argument
			[0xA0] (calldataload 64) ;Get third data argument
			(call (- (GAS) 100) (ADDRESS) 0 0x40 0x40 0xC0 0x20) ;Get the current status of the target
			(when @0x60
				{
					(when (MOD(DIV @0xC0 2)2) ;This person is an admin so delete first and then add
						{
							[0x40] "getadm"
							(call (- (GAS) 100) (ADDRESS) 0 0x40 0x40 0x160 0x20)
							[0x20] 0;

							;YOU MUST DO THIS CHECK NOW BECAUSE IN THE RECURSIVE CALL THIS CONTRACT WILL BE THE CALLER AND THEY HAVE 
							;SUPREME PRIVLEGES! 
							(when (<= @0x140 @0x160) ;If you are a higher Admin then the target 
								{
									[0x40] "deladm"
									(call (- (GAS) 100) (ADDRESS) 0 0x40 0x40 0x20 0x20) ;Call this address to delete the user we can now add them back in
								}
							)
							(unless @0x20 (return 0x20 0x20)) ;if the deletion failed stop.
						}
					)
					(if @0xA0
						{
							(if (>= @0xA0 @0x140) ;You can only promote as high as your position
								{
									[0xE0] (+ @0xA0 @@0x13) ;What is the address that it should end up at?

									(for [0x200] @@0x11 (>= @0x200 @0xE0) [0x200](- @0x200 1)
										[[@0x200]] @@(- @0x200 1) ;Copy over the value just below it
									)

									[[@0xE0]] @0x60 ;Copy the promoted member into the new slot
									[[0x11]] (+ @@0x11 1) ;Increment admin numbers
									[[@0x60]] 3; Admin + normal user = 3

									;Run check if this person has been moved into the super admins regions if so add one to superadmins
									[0x20](+ @@0x12 @@0x11)
									(when (<= @0xE0 @0x20) [[0x12]](+ @@0x12 1))
									[0x20] 1
									(return 0x20 0x20) ;Sucess!
								}
								{
									[0x20]0
									(return 0x20 0x20) ;failure
								}
								
							)
						}
						{
							;If not then just add them in the next available slot
							[[@@0x11]] @0x60 ;Store the new member in then next admin slot
							[[@0x60]] 3 ;Admin + normal user = 3
							[[0x11]] (+ @@0x11 1) ;Increment admin pointer
							[0x20] 1 ;Success!
							(return 0x20 0x20) 
						}
					)				
				}
			)
		}
	)

;NO LONGER NECESSARY (I left it here because its the simplest function here now so good example)
;	;Register new admin (Format: "regadm" 0xMemberaddress)
;	(when (&& (= @0x20 "regadm") (= @0x120 1))
;		{
;			[0x20] 0
;			[0x40] (calldataload 32) ;Get second data argument
;			(when @0x40
;				{
;					[[@@0x11]] @0x40 ;Store the new member in then next admin slot
;					[[@0x40]] 3; (normal user + admin = 3)
;					[[0x11]] (+ @@0x11 1) ;Increment admin pointer
;					[0x20] 1 
;				}
;			)
;			(return 0x20 0x20) ;Return Result (pass fail)
;		}
;	)
}