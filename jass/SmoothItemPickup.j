/*****************************************************************************
*
*    SmoothItemPickup v1.0.1.5
*       by Bannar
*
*    Allows for item pickup during certain conditions even when unit inventory is full.
*
******************************************************************************
*
*    Requirements:
*
*       Table by Bribe
*          hiveworkshop.com/forums/jass-resources-412/snippet-new-table-188084/
*
*       InventoryEvent by Bannar
*          hiveworkshop.com/threads/snippet-inventoryevent.287084/
*
*       RegisterPlayerUnitEvent by Bannar
*          hiveworkshop.com/threads/snippet-registerevent-pack.250266/
*
*       SmoothItemPickup by Bannar
*          hiveworkshop.com/forums/jass-resources-412/...
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
*        |     method canPickup takes unit whichUnit, item whichItem returns boolean
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
library SmoothItemPickup requires Alloc, RegisterPlayerUnitEvent

globals
    private constant integer PICK_UP_RANGE = 150
    
    integer EVENT_ITEM_SMOOTH_PICKUP
endglobals

native UnitAlive takes unit u returns boolean

globals
    private IntegerList conditions
    private Table table = 0
    private timer periodic = CreateTimer()
    private unit eventUnit = null
    private item eventItem = null
endglobals

struct SmoothItemPickupPredicate extends array
    implement Alloc

    method canPickup takes unit whichUnit, item whichItem returns boolean
        return false
    endmethod

    static method create takes nothing returns thistype
        return allocate()
    endmethod

    method destroy takes nothing returns nothing
        call deallocate()
    endmethod
endstruct

module SmoothPickupPredicateModule
    private delegate SmoothItemPickupPredicate predicate

    static method create takes nothing returns thistype
        local thistype this = SmoothItemPickupPredicate.create()
        set predicate = this
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
    set eventUnit = u
    set eventItem = itm

    call TriggerEvaluate(GetNativeEventTrigger(EVENT_ITEM_SMOOTH_PICKUP))
    call TriggerEvaluate(GetIndexNativeEventTrigger(GetPlayerId(GetOwningPlayer(u)), EVENT_ITEM_SMOOTH_PICKUP))

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

private function OnNullTimer takes nothing returns nothing
    local timer t = GetExpiredTimer()
    local integer id = GetHandleId(t)

    call FireEvent(table.unit[id], table.item[-id])

    call table.remove(id)
    call table.remove(-id)
    call DestroyTimer(t)
    set t = null
endfunction

private module SmoothItemPickupInit
    static method onInit takes nothing returns nothing
        set EVENT_ITEM_SMOOTH_PICKUP = CreateNativeEvent()
        set table = Table.create()
        call RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, function thistype.onTargetOrder)
    endmethod
endmodule

private struct SmoothItemPickup extends array
    static integer count = 0
    thistype recycle
    thistype next
    thistype prev
    unit unit
    item itm
    real range

    method deallocate takes nothing returns nothing
        set recycle = thistype(0).recycle
        set thistype(0).recycle = this
        set next.prev = prev
        set prev.next = next

        if thistype(0).next == 0 then
            call PauseTimer(periodic)
        endif
    endmethod

    method destroy takes nothing returns nothing
        call table.remove(GetHandleId(unit))
        set unit = null
        set itm = null
        call deallocate()
    endmethod

    static method onCallback takes nothing returns nothing
        local thistype data = thistype(0).next

        loop
            exitwhen data == 0
            if not UnitAlive(data.unit) or GetUnitCurrentOrder(data.unit) != 851986 /*
            */ or data.itm == null or IsItemOwned(data.itm) then // order move
                call data.destroy()
            else
                if Test(data.unit, data.itm, data.range) then
                    call FireEvent(data.unit, data.itm)
                    call data.destroy()
                endif
            endif
            set data = data.next
        endloop
    endmethod

    static method allocate takes nothing returns thistype
        local thistype this = thistype(0).recycle
        if thistype(0).next == 0 then
            call TimerStart(periodic, 0.031250000, true, function thistype.onCallback)
        endif

        if this == 0 then
            set count = count + 1
            set this = count
        else
            set thistype(0).recycle = recycle
        endif

        set next = 0
        set prev = thistype(0).prev
        set thistype(0).prev.next = this
        set thistype(0).prev = this

        return this
    endmethod

    static method create takes unit u, real range returns thistype
        local thistype this = allocate()
        set this.unit = u
        set this.range = range
        set table[GetHandleId(u)] = this
        return this
    endmethod

    static method onTargetOrder takes nothing returns boolean
        local unit u = GetTriggerUnit()
        local item itm = GetOrderTargetItem()
        local SmoothItemPickup data
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

        if itm == null or IsItemPowerup(itm) or GetIssuedOrderId() != 851971 then // order smart
            return false
        endif

        set iter = conditions.first
        loop
            exitwhen iter == 0
            set condition = iter.data
            if condition.canPickup(u, itm) then
                set proceed = true
                exitwhen true
            endif
            set iter = iter.next
        endloop

        if not proceed then
            set u = null
            set itm = null
            return false
        endif

        set collision = BlzGetUnitCollisionSize(u)
        set range = (PICK_UP_RANGE + collision) * (PICK_UP_RANGE + collision)

        if Test(u, itm, range) then
            // Ensures order is finished before item is picked up.
            // Fixes the issue with unit moving towards the item location, rather than stopping
            set tmr = CreateTimer()
            set table.unit[GetHandleId(tmr)] = u
            set table.item[-GetHandleId(tmr)] = itm
            call TimerStart(tmr, 0.0, false, function OnNullTimer)
            set tmr = null
        else
            if not table.has(GetHandleId(u)) then
                set data = SmoothItemPickup.create(u, range)
            else
                set data = table[GetHandleId(u)]
            endif
            set data.itm = itm

            set angle = bj_RADTODEG * Atan2(GetUnitY(u) - GetItemY(itm), GetUnitX(u) - GetItemX(itm))
            set x = GetItemX(itm) + PICK_UP_RANGE * Cos(angle * bj_DEGTORAD)
            set y = GetItemY(itm) + PICK_UP_RANGE * Sin(angle * bj_DEGTORAD)
            set t = GetAnyPlayerUnitEventTrigger(EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER)
            call DisableTrigger(t)
            call IssuePointOrderById(u, 851986, x, y) // order move
            call EnableTrigger(t)
        endif

        set u = null
        set itm = null
        return false
    endmethod

    implement SmoothItemPickupInit
endstruct

endlibrary