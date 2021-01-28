

10 Constant Update-Timer  { Sets windows update rate - lower = faster refresh            }

variable bmp-x-size     { x dimension of bmp file                                        }

variable bmp-y-size     { y dimension of bmp file                                        }

variable bmp-size       { Total number of bmp elements = (x * y)                         }

variable bmp-address    { Stores start address of bmp file # 1                           }

variable bmp-length     { Total number of chars in bmp including header block            }

variable bmp-x-start    { Initial x position of upper left corner                        }

variable bmp-y-start    { Initial y position of upper left corner                        }

variable array-x-size   { x dimension of array                                           }

variable array-y-size   { y dimension of array                                           }

variable bmp-window-handle  { Variable to store the handle used to ID display window     }

variable offset         { Memory offset used in bmp pixel adddress examples              }

variable array                           { variable to hold the array of live/dead cells }

variable new-array     { variable to hold the next generation's array of live/dead cells }

variable old-array     { variable to hold the last generation's array of live/dead cells }

variable older-array         { variable to hold the 2nd last generation's array of cells }

variable born            { variable to hold the number of cells born for each generation }

variable born_this_gen   { variable to hold the number of cells born at the start of the }
                                                                  {   current genaration }

variable die         { variable to hold the number of cells that die for each generation }

variable die_this_gen    { variable to hold the number of cells that die at the start of }
                                                                { the current genaration }

variable alive { variable to hold the number of cells that are alive for each generation }

variable generations                 { variable to hold the number of generations to run }

variable current_gen    { varibale to hold the number indicating the generation the game }
                                                                              {    is on }

variable alive_this_gen               { variable to hold the number of live cells in the }
                                                                  {   current generation }

variable array-file-id                          { Create Variable to hold file id handle }

variable born-file-id                           { Create Variable to hold file id handle }

variable alive-file-id                          { Create Variable to hold file id handle }

variable dead-file-id                           { Create Variable to hold file id handle }

variable currentx                                    { variable to store current x value }

variable currenty                                    { variable to store current x value }

variable neighbours                                   { variable to store num neighbours }

variable stability_variable                  { variable to check stability of the System }

variable start_time

variable end_time

variable stopper

5000 generations !                    { sets the number of generations to run the game for }

200 array-x-size !                                             { set initial x grid size }

200 array-y-size !                                             { set initial y grid size }

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


0 VALUE bmp-hApp            { Variable to hold handle for default bmp display window       }


: bmp-Classname Z" Show-bmp" ;      { Classname for the bmp output class                   }


: bmp-End-App ( -- res )
   'MAIN @ [ HERE CODE> ] LITERAL < IF ( not an application yet )
      0 TO bmp-hApp
   ELSE ( is an application )
      0 PostQuitMessage DROP
   THEN 0 ;


[SWITCH bmp-App-Messages DEFWINPROC ( msg -- res ) WM_DESTROY RUNS bmp-End-App SWITCH]


:NONAME ( -- res ) MSG LOWORD bmp-App-Messages ; 4 CB: bmp-APP-WNDPROC \ Link window messages to process


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


: bmp-window-shutdown     { Close bmp display window and unregister classes on shutdown     }
   bmp-hApp IF
   bmp-hApp WM_CLOSE 0 0 SendMessage DROP
   THEN
   bmp-Classname HINST UnregisterClass DROP
  ;


bmp-APP-CLASS                   { Call class for displaying bmp's in a child window         }

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

{ ----------------------------------- Array Handling ---------------------------------- }


{ word to create an array of the correct size and fill it with 0s }
: make_array
  array-x-size @ array-y-size @ * allocate
  drop dup array-x-size @ array-y-size @ * 0 fill
  ;

{ word to create an array to store variables }
: make_array_variables
  4 generations @ * allocate
  drop dup 4 generations @ * 0 fill
  ;

{ word to display the array representing the game grid in the console }
: show
  array-y-size @ 0 do
    cr
    array-x-size @ 0 do
      dup j array-y-size @ * i + + c@ 3 .r
    loop
  loop
  drop
  ;

{ word to display one of the variable arrays in the console }
: show_variable
  generations @ 0 do
    dup i 4 * + @ .
  loop
  drop
  ;

: array_!  + c! ;                  { word to write to an array. precede with n array @ i }

: array_@ + c@ ;                        { word to read and array. precede with array @ i }

: xy_array_! array-x-size @ * + array @ + c! ;            { word to write and array. n x y }

: xy_array_@ array-x-size @ * + array @ + c@ ;             	 { word to read and array. x y }


{ -------------------------------- Displaying The Array -------------------------------- }


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

{ word to convert an array to a bmp }
: display-array_abs
  bmp-x-size @ bmp-y-size @ * 0 do
    array @ 8 array-x-size @ * 8 + 16 I bmp-x-size @ / * + bmp-x-size @ I bmp-x-size @ / * + I bmp-x-size @ mod + array_@
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

{ word to create a window to display the game in }
: initialise-window_abs
  New-bmp-Window-stretch
  bmp-window-handle !
  display-array_abs
  bmp-address @ bmp-to-screen-stretch
  ;


{ ----------------------------------- File Handling ------------------------------------ }


: make-array-file                                { Create a test file to read / write to  }
  s" C:\Users\tedje\Documents\Conway's Life\Array_File.dat" r/w create-file drop     \ Create the file
  array-file-id !                                { Store file handle for later use        }
;

: make-born-file                                { Create a test file to read / write to  }
  s" C:\Users\tedje\Documents\Conway's Life\Born_File.dat" r/w create-file drop     \ Create the file
  born-file-id !                                { Store file handle for later use        }
;

: make-dead-file                                { Create a test file to read / write to  }
  s" C:\Users\tedje\Documents\Conway's Life\Dead_File.dat" r/w create-file drop     \ Create the file
  dead-file-id !                                { Store file handle for later use        }
;

: make-alive-file                                { Create a test file to read / write to  }
  s" C:\Users\tedje\Documents\Conway's Life\Alive_File.dat" r/w create-file drop     \ Create the file
  alive-file-id !                                { Store file handle for later use        }
;

\ : open-test-file                                { Open the file for read/write access    }
\   s" C:\Users\tedje\Documents\Conway's Life\Test_File.dat" r/w open-file drop       \ Not needed if we have just created
\   test-file-id !                                { file.                                  }
\ ;

: close-file                               { Close the file pointed to by the file  }
  close-file drop
;


\ : test-file-size                                { Leave size of file on top of stack as  }
\   test-file-id @                                { a double prescision integer if the     }
\   file-size drop                                { file is open.                          }
\ ;
\
\
\ { test writing numbers 20 to 40 in a file }
\ : testfile
\   make-test-file
\   test-file-size cr cr ." File Start Size = " d.
\   40 20 do
\     i (.) test-file-id @ write-line drop
\   loop
\   test-file-size cr cr ." File End Size =   " d. cr cr
\   close-test-file
\   ;

{ writing an array to a file }
: save_array
  make-array-file
  array-x-size @ array-y-size @ * 0 do
    array @ I array_@ (.) array-file-id @ write-line drop
  loop
  array-file-id @ close-file
  ;

{ writing an array to a file }
: save_variables
  make-born-file
  make-dead-file
  make-alive-file
  generations @ 0 do
    alive @ I 4 * + @ (.) alive-file-id @ write-line drop
    born @ I 4 * + @ (.) born-file-id @ write-line drop
    die @ I 4 * + @ (.) dead-file-id @ write-line drop
  loop
  alive-file-id @ close-file
  dead-file-id @ close-file
  born-file-id @ close-file
  ;

{ writing an array to a file NEW, aim to load array as grid in file}
: save_array_grid
  make-array-file
  array-x-size @ array-y-size @ * 0 do
    array @ I array_@ (.) array-file-id @ write-file drop
    s"  " array-file-id @ write-file drop
    I 0 >= if
      I 1 + array-x-size @ mod 0 = if
        s"  " array-file-id @ write-line drop
      then
    then
  loop
  array-file-id @ close-file
  ;


{ -------------------------------------- Counter --------------------------------------- }


{ word to save top two numbers on stack as x and y coordinates }
: variablexy currenty ! currentx ! ;

{ loop that takes n1 n2 from stack and leaves (n1-1, n2-1) (n1-1, n2) etc. on stack }
: neighbour_loop
  variablexy currenty @ 2 + dup 3 - do
    currentx @ 2 + dup 3 - do
      I currentx @ = not J currenty @ = not or if
        I J
      then
    loop
  loop
  ;

{ word to determine if a cell is alive or dead }
{ adds 1 or 0 to neighbours variable depending on if its alive or dead }
: alive_dead
  case
    0 of drop endof
    1 of neighbours @ 1 + neighbours ! drop endof
    ." error" .
  endcase
  ;

{ word to count the number of neighbours of a cell at x y }
: num_neighbours_abs
  0 neighbours !
  neighbour_loop 8 0 do
    dup 0 >= over array-y-size @ 1 - <= and if
      over dup 0 >= swap array-x-size @ 1 - <= and if
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

{ word to count the number of neighbours of a cell at x y }
{ includes wrapping, ie checks and accounts for cells at the edge }
{ NB: our coordinates take the bottom left of the grid as the origin }
: num_neighbours_wrap
  0 neighbours !
  neighbour_loop 8 0 do
    dup 0 >= if
      over 0 >= if
        dup array-y-size @ 1 - <= if
          over array-x-size @ 1 - <= if
              xy_array_@ dup alive_dead                                         \ checks if the neighbour is dead or alive as normal, our cell isnt near the edge
            else
              0 rot drop swap xy_array_@ dup alive_dead                         \ checks if neighbour at x=0 is dead or alive, our cell is on the right edge but not a corner
            then
          else
            over array-x-size @ 1 - <= if
              drop 0 xy_array_@ dup alive_dead                                  \ checks if neighbour at y=0 is dead or alive, our cell is on the top edge but not a corner
            else
              drop drop 0 0 xy_array_@ dup alive_dead                           \ checks if neighbour at x=0 y=0 is dead or alive, our cell is in the top right corner
            then
          then
        else
          dup array-y-size @ 1 - <= if
            array-x-size @ 1 - rot drop swap xy_array_@ dup alive_dead            \ checks if neighbour at x=max is alive or dead, our cell is on the left edge but not a corner
          else
            drop drop array-x-size @ 1 - 0 xy_array_@ dup alive_dead              \ checks if neighbour at x=max and y=0 is alive or dead, our cell is in bottom right corner
          then
        then
      else
        over 0 >= if
          over array-x-size @ 1 - <= if
            drop array-y-size @ 1 - xy_array_@ dup alive_dead                     \ checks if neighbour at y=max is alive or dead, our cell is on the bottom edge but not a corner
          else
            drop drop 0 array-y-size @ 1 - xy_array_@ dup alive_dead              \ checks if neighbour at x=0 and y=max is alive or dead, our cell is in the top left corner
          then
        else
          drop drop array-x-size @ 1 - array-y-size @ 1 - xy_array_@ dup alive_dead \ checks if neighbour at x=max and y=max is alive or dead, our cell is in the bottom left corner
        then
      then
  loop
  neighbours @
  ;

{ ------------------------------------- The Game --------------------------------------- }

: ms@ counter ;

{ word to count how many are born or have died }
: born_die
  array-x-size @ array-y-size @ * 0 do
    array @ i array_@
    new-array @ i array_@ -             { old (prev gen) array - new (current gen) array }
    case
      -1 of born_this_gen @ 1 + born_this_gen ! endof        { checks if a cell was born }
      1 of die_this_gen @ 1 + die_this_gen ! endof               { checks if a cell died }
      0 of endof                                           { cell remained alive or dead }
      ." error "
    endcase
  loop
  ;

{ word to count total alive this gen }
: no_alive
  array-x-size @ array-y-size @ * 0 do
    array @ i array_@
    alive_this_gen @ + alive_this_gen !
  loop
  ;

{ word to check if the system has reached stability }
: stability_check
  0 stability_variable !
  array-x-size @ array-y-size @ * 0 do
    array @ i array_@
    new-array @ i array_@ - abs         { old (prev gen) array - new (current gen) array }
    stability_variable @ abs max
    stability_variable !
  loop
  stability_variable @ 0 = if
    stopper @ 0 = if
      cr ." System statically stable after " current_gen @ . ." generations. " cr
      1 stopper !
      quit
    then
  else
    0 stability_variable !
    array-x-size @ array-y-size @ * 0 do
      old-array @ i array_@
      new-array @ i array_@ - abs       { old (prev gen) array - new (current gen) array }
      stability_variable @ abs max
      stability_variable !
    loop
    stability_variable @ 0 = if
      stopper @ 0 = if
        cr ." System oscillating with period 2 after " current_gen @ 1 - . ." generations. " cr
        1 stopper !
        quit
      then
    else
        0 stability_variable !
        array-x-size @ array-y-size @ * 0 do
          older-array @ i array_@
          new-array @ i array_@ - abs       { old (prev gen) array - new (current gen) array }
          stability_variable @ abs max
          stability_variable !
        loop
        stability_variable @ 0 = if
          stopper @ 0 = if
            cr ." System oscillating with period 3 after " current_gen @ 2 - . ." generations. " cr
            1 stopper !
            quit
          then
      then
    then
  then
  ;

{ word to update the array for the next generation, it is called within 'life' below }
: generation
  0 alive_this_gen !
  0 born_this_gen !
  0 die_this_gen !
  current_gen @ 1 + current_gen !
  make_array new-array !
  array-x-size @ array-y-size @ * 0 do
    100 rnd 4 >= if
      i array-x-size @ mod i array-x-size @ / num_neighbours_wrap
      case
        0 of 0 new-array @ i array_! endof
        1 of 0 new-array @ i array_! endof
        4 of 0 new-array @ i array_! endof
        5 of 0 new-array @ i array_! endof
        6 of 0 new-array @ i array_! endof
        7 of 0 new-array @ i array_! endof
        8 of 0 new-array @ i array_! endof
        3 of 1 new-array @ i array_! endof
        2 of array @ i array_@ new-array @ i array_!  endof
        ." error "
      endcase
    else
      array @ i array_@ new-array @ i array_!
    then
  loop
  born_die                           { counts number of cells that die and are born }
  \ stability_check
  old-array @ older-array !
  array @ old-array !
  new-array @ array !
  no_alive                                            { counts number of live cells }
  alive_this_gen @ alive @ current_gen @ 4 * + !                                \ stores number of live cells in the alive array for each generation
  born_this_gen @ born @ current_gen @ 4 * + !                                  \ stores number of cells born in the born array for each generation
  die_this_gen @ die @ current_gen @ 4 * + !                                    \ stores number of cells that die in the die array for each generation
  ;

{ word to update the array for the next generation, it is called within 'life' below }
: generation_abs
  0 alive_this_gen !
  0 born_this_gen !
  0 die_this_gen !
  current_gen @ 1 + current_gen !
  make_array new-array !
  array-x-size @ array-y-size @ * 0 do
    i array-x-size @ mod i array-x-size @ / num_neighbours_abs
    case
      0 of 0 new-array @ i array_! endof
      1 of 0 new-array @ i array_! endof
      4 of 0 new-array @ i array_! endof
      5 of 0 new-array @ i array_! endof
      6 of 0 new-array @ i array_! endof
      7 of 0 new-array @ i array_! endof
      8 of 0 new-array @ i array_! endof
      3 of 1 new-array @ i array_! endof
      2 of array @ i array_@ new-array @ i array_!  endof
      ." error "
    endcase
  loop
  born_die                           { counts number of cells that die and are born }
  stability_check
  old-array @ older-array !
  array @ old-array !
  new-array @ array !
  no_alive                                            { counts number of live cells }
  alive_this_gen @ alive @ current_gen @ 4 * + !                                \ stores number of live cells in the alive array for each generation
  born_this_gen @ born @ current_gen @ 4 * + !                                  \ stores number of cells born in the born array for each generation
  die_this_gen @ die @ current_gen @ 4 * + !                                    \ stores number of cells that die in the die array for each generation
  ;

{ word to run the game of life }
: life
  ms@ start_time !
  0 stopper !
  array-x-size @ bmp-x-size !
  array-y-size @ bmp-y-size !
  -1 current_gen !
  make_array_variables born !                                                   \ makes an array to store the number of cells born each generation
  make_array_variables die !                                                    \ makes an array to store the number of cells that die each generation
  make_array_variables alive !                                                  \ makes an array to store the number of live cells for each generation
  make_array old-array !
  make_array older-array !
  \ setup-bmp
  \ initialise-window
  \ 5000 ms
  generations @ 0 do
    \ 20 ms
    generation
    \ display-array
    \ bmp-address @ bmp-to-screen-stretch
  loop
  ms@ end_time !
  cr
  ." Simulation took " end_time @ start_time @ - . ." ms"
  cr
  ;

{ word to run the game of life }
: life_abs
  ms@ start_time !
  array-x-size @ 16 - bmp-x-size !
  array-y-size @ 16 - bmp-y-size !
  -1 current_gen !
  make_array_variables born !                                                   \ makes an array to store the number of cells born each generation
  make_array_variables die !                                                    \ makes an array to store the number of cells that die each generation
  make_array_variables alive !                                                  \ makes an array to store the number of live cells for each generation
  make_array old-array !
  make_array older-array !
  setup-bmp
  initialise-window_abs
  5000 ms
  generations @ 0 do
    20 ms
    generation_abs
    display-array_abs
    bmp-address @ bmp-to-screen-stretch
  loop
  ms@ end_time !
  cr
  ." Simulation took " end_time @ start_time @ - . ." ms "
  cr
  ;

{ --------------------------------------- Seeds ---------------------------------------- }

: methuselah
  make_array array !                                     { create an initial empty array }
  1 array-x-size @ 2 / array-y-size @ 2 / xy_array_!                       { this is a test setup of a methuselah seed }
  1 array-x-size @ 2 / 1 + array-y-size @ 2 / xy_array_!
  1 array-x-size @ 2 / 2 + array-y-size @ 2 / xy_array_!
  1 array-x-size @ 2 / 1 - array-y-size @ 2 / 1 - xy_array_!
  1 array-x-size @ 2 / 1 - array-y-size @ 2 / 2 - xy_array_!
  ;

: glider
  make_array array !                                      { create an initial empty array }
  1 array-x-size @ 2 / array-y-size @ 2 / xy_array_!                                    { this is a test setup of a glider }
  1 array-x-size @ 2 / 2 - array-y-size @ 2 / 1 - xy_array_!
  1 array-x-size @ 2 / array-y-size @ 2 / 1 - xy_array_!
  1 array-x-size @ 2 / 1 - array-y-size @ 2 / 2 - xy_array_!
  1 array-x-size @ 2 / array-y-size @ 2 / 2 - xy_array_!
  ;

: Pi
  make_array array !                                      { create an initial empty array }
  1 array-x-size @ 2 / array-y-size @ 2 / xy_array_!                           { this is a test setup of a pi heptomino }
  1 array-x-size @ 2 / 1 - array-y-size @ 2 / xy_array_!
  1 array-x-size @ 2 / 1 + array-y-size @ 2 / xy_array_!
  1 array-x-size @ 2 / 1 - array-y-size @ 2 / 1 - xy_array_!
  1 array-x-size @ 2 / 1 - array-y-size @ 2 / 2 - xy_array_!
  1 array-x-size @ 2 / 1 + array-y-size @ 2 / 1 - xy_array_!
  1 array-x-size @ 2 / 1 + array-y-size @ 2 / 2 - xy_array_!
  ;

: block
  make_array array !                                      { create an initial empty array }
  1 array-x-size @ 2 / array-y-size @ 2 / xy_array_!                                      { this is a test setup of a block }
  1 array-x-size @ 2 / array-y-size @ 2 / 1 + xy_array_!
  1 array-x-size @ 2 / 1 + array-y-size @ 2 / xy_array_!
  1 array-x-size @ 2 / 1 +  array-y-size @ 2 / 1  xy_array_!
  ;

: blinker
  make_array array !                                      { create an initial empty array }
  1  array-x-size @ 2 /  array-y-size @ 2 / xy_array_!                                    { this is a test setup of a blinker }
  1  array-x-size @ 2 /  array-y-size @ 2 / 1 + xy_array_!
  1  array-x-size @ 2 /  array-y-size @ 2 / 2 + xy_array_!
  ;

: caterer
  make_array array !                                      { create an initial empty array }
  1 150 150 xy_array_!                                    { this is a test setup of a blinker }
  1 151 150 xy_array_!
  1 152 149 xy_array_!
  1 149 148 xy_array_!
  1 149 147 xy_array_!
  1 153 147 xy_array_!
  1 149 146 xy_array_!
  1 153 146 xy_array_!
  1 154 146 xy_array_!
  1 155 146 xy_array_!
  1 156 146 xy_array_!
  1 151 145 xy_array_!
  ;

: random
  make_array array !
  array-x-size @ array-y-size @ * 0 do
    2 rnd 1 >= if
      1 array @ i array_!
    else
      0 array @ i array_!
    then
  loop
  ;

: line
  make_array array !
  dup 0 do
    dup 1 swap 2 / array-x-size @ 2 / - abs i + array-y-size @ 2 / xy_array_!
  loop drop
  ;
