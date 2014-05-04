;ACL

;Default behaviour: If the Contract name has been registered but the rule for a specific permission level
;					does not yet exist. The the permission is granted automatically.
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
;Request Permission - Permission needed: 0
;					- Form: "reqp" "contract name" #permission
;					- Returns: Nothing
;
;Set Permission 	- Permission needed: 1
;(give/change)		- Form: "setp" 0xtargetaddress "contract name" #permission
;					- Returns: 1(success), 0(failure)
;
;Add rule			- Permission needed: 2
;(replace rule)		- Form: "addrule" 0xRuleaddress "contract name" #permission
;
;Permissions
;@Address bitstring 
;+1
;...
;
;@"contract name" row|len|start position
;+1 Address for permission 1
;+2 Address for permission 2
;...
;+7 Address for permission 7
;
