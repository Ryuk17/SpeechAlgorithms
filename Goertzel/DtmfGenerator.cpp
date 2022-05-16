// Author:       Plyashkevich Viatcheslav <plyashkevich@yandex.ru>
 //

 // This program is free software; you can redistribute it and/or modify
 // it under the terms of the GNU General Public License as published by
 // the Free Software Foundation; either version 2 of the License, or
 // (at your option) any later version.
 //--------------------------------------------------------------------------
 // All rights reserved. 

#include "DtmfGenerator.hpp"

static inline INT32 MPY48SR(INT16 o16, INT32 o32)
{UINT32   Temp0;
 INT32    Temp1;
	Temp0 = (((UINT16)o32 * o16) + 0x4000) >> 15;
	Temp1 = (INT16)(o32 >> 16) * o16;
	return (Temp1 << 1) + Temp0;
}

static void frequency_oscillator(INT16 Coeff0, INT16 Coeff1,
       INT16 y[], UINT32 COUNT,
        INT32 *y1_0, INT32 *y1_1,
         INT32 *y2_0, INT32 *y2_1)
{
 register INT32 Temp1_0, Temp1_1, Temp2_0, Temp2_1, Temp0, Temp1, Subject;
 UINT16 ii;
	Temp1_0 = *y1_0,
	Temp1_1 = *y1_1,
	Temp2_0 = *y2_0,
	Temp2_1 = *y2_1,
	Subject = Coeff0 * Coeff1;
	for(ii = 0; ii < COUNT; ++ii)
	{
	 	Temp0 = MPY48SR(Coeff0, Temp1_0 << 1) - Temp2_0,
	 	Temp1 = MPY48SR(Coeff1, Temp1_1 << 1) - Temp2_1;
	 	Temp2_0 = Temp1_0,
	 	Temp2_1 = Temp1_1;
	 	Temp1_0 = Temp0,
	 	Temp1_1 = Temp1,
	 	Temp0 += Temp1;
	 	if(Subject)
	 		Temp0 >>= 1;
	 	y[ii] = (INT16)Temp0;
	}
	
	*y1_0 = Temp1_0,
	*y1_1 = Temp1_1,
	*y2_0 = Temp2_0,
	*y2_1 = Temp2_1;
}          

const INT16 DtmfGenerator::tempCoeff[8] = {27980, 26956, 25701, 24218,//Low frequences
                                               19073, 16325, 13085, 9315}; //High frequences   

DtmfGenerator::DtmfGenerator(INT32 FrameSize, INT32 DurationPush, INT32 DurationPause)
{
	 countDurationPushButton = (DurationPush << 3)/FrameSize + 1;
	 countDurationPause = (DurationPause << 3)/FrameSize + 1;
	 sizeOfFrame = FrameSize;
	 readyFlag = 1;
	 countLengthDialButtonsArray = 0;
}

DtmfGenerator::~DtmfGenerator()
{
}

void DtmfGenerator::dtmfGenerating(INT16 y[])
{
 if(readyFlag)   return;
 
 while(countLengthDialButtonsArray > 0)
  {
    if(countDurationPushButton == tempCountDurationPushButton)
     {
      switch(pushDialButtons[count])
       {
        case '1': tempCoeff1 = tempCoeff[0]; 
                  tempCoeff2 = tempCoeff[4];
                  y1_1 = tempCoeff[0];
                  y2_1 = 31000;
                  y1_2 = tempCoeff[4];
                  y2_2 = 31000; 
                  break;
        case '2': tempCoeff1 = tempCoeff[0]; 
                  tempCoeff2 = tempCoeff[5];
                  y1_1 = tempCoeff[0];
                  y2_1 = 31000;
                  y1_2 = tempCoeff[5];
                  y2_2 = 31000;                    
                  break;
        case '3': tempCoeff1 = tempCoeff[0]; 
                  tempCoeff2 = tempCoeff[6];
                  y1_1 = tempCoeff[0];
                  y2_1 = 31000;
                  y1_2 = tempCoeff[6];
                  y2_2 = 31000;                    
                  break;
        case 'A': tempCoeff1 = tempCoeff[0]; 
                  tempCoeff2 = tempCoeff[7];
                  y1_1 = tempCoeff[0];
                  y2_1 = 31000;
                  y1_2 = tempCoeff[7];
                  y2_2 = 31000;                    
                  break;
        case '4': tempCoeff1 = tempCoeff[1]; 
                  tempCoeff2 = tempCoeff[4];
                  y1_1 = tempCoeff[1];
                  y2_1 = 31000;
                  y1_2 = tempCoeff[4];
                  y2_2 = 31000;                    
                  break;
        case '5': tempCoeff1 = tempCoeff[1]; 
                  tempCoeff2 = tempCoeff[5];
                  y1_1 = tempCoeff[1];
                  y2_1 = 31000;
                  y1_2 = tempCoeff[5];
                  y2_2 = 31000; 
                  break;
        case '6': tempCoeff1 = tempCoeff[1]; 
                  tempCoeff2 = tempCoeff[6];
                  y1_1 = tempCoeff[1];
                  y2_1 = 31000;
                  y1_2 = tempCoeff[6];
                  y2_2 = 31000; 
                  break;
        case 'B': tempCoeff1 = tempCoeff[1]; 
                  tempCoeff2 = tempCoeff[7];
                  y1_1 = tempCoeff[1];
                  y2_1 = 31000;
                  y1_2 = tempCoeff[7];
                  y2_2 = 31000; 
                  break;
        case '7': tempCoeff1 = tempCoeff[2]; 
                  tempCoeff2 = tempCoeff[4];
                  y1_1 = tempCoeff[2];
                  y2_1 = 31000;
                  y1_2 = tempCoeff[4];
                  y2_2 = 31000; 
                  break;
        case '8': tempCoeff1 = tempCoeff[2]; 
                  tempCoeff2 = tempCoeff[5];
                  y1_1 = tempCoeff[2];
                  y2_1 = 31000;
                  y1_2 = tempCoeff[5];
                  y2_2 = 31000; 
                  break;
        case '9': tempCoeff1 = tempCoeff[2]; 
                  tempCoeff2 = tempCoeff[6];
                  y1_1 = tempCoeff[2];
                  y2_1 = 31000;
                  y1_2 = tempCoeff[6];
                  y2_2 = 31000; 
                  break;
        case 'C': tempCoeff1 = tempCoeff[2]; 
                  tempCoeff2 = tempCoeff[7];
                  y1_1 = tempCoeff[2];
                  y2_1 = 31000;
                  y1_2 = tempCoeff[7];
                  y2_2 = 31000; 
                  break;
        case '*': tempCoeff1 = tempCoeff[3]; 
                  tempCoeff2 = tempCoeff[4];
                  y1_1 = tempCoeff[3];
                  y2_1 = 31000;
                  y1_2 = tempCoeff[4];
                  y2_2 = 31000; 
                  break;
        case '0': tempCoeff1 = tempCoeff[3]; 
                  tempCoeff2 = tempCoeff[5];
                  y1_1 = tempCoeff[3];
                  y2_1 = 31000;
                  y1_2 = tempCoeff[5];
                  y2_2 = 31000; 
                  break;
        case '#': tempCoeff1 = tempCoeff[3]; 
                  tempCoeff2 = tempCoeff[6];
                  y1_1 = tempCoeff[3];
                  y2_1 = 31000;
                  y1_2 = tempCoeff[6];
                  y2_2 = 31000; 
                  break;
        case 'D': tempCoeff1 = tempCoeff[3]; 
                  tempCoeff2 = tempCoeff[7];
                  y1_1 = tempCoeff[3];
                  y2_1 = 31000;
                  y1_2 = tempCoeff[7];
                  y2_2 = 31000; 
                  break;
        default:
          tempCoeff1 = tempCoeff2 = 0;
          y1_1 = 0;
          y2_1 = 0;
          y1_2 = 0;
          y2_2 = 0; 
      }  
     } 
   while(tempCountDurationPushButton>0)
    {
     --tempCountDurationPushButton;

     frequency_oscillator(tempCoeff1, tempCoeff2,
       y, sizeOfFrame, 
        &y1_1, &y1_2,
         &y2_1, &y2_2
          );
     return;
    }
        
   while(tempCountDurationPause>0)
    {
     --tempCountDurationPause;
     for(INT32 ii=0; ii<sizeOfFrame; ii++)
      {
       y[ii] = 0;
      }
     return;     
    }
    
   tempCountDurationPushButton = countDurationPushButton;
   tempCountDurationPause = countDurationPause;
    
   ++count;
   --countLengthDialButtonsArray;
  }
 readyFlag = 1;
 return; 
}

INT32 DtmfGenerator::transmitNewDialButtonsArray(char dialButtonsArray[], UINT32 lengthDialButtonsArray)
{
 if(getReadyFlag() == 0) return 0;
 if(lengthDialButtonsArray == 0)
  {
   countLengthDialButtonsArray = 0;
   count = 0;
   readyFlag = 1;
   return 1;
  }
 countLengthDialButtonsArray = lengthDialButtonsArray;
 if(lengthDialButtonsArray > 20) countLengthDialButtonsArray = 20;
 for(unsigned ii=0; ii<countLengthDialButtonsArray; ii++)
  {
   pushDialButtons[ii] = dialButtonsArray[ii];
  }
  
 tempCountDurationPushButton = countDurationPushButton;
 tempCountDurationPause = countDurationPause;
  
 count = 0;
 readyFlag = 0; 
 return 1;
}



