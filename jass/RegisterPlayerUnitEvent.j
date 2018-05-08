/*****************************************************************************
*
*    RegisterPlayerUnitEvent v1.0.3.1
*       by Bannar
*
*    Register version of TriggerRegisterPlayerUnitEvent.
*
*    Special thanks to Magtheridon96, Bribe, azlier and BBQ for the original library version.
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
*    Functions:
*
*       function GetAnyPlayerUnitEventTrigger takes playerunitevent whichEvent returns trigger
*          Retrieves trigger handle for playerunitevent whichEvent.
*
*       function GetPlayerUnitEventTrigger takes player whichPlayer, playerunitevent whichEvent returns trigger
*          Retrieves trigger handle for playerunitevent whichEvent specific to player whichPlayer.
*
*       function RegisterAnyPlayerUnitEvent takes playerunitevent whichEvent, code func returns nothing
*          Registers generic playerunitevent whichEvent adding code func as callback.
*
*       function RegisterPlayerUnitEvent takes player whichPlayer, playerunitevent whichEvent, code func returns nothing
*          Registers playerunitevent whichEvent for player whichPlayer adding code func as callback.
*
*****************************************************************************/
library RegisterPlayerUnitEvent requires RegisterNativeEvent

function GetAnyPlayerUnitEventTrigger takes playerunitevent whichEvent returns trigger
    return GetNativeEventTrigger(GetHandleId(whichEvent))
endfunction

function GetPlayerUnitEventTrigger takes player whichPlayer, playerunitevent whichEvent returns trigger
    return GetIndexNativeEventTrigger(GetPlayerId(whichPlayer), GetHandleId(whichEvent))
endfunction

function RegisterAnyPlayerUnitEvent takes playerunitevent whichEvent, code func returns nothing
    local integer eventId = GetHandleId(whichEvent)
    local integer index = 0
    local trigger t = null

    if RegisterNativeEventTrigger(bj_MAX_PLAYER_SLOTS, eventId) then
        set t = GetNativeEventTrigger(eventId)
        loop
            call TriggerRegisterPlayerUnitEvent(t, Player(index), whichEvent, null)
            set index = index + 1
            exitwhen index == bj_MAX_PLAYER_SLOTS
        endloop
        set t = null
    endif

    call RegisterNativeEvent(eventId, func)
endfunction

function RegisterPlayerUnitEvent takes player whichPlayer, playerunitevent whichEvent, code func returns nothing
    local integer playerId = GetPlayerId(whichPlayer)
    local integer eventId = GetHandleId(whichEvent)

    if RegisterNativeEventTrigger(playerId, eventId) then
        call TriggerRegisterPlayerUnitEvent(GetIndexNativeEventTrigger(playerId, eventId), whichPlayer, whichEvent, null)
    endif

    call RegisterIndexNativeEvent(playerId, eventId, func)
endfunction

endlibrary