# png_to_tileset.py
# python3

# Given the "tiles.png" file, create tileset data for ANTIC mode 4. 
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

def printTileData(tileData, tileIndex):
	print("; Tile {}".format(tileIndex))
	i = 0
	for y in range(0, 4):
		sys.stdout.write("\t.byte ")
		for x in range(0, 8):
			c = tileData[i]
			i += 1
			sys.stdout.write("$%0.2X"%c)
			if x < 7: 
				sys.stdout.write(",")
		sys.stdout.write("\n")


# == Main Script ==
with open("tiles.png", "rb") as file:
	pngReader = png.Reader(file=file)
	(width, height, pixels, info) = pngReader.read()
	bitPlaneCount = info["planes"];
	print("; PNG image {}x{}x{}.".format(width, height, bitPlaneCount))

	packedData = []
	rowIndex = 0
	totalTiles = 0

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
			if lum < 0.125:
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

		rowIndex += 1

		# Reorganize packed data into blocks 4 bytes wide by 16 high.
		if rowIndex % 16 == 0:
			sys.stdout.write("\n")
			rowBytes = int(len(packedData) / 16)
			tileCount = int(rowBytes / 2)

			for tileIndex in range(0, tileCount): 
				tileData = []
				for y in range(0, 16):
					packedIndex = y * rowBytes + tileIndex * 4
					tileData.extend(packedData[packedIndex:packedIndex+4])
				printTileData(tileData, totalTiles)
				totalTiles += 1

			# Reset data for upper and lower rows
			packedData = []

	print("; Total tile count: {}".format(totalTiles))


