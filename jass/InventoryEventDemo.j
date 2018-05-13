scope InventoryEventDemo initializer Init

private function OnInventoryMoved takes nothing returns nothing
    local unit u = GetInventoryManipulatingUnit()
    local item itm = GetInventoryManipulatedItem()
    local item swapped = GetInventorySwappedItem()
    local integer slotFrom = GetInventorySlotFrom()
    local integer slotTo = GetInventorySlotTo()
    local string s

    if swapped != null then
        set s = GetUnitName(u) + " swapped " + GetItemName(itm) + "[" + I2S(slotFrom) + "] with "
        set s = s + GetItemName(swapped) + "[" + I2S(slotTo) + "]"
    else
        set s = GetUnitName(u) + " moved " + GetItemName(itm) + "[" + I2S(slotFrom) + "] to slot " + I2S(slotTo)
    endif

    call ClearTextMessages()
    call BJDebugMsg(s)

    set u = null
    set itm = null
    set swapped = null
endfunction

private function OnInventoryUsed takes nothing returns nothing
    local unit u = GetInventoryManipulatingUnit()
    local item itm = GetInventoryManipulatedItem()
    local integer slotFrom = GetInventorySlotFrom()

    local string s
    set s = GetUnitName(u) + " used " + GetItemName(itm) + "[" + I2S(slotFrom) + "]"

    call ClearTextMessages()
    call BJDebugMsg(s)

    set u = null
    set itm = null
endfunction

private function Callback takes nothing returns nothing
    local player p = GetLocalPlayer()
    local real x = GetCameraTargetPositionX()
    local real y = GetCameraTargetPositionY()

    // boots
    call CreateItem('bspd', x, y)
    // crystall ball
    call CreateItem('crys', x, y)
    // inferno
    call CreateItem('infs', x, y)
    // claws of attack
    call CreateItem('ratc', x, y)

    call SelectUnit(CreateUnit(p, 'Hpal', x, y, 0), true)

    call DestroyTimer(GetExpiredTimer())
endfunction

private function Init takes nothing returns nothing
    call RegisterNativeEvent(EVENT_INVENTORY_ITEM_MOVED, function OnInventoryMoved)
    call RegisterNativeEvent(EVENT_INVENTORY_ITEM_USED, function OnInventoryUsed)
    call TimerStart(CreateTimer(), 1, false, function Callback)
endfunction

endscope