/*****************************************************************************
*
*    SmoothItemPickup v1.0.1.8
*       by Bannar
*
*    Allows for item pickup despite unit inventory being full.
*
******************************************************************************
*
*    Requirements:
*
*       RegisterPlayerUnitEvent by Bannar
*          hiveworkshop.com/threads/snippet-registerevent-pack.250266/
*
*       ListT by Bannar
*          hiveworkshop.com/threads/containers-list-t.249011/
*
******************************************************************************
*
*    Event API:
*
*       integer EVENT_ITEM_SMOOTH_PICKUP
*
*       Use RegisterNativeEvent or RegisterIndexNativeEvent for event registration.
*       GetNativeEventTrigger and GetIndexNativeEventTrigger provide access to trigger handles.
*
*
*       function GetSmoothItemPickupUnit takes nothing returns unit
*          Returns unit attempting to pickup event item.
*
*       function GetSmoothItemPickupItem takes nothing returns item
*          Returns item that is being picked up.
*
******************************************************************************
*
*    Interface SmoothItemPickupPredicate:
*
*       method canPickup takes unit whichUnit, item whichItem returns boolean
*          Determinates whether unit can pickup specified item.
*
*       module SmoothPickupPredicateModule
*          Declares body for new predicate type.
*
*
*    Predicate implementation example:
*
*        | struct MyPredicate extends array
*        |     static method canPickup takes unit whichUnit, item whichItem returns boolean
*        |         return true
*        |     endmethod
*        |
*        |     implement SmoothPickupPredicateModule
*        | endstruct
*
******************************************************************************
*
*    Constants:
*
*       constant integer PICK_UP_RANGE = 150
*
*    Functions:
*
*       function AddSmoothItemPickupCondition takes SmoothItemPickupPredicate predicate returns nothing
*          Adds new condition for item to be picked up smoothly.
*
*       function RemoveSmoothItemPickupCondition takes SmoothItemPickupPredicate predicate returns nothing
*          Removes specified condition from predicate list.
*
*****************************************************************************/
library SmoothItemPickup requires /*
                         */ RegisterPlayerUnitEvent /*
                         */ ListT /*
                         */ ExtensionMethods

globals
    private constant integer PICK_UP_RANGE = 150
endglobals

globals
    integer EVENT_ITEM_SMOOTH_PICKUP
endglobals

native UnitAlive takes unit u returns boolean

globals
    private IntegerList conditions = 0
    private IntegerList ongoing = 0
    private Table table = 0
    private timer looper = CreateTimer()
    private unit eventUnit = null
    private item eventItem = null

    private unit argUnit = null
    private item argItem = null
endglobals

struct SmoothItemPickupPredicate extends array
    readonly trigger trigger
    implement Alloc

    static method canPickup takes unit whichUnit, item whichItem returns boolean
        return false
    endmethod

    static method create takes nothing returns thistype
        local thistype this = allocate()
        set trigger = CreateTrigger()
        return this
    endmethod

    method destroy takes nothing returns nothing
        call DestroyTrigger(trigger)
        set trigger = null
        call deallocate()
    endmethod
endstruct

module SmoothPickupPredicateModule
    private delegate SmoothItemPickupPredicate predicate

    private static method onInvoke takes nothing returns boolean
        return thistype.canPickup(argUnit, argItem)
    endmethod

    static method create takes nothing returns thistype
        local thistype this = SmoothItemPickupPredicate.create()
        set predicate = this
        call TriggerAddCondition(trigger, Condition(function thistype.onInvoke))
        return this
    endmethod

    method destroy takes nothing returns nothing
        call predicate.destroy()
    endmethod
endmodule

function GetSmoothItemPickupUnit takes nothing returns unit
    return eventUnit
endfunction

function GetSmoothItemPickupItem takes nothing returns item
    return eventItem
endfunction

function AddSmoothItemPickupCondition takes SmoothItemPickupPredicate predicate returns nothing
    if predicate != 0 then
        call conditions.push(predicate)
    endif
endfunction

function RemoveSmoothItemPickupCondition takes SmoothItemPickupPredicate predicate returns nothing
    if predicate != 0 then
        call conditions.remove(conditions.find(predicate))
    endif
endfunction

private function FireEvent takes unit u, item itm returns nothing
    local unit prevUnit = eventUnit
    local item prevItem = eventItem
    local integer playerId = GetPlayerId(GetOwningPlayer(u))

    set eventUnit = u
    set eventItem = itm

    call TriggerEvaluate(GetNativeEventTrigger(EVENT_ITEM_SMOOTH_PICKUP))
    if IsNativeEventRegistered(playerId, EVENT_ITEM_SMOOTH_PICKUP) then
        call TriggerEvaluate(GetIndexNativeEventTrigger(playerId, EVENT_ITEM_SMOOTH_PICKUP))
    endif

    set eventUnit = prevUnit
    set eventItem = prevItem
    set prevUnit = null
    set prevItem = null
endfunction

private function Test takes unit u, item itm, real range returns boolean
    local real dx
    local real dy

    if UnitHasItem(u, itm) then
        return true
    elseif IsItemOwned(itm) then
        return false
    endif

    set dx = GetItemX(itm) - GetUnitX(u)
    set dy = GetItemY(itm) - GetUnitY(u)
    // Assumes range is multipled to avoid invoking SquareRoot
    return (dx * dx + dy * dy) <= range
endfunction

private struct PeriodicData extends array
    unit unit
    item item
    real range

    implement Alloc

    method destroy takes nothing returns nothing
        call table.remove(GetHandleId(unit))
        set unit = null
        set item = null

        call ongoing.remove(ongoing.find(this))
        if ongoing.empty() then
            call PauseTimer(looper)
        endif

        call deallocate()
    endmethod

    static method create takes unit u, real range returns thistype
        local thistype this = allocate()

        call ongoing.push(this)
        set this.unit = u
        set this.range = range
        set table[GetHandleId(u)] = this

        return this
    endmethod
endstruct

private function OnCallback takes nothing returns nothing
    local IntegerListItem iter = ongoing.first
    local PeriodicData data

    loop
        exitwhen iter == 0
        set data = iter.data
        if not UnitAlive(data.unit) or GetUnitCurrentOrder(data.unit) != 851986 /*
        */ or data.item == null or IsItemOwned(data.item) then // order move
            call data.destroy()
        else
            if Test(data.unit, data.item, data.range) then
                call FireEvent(data.unit, data.item)
                call data.destroy()
            endif
        endif
        set iter = iter.next
    endloop
endfunction

private function OnNullTimer takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer id = GetHandleId(t)

    call FireEvent(table.unit[id], table.item[-id])

    call table.unit.remove(id)
    call table.item.remove(-id)
    call DestroyTimer(t)
    set t = null
endfunction

private function OnTargetOrder takes nothing returns nothing
    local PeriodicData data
    local boolean proceed = false
    local IntegerListItem iter
    local SmoothItemPickupPredicate condition
    local real collision
    local real range
    local timer tmr
    local real angle
    local real x
    local real y
    local trigger t
    set argUnit = GetTriggerUnit()
    set argItem = GetOrderTargetItem()

    if not IsUnitInventoryFull(argUnit) or GetIssuedOrderId() != 851971 then // order smart
        return
    elseif argItem == null or IsItemPowerup(argItem) then
        return
    endif

    set iter = conditions.first
    loop
        exitwhen iter == 0
        set condition = iter.data
        if TriggerEvaluate(condition.trigger) then
            set proceed = true
            exitwhen true
        endif
        set iter = iter.next
    endloop

    if not proceed then
        return
    endif

    set collision = BlzGetUnitCollisionSize(argUnit)
    set range = (PICK_UP_RANGE + collision) * (PICK_UP_RANGE + collision)

    if Test(argUnit, argItem, range) then
        // Ensures order is finished before item is picked up.
        // Fixes the issue with unit moving towards the item location, rather than stopping
        set tmr = CreateTimer()
        set table.unit[GetHandleId(tmr)] = argUnit
        set table.item[-GetHandleId(tmr)] = argItem
        call TimerStart(tmr, 0.0, false, function OnNullTimer)
        set tmr = null
    else // if unit is not nearby target item, issue artificial move order
        if not table.has(GetHandleId(argUnit)) then
            if ongoing.empty() then
                call TimerStart(looper, 0.031250000, true, function OnCallback)
            endif
            set data = PeriodicData.create(argUnit, range)
        else
            set data = table[GetHandleId(argUnit)]
        endif
        set data.item = argItem

        set angle = bj_RADTODEG * Atan2(GetUnitY(argUnit) - GetItemY(argItem), GetUnitX(argUnit) - GetItemX(argItem))
        set x = GetItemX(argItem) + PICK_UP_RANGE * Cos(angle * bj_DEGTORAD)
        set y = GetItemY(argItem) + PICK_UP_RANGE * Sin(angle * bj_DEGTORAD)
        set t = GetAnyPlayerUnitEventTrigger(EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER)
        call DisableTrigger(t)
        call IssuePointOrderById(argUnit, 851986, x, y) // order move
        call EnableTrigger(t)
    endif
endfunction

private module SmoothItemPickupInit
    private static method onInit takes nothing returns nothing
        set EVENT_ITEM_SMOOTH_PICKUP = CreateNativeEvent()
        set conditions = IntegerList.create()
        set ongoing = IntegerList.create()
        set table = Table.create()
        call RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, function OnTargetOrder)
    endmethod
endmodule

private struct SmoothItemPickup extends array
    implement SmoothItemPickupInit
endstruct

endlibrary