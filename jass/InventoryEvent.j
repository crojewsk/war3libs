/*****************************************************************************
*
*    InventoryEvent v1.0.1.7
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
*       integer EVENT_ITEM_INVENTORY_MOVE
*       integer EVENT_ITEM_INVENTORY_USE
*
*       Use RegisterNativeEvent or RegisterIndexNativeEvent for event registration.
*       GetNativeEventTrigger and GetIndexNativeEventTrigger provide access to trigger handles.
*
*
*       function GetInventoryManipulatingUnit takes nothing returns unit
*          Returns unit which manipulated event item.
*
*       function GetInventoryManipulatedItem takes nothing returns item
*          Returns manupilated event item.
*
*       function GetInventorySlotFrom takes nothing returns integer
*          Returns slot index of manipulated item from which it was moved or used.
*
*       function GetInventorySlotTo takes nothing returns integer
*          Returns slot index of manipulated item to which it was moved.
*
*       function GetInventorySwappedItem takes nothing returns item
*          Returns item which manipulated item switched position with if any.
*
*****************************************************************************/
library InventoryEvent requires RegisterPlayerUnitEvent, ExtensionMethods

globals
    integer EVENT_ITEM_INVENTORY_MOVE
    integer EVENT_ITEM_INVENTORY_USE
endglobals

globals
    private unit eventUnit = null
    private item eventItem = null
    private integer eventSlotFrom = -1
    private integer eventSlotTo = -1
endglobals

function GetInventoryManipulatingUnit takes nothing returns unit
    return eventUnit
endfunction

function GetInventoryManipulatedItem takes nothing returns item
    return eventItem
endfunction

function GetInventorySlotFrom takes nothing returns integer
    return eventSlotFrom
endfunction

function GetInventorySlotTo takes nothing returns integer
    return eventSlotTo
endfunction

function GetInventorySwappedItem takes nothing returns item
    return UnitItemInSlot(eventUnit, eventSlotTo)
endfunction

function GetEventInventoryUnit takes nothing returns unit
    debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,60,"Function GetEventInventoryUnit is obsolete, use GetInventoryManipulatingUnit instead.")
    return GetInventoryManipulatingUnit()
endfunction

function GetEventInventoryItem takes nothing returns item
    debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,60,"Function GetEventInventoryItem is obsolete, use GetInventoryManipulatedItem instead.")
    return GetInventoryManipulatedItem()
endfunction

function GetEventInventorySlotFrom takes nothing returns integer
    debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,60,"Function GetEventInventorySlotFrom is obsolete, use GetInventorySlotFrom instead.")
    return GetInventorySlotFrom()
endfunction

function GetEventInventorySlotTo takes nothing returns integer
    debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,60,"Function GetEventInventorySlotTo is obsolete, use GetInventorySlotTo instead.")
    return GetInventorySlotTo()
endfunction

function GetEventInventorySwapped takes nothing returns item
    debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,60,"Function GetEventInventorySwapped is obsolete, use GetInventorySwappedItem instead.")
    return GetInventorySwappedItem()
endfunction

function GetInventoryEventTrigger takes integer whichEvent returns trigger
    debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,60,"Function GetInventoryEventTrigger is obsolete, use GetNativeEventTrigger instead.")
    return GetNativeEventTrigger(whichEvent)
endfunction

function RegisterInventoryEvent takes code func, integer whichEvent returns nothing
    debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,60,"Function RegisterInventoryEvent is obsolete, use RegisterNativeEvent instead.")
    call RegisterNativeEvent(whichEvent, func)
endfunction

private function FireEvent takes integer evt, unit u, item itm, integer slotFrom, integer slotTo returns nothing
    local unit prevUnit = eventUnit
    local item prevItem = eventItem
    local integer prevSlotFrom = eventSlotFrom
    local integer prevSlotTo = eventSlotTo
    local integer playerId = GetPlayerId(GetOwningPlayer(u))

    set eventUnit = u
    set eventItem = itm
    set eventSlotFrom = slotFrom
    set eventSlotTo = slotTo

    call TriggerEvaluate(GetNativeEventTrigger(evt))
    if IsNativeEventRegistered(playerId, evt) then
        call TriggerEvaluate(GetIndexNativeEventTrigger(playerId, evt))
    endif

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
        call FireEvent(EVENT_ITEM_INVENTORY_MOVE, u, itm, slotFrom, slotTo)
    else
        set slotFrom = order - 852008 //  useslot1
        set itm = UnitItemInSlot(u, slotFrom)
        call FireEvent(EVENT_ITEM_INVENTORY_USE, u, itm, slotFrom, -1)
    endif

    set u = null
    set itm = null
endfunction

private function OnAnyOrder takes nothing returns nothing
    local integer order = GetIssuedOrderId()
    if order >= 852002 and order <= 852013 then // between moveslot1 and useslot6
        call OnItemOrder()
    endif
endfunction

private module InventoryEventInit
    private static method onInit takes nothing returns nothing
        set EVENT_ITEM_INVENTORY_MOVE = CreateNativeEvent()
        set EVENT_ITEM_INVENTORY_USE = CreateNativeEvent()
        set MOVED = EVENT_ITEM_INVENTORY_MOVE
        set USED = EVENT_ITEM_INVENTORY_USE

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