# png_to_tileset.py
# python3

# Given a PNG file, create tileset data for ANTIC mode 4. 
# This script divides up the PNG image into 16px by 16px units, and converts each unit into 4 tiles. Because mode-4 tiles are 4px width by 8px high, only the even-numbered pixel columns are considered when converting to tiles. 

import png, sys

# Color map
colorMap = [
	0, # black becomes background color
	3, # dark colors become playfield 3 or 4
	2, # light colors become playfield color 2 
	1 # white becomes playfield color 1
]

def characterData(packedData):
	chars = []
	charCount = int(len(packedData)/8)
	for charIndex in range(0, charCount):
		charUnit = []
		for y in range(0, 8):
			c = packedData[charIndex + y * charCount]
			charUnit.append(c)
		chars.append(charUnit)
	return chars

def printCharData(charData):
	sys.stdout.write(".byte ")
	for i in range(0, 8):
		c = charData[i]
		sys.stdout.write("$%0.2X"%c)
		if i < 7: 
			sys.stdout.write(",")
	sys.stdout.write("\n")


# == Main Script ==
with open("tiles.png", "rb") as file:
	pngReader = png.Reader(file=file)
	(width, height, pixels, info) = pngReader.read()
	bitPlaneCount = info["planes"];
	print("Valid PNG image {}x{}x{}.".format(width, height, bitPlaneCount))

	packedData = []
	upperRow = []
	lowerRow = []
	rowIndex = 0

	for pixelRow in pixels:
		colIndex = 0
		value = 0
		# Process image in 16px-high rows into a block of packed 2-bit pixel data.
		for col in range(0, int(width/2)):
			r = pixelRow[2 * col * bitPlaneCount]
			g = pixelRow[2 * col * bitPlaneCount + 1]
			b = pixelRow[2 * col * bitPlaneCount + 2]
			lum = float(r+g+b) / (255 * 3)

			value = (value << 2) 
			if lum < 0.05:
				value |= colorMap[0]
			elif lum < 0.3:
				value |= colorMap[1]
			elif lum < 0.9:
				value |= colorMap[2]
			else:
				value |= colorMap[3]

			colIndex += 1
			if colIndex % 4 == 0:
				packedData.append(value)
				value = 0 

		# Take the packed data and reorganize it into two rows of character data.
		rowIndex += 1
		if rowIndex % 16 == 8: 
			upperRow = characterData(packedData)
			# Reset packedData for lowerRow
			packedData = []

		if rowIndex % 16 == 0:
			lowerRow = characterData(packedData)

			# Output char data in the order 0, 1, halfway, halfway+1
			groupCount = int(len(lowerRow)/2)
			for groupIndex in range(0, groupCount):
				printCharData(upperRow[groupIndex*2])
				printCharData(upperRow[groupIndex*2+1])
				printCharData(lowerRow[groupIndex*2])
				printCharData(lowerRow[groupIndex*2+1])
				sys.stdout.write("\n") # separate tile groups

			# Reset data for upper and lower rows
			packedData = []
			upperRow = []
			lowerRow = []
