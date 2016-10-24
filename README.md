 **UPDATE 18 Oct'16**
  Iniitial implementation includes use of latches - purposly. 
  Need to mitigate Latch warnings during synthesis by using if AND else statements rather than only if statements.
 
  **UPDATE 20 Oct'16** 
  To avoid latches, you need to make sure all of your outputs are assigned at all possible branches of the code.
  
 **Refer to :**  
 http://electronics.stackexchange.com/questions/18075/how-to-avoid-latches-during-synthesis
 https://www.doulos.com/knowhow/vhdl_designers_guide/tips/avoid_synthesizing_unwanted_latches/
 https://www.eeweb.com/electronics-forum/removing-latches-generated-from-missing-assignment-in-if-statement
 http://www.edaboard.com/thread314097.html

  **UPDATE 24 Oct'16** 
  Mitigated latches by performing certian operations on negative edge.
