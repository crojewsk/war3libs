/*****************************************************************************
*
*    RegisterGameEvent v1.0.0.3
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
*       function RegisterGameEvent takes gameevent whichEvent, code cb returns nothing
*          registers generic gameevent whichEvent adding code cb as callback
*
*       function GetGameEventTrigger takes gameevent whichEvent returns trigger
*          retrieves trigger handle for gameevent whichEvent
*
*****************************************************************************/
library RegisterGameEvent requires RegisterNativeEvent

function RegisterGameEvent takes gameevent whichEvent, code cb returns nothing
    local integer eventId = GetHandleId(whichEvent)

    if RegisterNativeEvent(bj_MAX_PLAYER_SLOTS, eventId) then
        call TriggerRegisterGameEvent(GetNativeEventTrigger(eventId), whichEvent)
    endif

    call TriggerAddCondition(GetNativeEventTrigger(eventId), Condition(cb))
endfunction

function GetGameEventTrigger takes gameevent whichEvent returns trigger
    return GetNativeEventTrigger(GetHandleId(whichEvent))
endfunction

endlibrary