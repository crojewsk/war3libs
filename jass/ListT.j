/*****************************************************************************
*
*    List<T> v2.1.1.1
*       by Bannar
*
*    Doubly-linked list.
*
******************************************************************************
*
*    Requirements:
*
*       Table by Bribe
*          hiveworkshop.com/forums/jass-resources-412/snippet-new-table-188084/
*
*       Alloc - choose whatever you like
*          e.g.: by Sevion hiveworkshop.com/threads/snippet-alloc.192348/
*
******************************************************************************
*
*    Implementation:
*
*       macro DEFINE_STRUCT_LIST takes ACCESS, NAME, TYPE
*
*       macro DEFINE_LIST takes ACCESS, NAME, TYPE
*
*          ACCESS - encapsulation, choose retriction access
*            NAME - name of list type
*            TYPE - type of values stored
*
******************************************************************************
*
*    struct API:
*
*       struct <NAME>Item:
*
*        | <TYPE> data
*        | <NAME>Item next
*        | <NAME>Item prev
*
*
*       General:
*
*        | static method create takes nothing returns thistype
*        |    default ctor
*        |
*        | static method operator [] takes thistype list returns thistype
*        |    copy ctor
*        |
*        | method destroy takes nothing returns nothing
*        |    default dctor
*        |
*        | method empty takes nothing returns boolean
*        |    checks whether the list is empty
*        |
*        | method size takes nothing returns integer
*        |    returns size of a list
*
*
*       Access:
*
*        | readonly <NAME>Item first
*        | readonly <NAME>Item last
*        |
*        | method front takes nothing returns $TYPE$
*        |    retrieves first element
*        |
*        | method back takes nothing returns $TYPE$
*        |    retrieves last element
*
*
*       Modifiers:
*
*        | method clear takes nothing returns nothing
*        |    flushes list and recycles its nodes
*        |
*        | method push takes $TYPE$ value returns thistype
*        |    adds elements to the end
*        |
*        | method unshift takes $TYPE$ value returns thistype
*        |    adds elements to the front
*        |
*        | method pop takes nothing returns thistype
*        |    removes the last element
*        |
*        | method shift takes nothing returns thistype
*        |    removes the first element
*        |
*        | method find takes $TYPE$ value returns $NAME$Item
*        |    returns the first node which data equals value
*        |
*        | method remove takes $NAME$Item node returns boolean
*        |    removes node from the list, returns true on success
*
*
*****************************************************************************/
library ListT requires Table, Alloc

// Run here any global list types you want to be defined.
//! runtextmacro DEFINE_LIST("", "IntegerList", "integer")

//! textmacro_once DEFINE_STRUCT_LIST takes ACCESS, NAME, TYPE

$ACCESS$ struct $NAME$Item extends array
    // Cannot inherit methods via delegate due to limited array size

    method operator data takes nothing returns $TYPE$
        return IntegerListItem(this).data
    endmethod
    method operator data= takes $TYPE$ value returns nothing
        set IntegerListItem(this).data = value
    endmethod

    method operator next takes nothing returns thistype
        return IntegerListItem(this).next
    endmethod
    method operator next= takes thistype value returns nothing
        set IntegerListItem(this).next = value
    endmethod

    method operator prev takes nothing returns thistype
        return IntegerListItem(this).prev
    endmethod
    method operator prev= takes thistype value returns nothing
        set IntegerListItem(this).prev = value
    endmethod
endstruct

$ACCESS$ struct $NAME$ extends array
    private delegate IntegerList parent

    method front takes nothing returns $TYPE$
        return parent.front()
    endmethod

    method back takes nothing returns $TYPE$
        return parent.back()
    endmethod

    static method create takes nothing returns thistype
        local thistype this = IntegerList.create()
        set parent = this
        return this
    endmethod
endstruct

//! endtextmacro

//! textmacro_once DEFINE_LIST takes ACCESS, NAME, TYPE

$ACCESS$ struct $NAME$Item extends array
    // No default ctor and dctor due to limited array size

    method operator data takes nothing returns $TYPE$
        return Table(this).$TYPE$[0] // hashtable[ node, 0 ] = data
    endmethod
    method operator data= takes $TYPE$ value returns nothing
        set Table(this).$TYPE$[0] = value
    endmethod

    method operator next takes nothing returns thistype
        return Table(this)[1] // hashtable[ node, 1 ] = next
    endmethod
    method operator next= takes thistype value returns nothing
        set Table(this)[1] = value
    endmethod

    method operator prev takes nothing returns thistype
        return Table(this)[-1] // hashtable[ node, -1 ] = prev
    endmethod
    method operator prev= takes thistype value returns nothing
        set Table(this)[-1] = value
    endmethod
endstruct

$ACCESS$ struct $NAME$ extends array
    readonly $NAME$Item first
    readonly $NAME$Item last
    private integer count

    implement Alloc

    private method createNode takes $TYPE$ value returns $NAME$Item
        local $NAME$Item node = Table.create()
        set node.data = value
        set Table(node)[2] = this // ownership
        return node
    endmethod

    private method deleteNode takes $NAME$Item node returns nothing
        call Table(node).destroy() // also removes ownership
    endmethod

    static method create takes nothing returns thistype
        local thistype this = allocate()
        set count = 0
        return this
    endmethod

    method clear takes nothing returns nothing
        local $NAME$Item node = first
        local $NAME$Item temp

        loop // recycle all Table indexes
            exitwhen 0 == node
            set temp = node.next
            call deleteNode(node)
            set node = temp
        endloop

        set first = 0
        set last = 0
        set count = 0
    endmethod

    method destroy takes nothing returns nothing
        call clear()
        call deallocate()
    endmethod

    method front takes nothing returns $TYPE$
        return first.data
    endmethod

    method back takes nothing returns $TYPE$
        return last.data
    endmethod

    method empty takes nothing returns boolean
        return count == 0
    endmethod

    method size takes nothing returns integer
        return count
    endmethod

    method push takes $TYPE$ value returns thistype
        local $NAME$Item node = createNode(value)

        if ( not empty() ) then
            set last.next = node
            set node.prev = last
        else
            set first = node
            set node.prev = 0
        endif

        set last = node
        set node.next = 0
        set count = count + 1
        return this
    endmethod

    method unshift takes $TYPE$ value returns thistype
        local $NAME$Item node = createNode(value)

        if ( not empty() ) then
            set first.prev = node
            set node.next = first
            set first = node
        else
            set first = node
            set last = node
            set node.next = 0
        endif

        set node.prev = 0
        set count = count + 1
        return this
    endmethod

    method pop takes nothing returns thistype
        local $NAME$Item node

        if ( not empty() ) then
            set node = last
            set last = last.prev

            if ( last == 0 ) then
                set first = 0
            else
                set last.next = 0
            endif

            call deleteNode(node)
            set count = count - 1
        debug else
            debug call DisplayTimedTextFromPlayer(GetLocalPlayer(),0,0,60,"$NAME$::pop failed for instance "+I2S(this)+". List is empty.")
        endif
        return this
    endmethod

    method shift takes nothing returns thistype
        local $NAME$Item node

        if ( not empty() ) then
            set node = first
            set first = first.next

            if ( first == 0 ) then
                set last = 0
            else
                set first.prev = 0
            endif

            call deleteNode(node)
            set count = count - 1
        debug else
            debug call DisplayTimedTextFromPlayer(GetLocalPlayer(),0,0,60,"$NAME$::shift failed for instance "+I2S(this)+". List is empty.")
        endif
        return this
    endmethod

    static method operator[] takes thistype list returns thistype
        local thistype this = create()
        local $NAME$Item node = list.first

        loop
            exitwhen node == 0
            call push(node.data)
            set node = node.next
        endloop

        return this
    endmethod

    method find takes $TYPE$ value returns $NAME$Item
        local $NAME$Item node = first
        loop
            exitwhen node == 0 or node.data == value
            set node = node.next
        endloop
        return node
    endmethod

    method remove takes $NAME$Item node returns boolean
        if ( Table(node)[2] == this ) then // match ownership
            if ( node == first ) then
                call shift()
            elseif ( node == last ) then
                call pop()
            else
                set node.prev.next = node.next
                set node.next.prev = node.prev
                call deleteNode(node)
                set count = count - 1
            endif
            return true
        debug else
            debug call DisplayTimedTextFromPlayer(GetLocalPlayer(),0,0,60,"$NAME$::remove failed for instance "+I2S(this)+". Attempted to remove invalid node "+I2S(node)+".")
        endif
        return false
    endmethod

endstruct

//! endtextmacro

endlibrary