// main.c


// == About This Program ==
// This program is a Shanghai-like game. 


// Includes
#include "atari_memmap.h"
#include "graphics.h"
#include "text.h"
#include "types.h"
#include <atari.h>


// misc.asm stuff
void zeroOutMemory(uint8_t *ptr, uint16_t length);

// mouse.asm stuff
extern uint8_t pointerHasMoved;
extern point_t mouseLocation;

// tile.asm stuff
point_t tileLocation(uint8_t level, uint8_t row, uint8_t col);
void drawTileBoard(void);

// Typedef
typedef struct TileSpecifier {
	uint8_t value;
	uint8_t level;
	uint8_t x;
	uint8_t y;
} TileSpecifier;

// Globals
uint8_t isQuitting;
uint8_t isInDialog;

uint8_t tilesLevel0[14*8];
uint8_t tilesLevel1[8*6];
uint8_t tilesLevel2[6*4];
uint8_t tilesLevel3[4*2];
uint8_t tileApex;

uint8_t *tileLayers[5] = {
	tilesLevel0, tilesLevel1, tilesLevel2, tilesLevel3, &tileApex
};

TileSpecifier firstTileSelected;

#define MaxMoves (144)
TileSpecifier moves[MaxMoves];
uint8_t movesIndex;

// Constants
#define RowBytes (40)
#define middleLeftTileIndex (3*14)
#define middleRightTile0Index (3*14+13)
#define middleRightTile1Index (4*14+13)
#define PMLeftMargin (48)
#define PMTopMargin (16)

const char * tileSuits[3] = { "Dots", "Wan", "Bamboo" };

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

const uint8_t level0RowStart[] = { 1, 3, 2, 0, 1, 2, 3, 1 };
const uint8_t level0RowEnd[] = { 13, 11, 12, 14, 14, 12, 11, 13 };

// In-line function macros

#define clearLine(line) zeroOutMemory(SAVMSC_ptr + RowBytes * (line), RowBytes)
#define StatusLine (21)
#define CommandsLine (23)


static void drawTileBoardTimed(void) {
    uint16_t startTime = Clock16;
    
    drawTileBoard();

    // Print duration
    {
        char s[6];
        uint8_t len = uint16String(s, Clock16 - startTime);
        printStringAtXY("     ", 35, 22);
        printStringAtXY(s, 40-len, 22);
    }  
}

static void printCommand(const char *key, const char *title) {
	POKE(BITMSK, 0x80);
	printString(key);
	POKE(BITMSK, 0);
	printString(title);
}

static void printTilesLeft(void) {
	char s[5];
	uint8_t len;

	len = uint16String(s, MaxMoves - movesIndex);
	POKE(ROWCRS, 23);
	POKE(COLCRS, 38-len);
	printString("  ");
	printString(s);
}

static void printMainCommandMenu(void) {
	clearLine(CommandsLine);

	POKE(ROWCRS, CommandsLine);
	POKE(COLCRS, 2);

	printCommand("U", "ndo");
	POKE(COLCRS, PEEK(COLCRS)+2);

	printCommand("R", "estart");
	POKE(COLCRS, PEEK(COLCRS)+2);

	printCommand("N", "ew");
	POKE(COLCRS, PEEK(COLCRS)+2);

	printTilesLeft();
}

static void printStatusLine(const char *s) {
	clearLine(StatusLine);
	printStringAtXY(s, 2, 21);
}

static void debugLocation(uint8_t x, uint16_t y) {
	char s[6];

	clearLine(StatusLine);
	POKE(ROWCRS, 21);
	POKE(COLCRS, 2);
	printString("Location: ");
	uint16String(s, x);
	printString(s);
	printString(", ");
	uint16String(s, y);
	printString(s);
}

static void getShuffledTiles(uint8_t *outArray) {
	// This version just creates an array in order, for testing.
	uint8_t x;
	uint8_t value = 1;

	for (x=0; x<144; ++x) {
		outArray[x] = value;

		value += 4; 
		if (value > 144) {
			value = value - 143;
		}
	}
}

static void startNewGame(void) {
	uint8_t level, row, col;
	uint8_t height, width;
	uint8_t *layer;
	uint8_t layerIndex;
	uint8_t sortedTiles[144];
	uint8_t tileIndex = 0;

	// Sort tiles
	getShuffledTiles(sortedTiles);

	// Place tiles in regular positions, skipping ends of rows.
	for (level=0; level<5; ++level) {
		layer = tileLayers[level];
		height = layerSize[level].y;
		width = layerSize[level].x;
		for (row=0; row<height; ++row) {
			for (col=0; col<width; ++col) {
				layerIndex = row * width + col;
				layer[layerIndex] = 0;

				if (level == 0) {
					if (col < level0RowStart[row] || col >= level0RowEnd[row]) {
						continue;
					}
				} else if (level < 4) {
					if (col == 0 || col >= width-1) {
						continue;
					}
				}

				layer[layerIndex] = sortedTiles[tileIndex++];
			}
		}
	}

	printMainCommandMenu();
	isInDialog = 0;

	movesIndex = 0;
	printTilesLeft();

	drawTileBoard();
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
					if (pointInRect(x, y, loc.x, loc.y, 12, 24)) {
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

static uint8_t isTileFree(TileSpecifier *tile) {
	uint8_t level = tile->level;
	uint8_t x = tile->x;
	uint8_t y = tile->y;
	uint8_t left, right;

	// Level 4 is apex and always free
	if (level == 4) {
		return 1;
	}

	// Level 3 is free if apex tile is removed
	if (level == 3) {
		return (tileApex == 0) ? 1 : 0;
	}

	// Level 0 has some special tiles
	if (level == 0) {
		if (x == 0) {
			return 1; // Left-middle endcap tile
		}
		if (x == 1) {
			if (y == 3 || y == 4) {
				// Tiles blocked by left-middle endcap tile.
				left = tilesLevel0[middleLeftTileIndex];
				right = tilesLevel0[y * layerSize[level].x + x + 1];
				return (left && right) ? 0 : 1;
			}
		}
		if (x == 12) {
			if (y == 3 || y == 4) {
				// Tiles blocked by right-middle endcap tiles.
				left = tilesLevel0[y * layerSize[level].x + x - 1];
				right = tilesLevel0[middleRightTile0Index];
				return (left && right) ? 0 : 1;
			}
		}
		if (x == 13) {
			if (y == 3) {
				// Second-to-last right-middle tile is free if the last right-middle tile is removed, or if the 2 tiles to its left are both removed.
				left = tilesLevel0[3 * layerSize[level].x + 12] || tilesLevel0[4 * layerSize[level].x + 12];
				right = tilesLevel0[middleRightTile1Index];
				return  (left && right) ? 0 : 1;
			}
			if (y == 4) {
				return 1; // last right-middle tile
			}
		}
	}

	// Otherwise, tile is free if there is nothing to the left, right, or above.
	{
		const uint8_t *upperLayer = tileLayers[level+1];
		const uint8_t *sameLayer = tileLayers[level];
		point_t upperLayerSize;
		uint8_t upperX, upperY;

		upperLayerSize = layerSize[level+1];

		upperX = x - (layerOffset[level].x - layerOffset[level+1].x) / 2;
		upperY = y - (layerOffset[level].y - layerOffset[level+1].y);
		
		// First check tile above
		if (upperX < upperLayerSize.x && upperY < upperLayerSize.y) {
			if (upperLayer[upperX + upperY * upperLayerSize.x]) {
				return 0;
			}
		}

		// Second check left and right
		if (sameLayer[y * layerSize[level].x + x - 1] == 0) {
			return 1;
		}
		if (sameLayer[y * layerSize[level].x + x + 1] == 0) {
			return 1;
		}
	}
	return 0; // Otherwise, return false
}

static void printTileInfo(TileSpecifier *tile) {
	char s[8];
	uint8_t value = (tile->value - 1) / 4;
	uint8_t suit;

	clearLine(StatusLine);
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

	// Debugging
	printString(" Loc:");
	uint16String(s, tile->level);
	printString(s);
	printString(",");
	uint16String(s, tile->x);
	printString(s);
	printString(",");
	uint16String(s, tile->y);
	printString(s);

}

static void selectTile(TileSpecifier *tile) {
	point_t loc;

	loc = tileLocation(tile->level, tile->y, tile->x);
	setSelectionLocation(loc.x, loc.y);

	firstTileSelected.value = tile->value;
	firstTileSelected.x = tile->x;
	firstTileSelected.y = tile->y;
	firstTileSelected.level = tile->level;
}

static void removeTile(TileSpecifier *tile) {
	uint8_t *layer = tileLayers[tile->level];
	layer[tile->y * layerSize[tile->level].x + tile->x] = 0;

	// Add move for undo
	if (movesIndex < MaxMoves) {
		moves[movesIndex].value = tile->value;
		moves[movesIndex].x = tile->x;
		moves[movesIndex].y = tile->y;
		moves[movesIndex].level = tile->level;
		movesIndex += 1;
	}
}

static void undoRemoveTile(void) {
	TileSpecifier *tile;
	uint8_t *layer;

	if (movesIndex > 0) {
		movesIndex -= 1;
		tile = &moves[movesIndex];
		layer = tileLayers[tile->level];
		layer[tile->y * layerSize[tile->level].x + tile->x] = tile->value;
	}
}

static void restartGame(void) {
	// Undo all mvoes
	TileSpecifier *tile;
	uint8_t *layer;

	while (movesIndex > 0) {
		movesIndex -= 1;
		tile = &moves[movesIndex];
		layer = tileLayers[tile->level];
		layer[tile->y * layerSize[tile->level].x + tile->x] = tile->value;
	}	
	drawTileBoardTimed();
}

static void showNewGameConfirmation(void) {
	isInDialog = 1;
	zeroOutMemory(SAVMSC_ptr + RowBytes * StatusLine, 3 * RowBytes);
	printStatusLine("Start a new game?");

	POKE(ROWCRS, CommandsLine);
	POKE(COLCRS, 2);

	printCommand("Y", "es");
	POKE(COLCRS, PEEK(COLCRS)+2);

	printCommand("N", "o");
}

static void hideNewGameConfirmation(void) {
	isInDialog = 0;
	printStatusLine("");
	printMainCommandMenu();
}

static void handleKeyboard(void) {
	uint8_t key = PEEK(CH_) & 0x3F;
	POKE(CH_, 0xFF); // Accept the key

	if (isInDialog) {
		if (key == KEY_Y || key == KEY_RETURN) {
			startNewGame();
			printStatusLine("Started a new game");
		} else if (key == KEY_N || key == KEY_ESC) {
			hideNewGameConfirmation();
		}
	} else {
		if (key == KEY_DELETE || key == KEY_U) {
			// Put last 2 tiles back.
			if (movesIndex > 0) {
				undoRemoveTile();
				undoRemoveTile();
				printStatusLine("Move undone");
				printTilesLeft();
				drawTileBoard();
			}
		} else if (key == KEY_N) {
			showNewGameConfirmation();
		} else if (key == KEY_R) {
			restartGame();
			printStatusLine("Game restarted");
			printTilesLeft();
		}
	}
}

static void mouseDown(void) {
	uint8_t x = mouseLocation.x - PMLeftMargin;
	uint8_t y = (mouseLocation.y - PMTopMargin) * 2;
	uint8_t shouldDeselect = 1;
	uint8_t shouldRedraw = 0;
	TileSpecifier tileHit;

	if (isInDialog) {
		hideNewGameConfirmation();
	}

	// Select the tile if no tile was selected or previously selected tile does not match. Otherwise, remove the matching pair of tiles.

	getTileHit(&tileHit, x, y);
	if (tileHit.value) {
		uint8_t isFree = isTileFree(&tileHit);
		if (isFree) {
			if (firstTileSelected.value && tileHit.value != firstTileSelected.value && ((tileHit.value-1)/4 == (firstTileSelected.value-1)/4)) {
				// Tiles match if they are one of 4 identical tiles, but don't match the exact same instance of the tile already selected.
				removeTile(&firstTileSelected);
				removeTile(&tileHit);
				if (movesIndex < MaxMoves) {
					printStatusLine("Match removed");
				} else {
					printStatusLine("Congratulations!");
				}
				printTilesLeft();
				shouldDeselect = 1;
				shouldRedraw = 1;
			} else {
				// Change the selection to the selected tile, if tile is free.
				printTileInfo(&tileHit);
				selectTile(&tileHit);
				shouldDeselect = 0;
			}
		} else {
			// Tile is blocked
			shouldDeselect = 0;
			printTileInfo(&tileHit);
			selectTile(&tileHit);
			// if (firstTileSelected.value == 0) {
			// 	printStatusLine("Tile is blocked");
			// }
		}
	} else {
		if (movesIndex < MaxMoves) {
			// printStatusLine("Select a tile");
			debugLocation(x, y);
		}
	}

	if (firstTileSelected.value && shouldDeselect) {
		hideSelection();
		firstTileSelected.value = 0;
	}
	if (shouldRedraw) {
		drawTileBoard();
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

	printStatusLine("Use joystick (pt.1) or mouse (pt.2)");

	// New game
	startNewGame();

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
