/*****************************************************************************
*
*    RegisterUnitEvent v1.0.1.0
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
*       function GetUnitEventTrigger takes unitevent whichEvent returns trigger
*          Retrieves trigger handle for unitevent whichEvent.
*
*       function RegisterUnitEvent takes unit whichUnit, unitevent whichEvent, code func returns nothing
*          Registers unitevent whichEvent for unit whichUnit adding code func as callback.
*
*****************************************************************************/
library RegisterUnitEvent requires RegisterNativeEvent

function GetUnitEventTrigger takes unitevent whichEvent returns trigger
    return GetNativeEventTrigger(GetHandleId(whichEvent))
endfunction

function RegisterUnitEvent takes unit whichUnit, unitevent whichEvent, code func returns nothing
    local integer unitId = GetHandleId(whichUnit)
    local integer eventId = GetHandleId(whichEvent)

    if RegisterNativeEventTrigger(unitId, eventId) then
        call TriggerRegisterUnitEvent(GetIndexNativeEventTrigger(unitId, eventId), whichUnit, whichEvent)
    endif

    call TriggerAddCondition(GetIndexNativeEventTrigger(unitId, eventId), Condition(func))
endfunction

endlibrary