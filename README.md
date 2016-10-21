# CRC_Block_MKW2xD
CRC Block implementation for NXP MKW2xD_CRC series of devices         . 

UPDATE 18 Oct'16
Iniitial implementation includes use of latches - purposly. 
Need to mitigate Latch warnings during synthesis by using if AND else statements rather than only if statements.
UPDATE 20 Oct'16 
To avoid latches, you need to make sure all of your outputs are assigned at all possible branches of the code.
Refer to : http://electronics.stackexchange.com/questions/18075/how-to-avoid-latches-during-synthesis
