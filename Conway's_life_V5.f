
variable array                                              { variable to hold the array of live/dead cells }

variable new-array                                          { variable to hold the next generation's array of live/dead cells }

variable born

variable born_this_gen

variable die

variable die_this_gen

variable alive

variable generations

variable current_gen

variable alive_this_gen

200 generations !

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

{ word to display the variable array in the console }
: show_variable
  generations @ 0 do
    dup i 4 * + @ .
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

{ word to count the number of neighbours of a cell at x y }
: num_neighbours_wrap
  0 neighbours !
  neighbour_loop 4 0 do
    dup 0 >= if
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
  drop drop
  4 0 do
  dup 0 >= if
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

{ word to update the array for the next generation }
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
  bmp-x-size @ bmp-y-size @ * 0 do
    array @ i array_@
    new-array @ i array_@ -
    case
      -1 of born_this_gen @ 1 + born_this_gen ! endof
      1 of die_this_gen @ 1 + die_this_gen ! endof
      drop
    endcase
  loop
  new-array @ array !
  bmp-x-size @ bmp-y-size @ * 0 do
    array @ i array_@
    alive_this_gen @ + alive_this_gen !
  loop
  alive_this_gen @ alive @ current_gen @ 4 * + !
  born_this_gen @ born @ current_gen @ 4 * + !
  die_this_gen @ die @ current_gen @ 4 * + !
  ;


{ word to run the game of life }
: life
  -1 current_gen !
  make_array_variables born !
  make_array_variables die !
  make_array_variables alive !
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
