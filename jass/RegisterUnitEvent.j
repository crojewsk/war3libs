/*****************************************************************************
*
*    RegisterUnitEvent v1.0.0.1
*       by Bannar
*
*    Register version of TriggerRegisterUnitEvent.
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
*       function RegisterUnitEvent takes unit whichUnit, unitevent whichEvent, code cb returns nothing
*          registers unitevent whichEvent for unit whichUnit adding code cb as callback
*
*       function GetUnitEventTrigger takes unitevent whichEvent returns trigger
*          retrieves trigger handle for unitevent whichEvent
*
*****************************************************************************/
library RegisterUnitEvent requires RegisterNativeEvent

function RegisterUnitEvent takes unit whichUnit, unitevent whichEvent, code cb returns nothing
    local integer eventId = GetHandleId(whichEvent)

    if RegisterNativeEvent(GetHandleId(whichUnit), eventId) then
        call TriggerRegisterUnitEvent(GetNativeEventTrigger(eventId), whichUnit, whichEvent)
    endif

    call TriggerAddCondition(GetNativeEventTrigger(eventId), Condition(cb))
endfunction

function GetUnitEventTrigger takes unitevent whichEvent returns trigger
    return GetNativeEventTrigger(GetHandleId(whichEvent))
endfunction

endlibrary