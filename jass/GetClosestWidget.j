/*****************************************************************************
*
*    GetClosestWidget v3.0.1.3
*       by Bannar aka Spinnaker
*
*    Allows finding closest widget with ease.
*
******************************************************************************
*
*    Configurables:
*
*       Choose which modules should or should not be implemented.
*
*          constant boolean UNITS_MODULE
*          constant boolean GROUP_MODULE
*          constant boolean ITEMS_MODULE
*          constant boolean DESTS_MODULE
*
*       Define start and final distances for search iterations within generic GetClosest functions.
*       If final value is reached, enumeration is performed on whole map.
*
*          constant real START_DISTANCE
*          constant real FINAL_DISTANCE
*
******************************************************************************
*
*    Functions:
*
*       Units:
*        | function GetClosestUnit takes real x, real y, boolexpr filter returns unit
*        |    returns unit closest to coords(x, y)
*        |
*        | function GetClosestUnitInRange takes real x, real y, real radius, boolexpr filter returns unit
*        |    returns unit closest to coords(x, y) within range radius
*        |
*        | function GetClosestUnitInGroup takes real x, real y, group g returns unit
*        |    returns unit closest to coords(x, y) within group g
*
*
*       Group:
*        | function GetClosestNUnitsInRange takes real x, real y, real radius, integer n, group dest, boolexpr filter returns nothing
*        |    adds to group dest up to N units, closest to coords(x, y) within range radius
*        |
*        |  function GetClosestNUnitsInGroup takes real x, real y, integer n, group source, group dest returns nothing
*        |    adds to group dest up to N units, closest to coords(x, y) within group source
*
*
*       Items:
*        | function GetClosestItem takes real x, real y, boolexpr filter returns item
*        |    returns item closest to coords(x, y)
*        |
*        | function GetClosestItemInRange takes real x, real y, real radius, boolexpr filter returns item
*        |    returns item closest to coords(x, y) within range radius
*
*
*       Destructables:
*        | function GetClosestDestructable takes real x, real y, boolexpr filter returns destructable
*        |    returns destructable closest to coords(x, y)
*        |
*        | function GetClosestDestructableInRange takes real x, real y, real radius, boolexpr filter returns destructable
*        |    returns destructable closest to coords(x, y) within range radius
*
*
*****************************************************************************/
library GetClosestWidget

    globals
        private constant boolean UNITS_MODULE   = true
        private constant boolean GROUP_MODULE   = true
        private constant boolean ITEMS_MODULE   = true
        private constant boolean DESTS_MODULE   = true

        private constant real    START_DISTANCE = 800
        private constant real    FINAL_DISTANCE = 3200
    endglobals

    globals
        private real distance
        private real coordX
        private real coordY
    endglobals

    private keyword GroupModule

    private function calcDistance takes real x, real y returns real
        local real dx = x - coordX
        local real dy = y - coordY
        return ( (dx*dx + dy*dy) / 10000 )
    endfunction

    private struct ClosestWidget extends array
        static if UNITS_MODULE then
            static unit unit
            static group group = CreateGroup()
        endif

        static if GROUP_MODULE then
            static if not UNITS_MODULE then
                static group group = CreateGroup()
            endif
            static integer count = 0
            static unit array sorted
            static real array vector

            implement GroupModule
        endif

        static if ITEMS_MODULE then
            static item item
            static rect area = Rect(0, 0, 0, 0)
        endif

        static if DESTS_MODULE then
            static destructable destructable
            static if not ITEMS_MODULE then
                static rect area = Rect(0, 0, 0, 0)
            endif
        endif
    endstruct

    private function Defaults takes real x, real y returns nothing
        static if UNITS_MODULE then
            set ClosestWidget.unit = null
        endif
        static if ITEMS_MODULE then
            set ClosestWidget.item = null
        endif
        static if DESTS_MODULE then
            set ClosestWidget.destructable = null
        endif

        set distance = 100000
        set coordX = x
        set coordY = y
    endfunction

    static if UNITS_MODULE then
        //! runtextmacro DEFINE_GCW_UNIT_MODULE()
    endif
    static if GROUP_MODULE then
        //! runtextmacro DEFINE_GCW_GROUP_MODULE()
    endif
    static if ITEMS_MODULE then
        //! runtextmacro DEFINE_GCW_MODULE("Item", "item")
    endif
    static if DESTS_MODULE then
        //! runtextmacro DEFINE_GCW_MODULE("Destructable", "destructable")
    endif

//! textmacro DEFINE_GCW_UNIT_MODULE

    private function doEnumUnits takes unit u returns nothing
        local real dist = calcDistance(GetUnitX(u), GetUnitY(u))

        if ( dist < distance ) then
            set ClosestWidget.unit = u
            set distance = dist
        endif
    endfunction

    private function enumUnits takes nothing returns nothing
        call doEnumUnits(GetEnumUnit())
    endfunction

    function GetClosestUnit takes real x, real y, boolexpr filter returns unit
        local real r = START_DISTANCE
        local unit u
        call Defaults(x, y)

        loop
            if ( r > FINAL_DISTANCE ) then
                call GroupEnumUnitsInRect(ClosestWidget.group, GetWorldBounds(), filter)
                exitwhen true
            else
                call GroupEnumUnitsInRange(ClosestWidget.group, x, y, r, filter)
                exitwhen FirstOfGroup(ClosestWidget.group) != null
            endif
            set r = 2*r
        endloop

        loop
            set u = FirstOfGroup(ClosestWidget.group)
            exitwhen u == null
            call doEnumUnits(u)
            call GroupRemoveUnit(ClosestWidget.group, u)
        endloop

        return ClosestWidget.unit
    endfunction

    function GetClosestUnitInRange takes real x, real y, real radius, boolexpr filter returns unit
        local unit u
        call Defaults(x, y)

        if ( radius >= 0 ) then
            call GroupEnumUnitsInRange(ClosestWidget.group, x, y, radius, filter)
            loop
                set u = FirstOfGroup(ClosestWidget.group)
                exitwhen u == null
                call doEnumUnits(u)
                call GroupRemoveUnit(ClosestWidget.group, u)
            endloop
        endif

        return ClosestWidget.unit
    endfunction

    function GetClosestUnitInGroup takes real x, real y, group g returns unit
        call Defaults(x, y)
        call ForGroup(g, function enumUnits)
        return ClosestWidget.unit
    endfunction

//! endtextmacro

//! textmacro DEFINE_GCW_GROUP_MODULE

    private module GroupModule

        static method doSaveUnits takes unit u returns nothing
            set count = count + 1
            set sorted[count] = u
            set vector[count] = calcDistance(GetUnitX(u), GetUnitY(u))
        endmethod

        static method saveUnits takes nothing returns nothing
            call doSaveUnits(GetEnumUnit())
        endmethod

        static method sortUnits takes integer lo, integer hi returns nothing
            local integer i = lo
            local integer j = hi
            local real pivot = vector[(lo+hi)/2]

            loop
                loop
                    exitwhen vector[i] >= pivot
                    set i = i + 1
                endloop
                loop
                    exitwhen vector[j] <= pivot
                    set j = j - 1
                endloop

                exitwhen i > j

                set vector[0] = vector[i]
                set vector[i] = vector[j]
                set vector[j] = vector[0]

                set sorted[0] = sorted[i]
                set sorted[i] = sorted[j]
                set sorted[j] = sorted[0]

                set i = i + 1
                set j = j - 1
            endloop

            if ( lo < j ) then
                call sortUnits(lo, j)
            endif
            if ( hi > i ) then
                call sortUnits(i, hi)
            endif
        endmethod

        static method fillGroup takes integer n, group dest returns nothing
            loop
                exitwhen count <= 0 or sorted[count] == null
                if ( count <= n ) then
                    call GroupAddUnit(dest, sorted[count])
                endif
                set sorted[count] = null
                set count = count - 1
            endloop
        endmethod

    endmodule

    function GetClosestNUnitsInRange takes real x, real y, real radius, integer n, group dest, boolexpr filter returns nothing
        local unit u
        call Defaults(x, y)

        if ( radius >= 0 )then
            call GroupEnumUnitsInRange(ClosestWidget.group, x, y, radius, filter)
            loop
                set u = FirstOfGroup(ClosestWidget.group)
                exitwhen u == null
                call ClosestWidget.doSaveUnits(u)
                call GroupRemoveUnit(ClosestWidget.group, u)
            endloop

            call ClosestWidget.sortUnits(1, ClosestWidget.count)
            call ClosestWidget.fillGroup(n, dest)
        endif
    endfunction

    function GetClosestNUnitsInGroup takes real x, real y, integer n, group source, group dest returns nothing
        local integer i = 0
        call Defaults(x, y)

        call ForGroup(source, function ClosestWidget.saveUnits)
        call ClosestWidget.sortUnits(1, ClosestWidget.count)
        call ClosestWidget.fillGroup(n, dest)
    endfunction

//! endtextmacro

//! textmacro DEFINE_GCW_MODULE takes NAME, TYPE

    private function enum$NAME$s takes nothing returns nothing
        local $TYPE$ temp = GetEnum$NAME$()
        local real dist = calcDistance(Get$NAME$X(temp), Get$NAME$Y(temp))

        if ( dist < distance ) then
            set ClosestWidget.$TYPE$ = temp
            set distance = dist
        endif

        set temp = null
    endfunction

    function GetClosest$NAME$ takes real x, real y, boolexpr filter returns $TYPE$
        local real r = START_DISTANCE
        call Defaults(x, y)

        loop
            if ( r > FINAL_DISTANCE ) then
                call Enum$NAME$sInRect(GetWorldBounds(), filter, function enum$NAME$s)
                exitwhen true
            else
                call SetRect(ClosestWidget.area, x-r, y-r, x+r, y+r)
                call Enum$NAME$sInRect(ClosestWidget.area, filter, function enum$NAME$s)
                exitwhen ClosestWidget.$TYPE$ != null
            endif
            set r = 2*r
        endloop

        return ClosestWidget.$TYPE$
    endfunction

    function GetClosest$NAME$InRange takes real x, real y, real radius, boolexpr filter returns $TYPE$
        call Defaults(x, y)

        if ( radius > 0 ) then
            call SetRect(ClosestWidget.area, x-radius, y-radius, x+radius, y+radius)
            call Enum$NAME$sInRect(ClosestWidget.area, filter, function enum$NAME$s)
        endif

        return ClosestWidget.$TYPE$
    endfunction

//! endtextmacro

endlibrary