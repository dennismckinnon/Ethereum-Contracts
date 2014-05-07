;Doug-v4
;

;API
;Check Name 	- Permission needed: 0
; 				- Form: "check" "Name"
;				- Returns: 0 (DNE), 0xContractAddress

;Data Dump 		- Permission needed: 0
;				- Form: "dump"
;				- Returns: list["Name":0xContractAddress]

;In list? 	 	- Permission needed: 0
; (Known names)	- Form: "known" "Name"
;				- Returns: 1 (Is Known), 0 (Not)

;Get DB Size 	- Permission needed: 0
;				- Form: "dbsize"
;				- Returns: # of entries

;Register Name 	- Permission needed: 1
;				- Form: "register" "Name" <0xTargetAddress>
;				- Returns: 1 (Success), 0 (Failure)

