// graphics.h

#include "types.h"


void setSelectedTile(uint8_t x, uint8_t y);
uint8_t* getSpritePtr(uint8_t sprite);

void printStringAtXY(const char *s, uint8_t x, uint8_t y);
void printString(const char *s);

void moveToNextLine(void);
void setSavadrToCursor(void);

uint8_t toAtascii(uint8_t c);
void delayTicks(uint8_t ticks);

void initGraphics(void);
