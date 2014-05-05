#!/usr/bin/python
import math

def Encodeop(op):

	if (op=="STOP"):
		return "0x00" 
	elif (op=="ADD"):
		return "0x01"
	elif (op=="MUL"):
		return "0x02"
	elif (op=="SUB"):
		return "0x03"
	elif (op=="DIV"):
		return "0x04"
	elif (op=="SDIV"):
		return "0x05"
	elif (op=="MOD"):
		return "0x06"
	elif (op=="SMOD"):
		return "0x07"
	elif (op=="EXP"):
		return "0x08"
	elif (op=="NEG"):
		return "0x09"
	elif (op=="LT"):
		return "0x0a"
	elif (op=="GT"):
		return "0x0b"
	elif (op=="EQ"):
		return "0x0c"
	elif (op=="NOT"):
		return "0x0d"
	elif (op=="AND"):
		return "0x10"
	elif (op=="OR"):
		return "0x11"
	elif (op=="XOR"):
		return "0x12"
	elif (op=="BYTE"):
		return "0x13"
	elif (op=="SHA3"):
		return "0x20"
	elif (op=="ADDRESS"):
		return "0x30"
	elif (op=="BALANCE"):
		return "0x31"
	elif (op=="ORIGIN"):
		return "0x32"
	elif (op=="CALLER"):
		return "0x33"
	elif (op=="CALLVALUE"):
		return "0x34"
	elif (op=="CALLDATALOAD"):
		return "0x35"
	elif (op=="CALLDATASIZE"):
		return "0x36"
	elif (op=="GASPRICE"):
		return "0x37"
	elif (op=="PREVHASH"):
		return "0x40"
	elif (op=="COINBASE"):
		return "0x41"
	elif (op=="TIMESTAMP"):
		return "0x42"
	elif (op=="NUMBER"):
		return "0x43"
	elif (op=="DIFFICULTY"):
		return "0x44"
	elif (op=="GASLIMIT"):
		return "0x45"
	elif (op=="POP"):
		return "0x50"
	elif (op=="DUP"):
		return "0x51"
	elif (op=="SWAP"):
		return "0x52"
	elif (op=="MLOAD"):
		return "0x53"
	elif (op=="MSTORE"):
		return "0x54"
	elif (op=="MSTORE8"):
		return "0x55"
	elif (op=="SLOAD"):
		return "0x56"
	elif (op=="SSTORE"):
		return "0x57"
	elif (op=="JUMP"):
		return "0x58"
	elif (op=="JUMPI"):
		return "0x59"
	elif (op=="PC"):
		return "0x5a"
	elif (op=="MSIZE"):
		return "0x5b"
	elif (op=="GAS"):
		return "0x5c"
	elif (op=="PUSH1"):
		return "0x60"
	elif (op=="PUSH2"):
		return "0x61"
	elif (op=="PUSH3"):
		return "0x62"
	elif (op=="PUSH4"):
		return "0x63"
	elif (op=="PUSH5"):
		return "0x64"
	elif (op=="PUSH6"):
		return "0x65"
	elif (op=="PUSH7"):
		return "0x66"
	elif (op=="PUSH8"):
		return "0x67"
	elif (op=="PUSH9"):
		return "0x68"
	elif (op=="PUSH10"):
		return "0x69"
	elif (op=="PUSH11"):
		return "0x6a"
	elif (op=="PUSH12"):
		return "0x6b"
	elif (op=="PUSH13"):
		return "0x6c"
	elif (op=="PUSH14"):
		return "0x6d"
	elif (op=="PUSH15"):
		return "0x6e"
	elif (op=="PUSH16"):
		return "0x6f"
	elif (op=="PUSH17"):
		return "0x70"
	elif (op=="PUSH18"):
		return "0x71"
	elif (op=="PUSH19"):
		return "0x72"
	elif (op=="PUSH20"):
		return "0x73"
	elif (op=="PUSH21"):
		return "0x74"
	elif (op=="PUSH22"):
		return "0x75"
	elif (op=="PUSH23"):
		return "0x76"
	elif (op=="PUSH24"):
		return "0x77"
	elif (op=="PUSH25"):
		return "0x78"
	elif (op=="PUSH26"):
		return "0x79"
	elif (op=="PUSH27"):
		return "0x7a"
	elif (op=="PUSH28"):
		return "0x7b"
	elif (op=="PUSH29"):
		return "0x7c"
	elif (op=="PUSH30"):
		return "0x7d"
	elif (op=="PUSH31"):
		return "0x7e"
	elif (op=="PUSH32"):
		return "0x7f"
	elif (op=="CREATE"):
		return "0xf0"
	elif (op=="CALL"):
		return "0xf1"
	elif (op=="RETURN"):
		return "0xf2"
	elif (op=="SUICIDE"):
		return "0xff"
	else:
		return e

def chunkit(enum):
	chunk=""
	for e in enum:
		chunk=chunk+e[2:]
	return chunk


outfile=open("Conencode.txt","w")
infile="y.txt"
infostring=""
datastring=""
infopointer =16
datapointer = 256

for line in open(infile,"r"):
	enum=[]
	ln=line.strip().split()
	if (ln[0]=="name"):
		infostring=infostring+"[["+str(infopointer)+"]]"+ln[1]+"\n"
		infopointer=infopointer+1
	else:
		infostring=infostring+"[["+str(infopointer)+"]]"+str(datapointer)+"\n"
		infopointer=infopointer+1
		count=0
		for e in ln:
			enum.append(Encodeop(e))
			count=count+1
		ch=chunkit(enum)
		print ch

		lech=len(ch)
		lem64 = lech%64;
		fill=64-lem64
		for i in xrange(fill):
			ch=ch+"0"
		i=0
		print ch[(64*i):(64*(i+1))]
		rema = int(lech/64)
		print rema
		for i in xrange(rema+1):
			print i
			datastring=datastring+"[["+str(datapointer)+"]] 0x"+ch[(64*i):(64*(i+1))]+"\n"
			datapointer=datapointer+1

outfile.write(infostring)
outfile.write(datastring)
outfile.close()