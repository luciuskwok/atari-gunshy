// types.h

#ifndef TYPES_H
#define TYPES_H

#include <stddef.h>

typedef unsigned char uint8_t;
typedef unsigned int uint16_t;
typedef unsigned long uint32_t;
typedef signed char int8_t;
typedef signed int int16_t;
typedef signed long int32_t;

typedef struct point_t {
	uint8_t x, y;
} point_t;

typedef struct DataBlock {
	uint16_t length;
	uint8_t  bytes[];
} DataBlock;

#endif
