;Consensus contract
;
;Basic Always accepts
{
	[[0x0]] 0x847d424ac77448e0755f208f93e342363a1d811e ;Doug's Address
	[0x0]"reg"
	[0x20]"conc"
	(call @@0x0 0 0 0x0 0x40 0 0) ;Register with doug
}
{
	[0x20] "req"
	[0x40] "doug"
	(call @@0x10 0 0 0x20 0x40 0x0 0x20) ;Ask who you think Doug is who he thinks doug is
	[[0x10]] @0x10 ;Replace who you think doug is with who doug thinks Doug is.

	[0x0] 2 	;Always accept
	[0x20] (calldataload 0x20) ; return [2:contract address]
}