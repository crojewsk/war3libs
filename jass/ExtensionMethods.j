/*****************************************************************************
*
*    ExtensionMethods
*
*    General purpose functions that extend native jass interface.
*
******************************************************************************
*
*    Item handle extension method:
*
*       function GetUnitItemCount takes unit whichUnit returns integer
*          Returns the number of items equipped.
*
*       function IsUnitInventoryFull takes unit whichUnit returns boolean
*          Checks if unit inventory is full.
*
*       function GetUnitItemSlot takes unit whichUnit, item whichItem returns integer
*          Retrieves slot number of specified item equiped by unit whichUnit or -1 if not found.
*
*****************************************************************************/
library ExtensionMethods

function GetUnitItemCount takes unit whichUnit returns integer
    local integer size = UnitInventorySize(whichUnit)
    local integer slot = 0
    local integer result = 0
    loop
        exitwhen slot >= size
        if UnitItemInSlot(whichUnit, slot) != null then
            set result = result + 1
        endif
        set slot = slot + 1
    endloop

    return result
endfunction

function IsUnitInventoryFull takes unit whichUnit returns boolean
    return GetUnitItemCount(whichUnit) == UnitInventorySize(whichUnit)
endfunction

function GetUnitItemSlot takes unit whichUnit, item whichItem returns integer
    local integer slot = 0
    local integer size

    if UnitHasItem(whichUnit, whichItem) then
        set size = UnitInventorySize(whichUnit)
        loop
            if UnitItemInSlot(whichUnit, slot) == whichItem then
                return slot
            endif
            set slot = slot + 1
            exitwhen slot >= size
        endloop
    endif

    return -1 // NOT_FOUND
endfunction

endlibrary