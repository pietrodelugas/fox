undefine(`index')dnl
undefine(`len')dnl
undefine(`format')dnl
dnl
include(`foreach.m4')dnl
dnl
include(`common.m4')dnl
dnl
define(`TOHW_defaultargs', `dnl
    character(len=*), intent(in) :: s
    integer, intent(out), optional :: num
    integer, intent(out), optional :: iostat
')dnl
dnl
define(`TOHW_defaultdecls', `dnl
    integer :: i, j, ij, k, s_i, err, ios, length
    real :: r, c
')dnl
dnl
define(`TOHW_check_errors', `dnl
    if (present(num)) num = ij
    if (ij<length) then
      if (err==0) err = -1
    else
      if (verify(s(s_i:), XML_WHITESPACE)/=0) err = 1
    endif
')dnl
dnl
define(`TOHW_output_errors', `dnl
    if (present(iostat)) then
      iostat = err
    else
      select case (err)
      case(-1)
        write(0, *) "Error in m4f_thisfunc"
        write(0, *) "Too few elements found"
        stop
      case(1)
        write(0, *) "Error in m4f_thisfunc"
        write(0, *) "Too many elements found"
        stop
      case(2)
        write(0, *) "Error in m4f_thisfunc"
        write(0, *) "Malformed input"
        stop
      end select
    end if
')dnl
dnl
define(`TOHW_parse_strings', `dnl
      if (present(separator)) then
        k = index(s(s_i:), separator)
      else
        k = verify(s(s_i:), XML_WHITESPACE)
        if (k==0) exit loop
        s_i = s_i + k - 1
        k = scan(s(s_i:), XML_WHITESPACE)
      endif
      if (k==0) then
        k = len(s)
      else
        k = s_i + k - 2
      endif
      $1 = s(s_i:k)
      ij = ij + 1
      s_i = k + 2
      if (ij<length.and.s_i>len(s)) exit loop
')dnl
dnl
define(`TOHW_parse_logical', `dnl
      k = verify(s(s_i:), XML_WHITESPACE)
      if (k==0) exit loop
      s_i = s_i + k - 1
      k = scan(s(s_i:), XML_WHITESPACE)
      if (k==0) then
        k = len(s)
      else
        k = s_i + k - 2
      endif
      if (s(s_i:k)=="true".or.s(s_i:k)=="1") then
        $1 = .true.
      elseif (s(s_i:k)=="false".or.s(s_i:k)=="0") then
        $1 = .false.
      else
        err = 2
        exit loop
      endif
      ij = ij + 1
      s_i = k + 2
      if (ij<length.and.s_i>len(s)) exit loop
')dnl
dnl
define(`TOHW_parse_numbers', `dnl
      k = verify(s(s_i:), XML_WHITESPACE)
      if (k==0) exit loop
      s_i = s_i + k - 1
      k = scan(s(s_i:), XML_WHITESPACE)
      if (k==0) then
        k = len(s)
      else
        k = s_i + k - 2
      endif
      read(s(s_i:k), *, iostat=ios) $1
      if (ios/=0) then
        err = 2
        exit loop
      endif
      ij = ij + 1
      s_i = k + 2
      if (ij<length.and.s_i>len(s)) exit loop
')dnl
dnl
define(`TOHW_parse_complex', `dnl
      k = index(s(s_i:), "(")
      if (k==0) exit loop
      s_i = s_i + k
      k = index(s(s_i:), ")+i(")
      if (k==0) then
        err = 2
        exit loop
      else
        k = s_i + k - 2
      endif
      ! FIXME should write our own here so it is not recursive I/O
      ! Also not 100% sure that Fortran standard fp read is same as CMLComp
      read(s(s_i:k), *, iostat=ios) r
      if (ios/=0) then
        err = 2
        exit loop
      endif
      s_i = k + 5
      k = index(s(s_i:), ")")
      if (k==0) then
        err = 2
        exit loop
      else
        k = s_i + k - 2
      endif
      ! FIXME should write our own here so it is not recursive I/O
      ! Also not 100% sure that Fortran standard fp read is same as CMLComp
      read(s(s_i:k), *, iostat=ios) c
      if (ios/=0) then
        err = 2
        exit loop
      endif
      $1 = cmplx(r, c)
      ij = ij + 1
      s_i = k + 2
      if (ij<length.and.s_i>len(s)) exit loop
')dnl
dnl
module m_common_parse_input

  use m_common_charset, only : XML_WHITESPACE
  use m_common_realtypes, only: sp, dp

  implicit none
  private

  interface rts
    module procedure scalartostring
    module procedure scalartological
    module procedure scalartointeger
    module procedure scalartorealsp
    module procedure scalartorealdp
    module procedure scalartocomplexsp
    module procedure scalartocomplexdp
    module procedure arraytostring
    module procedure arraytological
    module procedure arraytointeger
    module procedure arraytorealsp
    module procedure arraytorealdp
    module procedure arraytocomplexsp
    module procedure arraytocomplexdp
    module procedure matrixtostring
    module procedure matrixtological
    module procedure matrixtointeger
    module procedure matrixtorealsp
    module procedure matrixtorealdp
    module procedure matrixtocomplexsp
    module procedure matrixtocomplexdp
  end interface

  public :: rts

contains

define(`m4f_thisfunc', `scalartostring')dnl
  subroutine m4f_thisfunc`'(s, data, separator, num, iostat)
    character(len=*), intent(in) :: s
    character(len=*), intent(out) :: data
    character, intent(in), optional :: separator
    integer, intent(out), optional :: num, iostat
TOHW_defaultdecls

    s_i = 1
    err = 0
    data = ""
    ij = 0
    length = 1
    loop: do i = 1, 1
TOHW_parse_strings(`data')
    end do loop

TOHW_check_errors

TOHW_output_errors
  end subroutine m4f_thisfunc

define(`m4f_thisfunc', `scalartological')dnl
  subroutine m4f_thisfunc`'(s, data, num, iostat)
    character(len=*), intent(in) :: s
    logical, intent(out) :: data
    integer, intent(out), optional :: num, iostat
TOHW_defaultdecls

    s_i = 1
    err = 0
    data = .false.
    ij = 0
    length = 1
    loop: do i = 1, 1
TOHW_parse_logical(`data')
    end do loop

TOHW_check_errors

TOHW_output_errors
  end subroutine m4f_thisfunc

define(`m4f_thisfunc', `scalartointeger')dnl
  subroutine m4f_thisfunc`'(s, data, num, iostat)
    character(len=*), intent(in) :: s
    integer, intent(out) :: data
    integer, intent(out), optional :: num, iostat

TOHW_defaultdecls

    s_i = 1
    err = 0
    data = 0
    ij = 0
    length = 1
    loop: do i = 1, 1
TOHW_parse_numbers(`data')
    end do loop

TOHW_check_errors

TOHW_output_errors
  end subroutine m4f_thisfunc

define(`m4f_thisfunc', `scalartorealsp')dnl
  subroutine m4f_thisfunc`'(s, data, num, iostat)
    character(len=*), intent(in) :: s
    real(sp), intent(out) :: data
    integer, intent(out), optional :: num, iostat

TOHW_defaultdecls

    s_i = 1
    err = 0
    data = 0.0_sp
    ij = 0
    length = 1
    loop: do i = 1, 1
TOHW_parse_numbers(`data')
    end do loop

TOHW_check_errors

TOHW_output_errors
  end subroutine m4f_thisfunc

define(`m4f_thisfunc', `scalartorealdp')dnl
  subroutine m4f_thisfunc`'(s, data, num, iostat)
    character(len=*), intent(in) :: s
    real(dp), intent(out) :: data
    integer, intent(out), optional :: num, iostat

TOHW_defaultdecls

    s_i = 1
    err = 0
    data = 0.0_dp
    ij = 0
    length = 1
    loop: do i = 1, 1
TOHW_parse_numbers(`data')
    end do loop

TOHW_check_errors

TOHW_output_errors
  end subroutine m4f_thisfunc

define(`m4f_thisfunc', `scalartocomplexsp')dnl
  subroutine m4f_thisfunc`'(s, data, num, iostat)
    character(len=*), intent(in) :: s
    complex(sp), intent(out) :: data
    integer, intent(out), optional :: num, iostat

TOHW_defaultdecls

    s_i = 1
    err = 0
    data = 0.0_sp
    ij = 0
    length = 1
    loop: do i = 1, 1
TOHW_parse_numbers(`data')
    end do loop

TOHW_check_errors

TOHW_output_errors
  end subroutine m4f_thisfunc

define(`m4f_thisfunc', `scalartocomplexdp')dnl
  subroutine m4f_thisfunc`'(s, data, num, iostat)
    character(len=*), intent(in) :: s
    complex(dp), intent(out) :: data
    integer, intent(out), optional :: num, iostat

TOHW_defaultdecls

    s_i = 1
    err = 0
    data = 0.0_dp
    ij = 0
    length = 1
    loop: do i = 1, 1
TOHW_parse_numbers(`data')
    end do loop

TOHW_check_errors

TOHW_output_errors
  end subroutine m4f_thisfunc



define(`m4f_thisfunc', `arraytostring')dnl
  subroutine m4f_thisfunc`'(s, data, separator, num, iostat)
    character(len=*) :: data(:)
    character, intent(in), optional :: separator
TOHW_defaultargs

TOHW_defaultdecls

    s_i = 1
    err = 0
    data = ""
    ij = 0
    length = size(data)
    loop: do i = 1, size(data)
TOHW_parse_strings(`data(i)')
    end do loop

    if (present(num)) num = ij
    if (ij<size(data)) then
      err = -1
    else
      if (present(separator)) then
        if (len(s)-s_i>=0) &
          err = 1
      else
        if (verify(s(s_i:), XML_WHITESPACE)/=0) &
          err = 1
      endif
    endif

TOHW_output_errors

  end subroutine m4f_thisfunc

define(`m4f_thisfunc', `matrixtostring')dnl
  subroutine m4f_thisfunc`'(s, data, separator, num, iostat)
    character(len=*) :: data(:,:)
    character, intent(in), optional :: separator
TOHW_defaultargs

TOHW_defaultdecls

    s_i = 1
    err = 0
    data = ""
    ij = 0
    length = size(data)
    loop: do j = 1, size(data, 2)
    do i = 1, size(data, 1)
TOHW_parse_strings(`data(i, j)')`'dnl
    end do
    end do loop

    if (present(num)) num = ij
    if (ij<size(data)) then
      err = -1
    else
      if (present(separator)) then
        if (len(s)-s_i>=0) &
          err = 1
      else
        if (verify(s(s_i:), XML_WHITESPACE)/=0) &
          err = 1
      endif
    endif

TOHW_output_errors

  end subroutine m4f_thisfunc

define(`m4f_thisfunc', `arraytological')dnl
  subroutine m4f_thisfunc`'(s, data, num, iostat)
    logical, intent(out) :: data(:)
TOHW_defaultargs

TOHW_defaultdecls

    s_i = 1
    err = 0
    data = .false.
    ij  = 0
    length = size(data)
    loop: do i = 1, size(data)
TOHW_parse_logical(`data(i)')
    end do loop

TOHW_check_errors

TOHW_output_errors

  end subroutine m4f_thisfunc

define(`m4f_thisfunc', `matrixtological')dnl
  subroutine m4f_thisfunc`'(s, data, num, iostat)
    logical, intent(out) :: data(:,:)
TOHW_defaultargs

TOHW_defaultdecls

    s_i = 1
    err = 0
    data = .false.
    ij = 0
    length = size(data)
    loop: do j = 1, size(data, 2)
    do i = 1, size(data, 1)
TOHW_parse_logical(`data(i, j)')
    end do
    end do loop

TOHW_check_errors

TOHW_output_errors

  end subroutine m4f_thisfunc

define(`m4f_thisfunc', `arraytointeger')dnl
  subroutine m4f_thisfunc`'(s, data, num, iostat)
    integer, intent(out) :: data(:)
TOHW_defaultargs

TOHW_defaultdecls
    s_i = 1
    err = 0
    data = 0
    ij  = 0
    length = size(data)
    loop: do i = 1, size(data)
TOHW_parse_numbers(`data(i)')
    end do loop

TOHW_check_errors

TOHW_output_errors

  end subroutine m4f_thisfunc

define(`m4f_thisfunc', `matrixtointeger')dnl
  subroutine m4f_thisfunc`'(s, data, num, iostat)
    integer, intent(out) :: data(:, :)
TOHW_defaultargs

TOHW_defaultdecls

    s_i = 1
    err = 0
    data = 0
    ij = 0
    length = size(data)
    loop: do j = 1, size(data, 2)
    do i = 1, size(data, 1)
TOHW_parse_numbers(`data(i, j)')
    end do
    end do loop

TOHW_check_errors

TOHW_output_errors

  end subroutine m4f_thisfunc

define(`m4f_thisfunc', `arraytorealsp')dnl
  subroutine m4f_thisfunc`'(s, data, num, iostat)
    real(sp), intent(out) :: data(:)
TOHW_defaultargs

TOHW_defaultdecls

    s_i = 1
    err = 0
    data = 0
    ij  = 0
    length = size(data)
    loop: do i = 1, size(data)
TOHW_parse_numbers(`data(i)')
    end do loop

TOHW_check_errors

TOHW_output_errors

  end subroutine m4f_thisfunc

define(`m4f_thisfunc', `matrixtorealsp')dnl
  subroutine m4f_thisfunc`'(s, data, num, iostat)
    real(sp), intent(out) :: data(:,:)
TOHW_defaultargs

TOHW_defaultdecls

    s_i = 1
    err = 0
    data = 0
    ij = 0
    length = size(data)
    loop: do j = 1, size(data, 2)
    do i = 1, size(data, 1)
TOHW_parse_numbers(`data(i, j)')
    end do
    end do loop

TOHW_check_errors

TOHW_output_errors

  end subroutine m4f_thisfunc

define(`m4f_thisfunc', `arraytorealdp')dnl
  subroutine m4f_thisfunc`'(s, data, num, iostat)
    real(dp), intent(out) :: data(:)
TOHW_defaultargs

TOHW_defaultdecls

    s_i = 1
    err = 0
    data = 0
    ij  = 0
    length = size(data)
    loop: do i = 1, size(data)
TOHW_parse_numbers(`data(i)')
    end do loop

TOHW_check_errors

TOHW_output_errors

  end subroutine m4f_thisfunc

define(`m4f_thisfunc', `matrixtorealdp')dnl
  subroutine m4f_thisfunc`'(s, data, num, iostat)
    real(dp), intent(out) :: data(:,:)
TOHW_defaultargs

TOHW_defaultdecls

    s_i = 1
    err = 0
    data = cmplx(0,0)
    ij = 0
    length = size(data)
    loop: do j = 1, size(data, 2)
    do i = 1, size(data, 1)
TOHW_parse_numbers(`data(i, j)')
    end do
    end do loop

TOHW_check_errors

TOHW_output_errors

  end subroutine m4f_thisfunc

define(`m4f_thisfunc', `arraytocomplexsp')dnl
  subroutine m4f_thisfunc`'(s, data, num, iostat)
    complex(sp), intent(out) :: data(:)
TOHW_defaultargs

TOHW_defaultdecls

    s_i = 1
    err = 0
    data = cmplx(0,0)
    ij  = 0
    length = size(data)
    loop: do i = 1, size(data)
TOHW_parse_complex(`data(i)')
    end do loop

TOHW_check_errors

TOHW_output_errors

  end subroutine m4f_thisfunc

define(`m4f_thisfunc', `matrixtocomplexsp')dnl
  subroutine m4f_thisfunc`'(s, data, num, iostat)
    complex(sp), intent(out) :: data(:,:)
TOHW_defaultargs

TOHW_defaultdecls

    s_i = 1
    err = 0
    data = cmplx(0,0)
    ij = 0
    length = size(data)
    loop: do j = 1, size(data, 2)
    do i = 1, size(data, 1)
TOHW_parse_complex(`data(i, j)')
    end do
    end do loop

TOHW_check_errors

TOHW_output_errors

  end subroutine m4f_thisfunc

define(`m4f_thisfunc', `arraytocomplexdp')dnl
  subroutine m4f_thisfunc`'(s, data, num, iostat)
    complex(dp), intent(out) :: data(:)
TOHW_defaultargs

TOHW_defaultdecls

    s_i = 1
    err = 0
    data = cmplx(0)
    ij  = 0
    length = size(data)
    loop: do i = 1, size(data)
TOHW_parse_complex(`data(i)')
    end do loop

TOHW_check_errors

TOHW_output_errors

  end subroutine m4f_thisfunc

define(`m4f_thisfunc', `matrixtocomplexdp')dnl
  subroutine m4f_thisfunc`'(s, data, num, iostat)
    complex(dp), intent(out) :: data(:,:)
TOHW_defaultargs

TOHW_defaultdecls

    s_i = 1
    err = 0
    data = cmplx(0,0)
    ij = 0
    length = size(data)
    loop: do j = 1, size(data, 2)
    do i = 1, size(data, 1)
TOHW_parse_complex(`data(i, j)')
    end do
    end do loop

TOHW_check_errors

TOHW_output_errors

  end subroutine m4f_thisfunc
  
end module m_common_parse_input

