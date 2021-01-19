{ ----------------- Basic File I/O in SwiftForth - R A Smith 2020 ------------------- }


{ NOTES  Forth uses an integer number called a "file handle" to identify any file you }
{        create or open for file I/O operations.  Before we start to use a file, we   }
{        need to create a variable to hold the file handle so that we can referr to   }
{        it in later read and write operations.  File operations will genarally       }
{        return a true / false flag depending on whether the operation worked or not  }
{        hence all the "drop" commands in the section below.                          }
{                                                                                     }
{        File Paths - You need to use a complete path to the file when creating or    }
{        opening a file.  If you dont use  a path the file will be assumed to be in   }
{        SwiftForth\Bin directory.                                                    }
{                                                                                     }
{        Here we hard code a path to files in a directory C:\Temp                     }


variable test-file-id                             { Create Variable to hold file id handle }


: make-test-file                                  { Create a test file to read / write to  }
  s" C:\Temp\Test_File.dat" r/w create-file drop  { Create the file                        } 
  test-file-id !                                  { Store file handle for later use        }
;

 
: open-test-file                                  { Open the file for read/write access    }
  s" C:\Temp\Test_File.dat" r/w open-file drop    { Not needed if we have just created     }
  test-file-id !                                  { file.                                  }
;


: close-test-file                                 { Close the file pointed to by the file  }
  test-file-id @                                  { handle.                                }
  close-file drop
; 


: test-file-size                                  { Leave size of file on top of stack as  }
  test-file-id @                                  { a double prescision integer if the     }
  file-size drop                                  { file is open.                          }
;


: write-file-header 
  s"   1st Line of header " test-file-id @ write-line drop { Writes single lines of text to a file }
  s"   2nd Line of header " test-file-id @ write-line drop { terminating each line with a LF/CR.   }
  s"   3rd Line of header " test-file-id @ write-line drop { The file must be open for R/W access  }
  s"                      " test-file-id @ write-line drop { first.                                }
 ;


: write-file-data-1                                        { Write a series of integer numbers to a }
  1 (.) test-file-id @ write-line drop                     { file as ASCII characters.  We use the  }
  2 (.) test-file-id @ write-line drop                     { Forth command (.) to convert numbers   }
  3 (.) test-file-id @ write-line drop                     { on the stack into counted ASCII strings}
;


: write-file-data-2                                        { Write a series of integer numbers to a }               
  100 1 do                                                 { file as ASCII characters from inside a }
  i 20 * (.) test-file-id @ write-line drop                { looped structure.  File must be open   }
  loop                                                     { for R/W access first.                  }
  ;

: Write-file-data-3                                        { Write a series of pairs of integer     }
  20 1 do                                                  { numbers to an open file.               }
  i (.)     test-file-id @ write-file drop
  s"  "     test-file-id @ write-file drop
  i 2 * (.) test-file-id @ write-line drop
  loop
;
  
: Write-blank-data                                         { Write an empty line to the file       }
  s"  " test-file-id @ write-line drop
;



{ --------------- Now lets put all of this together to create, write to and close a file ---------- }             



: go
  make-test-file
  test-file-size cr cr ." File Start Size = " d.
  write-file-header
  write-file-data-1
  Write-blank-data
  write-file-data-2
  Write-blank-data
  Write-file-data-3
  Write-blank-data
  test-file-size cr cr ." File End Size =   " d. cr cr
  close-test-file
  ." Test ascii data file written to C:\Temp directory " cr cr
;

go

{--------------------------------------------------------------}

{ ---------------------------------------------------------------------------------------- }
{                                                                                          }
{ Words to create bitmap image files ( .bmp) in memory and display them as part of         } 
{ a real time data visualisation routine - fixed and stretchable window version V6.        }
{                                                                                          }
{ This version prints the .bmp into windows separate from the console, requiring some      }
{ additional operating system specific (Windows, Mac OSX etc) code to build and "talk"     }
{ to the new window.                                                                       }
{                                                                                          }
{ The .bmp format consists of a short 54 byte "header" which encodes image type, size etc  }
{ followed by a block of memory which encodes the colour of individual pixels as 8-bit RGB }
{ triplets, e.g. (0, 0, 0) is black, (255, 255, 255) is white, (0, 255, 0) is bright green }
{ and so on.  You will need to identify where the "data" block of the .bmp lives in memory }
{ and write to this in order to create an image which the example routines below show you  }
{ how to then display.                                                                     }
{                                                                                          }
{ Note that bmp x size must be integer divisible by 4 to avoid display glitches without    }
{ padding line ends - this is a general feature of the bmp file format and is not codes    }
{ specific.  bmp x sizes will be rounded down to the nearest factor of as a result 4.      }
{                                                                                          }
{ Two methods are provided to write the .bmp to the screen, the first uses the Windows     }
{ call SetDIBitsToDevice and writes and image with single 1x1 pixels for each cell, the    }
{ second uses the call StretchDIBits which allows stretching of a .bmp image to fill the   }
{ available window - useful for "magnifying" and image so that individual pixels are       }
{ easier to view.  Functions of this kind are typically hardware accelerated by graphics   }
{ cards and so relatively "fast".                                                          }
{                                                                                          }
{        Roland Smith, V6 revised 26/11/2020 - For 3rd Year Lab D3 Experiment              }
{                      V6b        03/11/2020 - Internal random number function Rnd         }
{                      V6c        09/12/2020 - Added go-dark set, set reset close example  }
{                      V6d        28/12/2020 - Added paint single pixel example            }
{                                                                                          }
{ ---------------------------------------------------------------------------------------- }

{                                Global constants and variables                            }


10 Constant Update-Timer  { Sets windows update rate - lower = faster refresh            }

variable bmp-x-size     { x dimension of bmp file                                        }

variable bmp-y-size     { y dimension of bmp file                                        }

variable bmp-size       { Total number of bmp elements = (x * y)                         }

variable bmp-address    { Stores start address of bmp file # 1                           }

variable bmp-length     { Total number of chars in bmp including header block            }

variable bmp-x-start    { Initial x position of upper left corner                        }

variable bmp-y-start    { Initial y position of upper left corner                        }

variable bmp-window-handle  { Variable to store the handle used to ID display window     }

variable offset         { Memory offset used in bmp pixel adddress examples              }

16 bmp-x-size !                               { Set default x size of bmp in pixels     }

16 bmp-y-size !                               { Set y default size of bmp in pixels     }

bmp-x-size @ 4 / 1 max 4 *  bmp-x-size !       { Trim x-size to integer product of 4     }

bmp-x-size @ bmp-y-size @ * bmp-size !         { Find number of pixels in bmp            }

bmp-size   @ 3 * 54 +       bmp-length !       { Find length of bmp in chars inc. header }

100 bmp-x-start !                              { Set x position of upper left corner     }

100 bmp-y-start !                              { Set y position of upper left corner     }

: bmp-Wind-Name Z" BMP Display " ;             { Set capion of the display window # 1    }


{ -------------------------  Random number routine for testing ------------------------- } 

CREATE SEED  123475689 ,

: Rnd ( n -- rnd )   { Returns single random number less than n }
   SEED              { Minimal version of SwiftForth Rnd.f      }
   DUP >R            { Algorithm Rick VanNorman  rvn@forth.com  }
   @ 127773 /MOD 
   2836 * SWAP 16807 * 
   2DUP > IF - 
   ELSE - 2147483647 +  
   THEN  DUP R> !
   SWAP MOD ;

{ --------------------------- Words to create a bmp file in memory ----------------------- }


: Make-Memory-bmp  ( x y  -- addr )        { Create 24 bit (RGB) bitmap in memory          }
  0 Locals| bmp-addr y-size x-size |
  x-size y-size * 3 * 54 +                 { Find number of bytes required for bmp file    }
  chars allocate                           { Allocate  memory = 3 x size + header in chars }
  drop to bmp-addr
  bmp-addr                                 { Set initial bmp pixels and header to zero     }
  x-size y-size * 3 * 54 + 0 fill

  { Create the 54 byte .bmp file header block }

  66 bmp-addr  0 + c!                      { Create header entries - B                     }
  77 bmp-addr  1 + c!                      { Create header entries - M                     }
  54 bmp-addr 10 + c!                      { Header length of 54 characters                } 
  40 bmp-addr 14 + c!   
   1 bmp-addr 26 + c!
  24 bmp-addr 28 + c!                      { Set bmp bit depth to 24                       }
  48 bmp-addr 34 + c!
 117 bmp-addr 35 + c!
  19 bmp-addr 38 + c!
  11 bmp-addr 39 + c!
  19 bmp-addr 42 + c!
  11 bmp-addr 43 + c!
 
  x-size y-size * 3 * 54 +                 { Store file length in header as 32 bit Dword   }
  bmp-addr 2 + !
  x-size                                   { Store bmp x dimension in header               }
  bmp-addr 18 + ! 
  y-size                                   { Store bmp y dimension in header               }
  bmp-addr 22 + ! 
  bmp-addr                                 { Leave bmp start address on stack and exit     }
  ;


{ ---------------------------------- Stand Alone Test Routines --------------------------- }


 : Setup-Test-Memory  ( -- )                       { Create bmps in memory to start with   }
   bmp-x-size @ bmp-y-size @ make-memory-bmp
   bmp-address ! 
   cr ." Created Test bmp " cr
   ;


{ --------------------------- Basic Words to Color bmp Pixels -----------------------------}


: Reset-bmp-Pixels  ( addr -- )    { Set all color elements of bmp at addr to zero = black }
  dup 54 + swap
  2 + @ 54 - 0 fill
  ;

 
: Random-bmp-Green  ( addr -- )          { Set bmp starting at addr to random green pixels }
  dup dup 2 + @ + swap 54 + do
  000                                    { Red   RGB value                                 }
  255 RND                                { Green RGB value                                 }
  000                                    { Blue  RGB value                                 }
  i  tuck c!
  1+ tuck c!
  1+      c!      
  3 +loop
  ;


: Random-bmp-Blue  ( addr -- )            { Set bmp starting at addr to random blue pixels }
  dup dup 2 + @ + swap 54 + do
  000                                     { Red   RGB value                                }
  000                                     { Green RGB value                                }
  255 RND                                 { Blue  RGB value                                }
  i  tuck c!
  1+ tuck c!
  1+      c!      
  3 +loop
  ;


{ -------------------- Word to display a bmp using MS Windows API Calls -----------------  }
{                                                                                          }
{ Warning, this section contains MS Windows specific code to create and communicate with a }
{ new display window and will not automatically translate to another OS, e.g. Mac or Linux }


Function: SetDIBitsToDevice ( a b c d e f g h i j k l -- res )

: MEM-bmp ( addr -- )                    { Prints bmp starting at address to screen        }
   [OBJECTS BITMAP MAKES BM OBJECTS]
   BM bmp!
   HWND GetDC ( hDC )
   DUP >R ( hDC ) 1 1 ( x y )            { (x,y) upper right corner of bitmap              }
   BM Width @ BM Height @ 0 0 0
   BM Height @ BM Data
   BM InfoHeader DIB_RGB_COLORS SetDIBitsToDevice DROP  { Windows API calls                }   
   HWND R> ( hDC ) ReleaseDC DROP ;



{ ---------------------- bmp Display Window Class and Application ------------------------ }
{                                                                                          }
{ Warning, this section contains MS Windows specific code to create and communicate with a }
{ new display window and will not automatically translate to another OS, e.g. Mac or Linux }


0 VALUE bmp-hApp            { Variable to hold handle for default bmp display window     }


: bmp-Classname Z" Show-bmp" ;      { Classname for the bmp output class          }


: bmp-End-App ( -- res )
   'MAIN @ [ HERE CODE> ] LITERAL < IF ( not an application yet )
      0 TO bmp-hApp
   ELSE ( is an application )
      0 PostQuitMessage DROP
   THEN 0 ;


[SWITCH bmp-App-Messages DEFWINPROC ( msg -- res ) WM_DESTROY RUNS bmp-End-App SWITCH]


:NONAME ( -- res ) MSG LOWORD bmp-App-Messages ; 4 CB: bmp-APP-WNDPROC { Link window messages to process }


: bmp-APP-CLASS ( -- )
      0  CS_OWNDC   OR                  \ Allocates unique device context for each window in class
         CS_HREDRAW OR                  \ Window to be redrawn if movement / size changes width
         CS_VREDRAW OR                  \ Window to be redrawn if movement / size changes height
      bmp-APP-WNDPROC                   \ wndproc
      0                                 \ class extra
      0                                 \ window extra
      HINST                             \ hinstance
      HINST 101  LoadIcon 
   \   NULL IDC_ARROW LoadCursor        \ Default Arrow Cursor
      NULL IDC_CROSS LoadCursor         \ Cross cursor
      WHITE_BRUSH GetStockObject        \
      0                                 \ no menu
      bmp-Classname                     \ class name
   DefineClass DROP
  ;


: bmp-window-shutdown     { Close bmp display window and unregister classes on shutdown   }               
   bmp-hApp IF 
   bmp-hApp WM_CLOSE 0 0 SendMessage DROP
   THEN
   bmp-Classname HINST UnregisterClass DROP
  ;


bmp-APP-CLASS                   { Call class for displaying bmp's in a child window     }

13 IMPORT: StretchDIBits

11 IMPORT: SetDIBitsToDevice 


{ ----------------------------- bmp Window Output Routines -------------------------------- }
{                                                                                           }
{  Create a new "copy" or "stretch" window, save its handle, and then output a .bmp from    }
{  memory to the window in "copy" mode or "stretch" mode.  You will need to write your own  }
{  data to the .bmp between each display cycle to give a real time view of your simulation. }


: New-bmp-Window-Copy  ( -- res )            \ Window class for "copy" display 
   0                                         \ exended style
   bmp-Classname                             \ class name
   s" BMP Window " pad zplace                \ window title - including bmp number
   1  (.) pad zappend pad
   WS_OVERLAPPEDWINDOW                       \ window style
   bmp-x-start @ bmp-y-start @               \ x   y Window position
   bmp-x-size @ 19 + bmp-y-size @ 51 +       \ cx cy Window size
   0                                         \ parent window
   0                                         \ menu
   HINST                                     \ instance handle
   0                                         \ creation parameters
   CreateWindowEx 
   DUP 0= ABORT" create window failed" 
   DUP 1 ShowWindow DROP
   DUP UpdateWindow DROP 
   ;


: New-bmp-Window-Stretch  ( -- res )         \ Window class for "stretch" display 
   0                                         \ exended style
   bmp-Classname                             \ class name
   s" BMP Window " pad zplace                \ window title - including bmp number
   1  (.) pad zappend pad
   WS_OVERLAPPEDWINDOW                       \ window style
   bmp-x-start @ bmp-y-start @               \ x   y Window position
   bmp-x-size @ 250 max 10 + 
   bmp-y-size @ 250 max 49 +                 \ cx cy Window size, min start size 250x250
   0                                         \ parent window
   0                                         \ menu
   HINST                                     \ instance handle
   0                                         \ creation parameters
   CreateWindowEx 
   DUP 0= ABORT" create window failed" 
   DUP 1 ShowWindow DROP
   DUP UpdateWindow DROP 
   ;


: bmp-to-screen-copy  ( n -- )            { Writes bmp at address to window with hwnd   }
  bmp-window-handle @ GetDC               { handle of device context we want to draw in }
  2 2                                     { x , y of upper-left corner of dest. rect.   }
  bmp-x-size @ 3 -  bmp-y-size @          { width , height of source rectangle          }
  0 0                                     { x , y coord of source rectangle lower left  }
  0                                       { First scan line in the array                }
  bmp-y-size @                            { number of scan lines                        }
  bmp-address @ dup 54 + swap 14 +        { address of bitmap bits, bitmap header       }
  0
  SetDIBitsToDevice drop
  ;


: bmp-to-screen-stretch  ( n addr -- )    { Stretch bmp at addr to window n             }
  0 0 0 
  Locals| bmp-win-hWnd bmp-win-x bmp-win-y bmp-address |
  bmp-window-handle @
  dup to bmp-win-hWnd                     { Handle of device context we want to draw in }
  PAD GetClientRect DROP                  { Get x , y size of window we draw to         }
  PAD @RECT 
  to bmp-win-y to bmp-win-x
  drop drop                             
  bmp-win-hWnd GetDC                      { Get device context of window we draw to     }
  2 2                                     { x , y of upper-left corner of dest. rect.   }   
  bmp-win-x 4 - bmp-win-y 4 -             { width, height of destination rectangle      }
  0 0                                     { x , y of upper-left corner of source rect.  }
  bmp-address 18 + @                      { Width of source rectangle                   }
  bmp-address 22 + @                      { Height of source rectangle                  }
  bmp-address dup 54 + swap 14 +          { address of bitmap bits, bitmap header       }
  0                                       { usage                                       }
  13369376                                { raster operation code                       } 
  StretchDIBits drop
  ;


{ ----------------------------- Demonstration Routines -------------------------------- }


: go-copy                             { Copy bmp to screen at 1x1 pixel size            }
  cr ." Starting looped copy to window test " 
  cr cr
  New-bmp-Window-copy                 { Create new "copy" window                        }
  bmp-window-handle !                 { Store window handle                             }
  50 0 Do                             { Begin update / display loop                     }
  bmp-address @ Random-bmp-Green      { Add random pixels to .bmp in memory             }
  bmp-to-screen-copy                  { Copy .bmp to display window                     }
  100 ms                              { Delay for viewing ease, reduce for higher speed }
  Loop
  bmp-window-handle @ DestroyWindow drop  
  cr ." Ending looped copy to window test " 
  cr cr 
  ;
 

: go-stretch                          { Draw bmp to screen at variable pixel size       }
  cr ." Starting looped stretch to window test " 
  cr cr
  New-bmp-Window-stretch              { Create new "stretch" window                     }
  bmp-window-handle !                 { Store window handle                             }
  Begin	                              { Begin update / display loop                     }
  bmp-address @ Random-bmp-Blue       { Add random pixels to .bmp in memory             }
  bmp-address @ bmp-to-screen-stretch { Stretch .bmp to display window                  }
  100 ms                              { Delay for viewing ease, reduce for higher speed }
  key?                                { Break test loop on key press                    }
  until 
  cr ." Ending looped stretch to window test " 
  cr cr
  ;


: go-dark                              { Draw bmp to screen at variable pixel size       }
  New-bmp-Window-stretch
  bmp-window-handle !
  bmp-address @ Random-bmp-Blue        { Show random blue pixels for a second            }
  bmp-address @ bmp-to-screen-stretch 
  1000 ms
  bmp-address @ Random-bmp-Green       { Show random greenpixels for a second            }
  bmp-address @ bmp-to-screen-stretch
  1000 ms
  bmp-address @ reset-bmp-pixels       { Reset .bmp to all black 0,0,0 RGB values        }
  bmp-address @ bmp-to-screen-stretch
  1000 ms
  bmp-window-handle @ DestroyWindow drop  { Kill of display window                       }
  ;


: paint-pixels                  { Create a blank .bmp and then paint individual pixels   }
  cr ." Starting single pixel paint test " cr
  New-bmp-Window-stretch
  bmp-window-handle !
  bmp-address @ bmp-to-screen-stretch   { Write black bmp to screen }

  10 ms 
  54 offset !	                               { Paint 1st corner }
  255 bmp-address @ offset @ + 0 + C!  
  1000 ms bmp-address @ bmp-to-screen-stretch

  10 ms                                        { Paint 2nd corner }
  54 bmp-x-size @ 1 - 3 * + offset !
  255 bmp-address @ offset @ + 1 + C! 
  1000 ms bmp-address @ bmp-to-screen-stretch

  10 ms                                        { Paint 3rd corner }
  54 bmp-x-size @ 1 - bmp-y-size @ * 3 * + offset !
  255 bmp-address @ offset @ + 2 + C!  
  1000 ms bmp-address @ bmp-to-screen-stretch

  10 ms                                        { Paint 4th corner }
  54 bmp-x-size @ bmp-y-size @ * 1 - 3 * + offset !
  255 bmp-address @ offset @ + 0 + C!  
  255 bmp-address @ offset @ + 1 + C!  
  255 bmp-address @ offset @ + 2 + C!  
  1000 ms bmp-address @ bmp-to-screen-stretch

  1000 ms 
  cr ." Ending single pixel paint test " 
  bmp-window-handle @ DestroyWindow drop  { Kill of display window                       }
  cr cr
  ;


{ ----------------------------- Run Test Output Routines ------------------------------- }


 {  8 bmp-x-size ! }
 { 8 bmp-y-size !}
 {  Setup-Test-Memory  { Create a blank 8x8 .bmp in memory      } }
{
 {  paint-pixels       { Demo paint individual pixels           }}
{}
 {  16 bmp-x-size !    { Create a blank 16x16 .bmp in memory    }}
 {  16 bmp-y-size !}
 {  Setup-Test-Memory}  
{}
 {  go-copy            { Demo looped copy to screen routine     }}
{}
 {  go-dark            { Demo set, set, reset to screen routine }}
{}
 {  200 bmp-x-size ! }
 {  200 bmp-y-size !}
 { Setup-Test-Memory  { Create a blank 200x200 .bmp in memory  }}
{}
 {  go-stretch         { Demo stretch to screen routine         }}

{ -------------------------------- Life Stuff Goes Here -------------------------------- }

variable array                                              { variable to hold the array of live/dead cells }

variable new-array                                          { variable to hold the next generation's array of live/dead cells }

100 bmp-x-size !                                             { set initial x grid size to 100 }

100 bmp-y-size !                                             { set initial y grid size to 100 }

{ word to create an array of the correct size and fill it with 0s }
: make_array
  bmp-x-size @ bmp-y-size @ * allocate
  drop dup bmp-x-size @ bmp-y-size @ * 0 fill
  ;

{ word to display the array in the console }
: show
  bmp-y-size @ 0 do
    cr
    bmp-x-size @ 0 do
      dup j bmp-y-size @ * i + + c@ 3 .r
    loop
  loop
  drop
  ;

: array_!  + c! ;                                            { word to write to an array. precede with n array @ i }

: array_@ + c@ ;                                             { word to read and array. precede with array @ i }

: xy_array_! bmp-y-size @ * + array @ + c! ;  	             { word to read and array. precede with n x y }

: xy_array_@ bmp-y-size @ * + array @ + c@ ;	               { word to read and array. precede with x y }

{ ---------Displaying The Array--------- }

{ create an empty bmp of the correct size }
: setup-bmp
  bmp-x-size @ bmp-y-size @ make-memory-bmp
  bmp-address !
   ;

{ will set the colour of a cell in the bmp to alive }
: alive-bmp
  3 * 54 + offset !
  255 bmp-address @ offset @ + 1 + c!
  ;

{ will set the colour of a cell in the bmp to dead }
: dead-bmp
  3 * 54 + offset !
  0 bmp-address @ offset @ + 1 + c!
  ;

{ word to convert an array to a bmp }
: display-array
  bmp-x-size @ bmp-y-size @ * 0 do
    array @ I array_@
    case
      0 of I dead-bmp endof
      1 of I alive-bmp endof
      ." invalid array entry "
    endcase
  loop
  ;

{ word to create a window to display the game in }
: initialise-window
  New-bmp-Window-stretch
  bmp-window-handle !
  display-array
  bmp-address @ bmp-to-screen-stretch
  ;

{ word to roughly randomise an array }
: rnd-array
  20 0 do
    1 array @ 10000 rnd array_!
  loop
  20 0 do
    0 array @ 10000 rnd array_!
  loop
  ;

{ word to test the conversion of arrays to bmps }
: test
  initialise-window
  300 0 do
    10 ms
    rnd-array
    display-array
    bmp-address @ bmp-to-screen-stretch
  loop
  ;

{ ---------File Handling--------- }

{ test writing numbers 20 to 40 in a file }
: testfile
  make-test-file
  test-file-size cr cr ." File Start Size = " d.
  40 20 do
    i (.) test-file-id @ write-line drop
  loop
  test-file-size cr cr ." File End Size =   " d. cr cr
  close-test-file
  ;

{ test writing an array to a file  not working }
: testfilearray
  make-test-file
  test-file-size cr cr ." File Start Size = " d.
  bmp-x-size @ bmp-y-size @ * 0 do
    array @ I array_@ (.) @ write-line drop
  loop
  test-file-size cr cr ." File End Size =   " d. cr cr
  close-test-file
  ;

{ ---------Counter--------- }

variable currentx
variable currenty
variable neighbours

{ word to save top two numbers on stack as x and y coordinates }
: variablexy currenty ! currentx ! ;

{ loop that takes n1 n2 from stack and leaves (n1-1, n2-1) (n1-1, n2) etc. on stack }
: neighbour_loop
  variablexy currenty @ 2 + dup 3 - do
    currentx @ 2 + dup 3 - do
      I J
    loop
  loop
  ;

{ word to determine if a cell is alive or dead }
: alive_dead
  case
    0 of drop endof
    1 of neighbours @ 1 + neighbours ! drop endof
    ." error" .
  endcase
  ;

{ word to count the number of neighbours of a cell at x y }
: num_neighbours
  0 neighbours !
  neighbour_loop 4 0 do
    dup 0 >= over bmp-y-size @ 1 - <= and if
      over 0 >= over bmp-x-size @ 1 - <= and if
        xy_array_@ dup alive_dead
      else
        drop drop
      then
    else
      drop drop
    then
  loop
  drop drop
  4 0 do
    dup 0 >= over bmp-y-size @ 1 - <= and if
      over 0 >= over bmp-x-size @ 1 - <= and if
        xy_array_@ dup alive_dead
      else
        drop drop
      then
    else
      drop drop
    then
  loop
  neighbours @
  ;

{ ---------The Game--------- }

{ word to update the array for the next generation }
: generation
  make_array new-array !
  bmp-x-size @ bmp-y-size @ * 0 do
    i bmp-x-size @ mod i bmp-y-size @ / num_neighbours
    case
      0 of 0 new-array @ i array_! endof
      1 of 0 new-array @ i array_! endof
      4 of 0 new-array @ i array_! endof
      5 of 0 new-array @ i array_! endof
      6 of 0 new-array @ i array_! endof
      7 of 0 new-array @ i array_! endof
      8 of 0 new-array @ i array_! endof
      3 of 1 new-array @ i array_! endof
      2 of array @ i array_@ new-array @ i array_! endof
    endcase
  loop
  new-array @ array !
  ;


{ word to run the game of life }
: life
  setup-bmp
  initialise-window
  10000 ms
  1000 0 do
    50 ms
    generation
    display-array
    bmp-address @ bmp-to-screen-stretch
  loop
  ;

{ ---------Seeds--------- }

: methuselah
  make_array array !                                           { create an initial empty array }
  1 50 50 xy_array_!                                         { this is a test setup of a methuselah seed }
  1 51 50 xy_array_!
  1 52 50 xy_array_!
  1 49 49 xy_array_!
  1 49 48 xy_array_!
  ;

: glider
  make_array array !                                           { create an initial empty array }
  1 2 99 xy_array_!                                         { this is a test setup of a glider }
  1 0 98 xy_array_!
  1 2 98 xy_array_!
  1 1 97 xy_array_!
  1 2 97 xy_array_!
  ;

: blinker
make_array array !
1 3 3 xy_array_!
1 4 3 xy_array_!
1 2 3 xy_array_!
;

