;Transactions to the scoreboard are of three types:
;1) Scoreboard type - this is from the game contract
; txdata /winner/loser/tie?
;2) Admin type - This is from the account which first sends a transaction to this contract (they get Admin status) and can suicide and link/delink
; txdata /"suicide"
;3) Contract link manipulation - This is similar to Admin. Used to pair a scoreboard to a game
; txdata /"link" ("delink")

;Contract stores a record of scores in a users slot corresponding to their address. (passed along with winning data)
;
;the sums are stored in 16^0, 16^3, and 16^6 (this makes for easy reading in hex (ethereum storage data) and easy for a machine to parse (mod 16^3/ div 16^3) this allows counts up to 4096 in wins and loses (ties can of course go much much higher)
;
;Contract Flow (Use)
;The Txsender of first transaction received is set as Admin
;The Txsender of the first transaction with txdata is set to the linked address. Only this address may modify the values ##This can be triggered by the same transaction as admin##
;-----> The reason for setting this up like this is if a game contacts the scoreboard for the first time it will automatically be set as the linked contract and simplifies knowledge
;-----> on the game's side (doesn't need to track if this is the first time sending a message)
;If the transaction has at least three data pieces and comes from the linked address it will modify the scoreboard accordingly
;-----> The txdata 3 is 0 indicates not a tie, txdata 0 is winner, txdata 1 is loser. If tie then winner and loser are simply the players.
;-----> Low addresses are filtered
;If the admin sends a message with txdata 0 = "suicide" the contract is destroyed and all funds are sent to the admin.

;Data
;0xffe - Stores the linked game contract address
;0xfff - Stores the Admin address
;A low address check weeds out any address less then 0xfff (to be safe that code doesn't get overwritten). This is probably overly safe but I don't yet know how to  estimate how large
;----> the program will be in storage :S

(seq
    ;Redimentary spam prevention
    ;(unless (>= (txvalue) 200*(basefee)) (stop))
    (when (= (sload 0xfff) 0) ;If admin hasn't been set
        (seq
            (sstore 0xfff (txsender)) ;set the txsender as admin
        )
    )
    (when (txdatan)
        (seq
            (when (= (sload 0xffe) 0) ;Establish link if one doesn't exist (it doesn't care what the data is. Just that it exists. Distinguishes from admin only)
                (seq
                    (sstore 0xffe (txsender)) ;store txsender's address as link
                    (stop) ;done
                )
            )
            (when (and (= (txdata 0) "delink") (= (sload 0xfff) (txsender))) ;You can delink if you are the administrator (In future we could add transfers)
                (seq
                    (sstore 0xfe 0) ;set to 0, the next linking will succeed
                    (stop)
                )
            )
            (when (and (>= (txdatan) 3) (= (sload 0xffe)(txsender))) ;scoreboard type (only accept if it comes from the linked contract)
                (seq
                    (if (= (txdata 2) 0) ;Not tie
                        (seq
                            (when(>(txdata 0) 0xfff);data 1 Player 
                                (seq
                                    (when (= (sload (txdata 0)) 0) (sstore (txdata 0) 0xF000000000)) ;Formatting
                                    (sstore (txdata 0)(+ (sload(txdata 0)) 0x1))
                                )
                            ) 
                            (when(>(txdata 1) 0xfff)
                                (seq
                                    (when (= (sload (txdata 0)) 0) (sstore (txdata 0) 0xF000000000)) ;Formatting
                                    (sstore (txdata 1)(+ (sload(txdata 1)) 0x1000)) ;data 2 Player lost
                                )
                            )
                            (stop)
                        )
                        (seq ; Else it was a tie
                            (when(>(txdata 0) 0xfff);data 1 Player 
                                (seq
                                    (when (= (sload (txdata 0)) 0) (sstore (txdata 0) 0xF000000000)) ;Formatting
                                    (sstore (txdata 0)(+ (sload(txdata 0)) 0x1000000))
                                )
                            ) 
                            (when(>(txdata 1) 0xfff)
                                (seq
                                    (when (= (sload (txdata 0)) 0) (sstore (txdata 0) 0xF000000000)) ;Formatting
                                    (sstore (txdata 1)(+ (sload(txdata 1)) 0x1000000)) ;data 2 Player lost
                                )
                            )
                            (stop)
                        )
                    )
                )
            )
            (when (and (= (txsender)(sload 0xfff)) (= (txdata 0) "suicide"))
                (suicide (txsender)) ;Suicide to the Admin
            )
        )
    )
)