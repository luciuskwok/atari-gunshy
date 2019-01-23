// main.c


// == About This Program ==
// This program is a Shanghai-like game. 


// Includes
#include "atari_memmap.h"
#include "graphics.h"
#include "text.h"
#include "types.h"
#include <atari.h>


// mouse.asm stuff
extern uint8_t pointerHasMoved;
extern point_t mouseLocation;

// misc.asm stuff
void zeroOutMemory(uint8_t *ptr, uint16_t length);

// Typedef
typedef struct TileSpecifier {
	uint8_t value;
	uint8_t level;
	uint8_t x;
	uint8_t y;
} TileSpecifier;

// Globals
uint8_t isQuitting;

uint8_t tilesLevel0[14*8];
uint8_t tilesLevel1[8*6];
uint8_t tilesLevel2[6*4];
uint8_t tilesLevel3[4*2];
uint8_t tileApex;

uint8_t *tileLayers[5] = {
	tilesLevel0, tilesLevel1, tilesLevel2, tilesLevel3, &tileApex
};

uint8_t tilesRemaining;
TileSpecifier firstTileSelected;

// Constants
#define RowBytes (40)
#define middleLeftTileIndex (3*14)
#define middleRightTile0Index (3*14+13)
#define middleRightTile1Index (4*14+13)
#define PMLeftMargin (48)
#define PMTopMargin (16)

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

	0x64, 0x65, 0x66, 0x67, // East wind
	0x6C, 0x6D, 0x6E, 0x6F, // South wind
	0x68, 0x69, 0x6A, 0x6B, // West wind
	0x60, 0x61, 0x62, 0x63, // North wind

	0x70, 0x71, 0x72, 0x73, // Red dragon
	0x74, 0x75, 0x76, 0x77, // Green dragon
	0x04, 0x05, 0x06, 0x07, // White dragon
	
	0xF8, 0xF9, 0xFA, 0xFB, // Moon
	0xFC, 0xFD, 0x7E, 0x7F, // Flower
};

const char sDiscs[] = "Discs";
const char sChars[] = "Chars";
const char sBamboo[] = "Bamboo";
const char * tileSuits[3] = { sDiscs, sChars, sBamboo };

const char sEastWind[]  = "East Wind";
const char sSouthWind[] = "South Wind";
const char sWestWind[]  = "West Wind";
const char sNorthWind[] = "North Wind";
const char sRedDragon[] = "Red Dragon";
const char sGreenDragon[] = "Green Dragon";
const char sWhiteDragon[] = "White Dragon";
const char sMoon[] = "Moon";
const char sFlower[] = "Flower";
const char * tileNames[9] = {
	sEastWind, sSouthWind, sWestWind, sNorthWind, 
	sRedDragon, sGreenDragon, sWhiteDragon, sMoon, sFlower
};

// Position offsets from center for each tile layer
const point_t layerOffset[5] = {
	{ 14, 9 }, 
	{  8, 8 }, 
	{  6, 7 },
	{  4, 6 }, 
	{  1, 6 }
};

// Layer dimensions
const point_t layerSize[5] = {
	{ 14, 8 },
	{  8, 6 },
	{  6, 4 },
	{  4, 2 },
	{  1, 1 }
};

// Center of tile board
const point_t boardCenter = { 20, 11 };

const uint8_t level0RowHalfWidths[] = { 6, 4, 5, 6, 6, 5, 4, 6 };



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

static void clearStatusLine(void) {
	zeroOutMemory(SAVMSC_ptr + RowBytes * 21, RowBytes);
}

static void printStatusLine(const char *s) {
	clearStatusLine();
	printStringAtXY(s, 2, 21);
}

static void drawTile(uint8_t tile, uint8_t x, uint8_t y) {
	// Uses ROWCRS and COLCRS to position origin of tile.
	// Tile is in the range of 1...144 inclusive. 
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

static point_t tileLocation(uint8_t level, uint8_t row, uint8_t col) {
	uint8_t offsetX = layerOffset[level].x;
	uint8_t offsetY = layerOffset[level].y;
	point_t loc;

	loc.x = boardCenter.x + col * 2 - offsetX;
	loc.y = boardCenter.y + row * 2 - offsetY;

	// Special case for far left and far right tiles
	if (level == 0) {
		if (col == 0) {
			loc.y += 1;
		} else if (col == 13) {
			if (row == 3) {
				loc.y += 1;
			} else if (row == 4) {
				loc.y -= 1;
				loc.x += 2;
			}
		}
	}
	return loc;
}

static void drawTileBoard(void) {
	uint8_t level, row, col, tile;
	uint8_t layerWidth, layerHeight;
	point_t loc;
	uint8_t *layer;

	for (level=0; level<5; ++level) {
		layer = tileLayers[level];
		layerWidth = layerSize[level].x;
		layerHeight = layerSize[level].y;

		for (row=0; row<layerHeight; ++row) {
			for (col=0; col<layerWidth; ++col) {
				tile = layer[col + row * layerWidth];
				if (tile) {
					loc = tileLocation(level, row, col);
					drawTile(tile, loc.x, loc.y);
				}
			}
		}
	}

	// Draw apex tile
	if (tileApex) {
		setApexTileLeftBorderVisible(1);
	} else {
		setApexTileLeftBorderVisible(0);
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
		case KEY_U:
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

static void handleKeyboard(void) {
	static uint8_t previousKeycode = 0xFF;
	static uint8_t previousKeydown = 0;

	uint8_t isDown = (POKEY_READ.skstat & 0x04) == 0;
	uint8_t keycode = POKEY_READ.kbcode; // was POKEY_READ.kbcode

	if (keycode != previousKeycode) {
		// keyUp(previousKeycode);
		keyDown(keycode);
	} else if (previousKeydown == 0 && isDown != 0) {
		keyDown(keycode);
	} else if (previousKeydown != 0 && isDown == 0) {
		// keyUp(keycode);
	}
	previousKeydown = isDown;
	previousKeycode = keycode;
}

static uint8_t pointInRect(uint8_t ptx, uint8_t pty, uint8_t rx, uint8_t ry, uint8_t rw, uint8_t rh) {
	if (rx <= ptx && ptx < rx+rw && ry <= pty && pty < ry+rh) {
		return 1;
	} // else:
	return 0;
}

static void getTileHit(TileSpecifier *outTile, uint8_t x, uint8_t y) {
	int8_t level, row, col;
	int8_t layerWidth, layerHeight;
	uint8_t tile;
	uint8_t *layer;
	point_t loc;

	// Set outTile to none
	outTile->value = 0;

	// Search from top layer to bottom layer, front to back.
	for (level=4; level>=0; --level) {
		layer = tileLayers[level];
		layerWidth = layerSize[level].x;
		layerHeight = layerSize[level].y;

		for (row=layerHeight-1; row>=0; --row) {
			for (col=layerWidth-1; col>=0; --col) {
				tile = layer[col + row * layerWidth];
				if (tile) {
					loc = tileLocation(level, row, col);
					if (pointInRect(x, y, loc.x, loc.y, 2, 3)) {
						outTile->value = tile;
						outTile->x = col;
						outTile->y = row;
						outTile->level = level;
						return;
					}
				}
			}
		}
	}
}

static void printTileInfo(TileSpecifier *tile) {
	char s[8];
	uint8_t value = (tile->value - 1) % 36;
	uint8_t suit;

	clearStatusLine();
	ROWCRS_value = 21;
	COLCRS_value = 2;

	printString("Tile: ");

	if (value < 27) {
		// Suits
		suit = value / 9;
		value = value % 9;

		uint16String(s, value+1);
		printString(s);

		printString(" of ");
		printString(tileSuits[suit]);
	} else {
		printString(tileNames[value-27]);
	}
}

static void selectTile(TileSpecifier *tile) {
	point_t loc;

	loc = tileLocation(tile->level, tile->y, tile->x);
	setSelectionLocation(loc.x, loc.y);

	firstTileSelected.value = tile->value;
	firstTileSelected.x = tile->x;
	firstTileSelected.y = tile->y;
	firstTileSelected.level = tile->level;

	// Print info on selected tile
	printTileInfo(tile);
}

static void deselectTile(void) {
	hideSelection();
	firstTileSelected.value = 0;
	printStatusLine("Select a tile");
}

static void mouseDown(void) {
	uint8_t x = mouseLocation.x;
	uint8_t y = mouseLocation.y;
	uint8_t wasSelected = 0;
	TileSpecifier tileHit;

	x = (x - PMLeftMargin) / 4;
	y = (y - PMTopMargin) / 4;

	// Select the tile if no tile was selected or previously selected tile does not match. Otherwise, remove the matching pair of tiles.

	getTileHit(&tileHit, x, y);
	if (tileHit.value) {
		if (tileHit.value != firstTileSelected.value && ((tileHit.value-1)%36 == (firstTileSelected.value-1)%36)) {
			// Tiles match if they are one of 4 identical tiles, but don't match the exact same instance of the tile already selected.
			// TODO: remove tile
		} else {
			// Change the selection to the selected tile, if tile is free.
			// TODO: check if tile is free
			selectTile(&tileHit);
			wasSelected = 1;
		}
	}

	if (firstTileSelected.value && wasSelected == 0) {
		deselectTile();
	}
}

static void handleTrigger(void) {
	static uint8_t prevTrig0 = 0;
	static uint8_t prevTrig1 = 0;
	uint8_t trig0 = PEEK(STRIG0);
	uint8_t trig1 = PEEK(STRIG1);

	// Only the left mouse button is supported, since it is mapped to the joystick fire button on the Atari 9-pin joystick port.
	// Mouse should be plugged into the second port (STICK1).
	// Logic value = 0 means switch is closed, button is down.
	if (prevTrig0 != trig0) {
		prevTrig0 = trig0;
		if (trig0 == 0) { 
			// Button is down.
			mouseDown();
		}
		// else mouseUp(), which isn't handled
	}
	if (prevTrig1 != trig1) {
		prevTrig1 = trig1;
		if (trig1 == 0) { 
			// Button is down.
			mouseDown();
		}
		// else mouseUp(), which isn't handled
	}
}

int main (void) {
	uint8_t movePointerMessageVisible = 1;

	// Init
	initGraphics();
	isQuitting = 0;

	// Test all charas
	// {
	// 	uint8_t x;
	// 	for (x=0; x<255; ++x) {
	// 		screen[x] = x;
	// 	}
	// }

	// Add sprite data for apex tile left border
	{
		uint8_t *sprite = getSpritePtr(4);
		uint8_t y;
		for (y=0; y<10; ++y) {
			sprite[PMTopMargin+5*4+1+y] = 0x80;
		}
	}

	printStatusLine("Move pointer with joystick or mouse");
	printMainCommandMenu();

	// New game
	initTileBoard();
	drawTileBoard();

	pointerHasMoved = 0; // Reset this because initially it will be set when pointer is drawn for the first time.

	while (isQuitting == 0) {
		handleKeyboard();
		handleTrigger();
		ATRACT_value = 0;

		if (movePointerMessageVisible && pointerHasMoved) {
			movePointerMessageVisible = 0;
			printStatusLine("Select a tile");
		}
	}

	return 0; // success
}
