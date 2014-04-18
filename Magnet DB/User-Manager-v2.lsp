;Infohash Database manager with Membership structure

;This is a first generation permissions contract Its purpose is to return a value corresponding to the permissions an address has.

;API
;
;BASIC
;Check permissions (Format: "check" 0xADDRESS)
;
;ADMINS
;suicide (Format: "kill")
;Register new admin (Format: "regadm" 0xMemberaddress)
;Register new member (Format: "regmem" 0xMemberaddress)
;Delete normal member (must be an admin) (Format: "delmem" 0xMemberaddress)
;Delete Admin member (must be an admin that is higher then the member you re deleting) (Format: "deladm" 0xMemberaddress)
;Promote normal member to admin (Combo Delete and Add) (Format: "promem" 0xMemberaddress)
;Promote Admin to higher in the list
;normal members no longer need a list.

;

;Structure
;Admin list
;address:permission value

{
	[[0x0]] 0x13 ;Admin member pointer
	[[0x1]] 2; 0x10+this number is the list of SUPER-admins
	[[0x11]] (ADDRESS); Contract is supreme admin over itself
	[[(ADDRESS)]]3 ;Admin+normal
	[[0x12]] (CALLER) ;Set Caller as first admin
	[[(CALLER)]] 3 ;Admin+normal
	[0x0] "A"
;	(call 0x11d11764cd7f6ecda172e0b72370e6ea7f75f290 0 0 0 1 0 0)
}
{

	[0x20] (calldataload 0) ;First argument is txtype
	(unless @0x20 (stop)) ;No first argument stop
	
	;Check if a request has been made (check or getadm) if not then assume they want to apply the operation to
	;this contract. Recusively get their permissions before moving on to processing thier command
	(if (OR (= @0x20 "check")(= @0x20 "getadm"))
		{
			(if (= @0x20 "check") ;Get user permissions values
				{
					[0x0] @@(calldataload 32) ;Permission value at that user
					(return 0x0 0x20) ;Return the permisions of the user
				}
				{
					;Retrieve Admin Number (position in list)
					[0x60] (calldataload 32) ;Address to check
					[0x0] 0; Counter
					(for [0x200] 0x10 (< @0x200 @@0x0) [0x200](+ @0x200 1) ;Loop to find the 
						{
							(when (= @@ @0x200 @0x60) (return 0 0x20)) ;Return the admin number
							[0x0](+ @0x0 1) ;increment counter
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
			(call (ADDRESS) 0 0 0x40 0x40 0 0x20) ;Recusive permissions for this contract!
			(when (= @0x0 0) (stop)) ;if it returns 0 no permissions
		}
	)

	;Process the member number that gets sent. First bit is normal member. Second bit is Admin
	;(In the future this will need to have some simple way to determine when a contract can add permissions to a user!) 

	[0x100](MOD @0x0 2) ;First bit in this contract refers to normal user
	[0x120](MOD(DIV @0x0 2)2) ;Second bit is Admin user.
	(when @0x120 ;When they are an admin... get their admin number
		{
			[0x40] "getadm"
			[0x60] (CALLER)
			(call (ADDRESS) 0 0 0x40 0x40 0x140 0x20) ;Get Admin number
		}
	)


;Onto Commands

	;Admin suicide (Format: "kill")
	(when (AND (= @0x20 "kill") (<= @0x140 @@0x1)) ;SUPER-Admin and say kill suicide + deregister
		{
;			(call 0x11d11764cd7f6ecda172e0b72370e6ea7f75f290 0 0 0 0 0 0)
			(suicide @@0x10)
		}
	)

	;Admin modify superadmins level (Format: "modsal" #value)
	(when (AND (= @0x20 "modsal") (<= @0x140 @@0x1)) ;SUPER-Admin and say kill suicide + deregister
		{
			[0x40](calldataload 32)
			[0x20]0
			(when (<= @0x120 0x40) 
				{
					[[0x1]] @0x40
					[0x20] 1
				}
			)
			(return 0x20 0x20)
		}
	)

	;Register new admin (Format: "regadm" 0xMemberaddress)
	(when (AND (= @0x20 "regadm") (= @0x120 1))
		{
			[0x20] 0
			[0x40] (calldataload 32) ;Get second data argument
			(when @0x40
				{
					[[@@0x0]] @0x40 ;Store the new member in then next admin slot
					[[@0x40]] 3; (normal user + admin = 3)
					[[0x0]] (+ @@0x0 1) ;Increment admin pointer
					[0x20] 1 
				}
			)
			(return 0x20 0x20) ;Return Result (pass fail)
		}
	)

	;Register new member (Format: "regmem" 0xMemberaddress)
	(when (AND (= @0x20 "regmem")(= @0x120 1)) ;Registration needs admin powers
		{
			[0x20] 0
			[0x40] (calldataload 32) ;Get second data argument
			(when @0x40
				{
					[[@0x40]] 1; (normal user only)
					[0x20] 1 
				}
			)
			(return 0x20 0x20) ;return result (pass fail)
		}
	)


;REMOVED NO LONGER NECESSARY 
	;Delete normal member (must be an admin) (Format: "delmem" 0xMemberaddress)
;	(when (AND (= @0x20 "delmem")(= @0x120 1)) ;Admin priveleges required
;		{
;			[0x20] 0; clear
;			[0x40] (calldataload 32) ;Get second data argument
;			(when @0x40
;				{
;					[[@0x40]]0 ;Delete user
;					[0x20] 1
;				}
;			)
;			(return 0x20 0x20);return result (pass fail)
;		}
;	)

	;Delete Admin member (must be an admin that is higher then the member you re deleting) (Format: "deladm" 0xMemberaddress)
	;Note: This is REALLY costly since order must be maintained
	(when (AND (= @0x20 "delmem") (= @0x120 1))
		{
			[0x20] 0 ;Clear for return value
			[0x40] "check"
			[0x60] (calldataload 32) ;Get second data argument
			(call (ADDRESS) 0 0 0x40 0x40 0x160 0x20)
			(if (= (MOD(DIV @0x160 2)2) 1) ;If the traget is an admin
				{
					[0x40] "getadm"
					(call (ADDRESS) 0 0 0x40 0x40 0x160 0x20) ;Get the target's admin number (put at 0x160)
					(when (<= @0x140 @0x160) ;If you are a higher Admin then the target
						{
							(for [0x200](+ 0x10 @0x160) (< @0x200 @@0x0) [0x200](+ @0x200 1) ;Start at admins location and do delete and shuffle
								{ 
									[[@0x200]] @@ (+ @0x200 1)
								}
							)
							
							[[@0x160]]0 ;Delete member
							[[0x0]] (- @@0x0 1) ;Decrement admin pointer
							[[@0x60]] 0 ;Delete the guy
							(when (<= @0x160 @0x1);When the deleted admin was less then the super admin level
								[[0x1]] (- @@0x1 1) ;Decrement the number of SUPER-admins (so someone doesn't get hightened powers)
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
	(when (AND (= @0x20 "promem")(= @0x120 1)) ;Admin priveleges required
		{
			[0x40] "check"
			[0x60] (calldataload 32) ;Get second data argument
			[0xA0] (calldataload 64) ;Get third data argument
			(call (ADDRESS) 0 0 0x40 0x40 0xC0 0x20) ;Get the current status of the target
			(when @0x60
				{
					(when (MOD(DIV @0xC0 2)2) ;This person is an admin so delete first and then add
						{
							[0x40] "getadm"
							(call (ADDRESS) 0 0 0x40 0x40 0x160 0x20)
							[0x20] 0;

							;YOU MUST DO THIS CHECK NOW BECAUSE IN THE RECURSIVE CALL THIS CONTRACT WILL BE THE CALLER AND THEY HAVE 
							;SUPREME PRIVLEGES! 
							(when (<= @0x140 @0x160) ;If you are a higher Admin then the target 
								{
									[0x40] "deladm"
									(call (ADDRESS) 0 0 0x40 0x40 0x20 0x20) ;Call this address to delete the user we can now add them back in
								}
							)
							(unless @0x20 (return 0x20 0x20)) ;if the deletion failed stop.
						}
					)
					(if @0xA0
						{
							(if (>= @0xA0 @0x140) ;You can only promote as high as your position
								{
									[0xE0] (+ @0xA0 0x10) ;What is the address that it should end up at?

									(for [0x200] @@0x0 (>= @0x200 @0xE0) [0x200](- @0x200 1)
										[[@0x200]] @@(- @0x200 1) ;Copy over the value just below it
									)

									[[@0xE0]] @0x60 ;Copy the promoted member into the new slot
									[[0x0]] (+ @@0x0 1) ;Increment admin numbers
									[[@0x60]] 3; Admin + normal user = 3

									;Run check if this person has been moved into the super admins regions if so add one to superadmins
									[0x20](+ @@0x1 0x10)
									(when (<= @0xE0 @0x20) [[0x1]](+ @@0x1 1))
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
							[[@@0x0]] @0x60 ;Store the new member in then next admin slot
							[[@0x60]] 3 ;Admin + normal user = 3
							[[0x0]] (+ @@0x0 1) ;Increment admin pointer
							[0x20] 1 ;Success!
							(return 0x20 0x20) 
						}
					)
					
				}
			)
		}
	)

	;Promote


}