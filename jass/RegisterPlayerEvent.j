/*****************************************************************************
*
*    RegisterPlayerEvent v1.0.1.1
*       by Bannar
*
*    Register version of TriggerRegisterPlayerEvent.
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
*       function RegisterAnyPlayerEvent takes playerevent whichEvent, code cb returns nothing
*          registers generic playerevent whichEvent adding code cb as callback
*
*       function RegisterPlayerEvent takes player whichPlayer, playerevent whichEvent, code cb returns nothing
*          registers playerevent whichEvent for player whichPlayer adding code cb as callback
*
*       function GetPlayerEventTrigger takes playerevent whichEvent returns trigger
*          retrieves trigger handle for playerevent whichEvent
*
*       function GetPlayerEventTriggerForPlayer takes player whichPlayer, playerevent whichEvent returns trigger
*          retrieves trigger handle for playerevent whichEvent specific to player whichPlayer
*
*****************************************************************************/
library RegisterPlayerEvent requires RegisterNativeEvent

function RegisterAnyPlayerEvent takes playerevent whichEvent, code cb returns nothing
    local integer eventId = GetHandleId(whichEvent)
    local integer index = 0
    local trigger t = null

    if RegisterNativeEvent(bj_MAX_PLAYER_SLOTS, eventId) then
        set t = GetNativeEventTrigger(eventId)
        loop
            call TriggerRegisterPlayerEvent(t, Player(index), whichEvent)
            set index = index + 1
            exitwhen index == bj_MAX_PLAYER_SLOTS
        endloop
        set t = null
    endif

    call TriggerAddCondition(GetNativeEventTrigger(eventId), Condition(cb))
endfunction

function RegisterPlayerEvent takes player whichPlayer, playerevent whichEvent, code cb returns nothing
    local integer playerId = GetPlayerId(whichPlayer)
    local integer eventId = GetHandleId(whichEvent)

    if RegisterNativeEvent(playerId, eventId) then
        call TriggerRegisterPlayerEvent(GetIndexNativeEventTrigger(playerId, eventId), whichPlayer, whichEvent)
    endif

    call TriggerAddCondition(GetIndexNativeEventTrigger(playerId, eventId), Condition(cb))
endfunction

function GetPlayerEventTrigger takes playerevent whichEvent returns trigger
    return GetNativeEventTrigger(GetHandleId(whichEvent))
endfunction

function GetPlayerEventTriggerForPlayer takes player whichPlayer, playerevent whichEvent returns trigger
    return GetIndexNativeEventTrigger(GetPlayerId(whichPlayer), GetHandleId(whichEvent))
endfunction

endlibrary