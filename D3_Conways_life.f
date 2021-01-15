{KRB D3 Conways life Tutorial code}

{clear stack loop}
: remove 1 depth 0 do drop loop ;

{All combinations of n1xn2 from (0x0) to (10x10) in this case}
: combination 11 0 do 11 0 do I J * . loop loop ;

{prints square of top number in stack and removes it from stack}
{add an extra dup to keep original in stack}
: square_print dup * . ;

{add square of top number on stack to stack}
: square dup dup * ;



{CASE (OF/ENDOF) ENDCASE example}
: test_case cr dup
case
7 of ." Number 7 found" drop endof
1 of ." Number 1 found" drop endof
9 of ." Number 9 found" drop endof
." Nothing got done with the number " .
endcase
cr ;


{Ex 13}
: multiple_of_5
cr dup dup 5 mod 0=
if ." The number " . ." is a multiple of 5"
else ." The number " . ." is NOT a multiple of 5"
then cr ;



{Ex 14, is top of stack a 2, 5 or a 7}
: number_is_2_5_7
cr dup 
 case
  2 of drop true endof
  5 of drop true endof
  7 of drop true endof
drop >r false r>
endcase
cr ;


{Ex 15}
: ASCII 256 0 do I 
dup
10 mod 0=
if cr dup 1 + emit ."  " 
else dup 1 + emit ."  "
then drop loop ;

{Ex 16}
: number dup cr
case
0 of ." zero" drop endof
1 of ." one" drop endof
2 of ." two" drop endof
3 of ." three" drop endof
4 of ." four" drop endof
5 of ." five" drop endof
6 of ." six" drop endof
7 of ." seven" drop endof
8 of ." eight" drop endof
9 of ." nine" drop endof
10 of ." ten" drop endof
." whoops, not 0-10" drop
endcase
cr ;

{prints elements (100 here) of an array to the console}
: show_array 100 0 do small_array I + C@ . loop ;

{sets 1st 10 elements of array to 1}
: reset_array test_array 10 1 fill ;

{Ex 17}
: make_small_array 100 allocate drop dup 100 0 fill ;
make_small_array constant small_array
: show_small_array 10 0 do cr 10 0 do 
	small_array J 10 * I + + C@ . loop loop ;
show_small_array


{Ex18}
{write}
: array_! 1 - 10 * + 1 - small_array + C! ;
{read}
: array_@ 1 - 10 * + 1 - small_array + C@ ;


{Ex19}
: show_small_array 10 0 do cr 10 0 do 
	small_array J 10 * I + + C@ 4 .R loop loop ;

{Ex20}
: linear_small_array 100 0 do I small_array I + C! loop ;
 
 {Ex 21}
{DOOOOOOOOOOOOOOOOOOOOOO}



{------------------------------ Game of life ----------------------}

{Counting a cells neighbours taking (x,y) and leaving neighbours on stack}

{loop that takes n from stack and leaves (n-1) n (n+1) on stack}
: test_loop cr 2 + dup 3 - do I cr loop ;


{word that assigns x and y from stack to current x and y as variables}
{NB: (x,y) is coordinate of current square!}
variable x
variable y
: variablexy y ! x ! ;

{loop that takes n1 n2 from stack and leaves (n1-1, n2-1) (n1-1, n2) etc.
on stack}
: test_loop variablexy y @ 2 + dup 3 - do x @ 2 + dup 3 - do I J loop loop ;


{loop that reads values in neighbour cells}
{alive_dead checks value of point (ie alive of dead) 
ADAPT LATER TO NUMBER OF NEIGHBOURS IN CELLS PERHAPS}
: alive_dead case
0 of drop endof
1 of drop 1 + endof
." error"
endcase 
cr ;

: alive_dead_xy array_@ case
0 of drop endof
1 of drop 1 - endof
." error"
endcase
cr ;

{check checks if we are NOT on point x,y}
: check y @ = and x @ = if alive_dead_xy then ;

: num_neighbours test_loop 0 depth 1 - 2 / 0 do 
array_@ alive_dead check nip nip loop ; 