/*****************************************************************************
*
*    RegisterPlayerEvent v1.0.2.2
*       by Bannar
*
*    Register version of TriggerRegisterPlayerEvent.
*
******************************************************************************
*
*    Requirements:
*
*       RegisterNativeEvent by Bannar
*          hiveworkshop.com/threads/snippet-registerevent-pack.250266/
*
******************************************************************************
*
*    Functions:
*
*       function GetAnyPlayerEventTrigger takes playerevent whichEvent returns trigger
*          Retrieves trigger handle for playerevent whichEvent.
*
*       function GetPlayerEventTrigger takes player whichPlayer, playerevent whichEvent returns trigger
*          Retrieves trigger handle for playerevent whichEvent specific to player whichPlayer.
*
*       function RegisterAnyPlayerEvent takes playerevent whichEvent, code func returns nothing
*          Registers generic playerevent whichEvent adding code func as callback.
*
*       function RegisterPlayerEvent takes player whichPlayer, playerevent whichEvent, code func returns nothing
*          Registers playerevent whichEvent for player whichPlayer adding code func as callback.
*
*****************************************************************************/
library RegisterPlayerEvent requires RegisterNativeEvent

function GetAnyPlayerEventTrigger takes playerevent whichEvent returns trigger
    return GetNativeEventTrigger(GetHandleId(whichEvent))
endfunction

function GetPlayerEventTrigger takes player whichPlayer, playerevent whichEvent returns trigger
    return GetIndexNativeEventTrigger(GetPlayerId(whichPlayer), GetHandleId(whichEvent))
endfunction

function RegisterAnyPlayerEvent takes playerevent whichEvent, code func returns nothing
    local integer eventId = GetHandleId(whichEvent)
    local integer index = 0
    local trigger t = null

    if RegisterNativeEventTrigger(bj_MAX_PLAYER_SLOTS, eventId) then
        set t = GetNativeEventTrigger(eventId)
        loop
            call TriggerRegisterPlayerEvent(t, Player(index), whichEvent)
            set index = index + 1
            exitwhen index == bj_MAX_PLAYER_SLOTS
        endloop
        set t = null
    endif

    call RegisterNativeEvent(eventId, func)
endfunction

function RegisterPlayerEvent takes player whichPlayer, playerevent whichEvent, code func returns nothing
    local integer playerId = GetPlayerId(whichPlayer)
    local integer eventId = GetHandleId(whichEvent)

    if RegisterNativeEventTrigger(playerId, eventId) then
        call TriggerRegisterPlayerEvent(GetIndexNativeEventTrigger(playerId, eventId), whichPlayer, whichEvent)
    endif

    call RegisterIndexNativeEvent(playerId, eventId, func)
endfunction

endlibrary