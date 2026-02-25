module rle_lib
  implicit none

  ! A run of 'n' instances of character 'c'
  type, public :: run_t
    character :: c
    integer :: n
  end type

  public :: encode, decode

contains

  ! Function to encode a string to an array of runs
  function encode(str) result (run_arr)
    ! Parameters
    character(*), intent(in) :: str
    type(run_t), allocatable :: run_arr(:)

    ! Locals
    integer :: i, j

    ! Allocate sufficiently large result array
    allocate(run_arr(len(str)))

    ! Encode empty string
    if (len(str) == 0) then; return; end if

    ! Encode non-empty string
    i = 1
    run_arr(i)%n = 1
    run_arr(i)%c = str(1:1)
    do j = 2, len(str)
      if (str(j:j) == run_arr(i)%c) then
        run_arr(i)%n = run_arr(i)%n + 1
      else
        i = i + 1
        run_arr(i)%n = 1
        run_arr(i)%c = str(j:j)
      end if
    end do

    ! Truncate result array
    run_arr = run_arr(1:i)
  end function

  ! Function to decode an array of runs to a string
  function decode(run_arr) result(str)
    ! Parameters
    type(run_t), intent(in) :: run_arr(:)
    character(:), allocatable :: str

    ! Locals
    integer :: i, j, str_len

    ! Allocate result string
    str_len = sum([(run_arr(i)%n, i = 1, size(run_arr))])
    allocate(character(str_len) :: str)

    j = 1
    do i = 1, size(run_arr)
      associate (run => run_arr(i))
        str(j:j+run%n-1) = repeat(run%c, run%n)
        j = j + run%n
      end associate
    end do
  end function

end module
