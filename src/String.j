/*****************************************************************************
*
*    String v2.3.0.6
*       by Bannar aka Spinnaker
*
*    Jass version of string library.
*
******************************************************************************
*
*    struct String:
*
*       readonly static constant integer npos
*          special value, the exact meaning depends on the context
*
*
*       String ctors & dctors:
*
*        | static method create takes string s returns thistype
*        |    default ctor
*        |
*        | method destroy takes nothing returns nothing
*        |    default dctor
*        |
*        | static method operator [] takes thistype js returns thistype
*        |    copy ctor
*
*
*       Capacity:
*
*        | method empty takes nothing returns boolean
*        |    checks whether the string is empty
*        |
*        | method size takes nothing returns integer
*        |    returns the number of characters
*        |
*        | static constant method maxSize takes nothing returns integer
*        |    returns the maximum number of characters
*
*
*       Element access:
*
*        | method operator [] takes integer pos returns string
*        |    access specified character
*        |
*        | method operator []= takes integer pos, string s returns nothing
*        |    sets specified character
*        |
*        | method operator front takes nothing returns string
*        |    accesses the first character
*        |
*        | method operator back takes nothing returns string
*        |    accesses the last character
*        |
*        | method operator str takes nothing returns string
*        |    returns value of this string
*
*
*       Operations:
*
*        | method clear takes nothing returns nothing
*        |    clears the contents
*        |
*        | method assign takes string str returns thistype
*        |    replaces this string with a copy of str
*        |
*        | method assignSubstring takes string str, integer pos, integer count returns thistype
*        |    replaces this string with substring of str
*        |
*        | method insert takes integer pos, string str returns thistype
*        |    inserts str before character pointed by pos
*        |
*        | method insertSubstring takes integer pos, string str, integer subpos, integer count returns thistype
*        |    inserts substring of str before character pointed by pos
*        |
*        | method erase takes integer pos, integer count returns thistype
*        |    erases count characters starting at pos
*        |
*        | method pop takes nothing returns thistype
*        |    removes the last character
*        |
*        | method shift takes nothing returns thistype
*        |    removes the first character
*        |
*        | method append takes string str returns thistype
*        |    appends str to the end of this string
*        |
*        | method appendSubstring takes string str, integer pos, integer count returns thistype
*        |    appends substring of str to the end of this string
*        |
*        | method compare takes string str returns integer
*        |    compares value of this string with str
*        |
*        | method compareSubstrings takes integer pos, integer len, string str, integer subpos, integer sublen returns integer
*        |    compares substring of this string with substring of str
*        |
*        | method replace takes integer pos, integer count, string str returns thistype
*        |    replaces count characters starting at pos with str
*        |
*        | method replaceSubstrings takes integer pos, integer len, string str, integer subpos, integer sublen returns thistype
*        |    replaces len characters starting at pos with substring of str
*        |
*        | method substr takes integer pos, integer count returns string
*        |    returns substring of count characters starting at pos
*        |
*        | method resize takes integer count returns nothing
*        |    changes the number of characters stored
*
*
*       Search:
*
*        | method find takes string str returns integer
*        |    searches for the first occurrence of string str
*        |
*        | method findBuffer takes string str, integer pos, integer count returns integer
*        |    finds the first substring equal to the first count characters of str starting from pos
*        |
*        | method rfind takes string str returns integer
*        |    searches for the last occurrence of string s
*        |
*        | method rfindBuffer takes string str, integer pos, integer count returns integer
*        |    finds the last substring equal to the first count characters of str starting from pos
*
*
*       Case conversion:
*
*        | method capital takes nothing returns string
*        |    returns the value of string with first character in upper and all subsequent in lower case
*        |
*        | method upper takes nothing returns string
*        |    returns the value of this string in upper case
*        |
*        | method lower takes nothing returns string
*        |    returns the value of this string in lower case
*
*
*****************************************************************************/
library String

    struct String extends array
        readonly static constant integer npos = -1
        private static integer count = 0
        private thistype recycle

        private string value
        private integer length

        static method create takes string s returns thistype
            local thistype this = thistype(0).recycle

            if this == 0 then
                set count = count + 1
                set this = count
            else
                set thistype(0).recycle = this.recycle
            endif

            set value = s
            set length = StringLength(s)

            return this
        endmethod

        method clear takes nothing returns nothing
            set value = null
            set length = 0
        endmethod

        method destroy takes nothing returns nothing
            call clear()

            set this.recycle = thistype(0).recycle
            set thistype(0).recycle = this
        endmethod

        static method operator [] takes thistype js returns thistype
            return create(js.value)
        endmethod

        method empty takes nothing returns boolean
            return length == 0
        endmethod

        method size takes nothing returns integer
            return length
        endmethod

        static constant method maxSize takes nothing returns integer
            return 1023
        endmethod

        // private asserts for String objects
        private method assert_pos takes integer pos, string f returns boolean
            debug if ( pos < 0 or pos >= length ) then
                debug call DisplayTimedTextFromPlayer(GetLocalPlayer(),0,0,60,"String::assert_pos failed at "+f+" for instance "+I2S(this)+". Invalid index at position "+I2S(pos)+".")
            debug endif

            return ( pos >= 0 and pos < length )
        endmethod

        private method assert_size takes integer count, string f returns boolean
            debug if ( count > maxSize() ) then
                debug call DisplayTimedTextFromPlayer(GetLocalPlayer(),0,0,60,"String::assert_size failed at "+f+" for instance "+I2S(this)+". Maximum size reached.")
            debug endif

            return ( count <= maxSize() )
        endmethod

        private method assert_range takes integer index, string f returns boolean
            debug if ( index < 0 and index > length ) then
                debug call DisplayTimedTextFromPlayer(GetLocalPlayer(),0,0,60,"String::assert_range failed at "+f+" for instance "+I2S(this)+". Invalid iterator at position "+I2S(index)+".")
            debug endif

            return ( index >= 0 and index <= length )
        endmethod

        private method assert_resize takes integer count, string f returns boolean
            return assert_size(length + count, f)
        endmethod

        method operator [] takes integer pos returns string
            debug if not assert_pos(pos, "operator []") then
                debug return null
            debug endif

            return SubString(value, pos, pos+1)
        endmethod

        method operator []= takes integer pos, string s returns nothing
            debug if not assert_pos(pos, "operator []=") then
                debug return
            debug endif

            set value = SubString(value, 0, pos) + SubString(s, 0, 1) + SubString(value, pos+1, length)
        endmethod

        method operator front takes nothing returns string
            return SubString(value, 0, 1)
        endmethod

        method operator back takes nothing returns string
            return SubString(value, length-1, length)
        endmethod

        method operator str takes nothing returns string
            return value
        endmethod

        method assign takes string str returns thistype
            local integer len = StringLength(str)

            if ( assert_size(len, "assign") ) then
                set value = str
                set length = len
            endif

            return this
        endmethod

        method assignSubstring takes string str, integer pos, integer count returns thistype
            if ( count == npos ) then
                set count = StringLength(str)
            endif

            return assign(SubString(str, pos, pos+count))
        endmethod

        method insert takes integer pos, string str returns thistype
            local integer len

            if ( assert_range(pos, "insert") ) then
                set len = StringLength(str)

                if ( len > 0 and assert_resize(len, "insert") ) then
                    set value = SubString(value, 0, pos) + str + SubString(value, pos, length)
                    set length = length + len
                endif
            endif

            return this
        endmethod

        method insertSubstring takes integer pos, string str, integer subpos, integer count returns thistype
            if ( count == npos ) then
                set count = StringLength(str)
            endif

            return insert(pos, SubString(str, subpos, subpos+count))
        endmethod

        method erase takes integer pos, integer count returns thistype
            if assert_pos(pos, "erase") then
                if ( count == npos ) or ( pos+count > length ) then
                    set count = length - pos
                endif

                if ( count > 0 ) then
                    set value = SubString(value, 0, pos) + SubString(value, pos+count, length)
                    set length = length - count
                endif
            endif

            return this
        endmethod

        method pop takes nothing returns thistype
            if ( length > 0 ) then
                set value = SubString(value, 0, length-1)
                set length = length - 1
            endif

            return this
        endmethod

        method shift takes nothing returns thistype
            if ( length > 0 ) then
                set value = SubString(value, 1, length)
                set length = length - 1
            endif

            return this
        endmethod

        method append takes string str returns thistype
            local integer len = StringLength(str)

            if ( len > 0 and assert_resize(len, "append") ) then
                set value = value + str
                set length = length + len
            endif

            return this
        endmethod

        method appendSubstring takes string str, integer pos, integer count returns thistype
            if ( count == npos ) then
                set count = StringLength(str)
            endif

            return append(SubString(str, pos, pos+count))
        endmethod

        method compare takes string str returns integer
            if ( value == str ) then
                return 0
            elseif length > StringLength(str) then
                return 1
            endif

            return -1
        endmethod

        method compareSubstrings takes integer pos, integer len, string str, integer subpos, integer sublen returns integer
            local integer result = -1
            local string sub
            local string sub2

            if ( len == npos ) then
                set len = length
            endif
            if ( sublen == npos ) then
                set sublen = StringLength(str)
            endif

            set sub = SubString(value, pos, pos+len)
            set sub2 = SubString(str, subpos, subpos+sublen)

            if sub == sub2 then
                set result = 0
            elseif StringLength(sub) > StringLength(sub2) then
                set result = 1
            endif

            set sub = null
            set sub2 = null
            return result
        endmethod

        method replace takes integer pos, integer count, string str returns thistype
            local integer len

            if ( assert_pos(pos, "replace") ) then
                if ( count == npos ) or ( pos+count > length ) then
                    set count = length - pos
                endif

                set len = StringLength(str) - count
                if ( assert_resize(len, "replace") ) then
                    set value = SubString(value, 0, pos) + str + SubString(value, pos+count, length)
                    set length = length + len
                endif
            endif

            return this
        endmethod

        method replaceSubstrings takes integer pos, integer len, string str, integer subpos, integer sublen returns thistype
            if ( sublen == npos ) then
                set sublen = StringLength(str)
            endif

            return replace(pos, len, SubString(str, subpos, subpos+sublen))
        endmethod

        method substr takes integer pos, integer count returns string
            if ( assert_pos(pos, "substr") ) then
                if ( count == npos ) then
                    set count = length
                endif

                return SubString(value, pos, pos+count)
            endif

            return null
        endmethod

        method resize takes integer count returns nothing
            if ( count > length ) then
                if ( assert_size(count, "resize") ) then
                    loop
                        exitwhen length >= count
                        set value = value + " "
                        set length = length + 1
                    endloop
                endif
            elseif ( count >= 0 and count < length ) then
                set value = SubString(value, 0, count)
                set length = count
            endif
        endmethod

        method find takes string str, integer pos returns integer
            local integer count

            if ( assert_pos(pos, "find") ) then
                set count = StringLength(str)

                if ( count > 0 ) then
                    loop
                        exitwhen ( pos+count > length )
                        if ( SubString(value, pos, pos+count) == str ) then
                            return pos
                        endif
                        set pos = pos+1
                    endloop
                endif
            endif

            return npos
        endmethod

        method findBuffer takes string str, integer pos, integer count returns integer
            return find(SubString(str, 0, count), pos)
        endmethod

        method rfind takes string str, integer pos returns integer
            local integer count

            if ( pos == npos or pos >= length ) then
                set pos = length - 1
            endif

            if ( assert_pos(pos, "rfind") ) then
                set count = StringLength(str)

                if ( count > 0 ) then
                    set pos = pos - count + 1

                    loop
                        exitwhen ( pos+1 < count )
                        if ( SubString(value, pos, pos+count) == str ) then
                            return pos
                        endif
                        set pos = pos-1
                    endloop
                endif
            endif

            return npos
        endmethod

        method rfindBuffer takes string str, integer pos, integer count returns integer
            return rfind(SubString(str, 0, count), pos)
        endmethod

        method capital takes nothing returns string
            return StringCase(SubString(value, 0, 1), true) + SubString(value, 1, length)
        endmethod

        method upper takes nothing returns string
            return StringCase(value, true)
        endmethod

        method lower takes nothing returns string
            return StringCase(value, false)
        endmethod
    endstruct

endlibrary