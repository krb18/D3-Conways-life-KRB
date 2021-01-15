
16 bmp-x-size !

16 bmp-y-size ! 

: make_array 
bmp-x-size @ bmp-y-size @ * allocate 
drop dup bmp-x-size @ bmp-y-size @ * 0 fill ;

: show bmp-y-size @ 0 do cr bmp-x-size @ 0 do dup j 10 * i + + c@ 3 .r loop loop drop ; {array}

variable array

make_array array !


: array_!  + c! ;

: array_@ + c@ ;

1 array @ 10 array_!
1 array @ 2 array_!
1 array @ 13 array_!
1 array @ 30 array_!
1 array @ 7 array_!
1 array @ 100 array_!
1 array @ 200 array_!

Setup-Test-Memory

: alive-bmp  {x--}
3 * 54 + offset !
255 bmp-address @ offset @ + 1 + c! ;

: dead-bmp
3 * 54 + offset !
0 bmp-address @ offset @ + 1 + c! ;

: display-array
bmp-x-size @ bmp-y-size @ * 0 do
array @ I array_@
case
0 of I dead-bmp endof
1 of I alive-bmp endof
." invalid array entry "
endcase
loop ;

: initialise-window
New-bmp-Window-stretch
bmp-window-handle !
bmp-address @ bmp-to-screen-stretch ;

: rnd-array
20 0 do
1 array @ 255 rnd array_!
loop
20 0 do
0 array @ 255 rnd array_!
loop
;

: test
initialise-window
300 0 do
10 ms
rnd-array
display-array
bmp-address @ bmp-to-screen-stretch 
loop
;