;ACL

;API
;Request Permission - Permission needed: 0
;					- Form: "reqp" "contract name" #permission
;					- Returns: Nothing
;
;Set Permission 	- Permission needed: 1
;					- Form: "givep" 0xtargetaddress "contract name" #permission
;					- Returns: 1(success), 0(failure)
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