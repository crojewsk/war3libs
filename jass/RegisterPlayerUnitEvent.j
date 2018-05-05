/*****************************************************************************
*
*    RegisterPlayerUnitEvent v1.0.2.1
*       by Bannar
*
*    Register version of TriggerRegisterPlayerUnitEvent.
*
******************************************************************************
*
*    Requirements:
*
*       RegisterNativeEvent by Bannar
*          hiveworkshop.com/forums/submissions-414/snippet-registerevent-pack-250266/
*
******************************************************************************
*
*    constant boolean RPUE_VERSION_NEW
*       Defines API style. Choose between compatibility with standard RPUE or Blizzard alike interface
*
*
*    Functions:
*
*       function Register(Any)PlayerUnitEvent takes playerunitevent whichEvent, code cb returns nothing
*          registers generic playerunitevent whichEvent adding code cb as callback
*
*       function RegisterPlayerUnitEvent(ForPlayer) takes player whichPlayer, playerunitevent whichEvent, code cb returns nothing
*          registers playerunitevent whichEvent for player whichPlayer adding code cb as callback
*
*       function GetPlayerUnitEventTrigger takes playerunitevent whichEvent returns trigger
*          retrieves trigger handle for playerunitevent whichEvent
*
*       function GetPlayerUnitEventTriggerForPlayer takes player whichPlayer, playerunitevent whichEvent returns trigger
*          retrieves trigger handle for playerunitevent whichEvent specific to player whichPlayer
*
*****************************************************************************/
library RegisterPlayerUnitEvent requires RegisterNativeEvent

globals
    constant boolean RPUE_VERSION_NEW = false
endglobals

//! textmacro_once DEFINE_REGISTER_PLAYER_UNIT_EVENT takes GENERIC, SPECIFIC
function Register$GENERIC$PlayerUnitEvent takes playerunitevent whichEvent, code cb returns nothing
    local integer eventId = GetHandleId(whichEvent)
    local integer index = 0
    local trigger t = null

    if RegisterNativeEvent(bj_MAX_PLAYER_SLOTS, eventId) then
        set t = GetNativeEventTrigger(eventId)
        loop
            call TriggerRegisterPlayerUnitEvent(t, Player(index), whichEvent, null)
            set index = index + 1
            exitwhen index == bj_MAX_PLAYER_SLOTS
        endloop
        set t = null
    endif

    call TriggerAddCondition(GetNativeEventTrigger(eventId), Condition(cb))
endfunction

function RegisterPlayerUnitEvent$SPECIFIC$ returns nothing
    local integer playerId = GetPlayerId(whichPlayer)
    local integer eventId = GetHandleId(whichEvent)

    if RegisterNativeEvent(playerId, eventId) then
        call TriggerRegisterPlayerUnitEvent(GetIndexNativeEventTrigger(playerId, eventId), whichPlayer, whichEvent, null)
    endif

    call TriggerAddCondition(GetIndexNativeEventTrigger(playerId, eventId), Condition(cb))
endfunction
//! endtextmacro

static if RPUE_VERSION_NEW then
    //! runtextmacro DEFINE_REGISTER_PLAYER_UNIT_EVENT("Any", " takes player whichPlayer, playerunitevent whichEvent, code cb")
else
    //! runtextmacro DEFINE_REGISTER_PLAYER_UNIT_EVENT("", "ForPlayer takes playerunitevent whichEvent, code cb, player whichPlayer")
endif

function GetPlayerUnitEventTrigger takes playerunitevent whichEvent returns trigger
    return GetNativeEventTrigger(GetHandleId(whichEvent))
endfunction

function GetPlayerUnitEventTriggerForPlayer takes player whichPlayer, playerunitevent whichEvent returns trigger
    return GetIndexNativeEventTrigger(GetPlayerId(whichPlayer), GetHandleId(whichEvent))
endfunction

endlibrary