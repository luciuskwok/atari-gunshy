# atari-gunshy
A solitaire game like Shanghai or Mahjong Solitaire. 

This is a work-in-progress.  

To build this project, you will need [CC65](https://github.com/cc65/cc65).

To run the program, you will need an Atari 8-bit emulator such as [Altirra](http://www.virtualdub.org/altirra.html).

__Building this Project__

This project uses a Sublime Text 3 project file which contains the build command, cl65, and the list of files to build. Please see that file to see the latest list of files included in the build phase.

The build command will look something like: 
`cl65 -O -t atari -C <list of .c and .s files> -o adv.xex`

If you get build errors, make sure you have the latest maintained version of cc65 from [GitHub](https://github.com/cc65/cc65), and not one of the older versions floating around the Internet.

If you're on Windows, you can download the pre-built binaries in the Windows snapshot.

If you're on Mac OS, you can clone or download cc65 from github and in the terminal type `install bin` and then `install lib`. 

Make sure to put the path to the cc65 bin folder in your /etc/profile or equivalent location so that the shell can find it. 
