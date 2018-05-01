/*****************************************************************************
*
*    RegisterNativeEvent v1.1.0.0
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
*    Functions:
*
*       function IsNativeEventRegistered takes integer whichIndex, integer eventId returns boolean
*          whether index whichIndex has already been attached to event with id eventId
*
*       function RegisterNativeEvent takes integer whichIndex, integer eventId returns boolean
*          attaches index whichIndex to eventId if it hasn't been attached already and creates new trigger handle if needed
*
*       function GetIndexNativeEventTrigger takes integer whichIndex, integer eventId returns trigger
*          retrieves trigger handle for event with id eventId specific to provided index whichIndex
*
*       function GetNativeEventTrigger takes integer eventId returns trigger
*          retrieves trigger handle for event with id eventId
*
*       function CreateNativeEvent takes nothing returns integer
*          returns unique id for new event
*
*****************************************************************************/
library RegisterNativeEvent uses optional Table

globals
    private integer index = 500 // 0-499 reserved for native events
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

function IsNativeEventRegistered takes integer whichIndex, integer eventId returns boolean
static if LIBRARY_Table then
    return NativeEvent.table[eventId].has(whichIndex)
else
    return HaveSavedHandle(NativeEvent.table, eventId, whichIndex)
endif
endfunction

function RegisterNativeEvent takes integer whichIndex, integer eventId returns boolean
    if not IsNativeEventRegistered(whichIndex, eventId) then
static if LIBRARY_Table then
        set NativeEvent.table[eventId].trigger[whichIndex] = CreateTrigger()
else
        call SaveTriggerHandle(NativeEvent.table, eventId, whichIndex, CreateTrigger())
endif
        return true
    endif
    return false
endfunction

function GetIndexNativeEventTrigger takes integer whichIndex, integer eventId returns trigger
static if LIBRARY_Table then
    return NativeEvent.table[eventId].trigger[whichIndex]
else
    return LoadTriggerHandle(NativeEvent.table, eventId, whichIndex)
endif
endfunction

function GetNativeEventTrigger takes integer eventId returns trigger
    return GetIndexNativeEventTrigger(bj_MAX_PLAYER_SLOTS, eventId)
endfunction

function CreateNativeEvent takes nothing returns integer
    local integer eventId = index
    call RegisterNativeEvent(bj_MAX_PLAYER_SLOTS, eventId)
    set index = index + 1
    return eventId
endfunction

endlibrary