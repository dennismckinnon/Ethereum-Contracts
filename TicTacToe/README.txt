Ethereum Contracts Implementing TicTacToe and a Scoreboard
=============================================================================
Written by: Dennis McKinnon for the hell of it

Feel free to do what you want
-----------------------------------------------------------------------------
These are two Ethereum contracts for the POC 3 Client:
https://code.ethereum.org/

If you don't know about the Ethereum Project... How did you find this? In either case check it out. Its a pretty awesome project being run by a great team.

https://ethereum.org/

In order to get a feel of contract writing beyond the basic examples I implemented a TicTacToe game engine contract which allows you to play TicTacToe with people through the Ethereum Blockchain and a scoreboard for keeping track of how many times you tie. 

Its pretty much the hardest to play game of TicTacToe to play ever (OK not so much anymore since i changed from writing everything as bitstrings to storing them as strings of human readable hexdigits... You are welcome) since on each move you have to search through the storage of the contract in order to find the particular hex values which correspond to yourgame and gamestate. But it is doable.

It does not have any protection against spam because why?

Its written in LLL for ethereum.
=============================================================================
HOW TO USE/PLAY
In order to get it up and running and play follow these instructions. Both files have more detailed information in them. And they CAN be used on thier own (Scoreboard isn't tied to tictactoe) Also each file has various "Admin" operations. The first person to send a transaction to either contract is remembered and becomes admin which allows you certain commands which only you can send (such as suicide and suicide plus others). 

Assuming you have the POC 3:

In the following all quotation marks are REQUIRED. Include them when writing the data!

1) Create a contract with the contents of TicTacToe.lsp (you can skip the comments) *NOTE THE CONTRACT ID*
I recommend creating the contract with at least 1 ether so it can run.


(optional)
1 a) Create a contract with the contents of Scoreboard.lsp (Again note the contract id)
This will NEED you to create it with some funds. 1 ether should be more then enough but it won't function without funds so keep that in mind.

2) If you didn't create a score board skip to 3. Else Send a transaction to [TicTacToe Contract ID] with the data:
"link" [ScoreBoard contract ID]

The scoreboare ID has to be preceeded wit 0x to make it a hex number

from here on all transactions will got to  [TicTacToe Contract ID]

3) Send a transaction with:
"new" <gamename><Player2 address>
To create a new game. The gamename and player2 address are optional. I suggest using gamename since it will make it easier to find the block of data which corresponds to your game data (protip right your game name as a hex number such as 0xDEADBEEF that way it will show up as you wrote it and not as a string interpreted as a hex number).

NOTE: If you want to specify player 2 you MUST also pick a game name (because I was lazy) If you do not it will interpret player 2 as the game name. You've been warned :P

By this point your game has been created and has a game number (but since this contract gives you no feed back you will have to look in the contract storage for the address which is at the start of the chunk of game data corresponding to your game (Easy to spot because its the hex number after the @) the first  created game number will be 0x1001 and each one after is spaced by 6 (0x1007 0x100 0x100D etc.)

If you included the player 2 address (make sure you wrote it as a hex number!!) you can skip this otherwise

4) At this point Player 2 needs to join the game you just created they need to send a transaction to the TicTacToe contract ID with the data:
"join" [Gamenum]

Where gamenum is the number you found after step three. Don't worry if you mess it up you aren't going to get stuck playing a game you don't want to you just won't yet be in the game you intended.

5) Now that you are both in the game. The game has started and its player 1's turn. in order to make a move send a transaction with:
"move" [gamenum] [location number]

The location is the square in the grid you want to play in.

 1 | 2 | 3
-----------
 4 | 5 | 6
-----------
 7 | 8 | 9

You can now alternate turns making moves until the game is over. IF YOU MAKE AN INVALID MOVE (a spot that is already taken or try to move when its not your turn) NOTHING WILL HAPPEN. If it was your turn it STIL IS your turn. so try again.

At some point you will probably want to know what the hell is going on in game

HOW TO READ THE CONTRACT STORAGE
-------------------------------------------------------
In order to figure out whats going on you need to be able to read the contract data associated with your game it is orgainzed like this

@Gamenum
[Player 1's Address]
[Player 2's Address]
[Game Name]
[Game Data]
[Game State]

the first two are pretty ovbious the third is the name you gave the game when you created it

Game Data is a bit more complicated its actually three pieces of data in one in the hex string format of:

Turn/ winner / running

running is the lieast significant digit it is 1 when the game is active (after player 2 joins and before a winner or tie game is found)
winner stores 1 at the end of the game if player 1 won
              2 "   "   "   "  "   "   if Player 2 won
              F "   "   "   "  "   "   if the game was a tie

As an example when you first start a game the game data will read:
0x101 - indicating its player1's turn and that the game is running
0x0F0 - Indicates the game is over and it was a tie
etc

The Game state works similar to Game Data but it stores the state of the game board in hex digits for each slot:
0xF9/8/7/6/5/4/3/2/1 
9 is most significant digit
the number corresponds to the location on the board (shown above)
It will store a 0 if free, 1 if owned by player 1 and 2 if owned by player 2

For example the gamestate:
0xF222010101 indicates two things: 1) player 1 sucks at this game and 2) player 2 won by getting the bottom row of the board. 

The Leading "F" is there to make the entire gameboard visible at all times. The gameboard won't appear until player 2 has joined (this should make it painfully obvious you skipped a step)

Thats it. Easy right?
=============================================================================

Checking your scores in the Scoreboard
------------------------------------------------------------------------------
If you set up the scoreboard way back when And you have played at least one game to completion you can now see your record by looking at the contract storage for the scoreboard contract. Simply look for the address corresponding to your personal address. You will then see a hex string. Reading it works lik this:
0xF Ties (3 digits)/Loses (3 digits)/ Wins (3 digits)

For example if your address was e30eee56...  and you had 5 ties 2 loses and 3 wins you would see:

@0xE30EEE56...
0xF005002003

The scoreboard can be used independantly if you design your own game. Read its help section if you want specific

Happy TicTacToeing

...

I spent WAY too long writing this