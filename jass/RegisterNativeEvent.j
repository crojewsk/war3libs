/*****************************************************************************
*
*    RegisterNativeEvent v1.1.1.0
*       by Bannar
*
*    Storage of trigger handles for native events.
*
******************************************************************************
*
*    Optional requirements:
*
*       Table by Bribe
*          hiveworkshop.com/forums/jass-resources-412/snippet-new-table-188084/
*
******************************************************************************
*
*    Important:
*
*       Avoid using TriggerSleepAction within functions registered.
*       Destroy native event trigger on your own responsibility.
*
******************************************************************************
*
*    Core:
*
*       function IsNativeEventRegistered takes integer whichIndex, integer whichEvent returns boolean
*          Whether index whichIndex has already been attached to event whichEvent.
*
*       function RegisterNativeEvent takes integer whichIndex, integer eventId returns boolean
*          Registers whichIndex within whichEvent scope and assigns new trigger handle for it.
*
*       function GetIndexNativeEventTrigger takes integer whichIndex, integer whichEvent returns trigger
*          Retrieves trigger handle for event whichEvent specific to provided index whichIndex.
*
*       function GetNativeEventTrigger takes integer whichEvent returns trigger
*          Retrieves trigger handle for event whichEvent.
*
*
*    Custom events:
*
*       function CreateNativeEvent takes nothing returns integer
*          Returns unique id for new event and registers it with RegisterNativeEvent.
*
*       function GetPlayerNativeEventTrigger takes player whichPlayer, integer whichEvent returns trigger
*          Returns trigger handle assigned for event whichEvent specific to player whichPlayer.
*
*       function RegisterAnyPlayerNativeEvent takes integer whichEvent, code func returns nothing
*          Registers new event handler func for specified event whichEvent.
*
*       function RegisterPlayerNativeEvent takes player whichPlayer, integer whichEvent, code func returns nothing
*          Registers new event handler func for event whichEvent specific to player whichPlayer.
*
*****************************************************************************/
library RegisterNativeEvent uses optional Table

globals
    private integer eventIndex = 500 // 0-499 reserved for native events
endglobals

private module NativeEventInit
    private static method onInit takes nothing returns nothing
static if LIBRARY_Table then
        set table = TableArray[0x2000]
endif
    endmethod
endmodule

private struct NativeEvent extends array
static if LIBRARY_Table then
    static TableArray table
else
    static hashtable table = InitHashtable()
endif
    implement NativeEventInit
endstruct

function IsNativeEventRegistered takes integer whichIndex, integer whichEvent returns boolean
static if LIBRARY_Table then
    return NativeEvent.table[whichEvent].has(whichIndex)
else
    return HaveSavedHandle(NativeEvent.table, whichEvent, whichIndex)
endif
endfunction

function RegisterNativeEvent takes integer whichIndex, integer whichEvent returns boolean
    if not IsNativeEventRegistered(whichIndex, whichEvent) then
static if LIBRARY_Table then
        set NativeEvent.table[whichEvent].trigger[whichIndex] = CreateTrigger()
else
        call SaveTriggerHandle(NativeEvent.table, whichEvent, whichIndex, CreateTrigger())
endif
        return true
    endif
    return false
endfunction

function GetIndexNativeEventTrigger takes integer whichIndex, integer whichEvent returns trigger
static if LIBRARY_Table then
    return NativeEvent.table[whichEvent].trigger[whichIndex]
else
    return LoadTriggerHandle(NativeEvent.table, whichEvent, whichIndex)
endif
endfunction

function GetNativeEventTrigger takes integer whichEvent returns trigger
    return GetIndexNativeEventTrigger(bj_MAX_PLAYER_SLOTS, whichEvent)
endfunction

function CreateNativeEvent takes nothing returns integer
    local integer eventId = eventIndex
    call RegisterNativeEvent(bj_MAX_PLAYER_SLOTS, eventId)
    set eventIndex = eventIndex + 1
    return eventId
endfunction

function GetPlayerNativeEventTrigger takes player whichPlayer, integer whichEvent returns trigger
    return GetIndexNativeEventTrigger(GetPlayerId(whichPlayer), whichEvent)
endfunction

function RegisterAnyPlayerNativeEvent takes integer whichEvent, code func returns nothing
    call TriggerAddCondition(GetNativeEventTrigger(whichEvent), Condition(func))
endfunction

function RegisterPlayerNativeEvent takes player whichPlayer, integer whichEvent, code func returns nothing
    call RegisterNativeEvent(GetPlayerId(whichPlayer), whichEvent)
    call TriggerAddCondition(GetPlayerNativeEventTrigger(whichPlayer, whichEvent), Condition(func))
endfunction

endlibrary