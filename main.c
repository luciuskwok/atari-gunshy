// main.c


// == About This Program ==
// This program is a Shanghai-like game. 


// Includes
#include "atari_memmap.h"
#include "types.h"
#include <atari.h>


// Globals
uint8_t isQuitting;


static void keyDown(uint8_t keycode) {
	/* Musical keyboard:
		Use keys on the bottom row from Z to M and the comma key for the white keys.
		Use the home rome for black keys.
		Q: switches to wavetable synth for bass notes (-2 octaves)
		W: switches to normal square-wave tone.
		Keys 1-4: switches octaves.
		Keys 8, 9, 0: starts a song.
		Space: stops the song.
	*/
	uint8_t shift = keycode & 0x40;
	uint8_t control = keycode & 0x80;
	uint8_t note = 0xFF;
	const uint8_t vol = 8;

	switch (keycode & 0x3F) {
		case KEY_DELETE:
			// Handle "Undo Move" 
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

static void initGraphics(void) {

}

int main (void) {
	// Init
	initGraphics();
	isQuitting = 0;


	while (isQuitting == 0) {
		handleKeyboard();
		RESET_ATTRACT;
	}

	return 0; // success
}
