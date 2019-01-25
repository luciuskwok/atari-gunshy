# print_shift_table.py

# prints a shift table for use with ASM

shiftAmount = 2

print ("tableA:")
for x in range (0, 256):
	a = x >> shiftAmount
	print (".byte {}".format(a))

print ("tableB:")
for x in range (0, 256):
	b = x & ~(0xFF << shiftAmount)
	b = b << (8 - shiftAmount)
	print (".byte {}".format(b))
	
