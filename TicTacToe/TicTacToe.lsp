;Transactions
;All interaction with the game is made through transactions to this contract with different data attached. There are two main types of transactions Admin and Game
;
;--Admin--
;When the first transaction reaches this contract, The sender of that transaction becomes the Admin of the contract. This does not require any data to be attached but you can if you want
;All future Admin transactions need to be sent from this address (unless  Admin privileges are transferred)
;
;Link---------------- This transaction has the data ["link"][scoreboard contract address] 
;                       - It initializes a link with the scoreboard contract by sending a transaction to it with data "link"
;                       - The link can be changed any time by using another of this transaction (if you need to switch scoreboards)
;                       *NOTE* if the scoreboard doesn't yet have an administrator then this contract becomes its Admin (this can be useful)
;
;Scoreboard Suicide - Form: ["killscoreboard"]
;                       - Sends the transaction to cause the scoreboard contract to suicide
;                       *NOTE* This only functions if THIS contract has Admin status in the scoreboard
;
;Suicide ------------ Form: ["suicide"]
;                       - makes this contract commit suicide
;                       *NOTE* If this contract is Admin to the scoreboard you should killscoreboard first
;
;Transfer Admin ----- Form: ["transfer"][New Admin address]
;                       - Transfers Admin powers to the address specified

;--Game--
;The game only has three transactions "new", "join", "move". 
;
;New -------- Form: ["new"]<common name><player2>
;              - Creates a new game (The game number is automatically allocated.
;              - txsender becomes player 1
;                - If <custom name> provided it will set the custom name field
;                - If <custom name><player2> provided It will set the custom name and set player 2. It will then start the game with player1's turn
;
;In the following gamenum is passed to reference a particular game. It needs to satisfy gamenum>=0x1001 and (gamenum-0x1001) mod 6 = 0 These are the valid game locations
;
;Join ------- Form: ["join"][gamenum]
;              -  Attempts to join game specified by gamenum if it exists and doesn't have a player 2
;              - If successful player 2 is added and game is started with player 1's turn
;
;Move ------- Form: ["move"][gamenum][location]
;              - Runs checks to verify:
;                 - The game exists 
;                 - The game is running
;                 - You are a member of the game
;                 - Its your turn
;                 - Is the location valid?
;                 - Is it free
;              - Makes the move and checks for winning conditions
;                 - ends game
;                 - If linked to a scoreboard it will send a transaction to inform of the outcome
;              - If no winning conditions it will 
;                 - Changes whose turn it is
;              *Note* If any of these things fail, the turn will not be changed and the player can try again

;Data
;0xffd - Stores scoreboard contract address once linked
;0xffe - Stores Admin address once set
;0xfff - Stores Next free "game slot"

;Game Slots
;gamenum ---("gamebaseaddr")--- The address which the game slot begins at. This address stores Player 1's Address (This is the game number!! and is passed in a transaction)
;gamenum +1 ("player2addr")---- This address store Player 2's Address
;gamenum +2 --------------- This address currently store a custom name for a game (can be set but isn't used here)
;gamenum +3 ("gamedataaddr")--- This address stores 3 pieces of data, [turn (1 bit)|winner (2 bits)|running? (1 bit)]
;----------> turn    (1 hex digit)   - Indicates whose turn it is (1 for player 1, 2 for player 2). (Most significant bit)
;----------> winner  (1 hex digit )  - Indicates the winner of the game. 1 = player 1, 2 = player 2, F = tie game.
;----------> running (1 hex digit)   - Indicates if this game is running (1 = running) (Least significant bit)
;            EXAMPLE: If it is player 2's turn and the game has not finished it will read 0x201
;gamenum +4 ("gamestateaddr") - This address stores the game state. 10 hex digits, each digit 1-9 location corresponds to a location on the grid (The 10th digit is 0xF for ease of reading)
;                              - the storage of locations is as 0xF 9/8/7/6/5/4/3/2/1 when read in hex
;
;    1 | 2 | 3
;   -----------
;    4 | 5 | 6
;   -----------
;    7 | 8 | 9
;
;The valid values in a grid are:
;0 - Location is unclaimed
;1 - Location is owned by player 1
;2 - Location is owned by player 2
;
;EXAMPLE: If player 2 has locations 7,8,and 9, player 1 owns 1,3 and 5 the game state will read: 0xF222010101
;
;gamenum +5 ---------------- This is left empty to separate games
;
;Memory
;memory is occasionally used to store particular values. Important addresses include:
;Those listed above in quotation marks store the storage address to make accessing storage slots a little easier
;1-9 Used as scratch pad for processing game state
;"count" is used as a counter in a for loop during game state processing
;"state" is used to create a copy of the game state which can be modified
;"constate" is used to reconstruct the game state from the values in 1-9
;"playernum" Is where the current player is stored (translation of txsender into one of the two players)
;"turn" Which players turn it is
;"Winner" when a winner is found this stores who it is. (2 indicates a tie)
;
;gamebase Stores the value of gamebaseaddr (player 1's id)
;player2 Stores player 2's id
;gamedata Stores a copy of the gamedata
;gamestate Stores a copy of the gamestate
;Each one of these correspond to the values stored at their pairs given above
;
;######--Usage--######
;--Setup--
;To set up this contract, Submit it to the ether and supply it with sufficient funds to run (game runs off its own funds) (If you want to protect against spam uncomment the first unless statement)
;Once in the ether initialize it by sending a transaction to it. You do not need to have any data attached. This will prep the contract for use and will set you as the Admin.
;If you want to link to an already existing scoreboard contract send a link transaction (this will work as the first transaction for initialization if you want too it will both initialize and link in a single transaction (efficiency eh? :P)
;
;--To Play--
;It should be clear but the order goes "New", "Join" (if player 2 wasn't added in new), "Move" (repeat move alternating turns until game over) **NOTE** player 1 ALWAYS goes first.


(seq
;rudamentary spam prevention choose whatever you feel is sufficient deterrent
;    (unless (>= (txvalue) 200*(basefee)) (stop))
    (when (= (sload 0xfff) 0) ;First time running needs to initialize stuff
        (seq
            (sstore 0xfff 0x1001) ;The initial base for games
            (sstore 0xffe (txsender)) ;Stores the first ever contact becomes "admin" (only one who can suicide and set scoreboard address)
        )
    )
    
    (when (txdatan) ;no valid game transaction contains no data
        (seq
            ;###############CREATE GAME###################
            (when (= "new"(txdata 0)) ;Create new game, has two optional parameters <common name><player>
                (seq
                    (sstore (sload 0xfff)(txsender)) ;Add the transaction's sender as player 1
                    (sstore (ADD (sload 0xfff) 1) 0) ;Player 2
                    (sstore (ADD (sload 0xfff) 2) (sload 0xfff)) ;common name
                    (sstore (ADD (sload 0xfff) 3) 0) ;Game Data
                    (sstore (ADD (sload 0xfff) 4) 0) ;Game State
                    (when (>= (txdatan) 2) ;Custom name has been chosen
                        (sstore (ADD (sload 0xfff) 2) (txdata 1))
                    )
                    (when(>= (txdatan) 3) ;Player 2 chosen (Mostly for use if a Gui gets built on this)
                        (seq
                            (sstore (ADD (sload 0xfff) 1) (txdata 2)) ;Add player 2
                            (sstore (ADD (sload 0xfff) 3) 0x101) ;Start the game Pl1 turn (0)/ winner 00/ running 1
                        )
                    )
                    (sstore 0xfff (ADD (sload 0xfff) 6)) ;sets the next game to the next chunk (6 so that each game will be separated)
                    (stop) ;stop because game has been set up time to play!
                )
            )
            (when (>= (txdatan) 2)
                (seq
                    ;Check if valid gamenum was supplied. In the case that an Admin command happens to pass this. It will just have to suffer a few more checks. It will still work. Better then performing a large number of checks every time to weed out the admin commands. 
                    (when (and (>= (txdata 1) 0x1001) (= (mod (SUB (txdata 1) 0x1001) 6) 0))
                        (seq
                            ;Store some values in memory for easy use later
                            (mstore "gamebase" (sload (txdata 1))) ;player 1 is stored here
                            (mstore "player2" (sload(ADD (txdata 1) 1))) ;player 2 is stored here
                            (mstore "gamedata" (sload(ADD (txdata 1) 3))) ;some game data like if the game is running (see description above)
                            (mstore "gamestate" (sload(ADD (txdata 1) 4))) ;Game State
                            
                            (mstore "gamebaseaddr" (txdata 1)) ;gamebase ADDRESS stored here
                            (mstore "player2addr" (ADD (txdata 1) 1)) ;player 2 ADDRESS stored here
                            (mstore "gamedataaddr" (ADD (txdata 1) 3)) ;gamedata ADDRESS stored here
                            (mstore "gamestateaddr" (ADD (txdata 1) 4)) ;game state ADDRESS stored here
                            
                            ;#############JOIN GAME##################
                            (when (and (= "join" (txdata 0)) ;indicate they want to join
                                    (> (mload "gamebase") 0) ;the game exists
                                    (= (mload "player2") 0)) ;player 2 not set
                                (seq
                                    (sstore (mload "player2addr") (txsender)) ;Add the tx sender as player 2
                                    (sstore (mload "gamedataaddr") 0x101) ;Start the game Pl1 turn (0)/ winner 00/ running 1
                                    (sstore (mload "gamestateaddr") 0xF000000000);Initialize the gameboard.
                                    (stop) ;stop because game has started now need to wait for player 1s first turn
                                )
                            )
                            
                            ;############MAKE MOVE###################
                            (when (and (= "move" (txdata 0)) ;Wants to move-- This if is the Heart of the game
                                    (>= (txdatan) 3) ;Has at least 3 arguments "move"/game num/location
                                    (> (mload "gamebase") 0) ) ;makes sure the game exists
                                (when (and (or (= (txsender) (mload "gamebase")) (= (txsender) (mload "player2"))) ;txsender a player?
                                        (= (mod (mload "gamedata") 16) 1) ;Is it running?
                                        (> (txdata 2) 0) (< (txdata 2) 10)) ;Is the Location data valid?
                                    (seq
                                        (if (= (txsender)(mload "player1")) ;If the txsender is player 2
                                            (mstore "playernum" 1) ;player is player 1
                                            (mstore "playernum" 2) ;etc
                                        )
                                        (mstore "turn" (div (mload "gamedata") 0x100)) ;store who's turn it is (the mod is unneeded right now)
                                        (when (= (mload "turn") (mload "playernum")) ;Is it txsender's turn?
                                            ;Time to make your move
                                            (seq
                                                (mstore "count" 1) ;Set counter (I could have used a name)
                                                (mstore "state" (mload "gamestate")) ;Copy the Game State into memory
                                                (for (<= (mload "count") 9) ;Parse gamestate
                                                    (seq
                                                        (mstore (mload "count") (MOD (mload "state") 16)) ;copy four lowest bits out of gamestate (one hex slot)
                                                        (mstore "state" (DIV (mload "state") 16)) ;delete four lowest bits from gamestate
                                                        (mstore "count" (ADD (mload "count") 1)) ;Increment counter
                                                    )
                                                )
                                                (if (= (mload (txdata 2)) 0);check if the space is empty
                                                    ;Modify the gamestate in storage to add this move.
                                                    (seq
                                                        ;DOING IT THE FUCKIN LONG WAY CAUSE EXP DOESN'T WORK
                                                        (mstore (txdata 2) (mload "playernum"))
                                                        (mstore "count" 9) ;Set counter
                                                        (mstore "constate" 0) ;Constructing the game state here
                                                        (for (>= (mload "count") 1) ;Build gamestate
                                                            (seq
                                                                (mstore "constate" (ADD (MUL 16 (mload "constate")) (mload (mload "count"))))
                                                                (mstore "count" (SUB (mload "count") 1)) ;Decrement counter
                                                            )
                                                        )
                                                        (sstore (mload "gamestateaddr") (ADD 0xF000000000(mload "constate")))
                                                    )
                                                    ;ELSE if not free stop player needs to make a different move
                                                    (seq
                                                        (stop)
                                                    )
                                                )
                                                
                                                ;TIME TO CHECK IF THERE IS A WINNER! (or tie game)
                                                ;This could be optimized but it would only save you something if the game wasn't a tie (not worth it)
                                                (when (and (= (mload 1)(mload 2)) (= (mload 2)(mload 3)) (> (mload 1) 0)) ;123 (copy for the others)
                                                    (seq
                                                        (sstore (mload "gamedataaddr") (* 16 (mload "playernum")));set the game data to report game not running and who won (turn=0)
                                                        (mstore "winner" (mload "playernum")) ;store the winner
                                                    )
                                                )
                                                (when (and (= (mload 1)(mload 4)) (= (mload 4)(mload 7)) (> (mload 1) 0)) ;147
                                                    (seq
                                                        (sstore (mload "gamedataaddr") (* 16 (mload "playernum")));set the game data to report game not running and who won (turn=0)
                                                        (mstore "winner" (mload "playernum")) ;store the winner
                                                    )
                                                )
                                                (when (and (= (mload 1)(mload 5)) (= (mload 5)(mload 9)) (> (mload 1) 0)) ;159
                                                    (seq
                                                        (sstore (mload "gamedataaddr") (* 16 (mload "playernum")));set the game data to report game not running and who won (turn=0)
                                                        (mstore "winner" (mload "playernum")) ;store the winner
                                                    )
                                                )
                                                (when (and (= (mload 2)(mload 5)) (= (mload 5)(mload 8)) (> (mload 2) 0)) ;258
                                                    (seq
                                                        (sstore (mload "gamedataaddr") (* 16 (mload "playernum")));set the game data to report game not running and who won (turn=0)
                                                        (mstore "winner" (mload "playernum")) ;store the winner
                                                    )
                                                )
                                                (when (and (= (mload 3)(mload 6)) (= (mload 6)(mload 9)) (> (mload 3) 0)) ;369
                                                    (seq
                                                        (sstore (mload "gamedataaddr") (* 16 (mload "playernum")));set the game data to report game not running and who won (turn=0)
                                                        (mstore "winner" (mload "playernum")) ;store the winner
                                                    )
                                                )
                                                (when (and (= (mload 3)(mload 5)) (= (mload 5)(mload 7)) (> (mload 3) 0)) ;357
                                                    (seq
                                                        (sstore (mload "gamedataaddr") (* 16 (mload "playernum")));set the game data to report game not running and who won (turn=0)
                                                        (mstore "winner" (mload "playernum")) ;store the winner
                                                    )
                                                )
                                                (when (and (= (mload 4)(mload 5)) (= (mload 5)(mload 6)) (> (mload 4) 0)) ;456
                                                    (seq
                                                        (sstore (mload "gamedataaddr") (* 16 (mload "playernum")));set the game data to report game not running and who won (turn=0)
                                                        (mstore "winner" (mload "playernum")) ;store the winner
                                                    )
                                                )
                                                (when (and (= (mload 7)(mload 8)) (= (mload 8)(mload 9)) (> (mload 7) 0)) ;789
                                                    (seq
                                                        (sstore (mload "gamedataaddr") (* 16 (mload "playernum")));set the game data to report game not running and who won (turn=0)
                                                        (mstore "winner" (mload "playernum")) ;store the winner
                                                    )
                                                )
                                                (when (= (ADD (ADD (ADD (ADD (mload 1)(mload 2)) (ADD(mload 3)(mload 4)))(ADD (ADD (mload 5)(mload 6)) (ADD (mload 7)(mload 8))))(mload 9)) 0xD0) ;Tie
                                                    (seq
                                                    ;On Tie games winner will be 2 (code will be 0|10|0 => turn 0 | tie game |not running) 
                                                        (sstore (mload "gamedataaddr")  0xF0)
                                                        (mstore "winner" 3) ;store the tie (2)
                                                    )
                                                )
                                                ;#################################################################################################################################
                                                ;END OF GAME LOGIC
                                                (if (= (mod (sload (mload "gamedataaddr")) 16) 0) ;game is no longer running
                                                    (when (> (sload 0xffd) 0) ;scoreboard linked
                                                        (seq
                                                            (when (and (= (mload "winner") 3) ) ;Tied game(Placed first because most likely)
                                                                (seq
                                                                    (mktx (sload 0xffd) 0 3 (mload "gamebase") (mload "player2") 1)
                                                                    (stop) ;Result registered game over
                                                                )
                                                            )
                                                            (when (= (mload "winner") 1) ;Player 1 won 
                                                                (seq
                                                                    (mktx (sload 0xffd) 0 3 (mload "gamebase") (mload "player2") 0)
                                                                    (stop) ;Result registered game over
                                                                )
                                                            )
                                                            (when (= (mload "winner") 2) ;Player 2 won
                                                                (seq
                                                                    (mktx (sload 0xffd) 0 3 (mload "player2") (mload "gamebase") 0)
                                                                    (stop) ;Result registered game over
                                                                )
                                                            )
                                                        )
                                                    )
                                                    (seq ;ELSE if the game hasn't finished change who's turn it is.
                                                        (when (mload "turn")
                                                            (seq
                                                                (sstore (mload "gamedataaddr") 0x101) ; Hex
                                                                (stop) ;stop because turn over
                                                            )
                                                        )
                                                        (unless (mload "turn")
                                                            (seq
                                                                (sstore (mload "gamedataaddr") 0x201) ; Hex yo!
                                                                (stop) ;stop because turn over
                                                            )
                                                        )
                                                    )
                                                )
                                            )
                                        )
                                    )
                                )
                            )
                        )
                    )
                )
            )
            ;##############ADMIN POWERS################
            (when (= (txsender) (sload 0xffe))
                (seq
                    ;###########LINK TO SCOREBOARD#############
                    (when (and (= "link" (txdata 0)) ;the first says "link"
                            (= 2(txdatan))) ;message comes with two txdata
                        (seq
                            (sstore 0xffd (txdata 1)) ;set link
                            (mktx (txdata 1) 0 1 "link") ;Initialize link (This will link the scoreboard to this contract(and if an Admin has not been set this game will become Admin)
                            (stop)
                        )
                    )
                    
                    ;##########SCOREBOARD SUICIDE#############
                     ;Allows Admin to suicide scoreboard (only works if THIS contract is Admin of scoreboard)
                    (when (and (> (sload 0xffd) 0) (= (txdata 0) "killscoreboard"))
                        (seq
                            (mktx (sload 0xffd) 0 1 "suicide")
                            (sstore 0xffd 0) ;Delete the scoreboard from its memory
                            (stop)
                        )
                    )
                    
                    ;##########GAME CONTRACT SUICIDE##########
                    (when (= (txdata 0) "suicide") ;Allows the Admin to suicide contract (If game is admin to scoreboard should suicide scoreboard first)
                        (suicide (txsender))
                    )
                    
                    ;##########TRANSFER ADMIN POWERS##########
                    (when (and (= (txdata 0) "transfer") (= (txdatan) 2)) ;Admin message saying "transfer" with new address
                        (seq
                            (sstore 0xffe (txdata 1)) ;transfer ownership
                            (stop)
                        )
                    )
                    ;##########################################
                )
            )
            ;###########END OF ADMIN POWERS############
        )
    )
)