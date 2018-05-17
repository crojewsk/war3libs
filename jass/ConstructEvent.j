/*****************************************************************************
*
*    ConstructEvent v2.2.0.0
*       by Bannar
*
*    Provides complete solution to construction events.
*    Allows to retrieve unit which actually started construction of given structure.
*
******************************************************************************
*
*    Requirements:
*
*       RegisterPlayerUnitEvent by Bannar
*          hiveworkshop.com/threads/snippet-registerevent-pack.250266/
*
*       ListT by Bannar
*          hiveworkshop.com/threads/containers-list-t.249011/
*
*       UnitDex by TriggerHappy
*          hiveworkshop.com/threads/system-unitdex-unit-indexer.248209/
*
******************************************************************************
*
*    Event API:
*
*       integer EVENT_UNIT_CONSTRUCTION_START
*
*       integer EVENT_UNIT_CONSTRUCTION_CANCEL
*          Intentional construction stop.
*
*       integer EVENT_UNIT_CONSTRUCTION_FINISH
*
*       integer EVENT_UNIT_CONSTRUCTION_INTERRUPT
*          Undesired construction stop e.g. unit death.
*
*       Use RegisterNativeEvent or RegisterIndexNativeEvent for event registration.
*       GetNativeEventTrigger and GetIndexNativeEventTrigger provide access to trigger handles.
*
*
*       function GetConstructingBuilder takes nothing returns unit
*          Retrieves event builder unit, valid only for START event.
*
*       function GetConstructingBuilderId takes nothing returns integer
*          Returns index of builder unit.
*
*       function GetTriggeringStructure takes nothing returns unit
*          Retrieves event structure unit.
*
*       function GetTriggeringStructureId takes nothing returns integer
*          Returns index of constructed structure unit.
*
******************************************************************************
*
*    Functions:
*
*       function GetStructureBuilder takes unit whichUnit returns unit
*          Gets unit which constructed given structure.
*
*       function GetStructureBuilderById takes integer whichIndex returns unit
*          Gets unit which constructed given structure.
*
*       function IsStructureFinished takes unit whichUnit returns boolean
*          Checks whether construction of provided structure has been completed.
*
*****************************************************************************/
library ConstructEvent requires RegisterPlayerUnitEvent, ListT, UnitDex

globals
    integer EVENT_UNIT_CONSTRUCTION_START
    integer EVENT_UNIT_CONSTRUCTION_FINISH
    integer EVENT_UNIT_CONSTRUCTION_CANCEL
    integer EVENT_UNIT_CONSTRUCTION_INTERRUPT
endglobals

native UnitAlive takes unit id returns boolean

globals
    private IntegerList ongoing = 0
    private timer looper = CreateTimer()
    private unit eventBuilder = null
    private unit eventConstruct = null

    private unit array builders
    private boolean array finished
    private integer array instances
    private boolean array cancelled
endglobals

function GetConstructingBuilder takes nothing returns unit
    return eventBuilder
endfunction

function GetConstructingBuilderId takes nothing returns integer
    return GetUnitId(eventBuilder)
endfunction

function GetTriggeringStructure takes nothing returns unit
    return eventConstruct
endfunction

function GetTriggeringStructureId takes nothing returns integer
    return GetUnitId(eventConstruct)
endfunction

function GetStructureBuilder takes unit whichUnit returns unit
    return builders[GetUnitId(whichUnit)]
endfunction

function GetStructureBuilderById takes integer whichIndex returns unit
    return builders[whichIndex]
endfunction

function IsStructureFinished takes unit whichUnit returns boolean
    return finished[GetUnitId(whichUnit)]
endfunction

private function FireEvent takes integer evt, unit builder, unit structure returns nothing
    local unit prevBuilder = eventBuilder
    local unit prevConstruct = eventConstruct
    local integer playerId = GetPlayerId(GetOwningPlayer(builder))

    set eventBuilder = builder
    set eventConstruct = structure

    call TriggerEvaluate(GetNativeEventTrigger(evt))
    if IsNativeEventRegistered(playerId, evt) then
        call TriggerEvaluate(GetIndexNativeEventTrigger(playerId, evt))
    endif

    set eventBuilder = prevBuilder
    set eventConstruct = prevConstruct
    set prevBuilder = null
    set prevConstruct = null
endfunction

/*
*  Unit with no path-texture can be placed in 'arbitrary' location, that is, its x and y
*  won't have integral values. Whatmore, those values will be modified, depending on quarter of
*  coordinate axis where unit is going to be built. This takes form of rounding up and down to 
*  0.250-floor.
*
*  Calculus is different for positive (+x/+y) and negative values (-x/-y).
*  This function makes sure data is translated accordingly.
*/
private function TranslateXY takes real r returns real
    if r >= 0 then
        return R2I(r / 0.250) * 0.250
    else
        return (R2I(r / 0.250) - 1) * 0.250
    endif
endfunction

/*
*  Whether issued order can be counted as a build-ability order. Accounts for:
*  orders between useslot1 and useslot6, plus build tiny building - item ability.
*  Build type: start and forget, just like undead Acolytes do.
*/
private function IsBuildOrder takes integer o returns boolean
    return (o >= 852008 and o <= 852013) or (o == 852619)
endfunction

/*
*  On the contrary to what's described in TranslateXY regarding building position,
*  builder will have his coords "almost" unchanged. This creates situation
*  where builder and construct do not share the same location (x & y).
*
*  Additionally, builder's coords will differ from order's by a small margin. It could be
*  negligible if not for the fact that difference can be greater than or equal to 0.001.
*  In consequence, this invalidates usage of '==' operator when comparing coords
*  (i. e. jass reals - 3 significant digits displayed).
*/
private function IsUnitWithinCoords takes unit u, real x, real y returns boolean
    return (RAbsBJ(GetUnitX(u) - x) == 0) and (RAbsBJ(GetUnitY(u) - y) == 0)
endfunction

private struct PeriodicData extends array
    unit builder     // unit which started construction
    race btype       // build-type, race dependant
    real cx          // future construction point x
    real cy          // future construction point y
    real distance    // for distance measurement, UD/HUM only
    integer order    // unit-type order id
    real ox          // order point x
    real oy          // order point y

    implement Alloc

    method destroy takes nothing returns nothing
        set instances[GetUnitId(builder)] = 0
        set builder = null
        set btype = null

        call ongoing.erase(ongoing.find(this))
        if ongoing.empty() then
            call PauseTimer(looper)
        endif

        call deallocate()
    endmethod

    static method create takes thistype this, unit u, integer orderId, boolean flag, real x, real y returns thistype
        if this == 0 then
            set this = allocate()
            set builder = u
            set instances[GetUnitId(u)] = this
            call ongoing.push(this)
        endif

        set order = orderId
        if flag then // ability based build order
            set btype = RACE_UNDEAD
        else
            set btype = GetUnitRace(builder)
        endif

        set cx = x
        set cy = y
        set ox = cx
        set oy = cy

        if cx - I2R(R2I(cx)) != 0 then
            set cx = TranslateXY(cx)
        endif
        if cy - I2R(R2I(cy)) != 0 then
            set cy = TranslateXY(cy)
        endif

        return this
    endmethod
endstruct

private function OnCallback takes nothing returns nothing
    local IntegerListItem iter = ongoing.first
    local PeriodicData obj
    local real dx
    local real dy

    loop
        exitwhen iter == 0
        set obj = iter.data

        if not UnitAlive(obj.builder) then
            call obj.destroy()
        elseif obj.btype == RACE_UNDEAD or obj.btype == RACE_HUMAN then
            set dx = obj.cx - GetUnitX(obj.builder)
            set dy = obj.cy - GetUnitY(obj.builder)
            set obj.distance = dx*dx + dy*dy
        endif

        set iter = iter.next
    endloop
endfunction

private function OnNonPointOrder takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local unit target = GetOrderTargetUnit()
    local integer index = GetUnitId(u)
    local integer orderId = GetIssuedOrderId()
    local PeriodicData obj = instances[index]

    // Non handle-type orders usually take 852XXX form and are below 900000
    if orderId > 900000 and target != null then
        if ongoing.empty() then
            call TimerStart(looper, 0.031250000, true, function OnCallback)
        endif
        call PeriodicData.create(obj, u, orderId, true, GetUnitX(target), GetUnitY(target))

        set target =  null
    elseif obj != 0 then
        call obj.destroy()
    elseif orderId == 851976 and builders[index] != null and not finished[index] then // order cancel
        if not IsUnitType(u, UNIT_TYPE_STRUCTURE) then
            set cancelled[index] = true
            call FireEvent(EVENT_UNIT_CONSTRUCTION_CANCEL, null, u)
        endif
    endif

    set u = null
endfunction

private function OnPointOrder takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local integer orderId = GetIssuedOrderId()
    local PeriodicData obj = instances[GetUnitId(u)]
    local boolean isBuildOrder = IsBuildOrder(orderId)

    // Non handle-type orders usually take 852XXX form and are below 900000
    if orderId > 900000 or isBuildOrder then
        if ongoing.empty() then
            call TimerStart(looper, 0.031250000, true, function OnCallback)
        endif
        call PeriodicData.create(obj, u, orderId, isBuildOrder, GetOrderPointX(), GetOrderPointY())
    elseif obj != 0 then
        call obj.destroy()
    endif

    set u = null
endfunction

private function OnConstructCancel takes nothing returns nothing
    local unit u = GetTriggerUnit()

    set cancelled[GetUnitId(u)] = true
    call FireEvent(EVENT_UNIT_CONSTRUCTION_CANCEL, null, u)

    set u = null
endfunction

private function OnConstructFinish takes nothing returns nothing
    local unit u = GetTriggerUnit()

    set finished[GetUnitId(u)] = true
    call FireEvent(EVENT_UNIT_CONSTRUCTION_FINISH, null, u)

    set u = null
endfunction

private function OnIndex takes nothing returns nothing
    local unit u = GetIndexedUnit()
    local integer id = GetUnitTypeId(u)
    local IntegerListItem iter = ongoing.first
    local PeriodicData obj
    local PeriodicData found = 0
    local real d = 1000000

    loop
        exitwhen iter == 0
        set obj = iter.data

        if obj.order == id or IsBuildOrder(obj.order) then
            if obj.cx == GetUnitX(u) and obj.cy == GetUnitY(u) then
                if obj.btype == RACE_HUMAN or obj.btype == RACE_UNDEAD then
                    if obj.distance < d then
                        set d = obj.distance
                        set found = obj
                    endif
                elseif IsUnitWithinCoords(obj.builder, obj.ox, obj.oy) then
                    set found = obj
                    exitwhen true
                endif
            endif
        endif

        set iter = iter.next
    endloop

    if found != 0 then
        set builders[GetIndexedUnitId()] = found.builder
        call FireEvent(EVENT_UNIT_CONSTRUCTION_START, found.builder, u)
        call found.destroy()
    endif

    set u = null
endfunction

private function OnDeindex takes nothing returns nothing
    local integer index = GetIndexedUnitId()

    if instances[index] != 0 then
        call PeriodicData(instances[index]).destroy()
    elseif builders[index] != null then
        if not finished[index] or cancelled[index] then
            call FireEvent(EVENT_UNIT_CONSTRUCTION_INTERRUPT, null, GetIndexedUnit())
        endif

        set builders[index] = null
        set finished[index] = false
        set cancelled[index] = false
    endif
endfunction

private module ConstructEventInit
    private static method onInit takes nothing returns nothing
        set EVENT_UNIT_CONSTRUCTION_START = CreateNativeEvent()
        set EVENT_UNIT_CONSTRUCTION_CANCEL = CreateNativeEvent()
        set EVENT_UNIT_CONSTRUCTION_FINISH = CreateNativeEvent()
        set EVENT_UNIT_CONSTRUCTION_INTERRUPT = CreateNativeEvent()
        set START = EVENT_UNIT_CONSTRUCTION_START
        set CANCEL = EVENT_UNIT_CONSTRUCTION_CANCEL
        set FINISH = EVENT_UNIT_CONSTRUCTION_FINISH
        set INTERRUPT = EVENT_UNIT_CONSTRUCTION_INTERRUPT

        set ongoing = IntegerList.create()

        call RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, function OnNonPointOrder)
        call RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER, function OnPointOrder)
        call RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_ORDER, function OnNonPointOrder)
        call RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_CONSTRUCT_CANCEL, function OnConstructCancel)
        call RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_CONSTRUCT_FINISH, function OnConstructFinish)

        call RegisterUnitIndexEvent(Condition(function OnIndex), EVENT_UNIT_INDEX)
        call RegisterUnitIndexEvent(Condition(function OnDeindex), EVENT_UNIT_DEINDEX)
    endmethod
endmodule

struct ConstructEvent
    readonly static integer START
    readonly static integer CANCEL
    readonly static integer FINISH
    readonly static integer INTERRUPT

    implement ConstructEventInit
endstruct

function GetEventBuilder takes nothing returns unit
    debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,60,"Function GetEventBuilder is obsolete, use GetContructingBuilder instead.")
    return GetConstructingBuilder()
endfunction

function GetEventBuilderId takes nothing returns integer
    debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,60,"Function GetEventBuilderId is obsolete, use GetContructingBuilderId instead.")
    return GetConstructingBuilderId()
endfunction

function GetEventStructure takes nothing returns unit
    debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,60,"Function GetEventStructure is obsolete, use GetContructedStructure instead.")
    return GetTriggeringStructure()
endfunction

function GetEventStructureId takes nothing returns integer
    debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,60,"Function GetEventStructureId is obsolete, use GetContructedStructureId instead.")
    return GetTriggeringStructureId()
endfunction

function RegisterConstructEvent takes code func, integer whichEvent returns nothing
    debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,60,"Function RegisterConstructEvent is obsolete, use RegisterNativeEvent instead.")
    call RegisterNativeEvent(whichEvent, func)
endfunction

function GetConstructEventTrigger takes integer whichEvent returns trigger
    debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,60,"Function GetConstructEventTrigger is obsolete, use GetIndexNativeEventTrigger instead.")
    return GetNativeEventTrigger(whichEvent)
endfunction

endlibrary