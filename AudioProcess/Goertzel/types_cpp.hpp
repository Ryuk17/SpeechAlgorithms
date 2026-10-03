 // Author:       Plyashkevich Viatcheslav <plyashkevich@yandex.ru>
 //

 // This program is free software; you can redistribute it and/or modify
 // it under the terms of the GNU General Public License as published by
 // the Free Software Foundation; either version 2 of the License, or
 // (at your option) any later version.
 //--------------------------------------------------------------------------
 // All rights reserved. 


#if !_BASE_TYPES_
#define _BASE_TYPES_ 1

template<int, int, int, int> class Types;
template <> class Types<5, 4, 2, 1>
{
  public:
	typedef long int Int40;
	typedef unsigned long int Uint40;
	typedef int Int32;
	typedef unsigned int Uint32;
	typedef short int Int16;
	typedef unsigned short int Uint16;
	typedef char Int8;
	typedef unsigned char Uint8;
};
template <> class Types<8, 4, 2, 1>
{
  public:
	typedef long int Int64;
	typedef unsigned long int Uint64;
	typedef int Int32;
	typedef unsigned int Uint32;
	typedef short int Int16;
	typedef unsigned short int Uint16;
	typedef char Int8;
	typedef unsigned char Uint8;
};
template <> class Types<4, 4, 2, 1>
{
  public:
	typedef int Int32;
	typedef unsigned int Uint32;
	typedef short int Int16;
	typedef unsigned short int Uint16;
	typedef char Int8;
	typedef unsigned char Uint8;
};

// For 16bit chars
template <> class Types<2, 1, 1, 1>
{
  public:
	typedef long int Int32;
	typedef unsigned long int Uint32;
	typedef short int Int16;
	typedef unsigned short int Uint16;
};

#endif
