/*****************************************************************************
*
*    RegisterGameEvent v1.0.0.4
*       by Bannar
*
*    Register version of TriggerRegisterGameEvent.
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
*       function GetGameEventTrigger takes gameevent whichEvent returns trigger
*          Retrieves trigger handle for gameevent whichEvent.
*
*       function RegisterGameEvent takes gameevent whichEvent, code func returns nothing
*          Registers generic gameevent whichEvent adding code func as callback.
*
*****************************************************************************/
library RegisterGameEvent requires RegisterNativeEvent

function GetGameEventTrigger takes gameevent whichEvent returns trigger
    return GetNativeEventTrigger(GetHandleId(whichEvent))
endfunction

function RegisterGameEvent takes gameevent whichEvent, code func returns nothing
    local integer eventId = GetHandleId(whichEvent)

    if RegisterNativeEventTrigger(bj_MAX_PLAYER_SLOTS, eventId) then
        call TriggerRegisterGameEvent(GetNativeEventTrigger(eventId), whichEvent)
    endif

    call RegisterAnyPlayerNativeEvent(eventId, func)
endfunction

endlibrary