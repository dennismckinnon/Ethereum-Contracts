;Whenever Will gets a transaction he returns who Doug is (he first asks who he thought Doug was)
{
	[[0x0]] 0 ;Doug's address
}
{
	(if (= @@0x0 0)
		{
			[[0x0]](CALLER)
		}
		{
			[0x20] "req"
			[0x40] "doug"
			(call @@0x0 0 0 0x20 0x40 0x60 0x20) ;Find out who doug is
			[[0x0]]@0x60
		}
	)
	[0x0] @@0x0
	(return 0x0 0x20) ;Return who doug is
}