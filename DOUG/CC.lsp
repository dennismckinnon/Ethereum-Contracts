;Consensus contract
;
;Basic Always accepts
{
	[[0x0]] 0x2341ce496f485309329ead1a4e5a0f038515705e ;Doug's Address
	[0x0]"reg"
	[0x20]"conc"
	(call @@0x0 0 0 0x0 0x40 0 0) ;Register with doug
}
{
	[0x0](calldataload 0)
	(when (= (calldataload 0) "create")
		{
			[0x0] 2 	;Always accept
			[0x20] (calldataload 0x20) ; return [2:contract address]
			(return 0x0 0x40)
		}
	)
	(when (= (calldataload 0) "check")
		{
			[0x0]0
			[0x20] 0
			(return 0x0 0x40) ;This contract never stores anything so there is nothing to check
		}
	)
	(when (= (calldataload 0))
		{
			[0x0]0
			[0x20] 0
			(return 0x0 0x40) ;No voting available yet
		}
	)
}