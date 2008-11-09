module wncml

  use netcdf
  use m_wncml_xml
  use m_wncml_util, only : check, namedims, getType
  use FoX_wxml
  use FoX_common, only : str

  implicit none
  private
  public :: ncmlDumpContainer

contains
      
  subroutine ncmlDumpContainer( xf, ncid, path, unlimdim )

    type(xmlf_t),     intent(inout) :: xf
    integer,          intent(in) :: ncid
    character(len=*), intent(in) :: path
    character(len=*), optional, intent(in) :: unlimdim

  integer :: ndim, nvar, natt
  integer :: len
  integer :: i, j
  character(len=1000) ::  name, atname, string
  integer, dimension(1000) :: ints
  real, dimension(1000) :: reals ! FIXME - should be DP
  integer :: xtype, ndims, natts
  integer, dimension(nf90_max_var_dims) :: DimIds

    call ncmlStartContainer( xf, path)

    call check( NF90_INQUIRE(ncid, ndim, nvar, natt) )
!
! Handle each dimension
! NOTE:  What about varying dimensions?
!        It seems this is not avalable from the f90 bindings
!        which is a bit rubbish. "len: Returned length of
!        dimension. For the unlimited dimension, this is the
!        current maximum value used for writing any variables
!        with this dimension, that is the maximum record number.
!        The best we can do here is to ask the caller to provide 
!        the name of any unlimited dimension in an optional argument 
!        - this gets processed below.
!
    do i = 1, ndim
       call check ( NF90_INQUIRE_DIMENSION(ncid, i, name, len) )
       if (present(unlimdim)) then 
          if (trim(unlimdim).eq.trim(name)) then
            call ncmlAddDimension( xf, trim(name), len, unlim=.true. )
          else
            call ncmlAddDimension( xf, trim(name), len )
          endif
       else
         call ncmlAddDimension( xf, trim(name), len )
       endif
    enddo
!
! Handle any optional global attributes
!
    if ( natt > 0 ) then
      j = 0
      do i = 1, natt
        call ncmlDumpAttribute(ncid, j, i, xf)
      enddo 
    endif
!
! Handle each variable in turn
! Variable may contain attributes
!
    do i = 1, nvar
      call check( NF90_INQUIRE_VARIABLE(ncid, i, name, xtype, ndims=ndims) )
      call check( NF90_INQUIRE_VARIABLE(ncid, i, name, xtype, dimids=DimIds(:ndims),  nAtts=natts) )
      call ncmlStartVariable( xf, name, trim(getType(xtype)), trim(namedims(ncid, ndims, DimIds(:ndims))) )

      if ( natts > 0 ) then
        do j = 1, natts
          call ncmlDumpAttribute(ncid, i, j, xf)
        enddo
      endif

      call ncmlEndVariable( xf )
    enddo

  call ncmlEndContainer( xf )

  end subroutine ncmlDumpContainer

  subroutine ncmlDumpAttribute(ncid, varnum, attnum, xf)

    integer,          intent(in) :: ncid
    integer,          intent(in) :: varnum
    integer,          intent(in) :: attnum
    type(xmlf_t),     intent(inout) :: xf

  character(len=1000) ::  name, atname, string
  integer, dimension(1000) :: ints
  real, dimension(1000) :: reals ! FIXME - should be DP
  integer :: xtype, ndims, natts
  integer :: len

    call check( NF90_INQ_ATTNAME(ncid, varnum, attnum, atname) )
    call check( NF90_INQUIRE_ATTRIBUTE(ncid, varnum, trim(atname), xtype, len) )
    ! nf90_get_att takes multiple types as the last argument - should
    ! handle.
    ! According the the schema, the _value_ of the attribute is 
    ! an xsd:string - as far as I can see the encoding of non
    ! char / string / String xtypes are not defined. So, we take
    ! the easy solution and use FoX's convention (which is, at least,
    ! documents. I'm assuming that nf90_get_att already converts from
    ! e.g. byte to something in Fortran...
    select case(xtype)
    case (NF90_CHAR)
      call check ( nf90_get_att(ncid, varnum, atname, string) )
      call ncmlAddAttribute( xf, trim(atname), trim(getType(xtype)), string(1:len) )
    case (NF90_BYTE)
      call check ( nf90_get_att(ncid, varnum, atname, ints) )
      call ncmlAddAttribute( xf, trim(atname), trim(getType(xtype)), str(ints(1:len)) )
    case (NF90_SHORT)
      call check ( nf90_get_att(ncid, varnum, atname, ints) )
      call ncmlAddAttribute( xf, trim(atname), trim(getType(xtype)), str(ints(1:len)) )
    case (NF90_INT)
      call check ( nf90_get_att(ncid, varnum, atname, ints) )
      call ncmlAddAttribute( xf, trim(atname), trim(getType(xtype)), str(ints(1:len)) )
    case (NF90_FLOAT)
      call check ( nf90_get_att(ncid, varnum, atname, reals) )
      call ncmlAddAttribute( xf, trim(atname), trim(getType(xtype)), str(reals(1:len)) )
    case (NF90_DOUBLE)
      call check ( nf90_get_att(ncid, varnum, atname, reals) )
      call ncmlAddAttribute( xf, trim(atname), trim(getType(xtype)), str(reals(1:len)) )
    end select

  end subroutine ncmlDumpAttribute

end module wncml