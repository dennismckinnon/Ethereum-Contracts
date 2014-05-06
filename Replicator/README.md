Replicator
=================
Author: Dennis Mckinnon

Compatible with POC5 (May 6th 2014)

Quick example contract which replicates itself when someone transacts with it.
During initialization it copies the code into storage and during the body it copies it into memory again and uses create to spawn the new contract.

Pretty simple. Not many comments sorry. 
