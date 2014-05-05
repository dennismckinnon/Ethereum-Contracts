;Consensus contract
;
;Two Api Calls (it only accepts from Doug)
;Create, Format: "create" "name" 0xContractaddress
;Creates a poll contract for this contractID and this name, and creates a list entry
;The list entry will have a quadruplet of values"
;	Descision (0-undecided/ 1-rejected/ 2-Accepted)
;	Poll Contract Address
;	"name"
;	ContractID



{
	;Metadata  section
	[[0x0]] 0x88554646AB						;metadata notifier
	[[0x1]] (CALLER)							;contract creator
	[[0x2]] "Dennis McKinnon"					;contract Author
	[[0x3]] 0x18042014							;Date
	[[0x4]] 0x000001000							;version XXX.XXX.XXX
	[[0x5]] "Poll manager contract"				;Name
	[[0x6]] "12345678901234567890123456789012"	;Brief description (not past address 0xF)
	[[0x6]] "This Contract reports only to do"
	[[0x7]] "ug and allows doug to create pol"
	[[0x8]] "ls on wether a proposed contract"
	[[0x9]] "gets implemented."

	;Initialization of program
	[[0x10]] 0 				;Doug's Address (insert before making)
	[[0x11]] 0x40 			;Poll list start
	[[0x12]] @@0x11 		;Poll list pointer (it starts 4 after the start because start will be used for swaps)

	[0x0] "reg"
	[0x20] "conc"
	(call @@0x10 0 0 0x0 0x20 0 0) ;Register for name "conc" with doug
}
{
	;Always start by asking who Doug is
	[0x20] "req"
	[0x40] "doug"
	(call @@0x10 0 0 0x20 0x40 0x0 0x20) ;Ask who you think Doug is who he thinks doug is
	[[0x10]] @0x10 ;Replace who you think doug is with who doug thinks Doug is.

	;get dependancies

	[0x20](calldataload 0)

	;vote forwarding Format: "vote" 0xPolladdress #vote (the vote can be any number the vote contract will handle interpretation)
	(when (= @0x20 "vote")
		{
			[0x40] (calldataload 0x20) ;polladdress
			[0x60] (calldataload 0x40) ;vote
			[0x80] (CALLER)
			[0xA0] @@ @0x40 ;list pointer

			(call @0x40 0 0 0x60 0x20 0x0 0x20) ;register vote returns 0 if still undecided or result if decided
			[[@0x80]] @0x0 ;store the result at the result slot in the list
			(stop) this doesn't return anything 
		}
	)

	(unless (= (CALLER) @@0x0)) ;From this point on only calls from doug will be accepted

	;Now the meat


	(when (= 0x20 "check") ;no arguments i simply returns the first item in the list with non-zero result and deletes
		{
			(for [0x100]@@0x11 (< @100 @@0x12) (+ @@0x12 4) ;loop through entries
				{
					(when (> @@ @0x100 0)
						[0x0] @@ @0x100 		;Result
						[0x20] @@ (+ @0x100 3) 	;Target contract ID

						;Before returning delete from list
						[[0x12]](- @@0x12 4);Decrement list pointer

						[[@@(+ @@0x12 1)]] @0x100 ;Store the pointer to the new block 
						[[@@(+ @0x100 1)]] 0; Delete old pointer (not necessary but I like to be clean)

						[0x80]"kill"
						(call (+ @0x100 1) 0 0 0x80 0x0 0x0) ;Remove poll contract

						;Copy over from last slot and delete 
						[[@0x100]] @@ @@0x12
						[[@@0x12]]0
						[[(+ @0x100 1)]] @@ (+ @@0x12 1)
						[[(+ @@0x12 1)]] 0
						[[(+ @0x100 2)]] @@ (+ @@0x12 2)
						[[(+ @@0x12 2)]] 0
						[[(+ @0x100 3)]] @@ (+ @@0x12 3)
						[[(+ @@0x12 3)]] 0



						(return 0x0 0x40) ;return the result
					)
				}
			)

		}
	)

	(when (= @0x20 "create") ;create a poll
		{
			[0x40](calldataload 0x20) ;name
			[0x60](calldataload 0x40) ;contract ID

			;Create Poll contract [0x80] stores address
			(if (= @0x40 "doug")
				{
					;modifying doug requires a special type on contract
				}
				{
					;everything else I have set to a defualt type of contract (you could add more cases here)
					;NOTE you should always have a default case so if a contract tries to register a name not recognized
					;It can handle it correctly
				}
			)	

			;Send data to contract
			[0xA0] "init"
			[0xC0] @0x40
			[0xE0] @0x60
			(call @0x60 0 0 0xA0 0x60 0x0 0x20) ;Initialize contract (it returns if there was a decision already)

			(if (OR (= @0x0 1)(= @0x0 2))
				{
					;Decision already made so return
					[0x20] @0x40
					[0x40] "kill"
					(call @0x60 0 0 @0x40 0x20 0 0) ;Kill the poll contract
					(return 0x0 0x40) ;return the result
				}
				{
					;Create list entry
					[[@@0x12]] 0 			;Decision has not been made yet
					[[(+ @@0x12 1)]] @0x60 	;Poll contract Address
					[[(+ @@0x12 2)]] @0x20 	;Name
					[[(+ @@0x12 3)]] @0x40 	;Target Contract Address

					[[@0x80]] @@0x12 		;Store list pointer for poll id

					[[0x12]](+ @@0x12 4)	;increment list pointer
					[0x0]0
					[0x20]0
					(return 0x0 0x40) ;return no result
				}
			)
		}
	) 
}