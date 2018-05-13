/*****************************************************************************
*
*    ClickCouple v1.4.0.2
*       by Bannar
*
*    Detects unit double click event.
*
*    Credits to Azlier for original project. Thanks to Magtheridon96, Bribe and
*    all other hivers for helping me greatly during the development of this snippet.
*
******************************************************************************
*
*    Requirements:
*
*       RegisterPlayerUnitEvent by Bannar
*          hiveworkshop.com/threads/snippet-registerevent-pack.250266/
*
*    Optional requirements:
*
*       Table by Bribe
*          hiveworkshop.com/threads/snippet-new-table.188084/
*
******************************************************************************
*
*    Configurables:
*
*       constant real PERIOD
*          Maximum delay between separate clicks to fire double click event.
*
******************************************************************************
*
*    Event API:
*
*       integer EVENT_PLAYER_DOUBLE_CLICK
*
*       Use RegisterNativeEvent or RegisterIndexNativeEvent for event registration.
*       GetNativeEventTrigger and GetIndexNativeEventTrigger provide access to trigger handles.
*
*
*       function GetEventClickingPlayer takes nothing returns player
*          Retrieves player who performed double click event.
*
*       function GetEventClickingPlayerId takes nothing returns integer
*          Returns index of event player.
*
*       function GetEventClickedUnit takes nothing returns unit
*          Retrieves unit which has been double clicked.
*
*****************************************************************************/
library ClickCouple requires RegisterPlayerUnitEvent optional Table

globals
    private constant real PERIOD  = 0.30

    integer EVENT_PLAYER_DOUBLE_CLICK
endglobals

globals
    private timer clock = CreateTimer()
    private player eventPlayer = null
    private unit eventUnit = null
endglobals

function GetEventClickingPlayer takes nothing returns player
    return eventPlayer
endfunction

function GetEventClickingPlayerId takes nothing returns integer
    return GetPlayerId(eventPlayer)
endfunction

function GetEventClickedUnit takes nothing returns unit
    return eventUnit
endfunction

function RegisterDoubleClickEvent takes player whichPlayer, code func returns nothing
    debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,60,"Function RegisterDoubleClickEvent is obsolete, use RegisterIndexNativeEvent instead.")
    call RegisterIndexNativeEvent(GetPlayerId(whichPlayer), EVENT_PLAYER_DOUBLE_CLICK, func)
endfunction

function RegisterAnyDoubleClickEvent takes code func returns nothing
    debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,60,"Function RegisterAnyDoubleClickEvent is obsolete, use RegisterNativeEvent instead.")
    call RegisterNativeEvent(EVENT_PLAYER_DOUBLE_CLICK, func)
endfunction

function GetDoubleClickEventTrigger takes integer playerId returns trigger
    debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,60,"Function GetDoubleClickEventTrigger is obsolete, use GetIndexNativeEventTrigger instead.")
    return GetIndexNativeEventTrigger(playerId, EVENT_PLAYER_DOUBLE_CLICK)
endfunction

module ClickCoupleStruct
    static method operator clicker takes nothing returns player
        debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,60,"Method ClickCoupleStruct::clicker is obsolete, use GetEventClickingPlayer instead.")
        return GetEventClickingPlayer()
    endmethod

    static method operator clicked takes nothing returns unit
        debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,60,"Method ClickCoupleStruct::clicked is obsolete, use GetEventClickedUnit instead.")
        return GetEventClickedUnit()
    endmethod

    static if thistype.onDoubleClick.exists then
        private static method onDoubleClickEvent takes nothing returns nothing
            debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,60,"Module ClickCoupleStruct is obsolete, use RegisterNativeEvent directly instead.")
            static if thistype.filterPlayer.exists then
                if filterPlayer(GetEventClickingPlayer()) then
                    call thistype(GetEventClickingPlayerId()).onDoubleClick()
                endif
            else
                call thistype(GetEventClickingPlayerId()).onDoubleClick()
            endif
        endmethod

        private static method onInit takes nothing returns nothing
            call RegisterNativeEvent(EVENT_PLAYER_DOUBLE_CLICK, function thistype.onDoubleClickEvent)
        endmethod
    endif
endmodule

private function FireEvent takes player p, unit u returns nothing
    local player prevPlayer = eventPlayer
    local unit prevUnit = eventUnit
    local integer playerId = GetPlayerId(p)

    set eventPlayer = p
    set eventUnit = u

    call TriggerEvaluate(GetNativeEventTrigger(EVENT_PLAYER_DOUBLE_CLICK))
    if IsNativeEventRegistered(playerId, EVENT_PLAYER_DOUBLE_CLICK) then
        call TriggerEvaluate(GetIndexNativeEventTrigger(playerId, EVENT_PLAYER_DOUBLE_CLICK))
    endif

    set eventPlayer = prevPlayer
    set eventUnit = prevUnit
    set prevPlayer = null
    set prevUnit = null
endfunction

private module ClickCoupleInit
static if LIBRARY_Table then
    static TableArray table
else
    static hashtable table = InitHashtable()
endif

    private static method onInit takes nothing returns nothing
        set EVENT_PLAYER_DOUBLE_CLICK = CreateNativeEvent()

static if LIBRARY_Table then
        set table = TableArray[bj_MAX_PLAYER_SLOTS]
endif
        call RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_SELECTED, function thistype.onClick)
        call TimerStart(clock, 604800, false, null)
    endmethod
endmodule

private struct ClickCouple extends array
    static method onClick takes nothing returns nothing
        local player p = GetTriggerPlayer()
        local unit u = GetTriggerUnit()
        local integer id = GetPlayerId(p)
        local integer unitId = GetHandleId(u)

static if LIBRARY_Table then
        if table[id].unit.has(unitId) and table[id].unit[unitId] == u and /*
        */ (table[id].real[unitId] + PERIOD) > TimerGetElapsed(clock) then
            call FireEvent(p, u)
            call table[id].flush()
        else
            set table[id].unit[unitId] = u
            set table[id].real[unitId] = TimerGetElapsed(clock)
        endif
else
        if HaveSavedHandle(table, id, unitId) and LoadUnitHandle(table, id, unitId) == u and /*
        */ (LoadReal(table, id, unitId) + PERIOD) > TimerGetElapsed(clock) then
            call FireEvent(p, u)
            call FlushChildHashtable(table, id)
        else
            call SaveUnitHandle(table, id, unitId, u)
            call SaveReal(table, id, unitId, TimerGetElapsed(clock))
        endif
endif

        set p = null
        set u = null
    endmethod

    implement ClickCoupleInit
endstruct

endlibrary