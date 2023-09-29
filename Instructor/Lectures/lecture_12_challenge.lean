/-!
### CHALLENGE PROBLEM
-/

/-!
### Challenge Problem

Define a function, mk_interps, that takes as an argument
a natural number, n, specifying a number of propositional
variables, and that returns a list of 2^n interpretations 
for the variables, *mk_var 0 ... mk_var n-1*. 

#### Key Insight

To make the idea clearer, what mk_interps does is to take
a number of variables, which you can think of as labels on
the columns of the input side of a truth table, and that
then generates the contents of all of the rows. Each row
in effect specifies a function from variables labeling the
columns to the Boolean values in the row. With n variables
we will have 2^n rows. Here, for example, is the input part
of a truth table with three propositional variables.

|  v₀  |  v₁  |  v₃  |
|------|------|------|
|  F   |  F   |  F   |
|  F   |  F   |  T   |
|  F   |  T   |  F   |
|  F   |  T   |  T   |
|  T   |  F   |  F   |
|  T   |  F   |  T   |
|  T   |  T   |  F   |
|  T   |  T   |  T   |

There's a great deal of structure here. What do we find if
we add a column on the left with the natural number index of
each row, ranging from 0 to 7, while replacing the true (T)
and false (F) values in the table with the binary digits, 1 
for true and 0 for false?


| row  |  v₀  |  v₁  |  v₃  |
|------|------|------|------|
|  0   |  0   |  0   |  0   |
|  1   |  0   |  0   |  1   |
|  2   |  0   |  1   |  0   |
|  3   |  0   |  1   |  1   |
|  4   |  1   |  0   |  0   |
|  5   |  1   |  0   |  1   |
|  6   |  1   |  1   |  0   |
|  7   |  1   |  1   |  1   |

Do you see it? What's the relationship between
the row index and the sequence of binary digits
in each row? Think about it before reading on.

The answer, of course, is that each sequence of
binary digits is simply the binary representation
of the row index. 

#### Algorithm Design Strategy

This insight unlocks an algorithm 
design strategy. For each row index, compute the
corresponding list of binary digits (which we can
represent at Nats), add any zero padding on the 
left to each row to equal the number of columns,
convert these lists of binary digits (Nat) to Bool
values, derive a function (interpretation) taking 
each variable to the corresonding Bool (defaulting
to, say, false, for all variable beyond the few we
care about), and finally return the whole list of 
2^n interpretation functions. To compute the output
column of the truth table we can iteratively use
each function in this list as the Interp argument
to our expression evaluation (semantic evaluation)
function.    


We'll take a bottom-up approach to implementation
by building and teting the required functions and
then combining them into the desired overall result.

- convert a row index into a list of binary digits
- convert a list of binary digits into a list of Bools
- convert a list of Bools into a function from corresponding variables
- convert number, n, of variables to number, 2^n, of rows 
- generate a list of such functions, per row index from 2^n-1 down to 0
-/


/-!
#### Row Index to List of Binary Digits

The rightmost digit of a binary expansion of a number, n,
is 0 if n is even and 1 if n is odd. In other words, the
rightmost binary digit is n%2. To get the next digit, you
use integer division to divide n by 2, and repeat. 

Here's a first version. If the input is 0 it returns the
list of binary digits, [0]. Otherwise it returns a list 
of all the digits to the left of the last digit, whcih is
computed recursively, with the singlton list containing
the correct rightmost digit appended at the end.

As an example, suppose we're given a row index of 5.
We want its binary expansion as a list of bits, which 
is [1,0,1]. That's *1*2^2 + 0*2^1 + 1*2^0*, which in
turn is *4 + 0 * 1*, which is 5. 

The basic idea then is as follows. If the input, n, is 
0, we'll return [0] (the list containing just zero). If
the the input is 1, we'll return [1]. Otherwise n is at
least 2, so we can write it as n = n' + 2. We thus have
three cases to consider, and have already give solutions
for the first two.

So now suppose *n = n' + 2* for some *n'*. The rightmost 
bit is (n%2)*. Once we have this bit in hand, we want to 
eliminate it, shift all the remaining bits one place to 
the right and repeat. To throw away the rightmost bit of 
*n*, we just divide it by 2.

So now we have our algorithm. If n is a base case, output 
the corresponding singleton list of binary digits. In any
other case, we output the list obtained by appending two
lists: (1) the recursively computed list of digits to the
left of the rightmost bit, and (2) the list containing just
the rightmost bit. 

To make our code even clearer, we'll *reify* the abstract
operations of extracting the rightmost bit, and shifting
all remaining bits to the right.
-/

def right_bit (n : Nat) := n%2

def shift_right (n : Nat) := n/2

def nat_to_bin : Nat → List Nat
| 0     => [0]
| 1     => [1]
| n' + 2 =>
  have : (shift_right (n' + 2)) < (n' + 2) := sorry
  nat_to_bin (shift_right (n' + 2)) ++ [right_bit (n' + 2)]

/-!
Now you're probably wondering, what's that mysterious
*have : (shift_right (n' + 2)) < (n' + 2) := sorry?*
To make a long story short, the recursion here is 
*not* structural. (Why?) That means that Lean won't
be able to see that the argument to the recursion is
always decreasing. To avoid Lean giving an error saying 
it can't prove termination (because it can't tell that 
the argument is decreasing), we have to give Lean an
explicit proof of it. The mystery code tells Lean that 
we do have such a proof, while the *sorry* says, *but 
we're not going to give it now, just trust us.* That's 
good enough for Lean not to complain. We'll come back 
to termination at a later point, under the guise of 
*well founded relations*. 
-/

/- Test Cases. 
#eval right_bit 4   -- 4 = 100, expect 0
#eval right_bit 3   -- 3 =  11, expect 1
#eval shift_right 4 -- 4 = 100, expect 10 = 2
#eval shift_right 5 -- 5 = 101, expect 10 = 2
#eval nat_to_bin 6  -- expect [1,1,0] 
#eval nat_to_bin 5  -- expect [1,0,1]
#eval nat_to_bin 4  -- expect [1,0,0]
#eval nat_to_bin 3  -- expect   [1,1]
#eval nat_to_bin 2  -- expect   [1,0]
#eval nat_to_bin 1  -- expect     [1]
#eval nat_to_bin 0  -- expect     [0]
-/

/-!
As a next processing step, we need to fill each
resulting list of bits with zeros on the left to
make each list equal in length to the number of
variables being considered in a given situation.
For example, the list of bits returned when *n=1*
is just *[1]* but a truth table with three variable
columns will have *[0,0,1]* in the row with index 1.
We'll iteratively prepend zeros to a given list a
number of times equal to the number of variables
minus the list length. In Lean *v - l* is zero in
all cases where *l ≥ v*, so our function will do
nothing if the input list is already long enough. 
-/

-- Note new Lean construct introduced here
def zero_pad : Nat → List Nat → List Nat
  | v, l => zero_pad_helper (v - (l.length)) l
where zero_pad_helper : Nat → List Nat → List Nat
  | 0, l => l
  | v'+1, l => zero_pad_helper v' (0::l)


#eval zero_pad 5 [1,1]        -- expect [0,0,0,1,1]
#eval zero_pad 5 [1,0,1,1,0]  -- expect [1,0,1,1,0]


/-!
We can now write a function that will produce the
required list of binary digits for the (input part
of the) n'th row of a truth table with v variables
(columns).
-/

def mk_bit_row : (row: Nat) → (cols : Nat) → List Nat
| r, c => zero_pad c (nat_to_bin r)

#eval mk_bit_row 5 5  -- expect [0,0,1,0,1]

/-!
Next we need a function to convert a list of bits
(Nats) to a list of Bools. We'll consider Nat zero
to convert to mean false and any other Nat to true.
-/

def bit_to_bool : Nat → Bool
| 0 => false
| _ => true

def bit_list_to_bool_list : List Nat → List Bool
| [] => []
| h::t => bit_to_bool h :: bit_list_to_bool_list t

#eval bit_list_to_bool_list (mk_bit_row 5 4)  -- expect [f,t,f,t]

/-!
#### Convert List Nat to List Bool

Next we want a function, let's call it nats_to_bools,
that takes an argument of type List Nat and returns a
result of type List Bool, where the resultin list is of
the same length as the argument but with every 0 converted
to false and every non-zero entry (particular 1) converted
to true.

Given an empty list of Nat we'll return an empty list of 
Bool. Otherwise, if we have h at the head of a non-empty
list and t as the rest (tail), we'll return a new list with
false if the h is 0 and true otherwise as the head of the
new list, and the recursively converted list of Bools as 
the rest. 
-/

def nats_to_bools : List Nat → List Bool
| [] => []
| h::t => (if h=0 then false else true)::nats_to_bools t

#eval nats_to_bools (nat_to_bin 6)  -- expect [true, true, false]

/-!
#### List Bool to (var → Bool) Interpretation
-/

def mk_interp_helper : Interp  
| _ => _

def bit_to_bool : Nat → Bool
| 0 => false
| _ => true

def override : Interp → var → Bool → Interp
| i, n, b => (λ a => if (a.n == v.n) then b else i a)

def doit_helper : Nat → Nat → Interp → Interp
| 0,      nv, di => (λ v => _)
| n' + 1, nv, di => (λ v => _)

-- given row index for n variables return list of Bool entries
def doit : Nat → Nat → Interp
| ri, nv => doit_helper ri nv all_false


-- Given #variables and row# (zero-indexed) return interpretation
def mk_interp: Nat → Nat →  Interp
| 

def right_bit_bool : Nat → Bool := λ (n : Nat) => n % 2 = 0

def mk_interp : Nat → Interp
| 0,      i => λ v => if v.n = 0 then (right_bit_bool 0) else i 0
| n' + 1, i => λ v => if v.n = (n' + 1) then (right_bit_bool (n' + 1)) else 

def mk_interps_helper : Nat → List Interp
| 0        => []
| (n' + 1) => mk_interp n' :: mk_interps_helper n'


def mk_interps (n : Nat) : List Interp := mk_interps_helper (2^n) 

