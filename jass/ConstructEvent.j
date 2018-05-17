/*****************************************************************************
*
*    ConstructEvent v2.1.2.0
*       by Bannar aka Spinnaker
*
*    Provides functionality of generic CONSTRUCT events.
*    Allows to retrieve unit which actually started construction of given structure.
*
******************************************************************************
*
*    Requirements:
*
*       Unit Indexer library - supports:
*
*        | UnitIndexerGUI by Bribe
*        |    hiveworkshop.com/forums/submissions-414/snippet-gui-unit-indexer-vjass-plugin-268592/
*        |
*        | UnitIndexer by Nestharus
*        |    hiveworkshop.com/forums/jass-functions-413/unit-indexer-172090/
*
*    Optionaly uses:
*
*       RegisterPlayerUnitEvent library - supports:
*
*        | RegisterPlayerUnitEvent by Bannar
*        |    hiveworkshop.com/forums/submissions-414/snippet-registerevent-pack-250266/
*        |
*        | RegisterPlayerUnitEvent by Magtheridon96
*        |    hiveworkshop.com/forums/jass-resources-412/snippet-registerplayerunitevent-203338/
*
******************************************************************************
*
*    struct ConstructEvent:
*
*       readonly static START
*          generic START event
*
*       readonly static CANCEL
*          specific stop event i.e. fires on intentional construction stop
*
*       readonly static FINISH
*          generic FINISH event
*
*       readonly static INTERRUPT
*          specific stop event i.e. fires on undesired construction stop e.g. unit death
*
******************************************************************************
*
*    Functions:
*
*       function GetStructureBuilder takes unit u returns unit
*          gets unit which constructed given structure
*
*       function GetStructureBuilderById takes integer id returns unit
*          gets unit which constructed given structure
*
*       function GetEventBuilder takes nothing returns unit
*          retrieves event builder unit; valid only on START event
*
*       function GetEventBuilderId takes nothing returns integer
*          index of builder unit
*
*       function GetEventStructure takes nothing returns unit
*          retrieves event structure unit
*
*       function GetEventStructureId takes nothing returns integer
*          index of structure unit
*
*       function IsStructureFinished takes unit u returns boolean
*          checks whether structure has completed its construction
*
*       function RegisterConstructEvent takes code c, integer ev returns nothing
*          registers given function with construct event type
*
*       function TriggerRegisterConstructEvent takes trigger t, integer ev returns nothing
*          connects trigger handle with construct event type
*
*       function GetConstructEventTrigger takes integer whichEvent returns trigger
*          returns event trigger corresponding to construct event whichEvent
*
*****************************************************************************/
library ConstructEvent requires /*
                     */ optional UnitIndexerGUI /*
                     */ optional UnitIndexer /*
                     */ optional RegisterPlayerUnitEvent

globals
    private timer looper = CreateTimer()
    private unit eventBuilder = null
    private unit eventConstruct = null

    private unit array builders
    private boolean array finished

    private integer array instances
    private boolean array cancelled

    private trigger array triggers
    private real caller = 0
endglobals

native UnitAlive takes unit id returns boolean

function GetStructureBuilder takes unit u returns unit
    return builders[GetUnitId(u)]
endfunction

function GetStructureBuilderById takes integer id returns unit
    return builders[id]
endfunction

function GetEventBuilder takes nothing returns unit
    return eventBuilder
endfunction

function GetEventBuilderId takes nothing returns integer
    return GetUnitId(eventBuilder)
endfunction

function GetEventStructure takes nothing returns unit
    return eventConstruct
endfunction

function GetEventStructureId takes nothing returns integer
    return GetUnitId(eventConstruct)
endfunction

function IsStructureFinished takes unit u returns boolean
    return finished[GetUnitId(u)]
endfunction

private function RegisterAnyUnitEvent takes playerunitevent e, code c returns nothing
    static if LIBRARY_RegisterPlayerUnitEvent then
        static if RPUE_VERSION_NEW then
            call RegisterAnyPlayerUnitEvent(e, c)
        else
            call RegisterPlayerUnitEvent(e, c)
        endif
    else
        local trigger t = CreateTrigger()
        call TriggerRegisterAnyUnitEventBJ(t, e)
        call TriggerAddCondition(t, Condition(c))
        set t = null
    endif
endfunction

private module ConstructEventInit
    private static method onInit takes nothing returns nothing
        call RegisterAnyUnitEvent(EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, function thistype.onDifferentOrder)
        call RegisterAnyUnitEvent(EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER, function thistype.onPointOrder)
        call RegisterAnyUnitEvent(EVENT_PLAYER_UNIT_ISSUED_ORDER, function thistype.onDifferentOrder)

        call RegisterAnyUnitEvent(EVENT_PLAYER_UNIT_CONSTRUCT_CANCEL, function thistype.onConstructCancel)
        call RegisterAnyUnitEvent(EVENT_PLAYER_UNIT_CONSTRUCT_FINISH, function thistype.onConstructFinish)

        static if LIBRARY_UnitIndexerGUI then
            call OnUnitIndex(function thistype.onIndex)
            call OnUnitDeindex(function thistype.onDeindex)
        elseif LIBRARY_UnitIndexer then
            call RegisterUnitIndexEvent(Condition(function thistype.onIndex), UnitIndexer.INDEX)
            call RegisterUnitIndexEvent(Condition(function thistype.onDeindex), UnitIndexer.DEINDEX)
        endif

        set triggers[START] = CreateTrigger()
        set triggers[CANCEL] = CreateTrigger()
        set triggers[FINISH] = CreateTrigger()
        set triggers[INTERRUPT] = CreateTrigger()
    endmethod
endmodule

struct ConstructEvent extends array
    private static integer count = 0
    private thistype recycle
    private thistype next
    private thistype prev

    readonly static integer START = 1
    readonly static integer CANCEL = 2
    readonly static integer FINISH = 3
    readonly static integer INTERRUPT = 4

    private unit builder
    private race btype
    private real cx
    private real cy
    private real distance
    private integer order

    private real ox
    private real oy

    private static method fire takes unit builder, unit construct, integer ev returns nothing
        local unit prevBuilder = eventBuilder
        local unit prevConstruct = eventConstruct

        set eventBuilder = builder
        set eventConstruct = construct

        set caller = ev
        call TriggerEvaluate(triggers[ev])
        set caller = 0

        set eventBuilder = prevBuilder
        set eventConstruct = prevConstruct
        set prevBuilder = null
        set prevConstruct = null
    endmethod

    private static method translateXY takes real r returns real
        if ( r >= 0 ) then
            return R2I(r / 0.250) * 0.250
        else
            return (R2I(r / 0.250) - 1) * 0.250
        endif
    endmethod

    private static method orderCounts takes integer o returns boolean
        return ( o >= 852008 and o <= 852013 ) or ( o == 852619 )
    endmethod

    private static method withinCoords takes unit u, real x, real y returns boolean
        return ( RAbsBJ(GetUnitX(u) - x) == 0 ) and ( RAbsBJ(GetUnitY(u) - y) == 0 )
    endmethod

    private method deallocate takes nothing returns nothing
        set recycle = thistype(0).recycle
        set thistype(0).recycle = this
        set next.prev = prev
        set prev.next = next

        if ( thistype(0).next == 0 ) then
            call PauseTimer(looper)
        endif
    endmethod

    private method destroy takes nothing returns nothing
        set instances[GetUnitId(builder)] = 0
        set builder = null
        set btype = null

        call deallocate()
    endmethod

    private static method onCallback takes nothing returns nothing
        local thistype this = thistype(0).next
        local real dx
        local real dy

        loop
            exitwhen this == 0

            if not UnitAlive(builder) then
                call destroy()
            elseif ( btype == RACE_UNDEAD or btype == RACE_HUMAN ) then
                set dx = cx - GetUnitX(builder)
                set dy = cy - GetUnitY(builder)
                set distance = ( dx*dx + dy*dy )
            endif

            set this = next
        endloop
    endmethod

    private static method allocate takes nothing returns thistype
        local thistype this = thistype(0).recycle
        if ( thistype(0).next == 0 ) then
            call TimerStart(looper, 0.031250000, true, function thistype.onCallback)
        endif

        if ( this == 0 ) then
            set count = count + 1
            set this = count
        else
            set thistype(0).recycle = recycle
        endif

        set next = 0
        set prev = thistype(0).prev
        set thistype(0).prev.next = this
        set thistype(0).prev = this

        return this
    endmethod

    private static method create takes thistype this, unit u, integer orderId, boolean flag, real x, real y returns thistype
        if ( this == 0 ) then
            set this = allocate()
            set builder = u
            set instances[GetUnitId(u)] = this
        endif

        set order = orderId
        if ( flag ) then
            set btype = RACE_UNDEAD
        else
            set btype = GetUnitRace(builder)
        endif

        set cx = x
        set cy = y
        set ox = cx
        set oy = cy

        if ( cx - I2R(R2I(cx)) != 0 ) then
            set cx = translateXY(cx)
        endif
        if ( cy - I2R(R2I(cy)) != 0 ) then
            set cy = translateXY(cy)
        endif

        return this
    endmethod

    private static method onDifferentOrder takes nothing returns boolean
        local unit u = GetTriggerUnit()
        local unit target = GetOrderTargetUnit()
        local integer index = GetUnitId(u)
        local integer orderId = GetIssuedOrderId()
        local thistype instance = instances[index]

        if ( orderId > 900000 and target != null ) then
            call create(instance, u, orderId, true, GetUnitX(target), GetUnitY(target))
            set target =  null

        elseif ( instance != 0 ) then
            call instance.destroy()

        elseif ( orderId == 851976 and builders[index] != null and not finished[index] ) then
            if not IsUnitType(u, UNIT_TYPE_STRUCTURE) then
                set cancelled[index] = true
                call fire(null, u, CANCEL)
            endif
        endif

        set u = null
        return false
    endmethod

    private static method onPointOrder takes nothing returns boolean
        local unit u = GetTriggerUnit()
        local integer orderId = GetIssuedOrderId()
        local thistype instance = instances[GetUnitId(u)]
        local boolean flag = orderCounts(orderId)

        if ( orderId > 900000 or flag ) then
            call create(instance, u, orderId, flag, GetOrderPointX(), GetOrderPointY())
        elseif ( instance != 0 ) then
            call instance.destroy()
        endif

        set u = null
        return false
    endmethod

    private static method onConstructCancel takes nothing returns boolean
        local unit u = GetTriggerUnit()

        set cancelled[GetUnitId(u)] = true
        call fire(null, u, CANCEL)

        set u = null
        return false
    endmethod

    private static method onConstructFinish takes nothing returns boolean
        local unit u = GetTriggerUnit()

        set finished[GetUnitId(u)] = true
        call fire(null, u, FINISH)

        set u = null
        return false
    endmethod

    private static method onIndex takes nothing returns boolean
        local unit u = GetIndexedUnit()
        local integer id = GetUnitTypeId(u)
        local thistype this = thistype(0).next
        local thistype found = 0
        local real d = 1000000

        loop
            exitwhen this == 0

            if ( order == id or orderCounts(order) ) then
                if ( cx == GetUnitX(u) and cy == GetUnitY(u) ) then
                    if ( btype == RACE_HUMAN or btype == RACE_UNDEAD ) then
                        if ( distance < d ) then
                            set d = distance
                            set found = this
                        endif
                    elseif ( withinCoords(builder, ox, oy) ) then
                        set found = this
                        exitwhen true
                    endif
                endif
            endif

            set this = next
        endloop

        if ( found != 0 ) then
            set builders[GetIndexedUnitId()] = found.builder
            call fire(found.builder, u, START)
            call found.destroy()
        endif

        set u = null
        return false
    endmethod

    private static method onDeindex takes nothing returns boolean
        local thistype index = GetIndexedUnitId()

        if ( instances[index] != 0 ) then
            call thistype(instances[index]).destroy()

        elseif ( builders[index] != null ) then
            if not ( finished[index] or cancelled[index] ) then
                call fire(null, GetIndexedUnit(), INTERRUPT)
            endif

            set builders[index] = null
            set finished[index] = false
            set cancelled[index] = false
        endif

        return false
    endmethod

    implement ConstructEventInit
endstruct

function RegisterConstructEvent takes code c, integer ev returns nothing
    call TriggerAddCondition(triggers[ev], Condition(c))
endfunction

function TriggerRegisterConstructEvent takes trigger t, integer ev returns nothing
    call TriggerRegisterVariableEvent(t, SCOPE_PRIVATE + "caller", EQUAL, ev)
endfunction

function GetConstructEventTrigger takes integer whichEvent returns trigger
    return triggers[whichEvent]
endfunction

endlibrary