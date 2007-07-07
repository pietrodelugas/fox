
module m_dom_utils

  use m_common_array_str, only: str_vs, vs_str_alloc, vs_vs_alloc
  use m_common_attrs, only: dictionary_t, add_item_to_dict, getValue, &
    hasKey, init_dict, destroy_dict
  use m_common_format, only: operator(//)

  use m_dom_dom, only: Node, Namednodemap, Node
  use m_dom_dom, only: DOCUMENT_NODE, ELEMENT_NODE, TEXT_NODE, &
   CDATA_SECTION_NODE, COMMENT_NODE, DOCUMENT_TYPE_NODE, DOCUMENT_FRAGMENT_NODE, &
   ATTRIBUTE_NODE, ENTITY_NODE, NOTATION_NODE, ENTITY_REFERENCE_NODE, PROCESSING_INSTRUCTION_NODE
  use m_dom_dom, only: haschildnodes, getNodeName, getNodeType, &
    getFirstChild, getNextSibling, getlength, item, getDocumentElement, getOwnerElement, &
    getNameSpaceURI, getPrefix, getLocalName, getAttributes, getParentNode, &
    getNodeName, getNodeValue, getData, getName, getTagName, getValue, getTarget


  use FoX_wxml, only: xmlf_t
  use FoX_wxml, only: xml_OpenFile, xml_Close
  use FoX_wxml, only: xml_AddXMLDeclaration
  use FoX_wxml, only: xml_DeclareNamespace
  use FoX_wxml, only: xml_AddAttribute
  use FoX_wxml, only: xml_AddCharacters
  use FoX_wxml, only: xml_NewElement
  use FoX_wxml, only: xml_EndElement
  use FoX_wxml, only: xml_AddComment
  use FoX_wxml, only: xml_AddEntityReference
  use FoX_wxml, only: xml_AddXMLPI

  implicit none

  public :: dumpTree
  public :: serialize

  private

contains

  subroutine dumpTree(startNode)

    type(Node), pointer :: startNode   

    integer           :: indent_level

    indent_level = 0

    call dump2(startNode)

  contains

    recursive subroutine dump2(input)
      type(Node), pointer :: input
      type(Node), pointer :: temp     
      temp => input
      do while(associated(temp))
         write(*,"(3a,i0)") repeat(" ", indent_level), &
                        getNodeName(temp), " of type ", &
                        getNodeType(temp)
         !write(*,"(2a)") "containing value : ", getNodeValue(temp)
         if (hasChildNodes(temp)) then
            indent_level = indent_level + 3
            call dump2(getFirstChild(temp))
            indent_level = indent_level - 3
         endif
         temp => getNextSibling(temp)
      enddo

    end subroutine dump2

  end subroutine dumpTree
!----------------------------------------------------------------

  subroutine serialize(startNode,Name)

    type(Node), pointer :: startNode   
    character(len=*), intent(in) :: Name

    type(xmlf_t)  :: xf
    integer :: iostat
    
    !FIXME several of the below should be optional to serialize
    call xml_OpenFile(name, xf, iostat=iostat, unit=-1, preserve_whitespace=.true.)
    if (iostat/=0) then
      print*,"IOSTAT", iostat
      stop
      continue
    endif
    call iter_dmp_xml(xf, startNode)
    call xml_Close(xf)

  end subroutine serialize

  subroutine iter_dmp_xml(xf, arg)
    type(xmlf_t), intent(inout) :: xf
    type(Node), pointer :: doc

    type(Node), pointer :: this, arg
    integer :: i
    logical :: doneChildren, doneAttributes
    this => arg

!FIXME options for entityrefs & cdata ...

!FIXME output doctype


    i = 0
    doneChildren = .false.
    doneAttributes = .false.
    do

      if (.not.(getNodeType(this)==ELEMENT_NODE.and.doneAttributes)) then
      if (.not.doneChildren) then

print*,"GOING DOWN", getNodeType(this), getNodeName(this)
    select case(getNodeType(this))
    case (ELEMENT_NODE)
      call xml_NewElement(xf, getTagName(this))
    case (ATTRIBUTE_NODE)
      call xml_AddAttribute(xf, getName(this), getValue(this))
      doneChildren = .true.
    case (TEXT_NODE)
      call xml_AddCharacters(xf, getData(this))
    case (CDATA_SECTION_NODE)
      call xml_AddCharacters(xf, getData(this), parsed = .false.)
    case (ENTITY_REFERENCE_NODE)
      call xml_AddEntityReference(xf, getNodeName(this))
      doneChildren = .true.
    case (PROCESSING_INSTRUCTION_NODE)
      call xml_AddXMLPI(xf, getTarget(this), getData(this))
    case (COMMENT_NODE)
      call xml_AddComment(xf, getData(this))
    end select


      else
        if (getNodeType(this)==ELEMENT_NODE) doneAttributes = .true.


print*,"GOING UP", getNodeType(this), getNodeName(this)
    if (getNodeType(this)==ELEMENT_NODE) then
      call xml_EndElement(xf, getTagName(this))
    endif


      endif
      endif

      if (.not.doneChildren) then

        if (getNodeType(this)==ELEMENT_NODE.and..not.doneAttributes) then
          if (getLength(getAttributes(this))>0) then
                      this => item(getAttributes(this), 0)
          else
            doneAttributes = .true.
          endif
        elseif (hasChildNodes(this)) then
          this => getFirstChild(this)
          doneChildren = .false.
          doneAttributes = .false.
        else
          doneChildren = .true.
          doneAttributes = .false.
        endif

      else ! if doneChildren

        if (associated(this, arg)) exit
        if (getNodeType(this)==ATTRIBUTE_NODE) then
          if (i<getLength(getAttributes(getOwnerElement(this)))-1) then
            i = i + 1
            this => item(getAttributes(getOwnerElement(this)), i)
            doneChildren = .false.
          else
            i = 0
            this => getOwnerElement(this)
            doneAttributes = .true.
            doneChildren = .false.
          endif
        elseif (associated(getNextSibling(this))) then

          this => getNextSibling(this)
          doneChildren = .false.
          doneAttributes = .false.
        else
          this => getParentNode(this)
        endif
      endif

    enddo



  end subroutine iter_dmp_xml

end module m_dom_utils
