// graphics.h

#include "types.h"

void setSelectionLocation(uint8_t x, uint8_t y);
void hideSelection(void);

uint8_t* getSpritePtr(uint8_t sprite);

void setSavadrToCursor(void);
void delayTicks(uint8_t ticks);

void initGraphics(void);
