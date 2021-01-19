{Conways life V5, MUST load Graphics_V6d_Single_Scaled_BMP_Window AND Test_File_IO_Tools first}
{The above two files handle the graphics}

variable array                                              { variable to hold the array of live/dead cells }

variable new-array                                          { variable to hold the next generation's array of live/dead cells }

variable born						    { variable to hold the number of cells born for each generation }

variable born_this_gen					    { variable to hold the number of cells born at the start of the current genaration }

variable die						    { variable to hold the number of cells that die for each generation }

variable die_this_gen					    { variable to hold the number of cells that die at the start of the current genaration }

variable alive						    { variable to hold the number of cells that are alive for each generation }

variable generations					    { variable to hold the number of generations to run }

variable current_gen					    { varibale to hold the number indicating the generation the game is on }

variable alive_this_gen					    { variable to hold the number of live cells in the current generation }


200 generations !					     { sets the number of generations to run the game for }

300 bmp-x-size !                                             { set initial x grid size to 100 }

300 bmp-y-size !                                             { set initial y grid size to 100 }

{ word to create an array of the correct size and fill it with 0s }
: make_array
  bmp-x-size @ bmp-y-size @ * allocate
  drop dup bmp-x-size @ bmp-y-size @ * 0 fill
  ;

{ word to create an array to store variables }
: make_array_variables
  4 generations @ * allocate
  drop dup 4 generations @ * 0 fill
  ;

{ word to display the array representing the game grid in the console } 
: show
  bmp-y-size @ 0 do
    cr
    bmp-x-size @ 0 do
      dup j bmp-y-size @ * i + + c@ 3 .r
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

: array_!  + c! ;                                            { word to write to an array. precede with n array @ i }

: array_@ + c@ ;                                             { word to read an array. precede with array @ i }

: xy_array_! bmp-y-size @ * + array @ + c! ;  	             { word to read an array. precede with n x y }

: xy_array_@ bmp-y-size @ * + array @ + c@ ;	               { word to read an array. precede with x y }

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
{ adds 1 or 0 to neighbours variable depending on if its alive or dead }
: alive_dead
  case
    0 of drop endof
    1 of neighbours @ 1 + neighbours ! drop endof
    ." error" .
  endcase
  ;


{ word to count the number of neighbours of a cell at x y }
{ includes wrapping, ie checks and accounts for cells at the edge }
{ NB: our coordinates take the bottom left of the grid as the origin }
: num_neighbours_wrap
  0 neighbours !
  neighbour_loop 4 0 do								{ this loop checks the 4 neighbours before our cell }
    dup 0 >= if									
      over 0 >= if								
        dup bmp-y-size @ 1 - <= if           					 
          over bmp-x-size @ 1 - <= if						
              xy_array_@ dup alive_dead						{ checks if the neighbour is dead or alive as normal, our cell isnt near the edge }
            else
              0 rot drop swap xy_array_@ dup alive_dead				{ checks if neighbour at x=0 is dead or alive, our cell is on the right edge but not a corner }
            then
          else						
            over bmp-x-size @ 1 - <= if						
              drop 0 xy_array_@ dup alive_dead					{ checks if neighbour at y=0 is dead or alive, our cell is on the top edge but not a corner } 
            else
              drop drop 0 0 xy_array_@ dup alive_dead				{ checks if neighbour at x=0 y=0 is dead or alive, our cell is in the top right corner } 
            then
          then
        else
          dup bmp-y-size @ 1 - <= if						
            bmp-x-size @ 1 - rot drop swap xy_array_@ dup alive_dead		{ checks if neighbour at x=max is alive or dead, our cell is on the left edge but not a corner } 
          else
            drop drop bmp-x-size @ 1 - 0 xy_array_@ dup alive_dead		{ checks if neighbour at x=max and y=0 is alive or dead, our cell is in bottom right corner } 
          then
        then
      else
        over 0 >= if								
          over bmp-x-size @ 1 - <= if					
            drop bmp-y-size @ 1 - xy_array_@ dup alive_dead			{ checks if neighbour at y=max is alive or dead, our cell is on the bottom edge but not a corner } 
          else
            drop drop 0 bmp-y-size @ 1 - xy_array_@ dup alive_dead		{ checks if neighbour at x=0 and y=max is alive or dead, our cell is in the top left corner } 
          then
        else
          drop drop bmp-x-size @ 1 - bmp-y-size @ 1 - xy_array_@ dup alive_dead	{ checks if neighbour at x=max and y=max is alive or dead, our cell is in the bottom left corner } 
        then
      then
  loop
  drop drop
  4 0 do									{ this loop checks the 4 neighbours after our cell, it goes through the same procedere as the previous }
  dup 0 >= if									{ loop but checking the top and right edges and corners }
    over 0 >= if								
      dup bmp-y-size @ 1 - <= if
        over bmp-x-size @ 1 - <= if
            xy_array_@ dup alive_dead
          else
            0 rot drop swap xy_array_@ dup alive_dead
          then
        else
          over bmp-x-size @ 1 - <= if
            drop 0 xy_array_@ dup alive_dead
          else
            drop drop 0 0 xy_array_@ dup alive_dead
          then
        then
      else
        dup bmp-y-size @ 1 - <= if
          bmp-x-size @ 1 - rot drop swap xy_array_@ dup alive_dead
        else
          drop drop bmp-x-size @ 1 - 0 xy_array_@ dup alive_dead
        then
      then
    else
      over 0 >= if
        over bmp-x-size @ 1 - <= if
          drop bmp-y-size @ 1 - xy_array_@ dup alive_dead
        else
          drop drop 0 bmp-y-size @ 1 - xy_array_@ dup alive_dead
        then
      else
        drop drop bmp-x-size @ 1 - bmp-y-size @ 1 - xy_array_@ dup alive_dead
      then
    then
  loop
  neighbours @
  ;

{ ---------The Game--------- }

{ word to count how many are born or have died }
: born_die
  bmp-x-size @ bmp-y-size @ * 0 do
    array @ i array_@
    new-array @ i array_@ -						{ old (prev generation) array - new (current generation) array }
    dup -1 = if born_this_gen @ 1 + born_this_gen ! then		{ checks if a cell was born }
    dup 1 = if die_this_gen @ 1 + die_this_gen ! then			{ checks if a cell died }
    dup 0 = if drop then						{ cell remained alive or dead }
  loop
  ;

{ word to count total alive this gen }
: no_alive
  bmp-x-size @ bmp-y-size @ * 0 do
    array @ i array_@
    alive_this_gen @ + alive_this_gen !
  loop
  ;

{ word to update the array for the next generation, it is called each generation within 'life' below }
: generation
  0 alive_this_gen !							
  0 born_this_gen !
  0 die_this_gen !
  current_gen @ 1 + current_gen !
  make_array new-array !
  bmp-x-size @ bmp-y-size @ * 0 do
    i bmp-x-size @ mod i bmp-y-size @ / num_neighbours_wrap
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
  born_die								{ counts number of cells that die and are born }
  new-array @ array !
  no_alive								{ counts number of live cells }
  alive_this_gen @ alive @ current_gen @ 4 * + !			{ stores number of live cells in the alive array for each generation }
  born_this_gen @ born @ current_gen @ 4 * + !				{ stores number of cells born in the born array for each generation }
  die_this_gen @ die @ current_gen @ 4 * + !				{ stores number of cells that die in the die array for each generation }
  ;

{ word to run the game of life }
: life
  -1 current_gen !
  make_array_variables born !						{ makes an array to store the number of cells born each generation }
  make_array_variables die !						{ makes an array to store the number of cells that die each generation }
  make_array_variables alive !						{ makes an array to store the number of live cells for each generation }
  setup-bmp
  initialise-window
  5000 ms
  generations @ 0 do
    20 ms
    generation
    display-array
    bmp-address @ bmp-to-screen-stretch
  loop
  ;

{ ---------Seeds--------- }

: methuselah
  make_array array !                                           { create an initial empty array }
  1 150 150 xy_array_!                                         { this is a test setup of a methuselah seed }
  1 151 150 xy_array_!
  1 152 150 xy_array_!
  1 149 149 xy_array_!
  1 149 148 xy_array_!
  ;

: glider
  make_array array !                                           { create an initial empty array }
  1 2 99 xy_array_!                                         { this is a test setup of a glider }
  1 0 98 xy_array_!
  1 2 98 xy_array_!
  1 1 97 xy_array_!
  1 2 97 xy_array_!
  ;

: Pi
  make_array array !                                           { create an initial empty array }
  1 150 150 xy_array_!                                         { this is a test setup of a glider }
  1 149 150 xy_array_!
  1 151 150 xy_array_!
  1 149 149 xy_array_!
  1 149 148 xy_array_!
  1 151 149 xy_array_!
  1 151 148 xy_array_!
  ;
