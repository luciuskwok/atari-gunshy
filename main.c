// main.c


// == About This Program ==
// This program is a Shanghai-like game. 


// Includes
#include "atari_memmap.h"
#include "graphics.h"
#include "types.h"
#include <atari.h>


// Globals
uint8_t isQuitting;

uint8_t tilesLevel0[14*8];
uint8_t tilesLevel1[8*6];
uint8_t tilesLevel2[6*4];
uint8_t tilesLevel3[4*2];
uint8_t tileApex;



// Constants
#define RowBytes (40)
#define middleLeftTileIndex (3*14)
#define middleRightTile0Index (3*14+13)
#define middleRightTile1Index (4*14+13)
#define PMLeftMargin (48)
#define PMTopMargin (16)


// mouse.asm stuff
void initMouse(void);
extern uint8_t pointerHasMoved;

// interrupt.asm asm stuff
void initVBI(void);

// misc.asm stuff
void zeroOutMemory(uint8_t *ptr, uint16_t length);


// Mapping from tile number to character number
const uint8_t tileCharMap[] = {
	0x88, 0x89, 0x8A, 0x8B, // 1 of discs
	0x8C, 0x8D, 0x8E, 0x8F, // 2 of discs
	0x90, 0x91, 0x92, 0x93, // 3 of discs
	0x94, 0x95, 0x96, 0x97, // 4 of discs
	0x98, 0x99, 0x9A, 0x9B, // 5 of discs
	0x9C, 0x9D, 0x9E, 0x9F, // 6 of discs
	0xA0, 0xA1, 0xA2, 0xA3, // 7 of discs
	0xA4, 0xA5, 0xA6, 0xA7, // 8 of discs
	0xA8, 0xA9, 0xAA, 0xAB, // 9 of discs

	0x2C, 0x2D, 0x2E, 0x2F, // 1 of chars
	0x30, 0x31, 0x2E, 0x2F, // 2 of chars
	0x32, 0x33, 0x2E, 0x2F, // 3 of chars
	0x34, 0x35, 0x2E, 0x2F, // 4 of chars
	0x36, 0x37, 0x2E, 0x2F, // 5 of chars
	0x38, 0x39, 0x2E, 0x2F, // 6 of chars
	0x3A, 0x3B, 0x2E, 0x2F, // 7 of chars
	0x3C, 0x3D, 0x2E, 0x2F, // 8 of chars
	0x3E, 0x3F, 0x2E, 0x2F, // 9 of chars

	0x40, 0x41, 0x42, 0xC3, // 1 of bamboo
	0x44, 0x05, 0x46, 0x47, // 2 of bamboo
	0x45, 0x05, 0x4A, 0x4B, // 3 of bamboo
	0x48, 0x49, 0x4A, 0x4B, // 4 of bamboo
	0x4C, 0x4D, 0x4E, 0x4F, // 5 of bamboo
	0x50, 0x51, 0x52, 0x53, // 6 of bamboo
	0x54, 0x55, 0x56, 0x57, // 7 of bamboo
	0x58, 0x59, 0x5A, 0x5B, // 8 of bamboo
	0x5C, 0x5D, 0x5E, 0x5F, // 9 of bamboo

	0x60, 0x61, 0x62, 0x63, // North wind
	0x64, 0x65, 0x66, 0x67, // East wind
	0x68, 0x69, 0x6A, 0x6B, // West wind
	0x6C, 0x6D, 0x6E, 0x6F, // South wind

	0x70, 0x71, 0x72, 0x73, // Red dragon
	0x74, 0x75, 0x76, 0x77, // Green dragon
	0x04, 0x05, 0x06, 0x07, // White dragon
	
	0xF8, 0xF9, 0xFA, 0xFB, // Moon
	0xFC, 0xFD, 0x7E, 0x7F, // Flower
};


const uint8_t level0RowHalfWidths[] = { 6, 4, 5, 6, 6, 5, 4, 6 };

static void drawTile(uint8_t tile, uint8_t x, uint8_t y) {
	// Uses ROWCRS and COLCRS to position origin of tile.
	uint16_t offset = x + RowBytes * y;
	uint8_t *screen = (uint8_t*)PEEKW(SAVMSC);
	const uint8_t *charIndex = &tileCharMap[((tile-1)%36) * 4];
	const uint8_t frontTileMask = 0x80;

	screen[offset] = charIndex[0]; // draw tile face
	screen[offset+1] = charIndex[1];
	screen[offset+RowBytes] = charIndex[2];
	screen[offset+(RowBytes+1)] = charIndex[3];
	screen[offset+(2*RowBytes)] = frontTileMask|2; // draw front-side of tile
	screen[offset+(2*RowBytes+1)] = frontTileMask|3;

	// draw left-side of tile, if needed
	if (screen[offset+(0*RowBytes-1)] == 0) {
		screen[offset+(0*RowBytes-1)] = 1; 
	}
	if (screen[offset+(1*RowBytes-1)] == 0) {
		screen[offset+(1*RowBytes-1)] = 1;
		screen[offset+(2*RowBytes-1)] = 1;
	}
}

static void setApexTileLeftBorderVisible(uint8_t visible) {
	if (visible) {
		POKE(HPOSP3, PMLeftMargin+75);
	} else {
		POKE(HPOSP3, 0);
	}
}

static void drawTileBoard(void) {
	const uint8_t centerX = 20;
	const uint8_t centerY = 11;
	uint8_t x, y, row, col, tile;

	// Draw level 0
	for (row=0; row<8; ++row) {
		for (col=1; col<13; ++col) {
			tile = tilesLevel0[col + row * 14];
			if (tile) {
				x = centerX + col * 2 - 14;
				y = centerY + row * 2 - 9;
				drawTile(tile, x, y);
			}
		}
	}

	// Draw level 1
	for (row=0; row<6; ++row) {
		for (col=1; col<7; ++col) {
			tile = tilesLevel1[col + row * 8];
			if (tile) {
				x = centerX + col * 2 - 8;
				y = centerY + row * 2 - 8;
				drawTile(tile, x, y);
			}
		}
	}

	// Draw level 2
	for (row=0; row<4; ++row) {
		for (col=1; col<5; ++col) {
			tile = tilesLevel2[col + row * 6];
			if (tile) {
				x = centerX + col * 2 - 6;
				y = centerY + row * 2 - 7;
				drawTile(tile, x, y);
			}
		}
	}

	// Draw level 3
	for (row=0; row<2; ++row) {
		for (col=1; col<3; ++col) {
			tile = tilesLevel3[col + row * 4];
			if (tile) {
				x = centerX + col * 2 - 4;
				y = centerY + row * 2 - 6;
				drawTile(tile, x, y);
			}
		}
	}

	// Draw apex tile
	if (tileApex) {
		x = centerX - 1;
		y = centerY - 6;
		drawTile(tileApex, x, y);
		setApexTileLeftBorderVisible(1);
	} else {
		setApexTileLeftBorderVisible(0);
	}

	// Draw middle-left end tile
	tile = tilesLevel0[middleLeftTileIndex];
	if (tile) {
		x = centerX - 14;
		y = centerY - 2;
		drawTile(tile, x, y);
	}

	// Draw middle-right tiles
	tile = tilesLevel0[middleRightTile0Index];
	if (tile) {
		x = centerX + 12;
		y = centerY - 2;
		drawTile(tile, x, y);
	}
	tile = tilesLevel0[middleRightTile1Index];
	if (tile) {
		x = centerX + 14;
		y = centerY - 2;
		drawTile(tile, x, y);
	}
	


}

static void initTileBoard(void) {
	uint8_t x, y, hw, start, end, tile;

	for (x=0; x<(14*8); ++x) {
		tilesLevel0[x] = 0;
	}
	for (x=0; x<(8*6); ++x) {
		tilesLevel1[x] = 0;
	}
	for (x=0; x<(6*4); ++x) {
		tilesLevel2[x] = 0;
	}
	for (x=0; x<(4*2); ++x) {
		tilesLevel3[x] = 0;
	}
	tileApex = 0;

	tile = 18;

	// Place level 0 tiles
	for (y=0; y<8; ++y) {
		hw = level0RowHalfWidths[y];
		start = 7 - hw;
		end = start + hw * 2;
		for (x=start; x<end; ++x) {
			tilesLevel0[x + y * 14] = tile;
			++tile;
		}
	}

	// Place level 1 tiles 
	for (y=0; y<6; ++y) {
		for (x=1; x<7; ++x) {
			tilesLevel1[x + y * 8] = tile;
			++tile;
		}
	}

	// Place level 2 tiles 
	for (y=0; y<4; ++y) {
		for (x=1; x<5; ++x) {
			tilesLevel2[x + y * 6] = tile;
			++tile;
		}
	}

	// Place level 3 tiles 
	for (y=0; y<2; ++y) {
		for (x=1; x<3; ++x) {
			tilesLevel3[x + y * 4] = tile;
			++tile;
		}
	}

	// Place apex tile
	tileApex = tile;
	++tile;

	// Place middle-left tile
	tilesLevel0[middleLeftTileIndex] = tile;
	++tile;

	// Place middle-right tiles
	tilesLevel0[middleRightTile0Index] = tile;
	++tile;
	tilesLevel0[middleRightTile1Index] = tile;
	++tile;


}


static void keyDown(uint8_t keycode) {
	uint8_t shift = keycode & 0x40;
	uint8_t control = keycode & 0x80;
	uint8_t note = 0xFF;
	const uint8_t vol = 8;

	switch (keycode & 0x3F) {
		case KEY_DELETE:
		case KEY_Z:
			// Handle "Undo Move" 
			break;

		case KEY_N:
			// Handle "New"
			break;

		case KEY_R:
			// Handle "Restart"
			break;

		default:
			break;
	}
}

static void keyUp(uint8_t /* keycode */) {
}

static void handleKeyboard(void) {
	static uint8_t previousKeycode = 0xFF;
	static uint8_t previousKeydown = 0;

	uint8_t isDown = (POKEY_READ.skstat & 0x04) == 0;
	uint8_t keycode = POKEY_READ.kbcode; // was POKEY_READ.kbcode

	if (keycode != previousKeycode) {
		keyUp(previousKeycode);
		keyDown(keycode);
	} else if (previousKeydown == 0 && isDown != 0) {
		keyDown(keycode);
	} else if (previousKeydown != 0 && isDown == 0) {
		keyUp(keycode);
	}
	previousKeydown = isDown;
	previousKeycode = keycode;
}

static void setApexTileLeftBorderSprite(void) {
	uint8_t *sprite = getSpritePtr(4);
	uint8_t y;

	for (y=0; y<10; ++y) {
		sprite[PMTopMargin+5*4+1+y] = 0x80;
	}
}

static void printCommand(const char *key, const char *title) {
	POKE(BITMSK, 0x80);
	printString(key);
	POKE(BITMSK, 0);
	printString(title);
}

static void printMainCommandMenu(void) {
	POKE(ROWCRS, 23);
	POKE(COLCRS, 2);

	printCommand("U", "ndo");
	POKE(COLCRS, PEEK(COLCRS)+2);

	printCommand("R", "estart");
	POKE(COLCRS, PEEK(COLCRS)+2);

	printCommand("N", "ew");
	POKE(COLCRS, PEEK(COLCRS)+2);
}

static void printStatusLine(const char *s) {
	zeroOutMemory(SAVMSC_ptr + RowBytes * 21, RowBytes);
	printStringAtXY(s, 2, 21);
}

int main (void) {
	uint8_t movePointerMessageVisible = 1;

	// Init
	initGraphics();
	initMouse();
	initVBI();
	isQuitting = 0;

	// Test all charas
	// {
	// 	uint8_t x;
	// 	for (x=0; x<255; ++x) {
	// 		screen[x] = x;
	// 	}
	// }

	// Add sprite data for apex tile left border
	setApexTileLeftBorderSprite();

	printStatusLine("Move pointer with joystick or mouse");
	printMainCommandMenu();

	// New game
	initTileBoard();
	drawTileBoard();

	pointerHasMoved = 0; // Reset this because initially it will be set when pointer is drawn for the first time.

	while (isQuitting == 0) {
		handleKeyboard();
		ATRACT_value = 0;

		if (movePointerMessageVisible && pointerHasMoved) {
			movePointerMessageVisible = 0;
			printStatusLine("Select a tile");


		}
	}

	return 0; // success
}
