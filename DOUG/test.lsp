{
	[[0x10]]19
	[[16]]test
	[[17]]256
	[[18]]257
	[[19]]258
	[[256]] 0x63deadbeef600570000000000000000000000000000000000000000000000000
	[[257]] 0x33ff000000000000000000000000000000000000000000000000000000000000
}
{
	[0x20](calldataload 0)
	(when (= @0x20 "create")
		{
			[0x40](calldataload 0x20)
			(for [0x100]16 (> @0x100 @@0x10) [0x100](+ @0x100 4)
				{
					(when (= @@ @0x100 @0x40)
						{
							[0x80]@@(+ @0x100 1)
							[0xA0]@@(+ @0x100 2)
							[0xC0]@@(+ @0x100 3)
							[0x120](- @0xA0 @0x80)
							[0x140](- @0xC0 @0xA0)
						}
					)
				}
			)
			(for [0x100]@@ @0x80 (> @0x100 @@0xC0) (+ @0x100 1)
				{
					[@0x100]@@ @0x100 ;copy into memory
				}
			)

			[0x160](CREATE 0 @0x80 @0x120 @0xA0 @0x140)
			[[0x100]]@0x160
		}
	)
}