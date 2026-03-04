# Formulate

Formulate is a Fortran library for property-based testing, inspired by
Haskell's [QuickCheck](https://dl.acm.org/doi/10.1145/351240.351266).  The user
expresses program properties as regular Fortran functions, and Formulate checks
them using randomly generated data, reporting any counterexamples found.

* [Prerequisites](#prerequisites)
* [Quick start](#quick-start)
* [Library overview](#library-overview)
* [Case studies](#case-studies)

## Prerequisites

Formulate uses the [fypp](https://github.com/aradi/fypp) preprocessor

```sh
pip3 install fypp
```

and has been tested with the following compilers.

Compiler       | Version
-------------- | -------
`gfortran`     | 9.4.0
`ifx`          | 2025.2.1

The packaged examples all use `gfortran`.

## Quick start

To clone the repo:

```sh
$ git clone https://github.com/rse-cambridge/formulate
```

To run a simple [example](examples/reverse/reverse.fypp) that tests various
properties of a string reversal function:

```sh
$ cd formulate/examples/reverse
$ make
$ ./reverse
```

You should see the output

```
Testing prop_rev_rev:
OK: passed 100 tests
Testing prop_rev_append:
OK: passed 100 tests
Testing prop_rev_single:
OK: passed 100 tests
```

## Library overview

* [1. First example](#1-first-example)
* [2. Reporting intermediate values](#2-reporting-intermediate-values)
* [3. Silent quantification](#3-silent-quantification)
* [4. Quantifying over a restricted domain](#4-quantifying-over-a-restricted-domain)
* [5. Quantifying over allocated arrays](#5-quantifying-over-allocated-arrays)
* [6. Quantifying over arbitary-shape arrays](#6-quantifying-over-arbitrary-shape-arrays)
* [7. Quantifying over strings](#7-quantifying-over-strings)
* [8. Classifying tests cases](#8-classifying-test-cases)
* [9. User-defined types](#9-user-defined-types)

### 1. First example

Below is a short (but complete) program using Formulate, which tests the
property that addition in Fortran is associative, i.e.

```
(x + y) + z == x + (y + z)
```

for all `x`, `y`, and `z`.

```f90
#:include "formulate_macros.fypp"

program addition_test
  use formulate
  @:check(prop_add_assoc)

contains

  ! Property that addition is associative
  logical function prop_add_assoc()
    integer :: x, y, z
    @:for_all(x)
    @:for_all(y)
    @:for_all(z)
    prop_add_assoc = (x + y) + z == x + (y + z)
  end function
end program
```

Formulate's `check()` macro tests a given *property*, where a property is
zero-argument function returning a boolean. Inside a property, the `for_all()`
macro can be thought of as a universal quantifier: the property is expected to
hold for all possible values of its argument. Operationally, it assigns a
random value to its argument, and running the property multiple times, as
`check()` does, tests the property on a range of different values.

> [!NOTE]
> Programs using Formulate should both:
>
>   * `#:include "formulate_macros.fypp"`, and
>   * `use formulate`.

Compiling and running this program gives:

```
Testing prop_add_assoc:
OK: passed 100 tests
```

If we change the type of `x`, `y`, and `z` from `integer` to `real`,
then the same program produces a counterexample:

```
Testing prop_add_assoc:
Counterexample:
x = -.9779284000396728515625
y = -.257434904575347900390625
z = -.61584985256195068359375
```

Floating point addition is
[non-associative](https://en.wikipedia.org/wiki/Associative_property#Nonassociativity_of_floating-point_calculation).

> [!NOTE]
> The values shown in the above counterexample are all fairly small.  In
> Formulate, values are generated randomly but are bounded in size.  By
> default, the size bound grows in proportion to the number of test cases
> generated so far. This means that smaller values are usually tried
> before larger ones.

### 2. Reporting intermediate values

Additional information about a counterexample can help to understand
it. For example, we might like to see the actual values of `(x + y) + z` and
`x + (y + z)` that lead to the failure of `prop_add_assoc()`. To achieve this,
we can use Formulate's `record()` macro:

```f90
! Property that addition is associative
logical function prop_add_assoc()
  real :: x, y, z
  @:for_all(x)
  @:for_all(y)
  @:for_all(z)
  prop_add_assoc = (x + y) + z == x + (y + z)
  @:record((x + y) + z))
  @:record(x + (y + z))
end function
```

Now, the reported counterexample is more detailed:

```
Testing prop_add_assoc:
Counterexample:
x = -1.456022739410400390625
y = -2.6733531951904296875
z = -2.5733082294464111328125
(x + y) + z = -6.7026844024658203125
x + (y + z) = -6.702683925628662109375
```

> [!NOTE]
> The `record()` macro calls Formulate's `show()` function to render
> its argument value as text, which then gets printed when a counterexample
> is found. The `show()` function is overloaded for all built-in types and
> can be extended to derived types by the user
> (see [user-defined types](#9-user-defined-types)).

### 3. Silent quantification

Writing `@:for_all(x)` will cause the value of `x` to be displayed when a
counterexample is found. In later examples, we will see that this can sometimes
result in too much (redundant) information being displayed.  To quantify over
`x` such that its value is *not* displayed when a counterexample is found, we
can write:

```f90
call arbitrary(x)
```

Like the `show()` function, the `arbitrary()` subroutine is overloaded for all
built-in types and can be extended to derived types by the user (see
[user-defined types](#9-user-defined-types)).

> [!NOTE]
> Writing `@:for_all(x, ...)` is equivalent to writing
> 
> ```f90
> call arbitrary(x, ...)
> @:record(x)
> ```
>
> for any (possible empty) set of optional arguments `...`.

### 4. Quantifying over a restricted domain

Often, it's useful to restrict the domain of a quantified variable.  For
example, we might want to quantify over natural numbers rather than integers.
The easiest way to do this is to use the `min_val` optional argument:

```f90
integer :: x
@:for_all(x, min_val=0)
```

A second, more general, approach is to use Formulate's `discard()` subroutine
to discard undesired test cases:

```f90
integer :: x
@:for_all(x)
call discard(x < 0)
```

Calling `discard()` tells Formulate to ignore the result of a test if a given
condition holds. A discarded test will count neither as a passed test nor a
failed test. Discarding test cases is a powerful way to restrict the domain but
can be inefficient when the restricted domain is relatively small compared to
the full domain.

A third, equally general but potentially more efficient, approach is to use a
*custom generator*:

```f90
integer :: x
@:for_all_custom(x, natural)
```

The second argument to `for_all_custom()` is the name of a subroutine to
call to generate values. For example, the `natural` generator could be
defined as follows.

```f90
impure elemental subroutine natural(x)
  integer, intent(out) :: x
  call arbitrary(x, min_val=0)
end subroutine
```

> [!IMPORTANT]
> When defining a custom generator, it's often a good idea to declare it as
> `elemental`. This will allow generation of array values as well as scalars.
> In addition, since a custom generator is likely to use random number
> generator internally, it will also need to be declared as `impure`.

> [!NOTE]
> Writing `@:for_all(x, ...)` is equivalent to
>
> ```f90
> @:for_all_custom(x, arbitrary, ...)
> ```

The above examples quantify over values in a way that is biased towards trying
smaller values first, with the size gradually increasing over time. To
quanitify over values uniformly, the `for_all_uniform()` macro can be used:

```f90
integer :: x
@:for_all_uniform(x, min_val=1, max_val=10)
```

The `min_val` and `max_val` arguments are mandatory and this macro is limited
to `integer` and `real` types.  Underneath, this macro calls Formulate's
`between()` subroutine. A related macro is `for_all_in()`, which uniformly
picks an arbitrary element from a given array.

```f90
integer :: x
@:for_all_in(x, [1, 2, 4, 8])
```

### 5. Quantifying over allocated arrays

In the above examples, `for_all()` was used to quantify over both `integer` and
`real` values. Indeed, it can quantify over values of any type, array or
scalar, provided that:

1. the values are are *allocated*, i.e. they can be safely written to; and
2. the type implements a `show()` function and an `arbitrary()` subroutine.

As an example of quantifying over arrays rather than scalars, here is a
property stating that Fortran's built-in `transpose()` function computes its
own inverse when applied to a rank-2 array.

```f90
logical function prop_trans_trans()
  integer :: arr(10, 20)
  @:for_all(arr)
  prop_trans_trans = all(transpose(transpose(arr)) == arr)
end function
```

Here, `for_all()` quantifies over rank-2 arrays of integers.  However, it's
unsatisfying to limit the array shape to something specific, like `[10, 20]`.
A more general approach is:

```f90
logical function prop_trans_trans()
  integer, allocatable :: arr(:,:)
  integer :: n, m
  call arbitrary(n, min_val=0)
  call arbitrary(m, min_val=0)
  allocate(arr(n, m))
  @:for_all(arr)
  prop_trans_trans = all(transpose(transpose(arr)) == arr)
end function
```

This tests arbitrary-shape arrays, but is a bit of a mouthfull! In the next
section, we'll see more concise ways to write it.

The above example also demonstrates silent quantification: the `arr` variable
already includes the value of `n` and `m` within it, so it's preferable to
quantify over `n` and `m` using `arbitrary()` rather than `for_all()`, to avoid
redundant information when a counterexample is displayed.

> [!NOTE]
> Don't be too alarmed about allocating arrays with `arbitrary()` dimensions.
> Formulate limits the rate at which integer bounds grow over time, and by
> default they won't grow fast enough to run out of memory, at least
> for low-dimensional arrays. Still, a `max_val` can be provided if desired.

### 6. Quantifying over arbitrary-shape arrays

There are simpler ways to quantify over arbitrary-shape arrays.  First, instead
of using multiple `arbitrary()` calls to quantify over each dimension size
individually, we can use a single `abitrary_shape()` call:

```f90
logical function prop_trans_trans()
  integer, allocatable :: arr(:,:)
  integer :: shp(rank(arr))
  call arbitrary_shape(shp)
  allocate(arr(shp(1), shp(2)))
  @:for_all(arr)
  prop_trans_trans = all(transpose(transpose(arr)) == arr)
end function
```

This is preferable because `abitrary_shape()` will ensure that array sizes grow
linearly with respect to the number of tests, regardless of the number of
dimensions. It will also prevent more than one dimension from having zero
size, reducing the number of empty arrays generated.

As a second simplification, we can replace the line

```f90
allocate(arr(shp(1),shp(2)))
```

with

```f90
@:allocate(rank_2, arr, shp)
```

This macro allocates an array with a given rank and shape, reducing clutter,
especially for higher-dimensional arrays.  The rank should always be specified
in the form `rank_<n>` where `<n>` is a positive integer, and must match the
rank of the supplied array (otherwise a compiler error will be raised).

As a third simplfication, we can combine calls to the `allocate()` macro
and the `arbitrary_shape()` subroutine, replacing the lines

```f90
integer :: shp(rank(arr))
call arbitrary_shape(shp)
@:allocate(rank_2, arr, shp)
```

with

```f90
@:arbitrary_allocate(rank_2, arr)
```

Finally, we can combine the statements

```f90
@:arbitrary_allocate(rank_2, arr)
@:for_all(arr)
```

into a single statement

```f90
@:for_all_array(rank_2, arr)
```

resulting in:

```f90
logical function prop_trans_trans()
  integer, allocatable :: arr(:,:)
  @:for_all_array(rank_2, arr)
  prop_trans_trans = all(transpose(transpose(arr)) == arr)
end function
```

> [!NOTE]
> To quantify over an array of natural numbers, we can write
>
> ```f90
>   integer, allocatable :: arr(:,:)
>   @:for_all_array(rank_2, arr, min_val=0)
> ```
>
> Other macro variants for unallocated arrays include:
>
>   * `for_all_custom_array()`, to support custom generators;
>   * `for_all_shaped()`, to support a given array shape;
>   * `for_all_custom_shaped()`, to support custom generators and a
>      given array shape;
>   * `arbitrary_array()`, for silent quantification;
>   * `arbitrary_custom_array()`, for silent quantification and 
>     custom generation.

### 6. Quantifying over strings

If a string is allocated then simply use `for_all()` to quantify over it as
usual.  Otherwise, use `for_all_string()`:

```f90
logical function prop_concat_len()
  character(:), allocatable :: s1, s2
  @:for_all_string(s1)
  @:for_all_string(s2)
  prop_concat_len = len(s1 // s2) == len(s1) + len(s2)
end function
```

The `for_all_string()` macro calls Formulate's `arbitrary_str()` subroutine,
and supports various optional arguments:

  * `domain`: a string from which characters will be drawn;
  * `min_len`: the minimum string length to generate;
  * `max_len`: the maximum string length to generate.

For example, we can bound the domain and length of strings as follows

```f90
character(:), allocatable :: s
@:for_all_string(s, domain="abc", max_len=3)
```

### 7. Non-termination

Property-based testing is good at finding corner cases that the programmer
hasn't thought of. Naturally, if the programmer hasn't thought of it, it may
lead to a crash or non-termination.  In such situations, Formulate never gets a
chance to report the test case that caused the problem. To work around this,
the option `verbose=.true.` can be passed the `check()` macro.  This will
cause every generated test case to be printed, regardless of whether it leads
to a counterexample or not. The test case that causes a crash is then the last
test case to be printed.

> [!NOTE]
> Other options to the `check()` macro include:
>
>   * `num_tests`: the max number of test cases to try (default 100).
>   * `silent`: if `.true.`, never print output, even when a
>      counterexample is found.
>   * `passed`: this gets assigned to `.true.` if all tests pass, and
>      `.false.` otherwise.
>   * `int_size`: this is a function that controls the rate at which
>     `integer` bounds grow over time.
>   * `real_size`: this is a function that controls the rate at which
>     `real` bounds grow over time.

### 8. Classifying test cases

Classifying test cases can help determine whether or not testing has achieved
reasonable coverage of the property.  To illustate, consider the following
property about Fortran's intrinsic function `index(str, substr)`, which returns
the index of the first occurence of `substr` in `str`, or zero if no such
occurence exists.

```f90
! A simple property about searching for a sub-string in a string
logical function prop_index()
  character(:), allocatable :: str, substr
  integer :: i
  @:for_all_string(str)
  @:for_all_string(substr)
  i = index(str, substr)
  prop_index = implies(i /= 0, str(i:i+len(substr)-1) == substr)
  call classify("Empty", len(substr) == 0)
  call classify("Found", len(substr) > 0 .and. i > 0)
end function
```

Testing this property gives the following output.

```
Testing prop_index:
OK: passed 100 tests
Found                           6.0%
Empty                           2.0%
```

This tells us that 6% of the tests cases involved a non-empty `substr` that
occurred in `str`.  We can increase the likelihood of generating overlapping
strings by limiting their domain and length, replacing

```f90
@:for_all_string(str)
@:for_all_string(substr)
```

with

```f90
@:for_all_string(str, domain="abc")
@:for_all_string(substr, domain="abc", max_len=3)
```

Testing the property then gives:

```
OK: passed 100 tests
Found                           26.0%
Empty                           23.0%
```

### 9. User-defined types

Suppose we have the following user-defined type, for integer pairs, that
we'd like to be able to use when writing properties.

```f90
! A simple derived type for integer pairs
type :: pair_t
  integer :: x, y
end type
```

First, we need to define a "show" function for pairs, which converts a given
pair to textual form so that it can be displayed to the user:

```f90
! Extend Formulate's 'show' interface
interface show
  procedure :: show_pair
end interface

! Function for showing pairs
elemental function show_pair(p) result(txt)
  type(pair_t), intent(in) :: p
  type(text_t) :: txt
  txt = "pair_t(" // show(p%x) // "," // show(p%y) // ")"
end function
```

The return type of the function should be Formulate's `type(text_t)` type.
Typically, as in this example, a "show" function for a derived type will call
`show()` on the member variables and combine the results.

> [!IMPORTANT]
> When defining a "show" function for a derived type, remember to declare it as
> `elemental`.  This will allow Formulate to show arrays of the said type, as
> well as scalars.

> [!TIP]
> To show arrays, use the `show_array()` macro rather than the `show()`
> function, as the latter will return an array of texts rather than a single
> text.  In fact, `show_array()` also works for rank-0 arrays (scalars), so can
> always be used in place of `show()`; instead of writing `show(x)`, write
> `@{show_array(x)}@`.

> [!NOTE]
> Key operations supported by Formulate's `text_t` type include:
>
>   * `left // right`: appends `left` and `right` to form a new text. 
>     Both `left` and `right` can be texts or Fortran strings, but at
>     least one must be text.
>   * `text(str)`: converts a Fortran string `str` to text.
>   * `txt%to_string()`: converts text `txt` to a Fortran string.
>   * `txt%append(new)`: appends `new` to `txt` in-place, where `new` can
>      be text or a Fortran string. This is much more efficient than `//`
>      when called repeatedly.

As well as a "show" function for pairs, we also need an "arbitrary" function
for pairs.

```f90
! Extend Formulate's 'arbitrary' interface
interface arbitrary
  procedure :: arbitrary_pair
end interface

! Function for generating arbitrary pairs
impure elemental subroutine arbitrary_pair(p)
  type(pair_t), intent(out) :: p
  call arbitrary(p%x)
  call arbitrary(p%y)
end subroutine
```

Creating an "arbitrary" function for a derived type can be as simple as calling
`arbitrary()` on its member variables.

> [!IMPORTANT]
> When defining an "arbitrary" subroutine for a derived type, remember to
> declare it as `elemental`.  This will allow generating arrays of
> the said type, as well as scalars. It will also need to be declared
> as `impure` due to the use of a random number generator.

We can now formulate properties about pairs, such as:

```f90
! Function to sort a pair
function sort(p) result (q)
  type(pair_t), intent(in) :: p
  type(pair_t) :: q
  q%x = min(p%x, p%y)
  q%y = max(p%x, p%y)
end function

! Property stating that sorted pairs are correctly ordered
logical function prop_sort()
  type(pair_t) :: p, q
  @:for_all(p)
  q = sort(p)
  prop_sort = q%x <= q%y
end function
```

We quantify over pairs by writing `@:for_all(p)`.
The full source code for this example can be found in
[derived_type.fypp](examples/derived_type/derived_type.fypp).

## Case studies

* [1. Run-length encoding](#1-run-length-encoding)
* [2. FTL strings](#2-ftl-strings)
* [3. FTL hash maps](#2-ftl-hash-maps)

### 1. Run-length encoding

As a simple motivating example for property-based testing, we developed a
[program](examples/run_length_encoding/rle_lib.F90) for run-length encoding. It provides two functions: `encode` which converts a string to array of *runs*

```f90
! A run of 'n' instances of character 'c'
type :: run_t
  integer :: n
  character :: c
end type
```

and `decode`, which does the opposite. This program of around 70 lines has an
very simple-to-state property:

```f90
! Property that decode is the inverse of encode
logical function prop_encode_decode()
  character(:), allocatable :: str
  @:for_all_string(str)
  prop_encode_decode = decode(encode(str)) == str
end function
```

Despite believing that we'd got the program right first time, testing the above
property uncovered several bugs. Formulating this simple property led to some
quite thorough testing.

### 2. FTL strings

We applied Formulate to the
[ftlString](https://github.com/SCM-NV/ftl/blob/master/src/ftlString.F90) type
provided by the [Fortran Template Library](https://github.com/SCM-NV/ftl).
Browsing the code, we observed the following three methods, which have
relatively complex definitions:

  * `str%split(sep)` splits `str` using separator `sep` and returns an array
     of separated substrings;
  * `sep%join(strs)` joins an array of strings `strs` using separator `sep`;
  * `str%replace(old,new)` replaces all occurences of substring `old` in
     string `str` with string `new`.

Together, these methods comprise over 250 lines of code.

To test them, we developed
[ftl_string_test.fypp](examples/ftl/ftl_string_test.fypp), which adds simple
`arbitrary()` and `show()` definitions for `ftlString` and formulates a
property relating the three methods:

```f90
! A simple property relating split, join, and replace
logical function prop_split_join_replace()
  type(ftlString) :: str, old, new
  @:for_all(str)
  @:for_all(old)
  @:for_all(new)
  prop_split_join_replace = &
    str%replace(old, new) == new%join(str%split(old))
end function
```

In other words, replacing `old` with `new` in `str` is the same as splitting
`str` using `old` as a seperator and joining the resulting strings using `new`
as a separator.

Testing this property uncovered a number of unexpected behaviours, which were
[reported](https://github.com/SCM-NV/ftl/issues/15) on the FTL issue tracker
and fixed by the author within the hour. The chosen fix was such that the above
property now holds.  Despite `ftlString` being backed by thousands of lines
of [unit tests](https://github.com/SCM-NV/ftl/blob/master/tests/ftlStringTests.F90), a simple property was able to uncover a few surprises.

### 3. FTL hash maps

We also applied Formulate to the FTL's [hash
map](https://github.com/SCM-NV/ftl/blob/master/src/ftlHashMap.F90_template)
implementation. The challenge here is how to generate an `arbitrary()` value
for a data type whose representation is abstract.  A simple answer is to
generate an arbitrary array of "instructions" which, when performed one after
the other, produce a value of that type. By "instruction" we just mean a
data-type representation of a method call that creates or mutates a
a hash map value. 

FTL's hash map provides the following main methods for creating or mutating has maps:

  * `map%new(num_buckets)`;
  * `map%set(key, value)`;
  * `map%erase(key)`;
  * `map%copy()`;
  * `map%clear()`;
  * `map%rehash(num_buckets)`.

In [ftl_hashmap_test.fypp](examples/ftl/ftl_hashmap_test.fypp), we encode these
methods as a Fortran data-type:

```f90
! Hash map operation identifiers
integer, parameter :: OP_SET    = 0, &
                      OP_ERASE  = 1, &
                      OP_COPY   = 2, &
                      OP_REHASH = 3, &
                      OP_NEW    = 4, &
                      OP_CLEAR  = 5

! Type representing a hashmap operation
type :: hashmap_op_t
  ! Unique id denoting a hashmap operation
  integer :: id
  ! Key/value used by the get() and erase() operations
  type(ftlString) :: key
  integer :: val
  ! Number of buckets used by the new() and rehash() operations
  integer :: num_buckets
end type
```

We then define the following three functions/subroutines:

  * `perform(ops)` performs the array of operations `ops`, one after the other
    one, to produce hash map, which is then returned;

  * `golden_get(ops, key, val, found)` searches backwards through the array of
    operations `ops` for an `OP_SET` operation with a matching `key`,
    setting `val` to the corresponding value and `found` to `.true.`. If,
    before that, we hit an `OP_ERASE` with a matching `key`, or an `OP_NEW`
    or `OP_CLEAR` operation, or run out of operations, then `found` is set
    to `.false.`.

  * `agree(map, ops)` returns `.true.` if, for every `key` mentioned in `ops`, 
    `val = map%get(key)` and `found = map%has(key)` agree with
    `golden_get(ops, key, val, found)`.

We then express the property:

```f90
logical function prop_consistent()
  type(hashmap_op_t), allocatable :: ops(:)
  @:for_all_array(rank_1, ops)
  prop_consistent = agree(perform(ops), ops)
end function
```

Formulate did not find any counterexamples to this property. The FTL hash map
implementation is looking good! The full source code for this example can be
found in
[ftl_hashmap_test.fypp](examples/ftl/ftl_hashmap_test.fypp).
