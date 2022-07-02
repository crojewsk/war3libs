globals
    unit paladin = null
    group all = CreateGroup()
    group closest = CreateGroup()
endglobals

struct gcw_test extends array
    static method filter takes nothing returns boolean
        return GetFilterUnit() != paladin
    endmethod

    static method printU takes string prefix, unit u returns nothing
        call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, prefix + GetUnitName(u))
    endmethod

    static method printI takes string prefix, item i returns nothing
        call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, prefix + GetItemName(i))
    endmethod

    static method printD takes string prefix, destructable d returns nothing
        call DisplayTextToPlayer(GetLocalPlayer(), 0, 0, prefix + GetDestructableName(d))
    endmethod

    static method call_test takes nothing returns boolean
        local real x = GetUnitX(paladin)
        local real y = GetUnitY(paladin)

        call GroupClear(closest)
        call ClearTextMessages()
        call GetClosestNUnitsInGroup(x, y, 1, all, closest)

        call printU("closest unit: ", GetClosestUnit(x, y, Filter(function thistype.filter)))
        call printU("closest unit within group: ", FirstOfGroup(closest))
        call printI("closest item: ", GetClosestItem(x, y, null))
        call printD("closest destructable: ", GetClosestDestructable(x, y, null))
        return false
    endmethod

    static method onInit takes nothing returns nothing
        local trigger t = CreateTrigger()
        call TriggerRegisterTimerEvent(t, 3, true)
        call TriggerAddCondition(t, function thistype.call_test)
        set t = null

        set paladin = CreateUnit(Player(0), 'Hpal', 0, 0, 0)
        call GroupEnumUnitsInRange(all, 0, 0, 5000, function thistype.filter)
    endmethod
endstruct