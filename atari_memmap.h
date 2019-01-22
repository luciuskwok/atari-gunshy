// atari_memmap.h

#ifndef ATARI_MEMMAP_H
#define ATARI_MEMMAP_H

// Zero Page - OS
#define APPMHI (0x0E)
#define ATRACT (0x4D)

#define TMPCHR (0x50) /* Temporary register used by display handler */
#define HOLD1  (0x51) /* Also temporary register */
#define LMARGN (0x52) /* Left margin */
#define RMARGN (0x53) /* Right margin */
#define ROWCRS (0x54) /* Current graphics or text cursor row */
#define COLCRS (0x55) /* Current graphics or text cursor column, 16-bit */
#define DINDEX (0x57) /* Current screen/display mode */
#define SAVMSC (0x58) /* Pointer to screen memory, 16-bit */
#define OLDROW (0x5A) /* Previous graphics cursor row */
#define OLDCOL (0x5B) /* Previous graphics cursor column, 16-bit */
#define NEWROW (0x60)
#define NEWCOL (0x61)
#define SAVADR (0x68) /* Temporary pointer for screen row */
#define RAMTOP (0x6A)
#define BITMSK (0x6E)
#define DELTAR (0x76)
#define DELTAC (0x77)
#define ROWINC (0x79)
#define COLINC (0x7A)

#define SHORT_CLOCK (PEEK(20) + 256 * PEEK(19))

// Accessors for C
#define ATRACT_value (*(char*)ATRACT)
#define SAVMSC_ptr (*(char**)SAVMSC)
#define SAVADR_ptr (*(char**)SAVADR)
#define ROWCRS_value (*(char*)ROWCRS)
#define COLCRS_value (*(unsigned int*)COLCRS)


// Page 2 - OS
#define VDSLST (0x0200) /* Display list interrupt vector */
#define VVBLKI (0x0222) /* Immediate vertical blank interrupt vector */
#define VVBLKD (0x0224) /* Deferred vertical blank interrupt vector */

#define SDMCTL (0x022F)
#define SDLSTL (0x0230) /* Pointer to display list */
#define GPRIOR (0x026F)

// Joystick
#define STICK0 (0x0278)
#define STRIG0 (0x0284)

// Text Window
#define TXTMSC (0x0294) /* Pointer to text window memory */
#define BOTSCR (0x02BF)

// Colors (Shadow)
#define PCOLR0 (0x02C0)
#define PCOLR1 (0x02C1)
#define PCOLR2 (0x02C2)
#define PCOLR3 (0x02C3)
#define COLOR0 (0x02C4)
#define COLOR1 (0x02C5) /* text luminance */
#define COLOR2 (0x02C6) /* text background color */
#define COLOR3 (0x02C7)
#define COLOR4 (0x02C8)
#define COLOR5 (0x02C9) /* DLI text luminance */
#define COLOR6 (0x02CA) /* DLI text background color */

// Memory Management
#define MEMTOP (0x02E5)
#define CHBAS (0x02F4)

// Keyboard
#define CH1 (0x02F2)
#define CH_ (0x02FC)

// Sprites (GTIA)
#define HPOSP0 (0xD000)
#define HPOSP1 (0xD001)
#define HPOSP2 (0xD002)
#define HPOSP3 (0xD003)
#define HPOSM0 (0xD004)
#define HPOSM1 (0xD005)
#define HPOSM2 (0xD006)
#define HPOSM3 (0xD007)
#define SIZEP0 (0xD008)
#define SIZEP1 (0xD009)
#define SIZEP2 (0xD00A)
#define SIZEP3 (0xD00B)

// Sound (POKEY)
#define AUDF1  (0xD200)
#define AUDC1  (0xD201)
#define AUDCTL (0xD208)
#define SKCTL  (0xD20F)

// ANTIC
#define NMIEN  (0xD40E) 

// Macros
#define POKE(addr,val)  (*(unsigned char*) (addr) = (val))
#define POKEW(addr,val)  (*(unsigned*) (addr) = (val))
#define PEEK(addr)  (*(unsigned char*) (addr))
#define PEEKW(addr)  (*(unsigned*) (addr))

#endif
