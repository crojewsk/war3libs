/*****************************************************************************
*
*    StackNSplit v1.1.1.5
*       by Bannar
*
*    Easy item charges stacking and splitting.
*
*    Thanks to Dangerb0y for original system.
*    Container idea provided by Spinnaker.
*
******************************************************************************
*
*    Requirements:
*
*       ListT by Bannar
*          hiveworkshop.com/threads/containers-list-t.249011/
*
*       InventoryEvent by Bannar
*          hiveworkshop.com/threads/snippet-inventoryevent.287084/
*
*       RegisterPlayerUnitEvent by Bannar
*          hiveworkshop.com/threads/snippet-registerevent-pack.250266/
*
*
*    Optional requirement:
*
*       SmoothItemPickup by Bannar
*          hiveworkshop.com/threads/...
*
******************************************************************************
*
*    Event API:
*
*       integer EVENT_ITEM_CHARGES_ADDED
*       integer EVENT_ITEM_CHARGES_REMOVED
*
*       Use RegisterNativeEvent or RegisterIndexNativeEvent for event registration.
*       GetNativeEventTrigger and GetIndexNativeEventTrigger provide access to trigger handles.
*
*
*       function GetItemStackingUnit takes nothing returns unit
*          Returns unit which manupilated event item.
*
*       function GetItemStackingItem takes nothing returns item
*          Returns manipulated event item.
*
*       function GetItemStackingCharges takes nothing returns integer
*          Returns number of charges that has been added or removed.
*
******************************************************************************
*
*    Containers - idea behind:
*
*       Each item type is allowed to have another item type assigned as its container,
*       and becoming an element at the same time.
*
*       Example:
*
*        | element - Gold Coin
*        | container - Endless Sack of Gold
*
*       Any item type can become container for another as long as it is not a stackable item type.
*       Containers cannot have thier own containers assigned.
*       Containers may declare different maximum stack and split count values.
*       Container is always prioritized over element type when item charges are being redistributed.
*       Each element can have multiple item types assigned as its containers.
*
******************************************************************************
*
*    Functions:
*
*       function IsItemContainer takes integer containerType returns boolean
*          Returns value indicating whether specifed item is stackable or not.
*
*       function GetItemContainerMaxStacks takes integer containerType returns integer
*          Returns maximum number of charges for specified container.
*
*       function GetItemContainerSplitCount takes integer containerType returns integer
*          Returns number of charges lost by specified container per split.
*
*       function GetItemContainerItem takes integer containerType returns integer
*          Returns item type assigned to specified container as its elements.
*
*       function IsItemContainerEmptiable takes integer containerType returns boolean
*          Whether container charges can be lowered down to 0 during split operation.
*
*       function IsItemStackable takes integer elementType returns boolean
*          Returns value indicating whether specifed item is stackable or not.
*
*       function GetItemMaxStacks takes integer elementType returns integer
*          Returns maximum number of charges for specified item.
*
*       function GetItemSplitCount takes integer elementType returns integer
*          Returns number of charges lost by specified item per split.
*
*       function ItemHasContainer takes integer elementType returns boolean
*          Indicates if specifed element type has container assigned to it.
*
*       function GetItemContainers takes integer elementType returns IntegerList
*          Returns list of item types assigned to specified element as its containers.
*
*       function MakeItemUnstackable takes integer elementType returns nothing
*          Unregisters specified item from being stackable.
*
*       function MakeItemStackable takes integer elementType, integer stacks, integer splits returns boolean
*          Registers specified item as stackable.
*
*       function UnsetItemContainer takes integer elementType returns nothing
*          Unsets any container related data related to specified element item type.
*
*       function SetItemContainer takes integer elementType, integer containerType, integer stacks, integer splits, boolean emptiable returns boolean
*          Sets specified containerType item type as container for item type elementType.
*          If emptiable flags is set to true, container charges can be dropped down to 0
*          during split operation. Otherwise at least 1 charge will be left.
*
*       function IsUnitItemFullyStacked takes unit whichUnit, integer itemTypeId returns boolean
*          Checks if specified unit has hold any additional charges of provided item.
*
*       function UnitStackItem takes unit whichUnit, item whichItem returns boolean
*          Attempts to stack provided item for specified unit.
*
*       function UnitSplitItem takes unit whichUnit, item whichItem returns boolean
*          Attempts to split provided item for specified unit.
*
*****************************************************************************/
library StackNSplit requires /*
                    */ ListT /*
                    */ InventoryEvent /*
                    */ RegisterPlayerUnitEvent /*
                    */ ExtensionMethods /*
                    */ optional SmoothItemPickup

globals
    integer EVENT_ITEM_CHARGES_ADDED
    integer EVENT_ITEM_CHARGES_REMOVED
endglobals

globals
    private unit eventUnit = null
    private item eventItem = null
    private integer eventCharges = -1
    private TableArray table = 0
endglobals

function GetItemStackingUnit takes nothing returns unit
    return eventUnit
endfunction

function GetItemStackingItem takes nothing returns item
    return eventItem
endfunction

function GetItemStackingCharges takes nothing returns integer
    return eventCharges
endfunction

function IsItemContainer takes integer containerType returns boolean
    return table[3].has(containerType)
endfunction

function GetItemContainerMaxStacks takes integer containerType returns integer
    if IsItemContainer(containerType) then
        return table[0][containerType]
    endif
    return 0
endfunction

function GetItemContainerSplitCount takes integer containerType returns integer
    if IsItemContainer(containerType) then
        return table[1][containerType]
    endif
    return 0
endfunction

function GetItemContainerItem takes integer containerType returns integer
    if IsItemContainer(containerType) then
        return table[3][containerType]
    endif
    return 0
endfunction

function IsItemContainerEmptiable takes integer containerType returns boolean
    if IsItemContainer(containerType) then
        return table[4].boolean[containerType]
    endif
    return false
endfunction

function IsItemStackable takes integer elementType returns boolean
    return not IsItemContainer(elementType) and table[0].has(elementType)
endfunction

function GetItemMaxStacks takes integer elementType returns integer
    if IsItemStackable(elementType) then
        return table[0][elementType]
    endif
    return 0
endfunction

function GetItemSplitCount takes integer elementType returns integer
    if IsItemStackable(elementType) then
        return table[1][elementType]
    endif
    return 0
endfunction

function ItemHasContainer takes integer elementType returns boolean
    return table[2].has(elementType)
endfunction

function GetItemContainers takes integer elementType returns IntegerList
    if ItemHasContainer(elementType) then
        return table[2][elementType]
    endif
    return 0
endfunction

function MakeItemUnstackable takes integer elementType returns nothing
    if IsItemStackable(elementType) then
        call table[0].remove(elementType)
        call table[1].remove(elementType)
    endif
endfunction

function MakeItemStackable takes integer elementType, integer stacks, integer splits returns boolean
    local integer value = splits

    if not IsItemContainer(elementType) and stacks > 0 then
        if value < 1 then
            set value = 1
        endif
        set table[0][elementType] = stacks
        set table[1][elementType] = value
        return true
    endif
    return false
endfunction

function UnsetItemContainer takes integer containerType returns nothing
    local integer elementType = GetItemContainerItem(containerType)
    local IntegerList containers

    if elementType != 0 then
        call table[0].remove(containerType)
        call table[1].remove(containerType)
        call table[3].remove(containerType)
        call table[4].boolean.remove(containerType)

        // remove containerType from containers list
        set containers = GetItemContainers(elementType)
        call containers.removeElem(containerType)
        if containers.empty() then
            call containers.destroy()
            call table[2].remove(elementType)
        endif
    endif
endfunction

function SetItemContainer takes integer elementType, integer containerType, integer stacks, integer splits, boolean emptiable returns boolean
    local IntegerList containers

    if elementType == 0 or containerType == 0 then
        return false
    elseif stacks <= 0 or elementType == containerType then
        return false
    elseif IsItemContainer(elementType) or IsItemContainer(containerType) then
        return false
    elseif IsItemStackable(containerType) then
        return false
    endif

    if splits < 1 then
        set splits = 1
    endif

    set containers = GetItemContainers(elementType)
    if containers == 0 then
        set containers = IntegerList.create()
        set table[2][elementType] = containers
    endif
    call containers.push(containerType)

    set table[0][containerType] = stacks
    set table[1][containerType] = splits
    set table[3][containerType] = elementType
    set table[4].boolean[containerType] = emptiable
    return true
endfunction

function IsUnitItemFullyStacked takes unit whichUnit, integer itemTypeId returns boolean
    local boolean result = true
    local integer max
    local item itm
    local integer size
    local integer slot = 0
    local IntegerListItem iter

    if not IsUnitInventoryFull(whichUnit) then
        return false
    elseif IsItemContainer(itemTypeId) then
        return result
    endif

    set size = UnitInventorySize(whichUnit)
    if ItemHasContainer(itemTypeId) then
        set iter = GetItemContainers(itemTypeId).first
        loop
            exitwhen iter == 0
            set max = GetItemContainerMaxStacks(iter.data)

            if max > 0 then
                loop
                    exitwhen slot >= size
                    set itm = UnitItemInSlot(whichUnit, slot)
                    if GetItemTypeId(itm) == iter.data and GetItemCharges(itm) < max then
                        set result = false
                        exitwhen true
                    endif
                    set slot = slot + 1
                endloop
            endif
            set iter = iter.next
        endloop
    endif

    if result and IsItemStackable(itemTypeId) then
        set max = GetItemMaxStacks(itemTypeId)
        if max > 0 then
            set slot = 0
            loop
                exitwhen slot >= size
                set itm = UnitItemInSlot(whichUnit, slot)
                if GetItemTypeId(itm) == itemTypeId and GetItemCharges(itm) < max then
                    set result = false
                    exitwhen true
                endif
                set slot = slot + 1
            endloop
        endif
    endif

    set itm = null
    return result
endfunction

private function FireEvent takes integer evt, unit u, item itm, integer charges returns nothing
    local unit prevUnit = eventUnit
    local item prevItem = eventItem
    local integer prevCharges = eventCharges

    set eventUnit = u
    set eventItem = itm
    set eventCharges = charges

    call TriggerEvaluate(GetNativeEventTrigger(evt))
    call TriggerEvaluate(GetIndexNativeEventTrigger(GetPlayerId(GetOwningPlayer(u)), evt))

    set eventUnit = prevUnit
    set eventItem = prevItem
    set eventCharges = prevCharges

    set prevUnit = null
    set prevItem = null
endfunction

private function StackItem takes unit u, item itm, item ignored, integer withTypeId, integer max returns integer
    local integer charges = GetItemCharges(itm)
    local integer slot = 0
    local integer size = UnitInventorySize(u)
    local item with
    local integer withCharges
    local integer diff

    loop
        exitwhen slot >= size
        set with = UnitItemInSlot(u, slot)

        if with != ignored and GetItemTypeId(with) == withTypeId then
            set withCharges = GetItemCharges(with)
            if withCharges < max then
                set diff = max - withCharges

                if diff >= charges then
                    call SetItemCharges(with, withCharges + charges)
                    call RemoveItem(itm)
                    call FireEvent(EVENT_ITEM_CHARGES_ADDED, u, with, charges)
                    set charges = 0
                    exitwhen true
                else
                    set charges = charges - diff
                    call SetItemCharges(with, max)
                    call SetItemCharges(itm, charges)
                    call FireEvent(EVENT_ITEM_CHARGES_REMOVED, u, itm, diff)
                    call FireEvent(EVENT_ITEM_CHARGES_ADDED, u, with, diff)
                endif
            endif
        endif

        set slot = slot + 1
    endloop

    set with = null
    return charges
endfunction

function UnitStackItem takes unit whichUnit, item whichItem returns boolean
    local integer charges = GetItemCharges(whichItem)
    local integer itemTypeId = GetItemTypeId(whichItem)
    local integer containerType
    local integer max
    local boolean result = false
    local IntegerListItem iter

    if whichUnit == null or charges == 0 then
        return result
    endif

    if IsItemContainer(itemTypeId) then
        set max = GetItemContainerMaxStacks(itemTypeId)
        call StackItem(whichUnit, whichItem, whichItem, GetItemContainerItem(itemTypeId), max)
        return true
    elseif ItemHasContainer(itemTypeId) then
        set iter = GetItemContainers(itemTypeId).first
        loop
            exitwhen iter == 0
            set containerType = iter.data

            set max = GetItemContainerMaxStacks(containerType)
            set charges = StackItem(whichUnit, whichItem, whichItem, containerType, max)
            exitwhen charges == 0
            set iter = iter.next
        endloop
        set result = true
    endif

    if IsItemStackable(itemTypeId) and charges > 0 then
        set max = GetItemMaxStacks(itemTypeId)
        call StackItem(whichUnit, whichItem, whichItem, itemTypeId, max)
        set result = true
    endif
    return result
endfunction

function UnitSplitItem takes unit whichUnit, item whichItem returns boolean
    local integer charges = GetItemCharges(whichItem)
    local integer itemTypeId = GetItemTypeId(whichItem)
    local integer max
    local integer toSplit
    local integer elementType
    local IntegerListItem iter
    local integer containerType
    local item with
    local trigger t
    local integer minCharges = 1

    if IsItemContainer(itemTypeId) then
        if IsItemContainerEmptiable(itemTypeId) then
            set minCharges = 0
        endif
        if charges <= minCharges then
            return false
        endif

        set elementType = GetItemContainerItem(itemTypeId)
        set toSplit = GetItemContainerSplitCount(itemTypeId)
    elseif IsItemStackable(itemTypeId) and charges > minCharges then
        set elementType = itemTypeId
        set toSplit = GetItemSplitCount(itemTypeId)
    else
        return false
    endif

    if toSplit >= charges then
        set toSplit = charges - minCharges
    endif
    call SetItemCharges(whichItem, charges - toSplit)
    call FireEvent(EVENT_ITEM_CHARGES_REMOVED, whichUnit, whichItem, toSplit)
    set with = CreateItem(elementType, GetUnitX(whichUnit), GetUnitY(whichUnit))
    call SetItemCharges(with, toSplit)    

    // Redistribute splitted stacks if possible
    if ItemHasContainer(elementType) then
        set iter = GetItemContainers(elementType).first
        loop
            exitwhen iter == 0
            set containerType = iter.data

            set max = GetItemContainerMaxStacks(containerType)
            set toSplit = StackItem(whichUnit, with, whichItem, containerType, max)
            exitwhen toSplit == 0
            set iter = iter.next
        endloop
    endif
    if IsItemStackable(elementType) and toSplit > 0 then
        set max = GetItemMaxStacks(elementType)
        set toSplit = StackItem(whichUnit, with, whichItem, elementType, max)
    endif

    if toSplit > 0 then // something is left
        set t = GetAnyPlayerUnitEventTrigger(EVENT_PLAYER_UNIT_PICKUP_ITEM)
        call DisableTrigger(t)
        call UnitAddItem(whichUnit, with)
        call EnableTrigger(t)
        set t = null
    endif

    set with = null
    return true
endfunction

private function PickupItem takes unit u, item itm returns boolean
    local integer itemTypeId = GetItemTypeId(itm)
    local integer charges
    local integer elementType
    local integer max
    local item with
    local integer withCharges
    local integer diff
    local integer slot = 0
    local integer size

    if IsItemContainer(itemTypeId) then
        set max = GetItemContainerMaxStacks(itemTypeId)
        set elementType = GetItemContainerItem(itemTypeId)
        set charges = GetItemCharges(itm)
        set size = UnitInventorySize(u)
        loop
            exitwhen charges >= max
            exitwhen slot >= size
            set with = UnitItemInSlot(u, slot)
            set withCharges = GetItemCharges(with)

            if with != itm and withCharges > 0 and GetItemTypeId(with) == elementType then
                if charges + withCharges > max then
                    set diff = max - charges
                    call SetItemCharges(itm, max)
                    call SetItemCharges(with, withCharges - diff)
                    call FireEvent(EVENT_ITEM_CHARGES_REMOVED, u, with, diff)
                    call FireEvent(EVENT_ITEM_CHARGES_ADDED, u, itm, diff)
                    exitwhen true
                else
                    set charges = charges + withCharges
                    call SetItemCharges(itm, charges)
                    call RemoveItem(with)
                    call FireEvent(EVENT_ITEM_CHARGES_ADDED, u, itm, withCharges)
                endif
            endif

            set slot = slot + 1
        endloop
    else
        call UnitStackItem(u, itm)
    endif
    return false
endfunction

private function OnPickup takes nothing returns boolean
    return PickupItem(GetTriggerUnit(), GetManipulatedItem())
endfunction

private function OnMoved takes nothing returns nothing
    local unit u = GetEventInventoryUnit()
    local item itm = GetEventInventoryItem()
    local integer itemTypeId = GetItemTypeId(itm)
    local integer charges
    local item swapped
    local integer swappedTypeId
    local integer swappedCharges
    local integer max = 0
    local integer total
    local integer diff

    if GetEventInventorySlotFrom() == GetEventInventorySlotTo() then // splitting
        call UnitSplitItem(u, itm)
    elseif not IsItemContainer(itemTypeId) then
        set charges = GetItemCharges(itm)
        set swapped = GetEventInventorySwapped()
        set swappedTypeId = GetItemTypeId(swapped)
        set swappedCharges = GetItemCharges(swapped)

        if charges > 0 then
            if swappedTypeId == itemTypeId and swappedCharges > 0 then
                set max = GetItemMaxStacks(itemTypeId)
            elseif GetItemContainerItem(swappedTypeId) == itemTypeId then
                set max = GetItemContainerMaxStacks(swappedTypeId)
            endif
        endif

        if max > 0 then
            set total = charges + swappedCharges
            if total > max then
                if swappedCharges < max then // if not met, allow for standard replacement action
                    set diff = max - charges
                    call SetItemCharges(itm, max)
                    call SetItemCharges(swapped, total - max)
                    call FireEvent(EVENT_ITEM_CHARGES_REMOVED, u, swapped, diff)
                    call FireEvent(EVENT_ITEM_CHARGES_ADDED, u, itm, diff)
                endif
            else
                call SetItemCharges(swapped, total)
                call RemoveItem(itm)
                call FireEvent(EVENT_ITEM_CHARGES_ADDED, u, swapped, charges)
            endif
        endif
        set swapped = null
    endif

    set u = null
    set itm = null
endfunction

static if LIBRARY_SmoothItemPickup then
private function OnSmoothPickup takes nothing returns nothing
    call PickupItem(GetSmoothItemPickupUnit(), GetSmoothItemPickupItem())
endfunction

private struct StackSmoothPickupPredicate extends array
    static method canPickup takes unit whichUnit, item whichItem returns boolean
        local integer itemTypeId = GetItemTypeId(whichItem)

        if IsItemContainer(itemTypeId) then
            return not IsUnitItemFullyStacked(whichUnit, GetItemContainerItem(itemTypeId))
        elseif IsItemStackable(itemTypeId) then
            return not IsUnitItemFullyStacked(whichUnit, itemTypeId)
        endif

        return false
    endmethod

    implement optional SmoothPickupPredicateModule
endstruct
endif

private module StackNSplitInit
    private static method onInit takes nothing returns nothing
        set EVENT_ITEM_CHARGES_ADDED = CreateNativeEvent()
        set EVENT_ITEM_CHARGES_REMOVED = CreateNativeEvent()

        set table = TableArray[5]

        call RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_PICKUP_ITEM, function OnPickup)
        call RegisterNativeEvent(InventoryEvent.MOVED, function OnMoved)
static if LIBRARY_SmoothItemPickup then
        call RegisterNativeEvent(EVENT_ITEM_SMOOTH_PICKUP, function OnSmoothPickup)
        call AddSmoothItemPickupCondition(StackSmoothPickupPredicate.create())
endif
    endmethod
endmodule

private struct StackNSplit extends array
    implement StackNSplitInit
endstruct

endlibrary