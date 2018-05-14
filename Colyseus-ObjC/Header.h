//
//  Header.h
//  CocosEngine
//
//  Created by Hung Hoang Manh on 3/15/17.
//
//

#ifndef Header_h
#define Header_h

#include "msgpack.hpp"
#include <string>
#include <sstream>
#include <iostream>

template <typename T> std::string u_to_string(const T& n)
{
	std::ostringstream stm;
	stm << n;
	return stm.str();
}


#endif /* Header_h */
