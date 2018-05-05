/*****************************************************************************
*
*    InventoryEvent v1.0.0.0
*       by Bannar
*
*    For intuitive inventory event handling.
*
******************************************************************************
*
*    Optional requirements:
*
*       RegisterPlayerUnitEvent by Bannar
*          hiveworkshop.com/forums/submissions-414/snippet-registerevent-pack-250266/
*
*       OrderEvent by Bribe
*          hiveworkshop.com/forums/jass-resources-412/snippet-order-event-190871/
*
******************************************************************************
*
*    Functions:
*
*       function GetEventInventoryUnit takes nothing returns unit
*          returns unit which manipulated event item
*
*       function GetEventInventoryItem takes nothing returns item
*          returns manupilated event item
*
*       function GetEventInventorySlotFrom takes nothing returns integer
*          returns slot index of manipulated item from which it was moved or used
*
*       function GetEventInventorySlotTo takes nothing returns integer
*          returns slot index of manipulated item to which it was moved
*
*       function GetEventInventorySwapped takes nothing returns item
*          returns item which was swapped with manipulated item on MOVED event if any
*
*       function GetUnitItemSlot takes unit u, item it returns integer
*          retrieves item index slot if any for item owning unit u
*
*       function RegisterInventoryEvent takes code cb, integer ev returns nothing
*          registers new event handler cb for inventory event ev
*
*       function TriggerRegisterInventoryEvent takes trigger t, integer ev returns nothing
*          registers event ev for trigger t
*
*       function GetInventoryEventTrigger takes integer whichEvent returns trigger
*          retrieves trigger handle for event with id whichEvent
*
******************************************************************************
*
*      Events that can be used:
*
*         integer InventoryEvent.MOVED
*         integer InventoryEvent.USED
*
*****************************************************************************/

library InventoryEvent requires /*
                     */ optional RegisterPlayerUnitEvent /*
                     */ optional OrderEvent

globals
   private unit eventUnit = null
   private item eventItem = null
   private integer eventSlotFrom = -1
   private integer eventSlotTo = -1

   private trigger array triggers
   private real caller = 0
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

function GetUnitItemSlot takes unit u, item it returns integer
   local integer i = 0
   local integer size = UnitInventorySize(u)

   if ( UnitHasItem(u, it) ) then
       loop
           if ( UnitItemInSlot(u, i) == it ) then
               return i
           endif
           set i = i+1
           exitwhen i == size
       endloop
   endif

   return -1 // NOT_FOUND
endfunction

private function RegisterAnyUnitEvent takes playerunitevent e, code c returns nothing
   static if LIBRARY_RegisterPlayerUnitEvent then
       static if RPUE_VERSION_NEW then
           call RegisterAnyPlayerUnitEvent(e, c)
       else
           call RegisterPlayerUnitEvent(e, c)
       endif
   else
       local trigger t = CreateTrigger()
       call TriggerRegisterAnyUnitEventBJ(t, e)
       call TriggerAddCondition(t, Condition(c))
       set t = null
   endif
endfunction

private module InventoryEventInit
   private static method onInit takes nothing returns nothing
       static if LIBRARY_OrderEvent then
           local integer i = 852002 // range from 852002 to 852013
           loop
               call RegisterOrderEvent(i, function thistype.onItemOrder)
               set i = i+1
               exitwhen i > 852013
           endloop
       else // MOVED is order of type TARGET_ORDER yet USED can be anyone of them
           call RegisterAnyUnitEvent(EVENT_PLAYER_UNIT_ISSUED_ORDER, function thistype.onAnyOrder)
           call RegisterAnyUnitEvent(EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, function thistype.onAnyOrder)
           call RegisterAnyUnitEvent(EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER, function thistype.onAnyOrder)
       endif

       set triggers[MOVED] = CreateTrigger()
       set triggers[USED] = CreateTrigger()
       call TriggerRegisterVariableEvent(triggers[MOVED], SCOPE_PRIVATE + "caller", EQUAL, MOVED)
       call TriggerRegisterVariableEvent(triggers[USED], SCOPE_PRIVATE + "caller", EQUAL, USED)
   endmethod
endmodule

struct InventoryEvent extends array
   readonly static integer MOVED = 1
   readonly static integer USED = 2

   private static method fire takes integer ev, unit u, item it, integer slotFrom, integer slotTo returns nothing
       local unit prevUnit = eventUnit
       local item prevItem = eventItem
       local integer prevSlotFrom = eventSlotFrom
       local integer prevSlotTo = eventSlotTo

       set eventUnit = u
       set eventItem = it
       set eventSlotFrom = slotFrom
       set eventSlotTo = slotTo

       set caller = ev
       set caller = 0

       set eventUnit = prevUnit
       set eventItem = prevItem
       set eventSlotFrom = prevSlotFrom
       set eventSlotTo = prevSlotTo

       set prevUnit = null
       set prevItem = null
   endmethod

   private static method onItemOrder takes nothing returns nothing
       local integer order = GetIssuedOrderId()
       local unit u = GetTriggerUnit()
       local item it
       local integer slot
       local integer slot2

       if ( order >= 852002 and order <= 852007 ) then
           set it = GetOrderTargetItem()
           set slot = GetUnitItemSlot(u, it)
           set slot2 = order - 852002
           call fire(MOVED, u, it, slot, slot2)
       else
           set slot = order - 852008
           set it = UnitItemInSlot(u, slot)
           call fire(USED, u, it, slot, -1)
       endif

       set u = null
       set it = null
   endmethod

static if not LIBRARY_OrderEvent then
   private static method onAnyOrder takes nothing returns boolean
       local integer order = GetIssuedOrderId()
       if ( order >= 852002 and order <= 852013 ) then
           call onItemOrder()
       endif
       return false
   endmethod
endif

   implement InventoryEventInit
endstruct

function RegisterInventoryEvent takes code c, integer ev returns nothing
   call TriggerAddCondition(triggers[ev], Condition(c))
endfunction

function TriggerRegisterInventoryEvent takes trigger t, integer ev returns nothing
   call TriggerRegisterVariableEvent(t, SCOPE_PRIVATE + "caller", EQUAL, ev)
endfunction

function GetInventoryEventTrigger takes integer whichEvent returns trigger
   return triggers[whichEvent]
endfunction

endlibrary