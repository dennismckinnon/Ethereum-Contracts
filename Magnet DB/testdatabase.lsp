{
	[[0x0]](caller) ;Set admin
	[[0x1]] 32 ;Number of segments per item
	[[0x2]] 0x50 ;infohash list pointer
	[[0x3]] 0 ;0xADDRESS OF WILL
	[[0x4]] 0 ;0xADDRESS OF DOUG
	[[0x5]] 0 ;0xADDRESS OF USER MANAGER - ONE of these must be filled in or the admin must set it before anything will happen
	[[0x6]] (* (EXP 0x100 21) @@0x1) ;Where to start the inforhash look up. 20 bytes hence 21
	[[0x7]] 3 ;count number of entries

	[[(+ 0xDEADBEEF @@0x6)]]0x10 ;first entry pointer
	[[0x10]]0xDEADBEEF
	[[0x11]]0x38155ef3698a43b24b054d816a8a5f79fc148623
	[[0x12]]"Dennis Mckinnon"
	[[0x13]]"Nuclear Launch codes"
	[[0x14]]"crappy"
	[[0x15]]"Do you hear the people sing?"
	[[0x16]]""
	[[0x17]]"12345678901234567890123456789012"
	[[0x17]]"Hello Andreas! How are you today"
	[[0x18]]"? I really hope this code has wo"
	[[0x19]]"rked because its pretty hard to "
	[[0x20]]"hand code this text case. :P"


	[[(+ 0xFEEDFACE @@0x6)]]0x30;
	[[0x30]]0xFEEDFACE
	[[0x31]]0x38155ef3698a43b24b054d816a8a5f79fc148623
	[[0x32]]"Androlo-the-awesome"
	[[0x33]]"Secret plans"
	[[0x34]]"not too bad"
	[[0x35]]"How to take over Denmark"
	[[0x36]]""
	[[0x37]]"Damn Denmarkians! We will get th"
	[[0x38]]"em this time! mark my words!"
}
{
	(suicide (CALLER))
}