;0 GameLocator?
;1 Player1
;2 Player2
;3 GameName
;4 game data turn/PIECELOCK?/winner/running
;5 gameboard 8 entries 8 hex digits
;12 pieces left +0x0 +0x1 
;15 pieces list +0x0 - +0x31 0x0-0x15 = player 1 rest player 2 format is exist?/king?/row/location
;48 tie
;49 last move time etc.
;50 -slots per game

;0x0 admin
;0x1 Scoreboard Address
;0x2 Game pointer

;Transaction types
;"new"  - Number 1 (no arguments allowed for now)
;"join" - Number 2 (1 argument Game number)
;"move" - Number 3 (2 arguments gamenumber move (1-4))
;"Tie request"  - Number 4
;"Quit" - Number 5
;"req timekill" - Number 6
;"admin"- number 7 (1 argument for specifc option 1=suicide)

{
	;Initialization (Whatever I want to do there)
	[[0x0]] (caller) ;Admin!
	[[0x2]] 0x10
	[0]:"Checkers" ;You can put a more specific name here
	(call NAMEREGADDR 0 0 0 8 0 0) ;Register with name registration
}
{
	(if (callerdatasize)
		{
			;Input Processing
			[0x0] (calldataload 0) ;Transaction type number
			(when (= @0x0 1)
				[0x1] (calldataload 32) ;Data value 1 (game num or admin option) ;CHANGE THIS SECTION NEED TO PERFORM MORE SPECIFIC CHECKS FOR PROPER GAME NUM ETC
				(when (= @0x0 3)
					{
						[0x2] (calldataload 64) ;Data value for piece (0-B)
						[0x3] (calldataload 96) ;Data Value for move direction (0-3)
					}
				)
			)
		}
		(stop)
	)
	;Case Separation
	(when (= @0x0 3) ;Make Move (Most common)
		{
			[0x1] (calldataload 32) ;Game Num
			(unless (AND (> @0x1 0x10)(= (MOD (- @0x1 0x10) 50) 0)) (stop)) ;Make sure its a valid game number
			(unless (AND (<= @0x2 0xB)(>= @0x2 0)) (stop)) ;Check valid  piece number
			(unless (AND (<= @0x3 0x3)(>= @0x3 0)) (stop)) ;Check if valid move number

			;copy some useful values into memory
			[gdaddr] (+ @0x1 4) ;Game Data Address
			[gd] @@(@gdaddr)    ;Game Data

			[ply1raddr] (+ @0x1 1) ;Player 1 address location
			[ply2raddr] (+ @0x1 2) ;Player 2 address location


			;WHO IS PLAYER?
			[player] 1
			(when (= (caller) @@(@plyr2addr)) {[player] 2})

			[pstart] (+ @0x1 15) ;Address the piece data starts at
			[piece] (+ (* @player 0x10) @0x2) ;Piece name as it appears on the board
			[piecenum] (+ (- @piece 0x10) @pstart) ;Store piece memory addr
			

			[mvhor] (MOD @0x03 2) ;Horizontal component (0 = right)
			[mvver] (DIV @0x03 2) ;Vertical component (0 = down)

			;check validity
			;Is it your turn? Does the piece exist? does the game exist?
				;GAME LOGIC
			(if (AND (= (/ @gd 0x1000) @player) (> @@(+ @pstart @piecenum) 0)) ;GAME only exists if its someone's turn piece only exists if it is non-zero
				{
					;FINALLY READY TO BEGIN MAKING IT HAPPEN
					;Locate the piece and process its data
					[bdstart] (+ @0x01 5) ;Bottom row of board
					[square] (MOD @@(@piecenum) 0x10) ;First hex digit 
					[row] (MOD (/ @@(@piecenum) 0x10) 0x10) ;Second hex digit
					[king] (MOD (/ @@(@piecenum) 0x100) 0x10) ;Third hex digit

					;GAME LOGIC!!!!!
					;check you can move that direction (Either player dependant) (If the board gets flipped the computer will handle this anyways)
					;player1 moves up player2 moves down or king
					(unless (OR (OR (AND (= @player 1)(= @mvver 1))(AND (= @player 2)(= @mvver 0)))(KING)) (stop))

					(when (OR (AND (= @square 0)(= @mvhor 0)) (AND (= @square 7)(= @mvhor 1)))(stop)) ;BOUNDARY STOPPING!!!!!!!!!!!!!!!!!!!!!! (REMOVE FOR TORIC?)
					(when (OR (AND (= @row 0)(= @mvver 0)) (AND (= @row 7)(= @mvver 1)))(stop))

					;Test location
					[testhor] (MOD (+ (-(* @mvhor 2) 1) @square) 8) ;The mod is unecessary but used for toric checkers
					[testver] (MOD (+ (-(* @mvver 2) 1) @row) 8)

					;testver gets row
					[temp] (MOD (DIV @@(+ @bdstart @testver) (EXP 0x10 (* 2 @testhor))) 0x100) ;This is piece data
					(when (= @temp 0) ;If spot empty
						{
							;make move
							[[(+ @bdstart @row)]] (- @@(+ @bdstart @row) (* @piece (EXP 0x100 @square))) ;Remove from old space
							[[(+ @bdstart @testver)]] (+ @@(+ @bdstart @testver) (* @piece (EXP 0x100 @testhor))) ;Place in new space
							[[@piecenum]] (+ 0x1000 (+ @testhor (* @testver 0x10))) ;Modify piece data
							(if (= @player 1) ;Change turn
								([[@gdaddr]] 0x2001)
								([[@gdaddr]] 0x1001)
							)
							(stop) ;can't possibly win on a turn you don't jump
						}
					)
					(if (NOT(= (DIV @temp 0x10) @player)) ;if place is occupied by other player
						{
							;JUMP!
							;Check if the space beyond is free.... TOMORROW (Repeat the test) Need to have jumped flag

							(when (OR (AND (= @testhor 0)(= @mvhor 0)) (AND (= @testhor 7)(= @mvhor 1)))(stop)) ;BOUNDARY STOPPING!!!!!!!!!!!!!!!!!!!!!! (REMOVE)
							(when (OR (AND (= @testver 0)(= @mvver 0)) (AND (= @testver 7)(= @mvver 1)))(stop))

							;Test location
							[testhor2] (MOD (+ (-(* @mvhor 2) 1) @testhor) 8) ;The mod is unecessary but used for toric checkers
							[testver2] (MOD (+ (-(* @mvver 2) 1) @testver) 8)

							[temp] (MOD (DIV @@(+ @bdstart @testver2) (EXP 0x10 (* 2 @testhor2))) 0x100) ;This is piece data
							(when (= @temp 0)
								{
									[opcountaddr] (+ (+ @0x1 11) @player) ;The address where the opponents piece count is located.
									;Move to the jump spot
									[[(+ @bdstart @row)]] (- @@(+ @bdstart @row) (* @piece (EXP 0x100 @square))) ;Remove from old space
									[[(+ @bdstart @testver)]] (- @@(+ @bdstart @testver) (* @piece (EXP 0x100 @testhor))) ;Remove oponents piece
									[[(+ @bdstart @testver2)]] (+ @@(+ @bdstart @testver2) (* @piece (EXP 0x100 @testhor2))) ;Place in new space
									[[@piecenum]] (+ 0x1000 (+ @testhor2 (* @testver2 0x10))) ;Modify piece data
									[[@opcountaddr]] (- @@(@opcountaddr) 1) ;Deduct from opponents piece total
									[[(+ (- @piecenum 0x10) @pstart)]] 0x0 ;Remove opponent's piece data

									(if (= @player 1) ;Don't change turn but lock piece
										([[@gdaddr]] (+ 0x1001 (* @0x2 0x10)))
										([[@gdaddr]] (+ 0x2001 (* @0x2 0x10)))
									)

									;WIN CHECK (opponent has no pieces)
									(if (= @@(@opcountaddr) 0)
										{
											;GAME HAS BEEN WON @player is winner game is done
											(if (= @player 1)
												([[@gdaddr]] 0x0010)
												([[@gdaddr]] 0x0020)
											)
											;Clear out game data
											(for ([i] @bdstart))(<= @i (+ @bdstart 45)) [i](+ @i 1)
												[[@i]] 0x0
											)
										}
										(stop)
									)

								}
							)
						}
						(stop)
					)
				}
				(stop)
			)
		}
	)
	(when (= @0x0 1) ;New Game
		{
			[[@@0x2]] 0xDEADBEEF ;Game Identitfier (for ease of reading by the computer)
			[[(+ @@0x2 1)]] (caller) ;Player 1 registered
;			[[(+ @@0x2 3)]] @0x1 ;Game Name (To be implemented)
			[[0x2]] (+ @0x2 50) ; Increment pointer to next game.
		}

	)
	(when (= @0x0 2) ;join game
		{
			(unless (AND (> @@(@0x1) 0) (AND (> @0x1 0x10)(= (MOD (- @0x1 0x10) 50) 0))) (stop)) ;Make sure its a valid game number and game exists
			[[(+ @0x1 2)]] (caller) ;Register player 2
			;Game set up
			[[(+ @0x1 4)]] 0x1001 ;Game running player 1's turn ############################### IMPLEMENT RANDOM START ################################
			;GAME BOARD
			[[(+ @0x1 5)]]  0xF0010001100120013
			[[(+ @0x1 6)]]  0xF1400150016001700
			[[(+ @0x1 7)]]  0xF00180019001A001B
			[[(+ @0x1 8)]]  0xF0000000000000000 ;NOT SURE THIS IS IDEAL...
			[[(+ @0x1 9)]]  0xF0000000000000000
			[[(+ @0x1 10)]] 0xF280029002A002B00
			[[(+ @0x1 11)]] 0xF0024002500260027
			[[(+ @0x1 12)]] 0xF2000210022002300

			;Pieces Remaining
			[[(+ @0x1 13)]] 12
			[[(+ @0x1 14)]] 12

			;Pieces Data     ;PLAYER 1'S TEAM
			[[(+ @0x1 15)]] 0x1006 ;0x00
			[[(+ @0x1 16)]] 0x1004 ;0x01
			[[(+ @0x1 17)]] 0x1002 ;0x02
			[[(+ @0x1 18)]] 0x1000 ;0x03
			[[(+ @0x1 19)]] 0x1017 ;0x04
			[[(+ @0x1 20)]] 0x1015 ;0x05
			[[(+ @0x1 21)]] 0x1013 ;0x06
			[[(+ @0x1 22)]] 0x1011 ;0x07
			[[(+ @0x1 23)]] 0x1026 ;0x08
			[[(+ @0x1 24)]] 0x1024 ;0x09
			[[(+ @0x1 25)]] 0x1022 ;0x0A
			[[(+ @0x1 26)]] 0x1020 ;0x0B
							 ;PLAYER 2'S TEAM
			[[(+ @0x1 31)]] 0x1077 ;0x10 
			[[(+ @0x1 32)]] 0x1075 ;0x11
			[[(+ @0x1 33)]] 0x1073 ;0x12
			[[(+ @0x1 34)]] 0x1071 ;0x13
			[[(+ @0x1 35)]] 0x1066 ;0x14
			[[(+ @0x1 36)]] 0x1064 ;0x15
			[[(+ @0x1 37)]] 0x1062 ;0x16
			[[(+ @0x1 38)]] 0x1060 ;0x17
			[[(+ @0x1 39)]] 0x1057 ;0x18
			[[(+ @0x1 40)]] 0x1055 ;0x19
			[[(+ @0x1 41)]] 0x1053 ;0x1A
			[[(+ @0x1 42)]] 0x1051 ;0x1B

		}
	)
;	############# ADMIN POWERS ###########
	(when (= @0x0 8) ;ADMIN

	)
	;BODY
	;Input Processing
	;Case Separation
	;Game creation
	;Join
	;Tie-Request
	;Surrender
	;Game move
	    ;Validity check (Boundaries)
	    ;Game win check
	    ;If win clean out unecessary slots
}