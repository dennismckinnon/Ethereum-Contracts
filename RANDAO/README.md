RANDAO
=================
Author: Dennis Mckinnon

Compatible with POC5 (May 6th 2014)

Much discussion has occured around the production of random (unpredictable/uncontrollable) numbers.

This Contract is a first attempt at producing random numbers using the commitment method.

When someone requests a number, A new job is added to the contract and participants are randomly chosen to... participate (this choosing is based on rep but i will explain the basic rep system below). 

Random Number Production
---------------------------------------
Production of a random number has two stages to it.

First each participant chooses a value (v1,v2...) which they keep secret for the time being. The instead submit the hash of thier value H(v1). The contract stores all of these values. All participants must wait until phase two occurs to continue. If a participant fails to participate in stage 1 they can not be rewarded and reputation will be hurt.

The second stage each participant now reveals the unhashed value associated to the value they had previously sent. The contract will check that the Hash of this value matches what was previously given. If both steps have been performed correctly you will get your reward for participation. If you fail any stage you will not get a reward and your rep will be punished.

NOTE: The last person to submit will have a choice between two possible final values based on the results of all previous participants inputs. Overall I think this is a minor issue for most situations UNLESS you are using this random number for a two outcome scenario in which case it could be considered extremely problematic.

The benefit of this system is as long as one participant is not in collusion with the others then the outcome can not be controlled (except for the case discussed in the NOTE above)

After a time (chosen by the requester at the begining) the original requester can claim thier random number which then gets returned to them. The final random number is calculate by hashing together all of the values submitted by participants.

Reputation System
------------------------------------------------------- 
This contract includes a very basic integrated rep system. In order to buy a position to be eligiable for participation you must pay 100 ether (configurable). This is a 1 time never refunded fee. (to stop botnets). Each participant starts with perfect rep (1) which is degraded (increased) if they fail to perform the steps above correctly and improved (decreased) if they perform them correctly.

Rep is set up like this so that the chance of someone getting picked is (1/(# of active participants))*(1/rep). The closer your rep is to 1 the more often you get chosen.

Pretty rudimentary.

Payment
--------------------------------------------------------
People requesting the random numbers actually have to pay for the number of participants they want. This is paid up-front no refunds. When a participant sucessfully complete all steps they are rewarded 1 ether (configurable). In order to save expense. The amount is credited to their account and can be claimed whenever they wish.

Usage
----------------------------------------------------------
Though it has not yet been written the idea is that people could run this submission system from a webpage or some such application where it watches for the user being selected and then submits the values when required.



