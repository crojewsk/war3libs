/*****************************************************************************
*
*    ClickCouple v1.3.4.0
*       by Bannar aka Spinnaker
*          Credits to Azlier for original project
*
*    Detects unit double click event.
*
******************************************************************************
*
*    Optional requirements:
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
*    Configurables:
*
*       constant real PERIOD
*          maximum delay between separate clicks to fire double click event
*
*       constant boolean UNIT_INDEXER
*          if unit indexer is present, GetEventClickedUnitId will be implemented
*
******************************************************************************
*
*    Functions:
*
*       function GetEventClickingPlayer takes nothing returns player
*          retrieves player who performed double click event
*
*       function GetEventClickingPlayerId takes nothing returns integer
*          returns index of event player
*
*       function GetEventClickedUnit takes nothing returns unit
*          retrieves unit which has been double clicked
*
*       function GetEventClickedUnitId takes nothing returns integer
*          returns index of event unit; exists only if UNIT_INDEXER equals true
*
*       function RegisterDoubleClickEvent takes player p, code c returns nothing
*          registers double click event for player p
*
*       function RegisterAnyDoubleClickEvent takes code c returns nothing
*          registers any double click event, no matter the circumstances
*
*       function TriggerRegisterDoubleClickEvent takes trigger t, player p returns nothing
*          trigger version of RegisterDoubleClickEvent function
*
*       function TriggerRegisterAnyDoubleClickEvent takes trigger t returns nothing
*          trigger version of RegisterAnyDoubleClickEvent function
*
*       function GetDoubleClickEventTrigger takes integer playerId returns trigger
*          returns event trigger corresponding to given player's id; use 16 to retrieve generic one
*
******************************************************************************
*
*    Module ClickCoupleStruct:
*
*       Expects:    method onDoubleClick takes nothing returns nothing
*       Optional:   method filterPlayer takes nothing returns nothing
*
*       static method operator clicker takes nothing returns player
*          returns event player
*
*       static method operator clicked takes nothing returns unit
*          returns event unit
*
*****************************************************************************/
library ClickCouple requires optional RegisterPlayerUnitEvent

globals
    private constant real    PERIOD          = 0.30
    private constant boolean UNIT_INDEXER    = false
endglobals

globals
    private timer clock = CreateTimer()
    private player eventPlayer = null
    private unit eventUnit = null

    private trigger array triggers
    private real caller = -1
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

static if UNIT_INDEXER then
	function GetEventClickedUnitId takes nothing returns integer
		return GetUnitId(eventUnit)
	endfunction
endif

private module ClickCoupleInit
    static method onInit takes nothing returns nothing
        static if LIBRARY_RegisterPlayerUnitEvent then
            static if RPUE_COMPATIBILITY then
                call RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_SELECTED, function thistype.onClick)
            else
                call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_SELECTED, function thistype.onClick)
            endif
        else
            local trigger t = CreateTrigger()
            call TriggerRegisterAnyUnitEventBJ(t, EVENT_PLAYER_UNIT_SELECTED)
            call TriggerAddCondition(t, function thistype.onClick)
            set t = null
        endif

        call TimerStart(clock, 604800, false, null)
    endmethod
endmodule

private struct ClickCouple extends array
    unit unit
    real interval

    static method trigger takes integer id returns trigger
        if ( triggers[id] == null ) then
            set triggers[id] = CreateTrigger()
        endif
        return triggers[id]
    endmethod

    static method onClick takes nothing returns boolean
        local player prevPlayer
        local unit prevUnit
        local thistype this = GetPlayerId(GetTriggerPlayer())

        if ( GetTriggerUnit() == unit ) and ( interval + PERIOD > TimerGetElapsed(clock) ) then
            set prevPlayer = eventPlayer
            set prevUnit = eventUnit

            set eventPlayer = GetTriggerPlayer()
            set eventUnit = GetTriggerUnit()

            set caller = 16
            set caller = this
            call TriggerEvaluate(triggers[16])
            call TriggerEvaluate(triggers[this])
            set caller = -1

            set eventPlayer = prevPlayer
            set eventUnit = prevUnit
            set prevPlayer = null
            set prevUnit = null

            set unit = null
            set interval = 0
        else
            set unit = GetTriggerUnit()
            set interval = TimerGetElapsed(clock)
        endif

        return false
    endmethod

    implement ClickCoupleInit
endstruct

function RegisterDoubleClickEvent takes player p, code c returns nothing
    call TriggerAddCondition(ClickCouple.trigger(GetPlayerId(p)), Condition(c))
endfunction

function RegisterAnyDoubleClickEvent takes code c returns nothing
    call TriggerAddCondition(ClickCouple.trigger(16), Condition(c))
endfunction

function TriggerRegisterDoubleClickEvent takes trigger t, player p returns nothing
    call TriggerRegisterVariableEvent(t, SCOPE_PRIVATE + "caller", EQUAL, GetPlayerId(p))
endfunction

function TriggerRegisterAnyDoubleClickEvent takes trigger t returns nothing
    call TriggerRegisterVariableEvent(t, SCOPE_PRIVATE + "caller", EQUAL, 16)
endfunction

function GetDoubleClickEventTrigger takes integer playerId returns trigger
    return ClickCouple.trigger(playerId) // playerId of 16 will return generic trigger
endfunction

module ClickCoupleStruct
    static method operator clicker takes nothing returns player
        return GetEventClickingPlayer()
    endmethod

    static method operator clicked takes nothing returns unit
        return GetEventClickedUnit()
    endmethod

    static if thistype.onDoubleClick.exists then
        private static method onDoubleClickEvent takes nothing returns nothing
            static if thistype.filterPlayer.exists then
                if ( filterPlayer(clicker) ) then
                    call thistype(GetEventClickingPlayerId()).onDoubleClick()
                endif
            else
                call thistype(GetEventClickingPlayerId()).onDoubleClick()
            endif
        endmethod

        private static method onInit takes nothing returns nothing
            call RegisterAnyDoubleClickEvent(function thistype.onDoubleClickEvent)
        endmethod
    endif
endmodule

endlibrary