/*****************************************************************************
*
*    InventoryEvent v1.0.1.5
*       by Bannar
*
*    For intuitive inventory event handling.
*
******************************************************************************
*
*    Requirements:
*
*       RegisterPlayerUnitEvent by Bannar
*          hiveworkshop.com/threads/snippet-registerevent-pack.250266/
*
******************************************************************************
*
*    Event API:
*
*       integer EVENT_INVENTORY_ITEM_MOVED
*       integer EVENT_INVENTORY_ITEM_USED
*
*       Use RegisterNativeEvent or RegisterIndexNativeEvent for event registration.
*       GetNativeEventTrigger and GetIndexNativeEventTrigger provide access to trigger handles.
*
*
*       function GetEventInventoryUnit takes nothing returns unit
*          Returns unit which manipulated event item.
*
*       function GetEventInventoryItem takes nothing returns item
*          Returns manupilated event item.
*
*       function GetEventInventorySlotFrom takes nothing returns integer
*          Returns slot index of manipulated item from which it was moved or used.
*
*       function GetEventInventorySlotTo takes nothing returns integer
*          Returns slot index of manipulated item to which it was moved.
*
*       function GetEventInventorySwapped takes nothing returns item
*          Returns item which was swapped with manipulated item on MOVED event if any.
*
*****************************************************************************/
library InventoryEvent requires RegisterPlayerUnitEvent, ExtensionMethods

globals
    integer EVENT_INVENTORY_ITEM_MOVED
    integer EVENT_INVENTORY_ITEM_USED
endglobals

globals
    private unit eventUnit = null
    private item eventItem = null
    private integer eventSlotFrom = -1
    private integer eventSlotTo = -1
endglobals

function GetEventInventoryUnit takes nothing returns unit
    return eventUnit
endfunction

function GetEventInventoryItem takes nothing returns item
    return eventItem
endfunction

function GetEventInventorySlotFrom takes nothing returns integer
    return eventSlotFrom
endfunction

function GetEventInventorySlotTo takes nothing returns integer
    return eventSlotTo
endfunction

function GetEventInventorySwapped takes nothing returns item
    return UnitItemInSlot(eventUnit, eventSlotTo)
endfunction

function GetInventoryEventTrigger takes integer whichEvent returns trigger
    debug call DisplayTimedTextFromPlayer(GetLocalPlayer(),0,0,60,"Function GetInventoryEventTrigger is obsolete, use GetNativeEventTrigger instead.")
    return GetNativeEventTrigger(whichEvent)
endfunction

function RegisterInventoryEvent takes code func, integer whichEvent returns nothing
    debug call DisplayTimedTextFromPlayer(GetLocalPlayer(),0,0,60,"Function RegisterInventoryEvent is obsolete, use RegisterNativeEvent instead.")
    call RegisterNativeEvent(whichEvent, func)
endfunction

private function FireEvent takes integer evt, unit u, item itm, integer slotFrom, integer slotTo returns nothing
    local unit prevUnit = eventUnit
    local item prevItem = eventItem
    local integer prevSlotFrom = eventSlotFrom
    local integer prevSlotTo = eventSlotTo

    set eventUnit = u
    set eventItem = itm
    set eventSlotFrom = slotFrom
    set eventSlotTo = slotTo

    call TriggerEvaluate(GetNativeEventTrigger(evt))
    call TriggerEvaluate(GetIndexNativeEventTrigger(GetPlayerId(GetOwningPlayer(u)), evt))

    set eventUnit = prevUnit
    set eventItem = prevItem
    set eventSlotFrom = prevSlotFrom
    set eventSlotTo = prevSlotTo

    set prevUnit = null
    set prevItem = null
endfunction

private function OnItemOrder takes nothing returns nothing
    local integer order = GetIssuedOrderId()
    local unit u = GetTriggerUnit()
    local item itm
    local integer slotFrom
    local integer slotTo

    if order >= 852002 and order <= 852007 then // between moveslot1 and moveslot6
        set itm = GetOrderTargetItem()
        set slotFrom = GetUnitItemSlot(u, itm)
        set slotTo = order - 852002 // moveslot1
        call FireEvent(EVENT_INVENTORY_ITEM_MOVED, u, itm, slotFrom, slotTo)
    else
        set slotFrom = order - 852008 //  useslot1
        set itm = UnitItemInSlot(u, slotFrom)
        call FireEvent(EVENT_INVENTORY_ITEM_USED, u, itm, slotFrom, -1)
    endif

    set u = null
    set itm = null
endfunction

private function OnAnyOrder takes nothing returns boolean
    local integer order = GetIssuedOrderId()
    if order >= 852002 and order <= 852013 then // between moveslot1 and useslot6
        call OnItemOrder()
    endif
    return false
endfunction

private module InventoryEventInit
    private static method onInit takes nothing returns nothing
        set EVENT_INVENTORY_ITEM_MOVED = CreateNativeEvent()
        set EVENT_INVENTORY_ITEM_USED = CreateNativeEvent()
        set MOVED = EVENT_INVENTORY_ITEM_MOVED
        set USED = EVENT_INVENTORY_ITEM_USED

        // MOVED is order of type TARGET_ORDER yet USED can be anyone of them
        call RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_ORDER, function OnAnyOrder)
        call RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, function OnAnyOrder)
        call RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER, function OnAnyOrder)
    endmethod
endmodule

struct InventoryEvent extends array
    // Events below are depreated in favor of EVENT_ alike globals
    readonly static integer MOVED
    readonly static integer USED

    implement InventoryEventInit
endstruct

endlibrary