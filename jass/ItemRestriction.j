/*****************************************************************************
*
*    ItemRestriction v1.1.2.1
*       by Bannar
*
*    For restricting or limiting items from being equipped.
*
******************************************************************************
*
*    Requirements:
*
*       ListT by Bannar
*          hiveworkshop.com/threads/containers-list-t.249011/
*
*       RegisterPlayerUnitEvent by Bannar
*          hiveworkshop.com/threads/snippet-registerevent-pack.250266/
*
*       UnitDex by TriggerHappy
*          hiveworkshop.com/threads/system-unitdex-unit-indexer.248209/
*
*
*    Optional requirement:
*
*       SimError by Vexorian
*          wc3c.net/showthread.php?t=101260&highlight=SimError
*
******************************************************************************
*
*    Configurable error messages:
*
*       function GetUnitTypeErrorMessage takes UnitRequirement requirement, integer unitId returns string
*       function GetLevelErrorMessage takes UnitRequirement requirement, integer level returns string
*       function GetStatisticErrorMessage takes UnitRequirement requirement, integer value, string statistic returns string
*       function GetLimitErrorMessage takes ItemRestriction restriction, integer limit returns string
*       function GetExclusiveErrorMessage takes ItemRestriction first, ItemRestriction second returns string
*       function GetForbiddenErrorMessage takes ItemRestriction restriction returns string
*       function PrintErrorMessage takes player whichPlayer, string message returns nothing
*
******************************************************************************
*
*    Interface UnitRequirementPredicate:
*
*       static method isMet takes unit whichUnit returns string
*          Returns null on success or error message if unit does not meet predicate criteria.
*
*       module UnitRequirementPredicateModule
*          Declares body for new predicate type.
*
*
*    Predicate implementation example:
*
*        | struct MyPredicate extends array
*        |     static method isMet takes unit whichUnit returns string
*        |         return "This unit does not meet requirement criteria"
*        |     endmethod
*        |
*        |     implement UnitRequirementPredicateModule
*        | endstruct
*
******************************************************************************
*
*    struct UnitRequirement:
*
*       Fields:
*
*        | string name
*        |    Name associated with requirement.
*        |
*        | integer level
*        |    Unit level requirement.
*        |
*        | integer strength
*        |    Hero strength requirement.
*        |
*        | integer agility
*        |    Hero agility requirement.
*        |
*        | integer intelligence
*        |    Hero intelligence requirement.
*        |
*        | boolean includeBonuses
*        |    Whether to include bonuses when checking unit staticstics.
*
*
*       General:
*
*        | static method create takes string name returns thistype
*        |    Default ctor.
*        |
*        | method destroy takes nothing returns nothing
*        |    Default dctor.
*
*
*       Methods:
*
*        | method getUnits takes nothing returns IntegerList
*        |    Returns unit type requirement list.
*        |
*        | method has takes integer unitTypeId returns boolean
*        |    Whether specified unit type is a part of requirement.
*        |
*        | method addUnit takes integer unitTypeId returns thistype
*        |    Adds specified unit type to requirement criterias.
*        |
*        | method removeUnit takes integer unitTypeId returns thistype
*        |    Removes specified unit type from requirement criterias.
*        |
*        | method requireStat takes integer str, integer agi, integer int returns thistype
*        |    Sets hero statistic requirements to specified values.
*        |
*        | method addCondition takes UnitRequirementPredicate predicate returns thistype
*        |    Adds new criteria to requirement criterias.
*        |
*        | method removeCondition takes UnitRequirementPredicate predicate returns thistype
*        |    Removes specified condition from requirement criterias.
*        |
*        | method test takes unit whichUnit returns string
*        |    Validates whether specified unit meets this unit requirements.
*        |
*        | method filter takes unit whichUnit returns boolean
*        |    Returns value indicating whether specified unit successfully passed requirement test.
*
*
*    struct ItemRestriction:
*
*       Fields:
*
*        | string name
*        |    Name associated with restriction.
*        |
*        | integer limit
*        |    Maximum number of items a unit can carry.
*        |
*        | UnitRequirement requirement
*        |    Requirement a unit must meet to hold items.
*
*
*       General:
*
*        | static method create takes string name, integer limit returns thistype
*        |    Default ctor.
*        |
*        | method destroy takes nothing returns nothing
*        |    Default dctor.
*
*
*       Methods:
*
*        | method getItems takes nothing returns IntegerList
*        |    Item types that enforce this restriction.
*        |
*        | method has takes integer itemTypeId returns boolean
*        |    Whether specified item type is a part of restriction.
*        |
*        | method removeItem takes integer itemTypeId returns thistype
*        |    Remove specified item type from this restriction.
*        |
*        | method addItem takes integer itemTypeId returns thistype
*        |    Add specified item type to this restriction.
*        |
*        | method getExceptions takes nothing returns LimitExceptionList
*        |    Returns collection of UnitRequirement instances that may define different limits.
*        |    Example: berserker may carry two 2H-weapons, rather than one.
*        |
*        | method removeException takes UnitRequirement requirement returns thistype
*        |    Removes item limit exception for specified requirement.
*        |
*        | method addException takes UnitRequirement requirement, integer newLimit returns thistype
*        |    Adds new item limit exception for specified requirement.
*        |
*        | method getExclusives takes nothing returns ItemRestrictionList
*        |    Returns collection of ItemRestriction instances that exclude each other from being picked.
*        |    Example: a unit cannot carry both 1H-weapons and 2H-weapons at the same time.
*        |
*        | method removeExclusive takes ItemRestriction restriction returns thistype
*        |    Makes specified restriction non-exclusive with this restriction.
*        |
*        | method addExclusive takes ItemRestriction restriction returns thistype
*        |    Makes specified restriction exclusive with this restriction.
*        |
*        | method getCount takes unit whichUnit returns integer
*        |    Returns related to this restriction, current item count for specified unit.
*        |
*        | method getException takes unit whichUnit returns LimitException
*        |    Returns currently chosen limit exception if any for specified unit.
*        |
*        | method test takes unit whichUnit, item whichItem returns string
*        |    Validates whether specified unit can hold specified itm given the restriction criteria.
*        |
*        | method filter takes unit whichUnit, item whichItem returns boolean
*        |    Returns value indicating whether specified unit successfully
*        |    passed restriction test for specified item.
*
*
*****************************************************************************/
library ItemRestriction requires /*
                        */ ListT /*
                        */ RegisterPlayerUnitEvent /*
                        */ UnitDex /*
                        */ optional SimError

private function GetUnitTypeErrorMessage takes UnitRequirement requirement, integer unitId returns string
    return "This item can not be hold by this unit type."
endfunction

private function GetLevelErrorMessage takes UnitRequirement requirement, integer level returns string
    return "This item requires level " + I2S(level) + " to be picked up."
endfunction

private function GetStatisticErrorMessage takes UnitRequirement requirement, integer value, string statistic returns string
    return "This item requires " + I2S(value) + " " + statistic + "."
endfunction

private function GetLimitErrorMessage takes ItemRestriction restriction, integer limit returns string
    return "This unit can not hold more than " + I2S(limit) + " item(s) of \"" + restriction.name + "\" type."
endfunction

private function GetExclusiveErrorMessage takes ItemRestriction first, ItemRestriction second returns string
    return "This unit cannot hold items of type \"" + first.name + "\" and \"" + second.name + "\" at the same time."
endfunction

private function GetForbiddenErrorMessage takes ItemRestriction restriction returns string
    return "This item can not be picked up by this unit."
endfunction

private function PrintErrorMessage takes player whichPlayer, string message returns nothing
static if LIBRARY_SimError then
    call SimError(whichPlayer, message)
else
    call DisplayTimedTextToPlayer(whichPlayer, 0, 0, 2.0, message)
endif
endfunction

globals
    private trigger array triggers
    private unit argUnit = null
    private string retMessage = null
endglobals

struct UnitRequirementPredicate extends array
    implement Alloc

    static method isMet takes unit whichUnit returns string
        return null
    endmethod

    static method create takes nothing returns thistype
        local thistype this = allocate()
        set triggers[this] = CreateTrigger()
        return this
    endmethod

    method destroy takes nothing returns nothing
        call DestroyTrigger(triggers[this])
        set triggers[this] = null
        call deallocate()
    endmethod
endstruct

module UnitRequirementPredicateModule
    private delegate UnitRequirementPredicate predicate

    private static method onInvoke takes nothing returns boolean
        set retMessage = thistype.isMet(argUnit)
        return retMessage == null
    endmethod

    static method create takes nothing returns thistype
        local thistype this = UnitRequirementPredicate.create()
        set predicate = this
        call TriggerAddCondition(triggers[this], Condition(function thistype.onInvoke))
        return this
    endmethod

    method destroy takes nothing returns nothing
        call predicate.destroy()
    endmethod
endmodule

struct UnitRequirement extends array
    string name
    integer level
    integer strength
    integer agility
    integer intelligence
    boolean includeBonuses
    private IntegerList units
    private IntegerList conditions

    implement Alloc

    static method create takes string name returns thistype
        local thistype this = allocate()

        set units = IntegerList.create()
        set level = 0
        set strength = 0
        set agility = 0
        set intelligence = 0
        set includeBonuses = false
        set this.name = name
        set conditions = IntegerList.create()

        return this
    endmethod

    method destroy takes nothing returns nothing
        set name = null
        call units.destroy()
        call conditions.destroy()
        call deallocate()
    endmethod

    method has takes integer unitTypeId returns boolean
        return units.find(unitTypeId) != 0
    endmethod

    method requireStat takes integer str, integer agi, integer intel returns thistype
        set strength = str
        set agility = agi
        set intelligence = intel

        return this
    endmethod

    method getUnits takes nothing returns IntegerList
        return IntegerList[units]
    endmethod

    method addUnit takes integer unitTypeId returns thistype
        local IntegerListItem node = units.find(unitTypeId)
        if unitTypeId > 0 and node == 0 then
            call units.push(unitTypeId)
        endif
        return this
    endmethod

    method removeUnit takes integer unitTypeId returns thistype
        local IntegerListItem node = units.find(unitTypeId)
        if node != 0 then
            call units.erase(node)
        endif
        return this
    endmethod

    method addCondition takes UnitRequirementPredicate predicate returns thistype
        local IntegerListItem node = conditions.find(predicate)
        if predicate != 0 and node == 0 then
            call conditions.push(predicate)
        endif
        return this
    endmethod

    method removeCondition takes UnitRequirementPredicate predicate returns thistype
        local IntegerListItem node = conditions.find(predicate)
        if node != 0 then
            call conditions.erase(node)
        endif
        return this
    endmethod

    method test takes unit whichUnit returns string
        local integer unitTypeId = GetUnitTypeId(whichUnit)
        local IntegerListItem iter
        local UnitRequirementPredicate condition

        if not units.empty() and not has(unitTypeId) then
            return GetUnitTypeErrorMessage(this, unitTypeId)
        elseif level > 0 and GetHeroLevel(whichUnit) < level then
            return GetLevelErrorMessage(this, level)
        elseif strength > 0 and GetHeroStr(whichUnit, includeBonuses) < strength then
            return GetStatisticErrorMessage(this, strength, "Strength")
        elseif agility > 0 and GetHeroAgi(whichUnit, includeBonuses) < agility then
            return GetStatisticErrorMessage(this, agility, "Agility")
        elseif intelligence > 0 and GetHeroInt(whichUnit, includeBonuses) < intelligence then
            return GetStatisticErrorMessage(this, intelligence, "Intelligence")
        endif

        set argUnit = whichUnit
        set iter = conditions.first
        loop
            exitwhen iter == 0
            set condition = iter.data
            if not TriggerEvaluate(triggers[condition]) then
                return retMessage
            endif
            set iter = iter.next
        endloop

        return null
    endmethod

    method filter takes unit whichUnit returns boolean
        return test(whichUnit) == null
    endmethod
endstruct

struct LimitException extends array
    UnitRequirement requirement
    integer newLimit

    implement Alloc

    static method create takes UnitRequirement requirement, integer newLimit returns thistype
        local thistype this = allocate()
        set this.requirement = requirement
        set this.newLimit = newLimit
        return this
    endmethod

    method destroy takes nothing returns nothing
        call deallocate()
    endmethod
endstruct

//! runtextmacro DEFINE_STRUCT_LIST("", "LimitExceptionList", "LimitException")
//! runtextmacro DEFINE_STRUCT_LIST("", "ItemRestrictionList", "ItemRestriction")

private module ItemRestrictionInit
    private static method onInit takes nothing returns nothing
        set instanceTable = Table.create()

        call RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_PICKUP_ITEM, function thistype.onPickup)
        call RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_DROP_ITEM, function thistype.onDrop)
        call RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, function thistype.onTargetOrder)
        call RegisterUnitIndexEvent(Condition(function thistype.onDeindex), EVENT_UNIT_DEINDEX)
    endmethod
endmodule

struct ItemRestriction extends array
    string name
    integer limit
    UnitRequirement requirement
    private Table table
    private IntegerList items
    private LimitExceptionList exceptions
    private ItemRestrictionList exclusives
    // For extra speed, each item type involved will have separate list assigned
    private static Table instanceTable

    implement Alloc

    private static method saveRestriction takes integer index, ItemRestriction restriction returns nothing
        local ItemRestrictionList restrictions
        if not instanceTable.has(index) then
            set instanceTable[index] = ItemRestrictionList.create()
        endif
        set restrictions = instanceTable[index]
        if restrictions.find(restriction) == 0 then
            call restrictions.push(restriction)
        endif
    endmethod

    private static method flushRestriction takes integer index, ItemRestriction restriction returns nothing
        local ItemRestrictionList restrictions = instanceTable[index]
        call restrictions.erase(restrictions.find(restriction))
        if restrictions.empty() then
            call restrictions.destroy()
            call instanceTable.remove(index)
        endif
    endmethod

    static method getRestrictions takes integer index returns ItemRestrictionList
        if instanceTable.has(index) then
            return instanceTable[index]
        endif
        return 0
    endmethod

    static method create takes string name, integer limit returns thistype
        local thistype this = allocate()

        set table = Table.create()
        set items = IntegerList.create()
        set exceptions = LimitExceptionList.create()
        set exclusives = ItemRestrictionList.create()
        set this.name = name
        set this.limit = limit
        set this.requirement = 0
        // Global instance list for handling deindex event
        call saveRestriction(0, this)

        return this
    endmethod

    method destroy takes nothing returns nothing
        local ItemRestrictionList restrictions
        local ItemRestrictionListItem iter
        local ItemRestrictionListItem node
        local ItemRestriction exclusive
        call flushRestriction(0, this)

        set iter = items.first
        loop
            exitwhen iter == 0
            call flushRestriction(iter.data, this)
            set iter = iter.next
        endloop

        if not exclusives.empty() then
            set iter = exclusives.first
            loop
                exitwhen iter == 0
                set exclusive = iter.data
                set node = exclusive.exclusives.find(this)
                call exclusive.exclusives.erase(node)
                set iter = iter.next
            endloop
        endif

        call table.destroy()
        call items.destroy()
        call exceptions.destroy()
        call exclusives.destroy()
        set name = null
        call deallocate()
    endmethod

    method getItems takes nothing returns IntegerList
        return IntegerList[items]
    endmethod

    method has takes integer itemTypeId returns boolean
        return items.find(itemTypeId) != 0
    endmethod

    method removeItem takes integer itemTypeId returns thistype
        if has(itemTypeId) then
            call items.erase(items.find(itemTypeId))
            call flushRestriction(itemTypeId, this)
        endif
        return this
    endmethod

    method addItem takes integer itemTypeId returns thistype
        if itemTypeId > 0 and not has(itemTypeId) then
            call items.push(itemTypeId)
            call saveRestriction(itemTypeId, this)
        endif
        return this
    endmethod

    method getExceptions takes nothing returns LimitExceptionList
        return LimitExceptionList[exceptions]
    endmethod

    method removeException takes UnitRequirement requirement returns thistype
        local LimitExceptionListItem iter = exceptions.first
        local LimitException exception

        loop
            exitwhen iter == 0
            set exception = iter.data
            if exception.requirement == requirement then
                call exceptions.erase(iter)
                call exception.destroy()
                exitwhen true
            endif
            set iter = iter.next
        endloop

        return this
    endmethod

    method addException takes UnitRequirement requirement, integer newLimit returns thistype
        local LimitExceptionListItem iter = exceptions.first
        loop
            exitwhen iter == 0
            if iter.data.requirement == requirement then
                return this
            endif
            set iter = iter.next
        endloop
        call exceptions.push(LimitException.create(requirement, newLimit))

        return this
    endmethod

    method getExclusives takes nothing returns ItemRestrictionList
        return ItemRestrictionList[exclusives]
    endmethod

    method removeExclusive takes ItemRestriction restriction returns thistype
        local ItemRestrictionListItem node = exclusives.find(restriction)
        if node != 0 then
            call exclusives.erase(node)
            set node = restriction.exclusives.find(this)
            call restriction.exclusives.erase(node)
        endif

        return this
    endmethod

    method addExclusive takes ItemRestriction restriction returns thistype
        if restriction != 0 and exclusives.find(restriction) == 0 then
            call exclusives.push(restriction)
            call restriction.exclusives.push(this)
        endif

        return this
    endmethod

    private method geTcount takes integer index returns integer
        return table[index]
    endmethod

    private method incCount takes integer index returns nothing
        set table[index] = geTcount(index) + 1
    endmethod

    private method decCount takes integer index returns nothing
        set table[index] = geTcount(index) - 1
    endmethod

    private method geTexception takes integer index returns LimitException
        return table[-index]
    endmethod

    private method setException takes integer index, LimitException exception returns nothing
        set table[-index] = exception
    endmethod

    method getCount takes unit whichUnit returns integer
        return geTcount(GetUnitId(whichUnit))
    endmethod

    method getException takes unit whichUnit returns LimitException
        return geTexception(GetUnitId(whichUnit))
    endmethod

    method test takes unit whichUnit, item whichItem returns string
        local string errorMessage
        local IntegerListItem iter
        local ItemRestriction exclusive
        local integer index = GetUnitId(whichUnit)
        local integer threshold = limit
        local LimitException exception

        if not has(GetItemTypeId(whichItem)) then
            return null
        elseif requirement != 0 then
            set errorMessage = requirement.test(whichUnit)
            if errorMessage != null then
                return errorMessage
            endif
        endif

        set iter = exclusives.first
        loop
            exitwhen iter == 0
            set exclusive = iter.data

            if exclusive.geTcount(index) > 0 then
                return GetExclusiveErrorMessage(this, exclusive)
            endif
            set iter = iter.next
        endloop

        if not exceptions.empty() then
            set exception = geTexception(index)
            if exception == 0 or exceptions.find(exception) == 0 then
                call table.remove(-index) // clear assigned exception if any

                set iter = exceptions.first
                loop
                    exitwhen iter == 0
                    set exception = iter.data

                    if exception.requirement.filter(whichUnit) then
                        set threshold = exception.newLimit
                        call setException(index, exception)
                        exitwhen true
                    endif

                    set iter = iter.next
                endloop
            else
                set threshold = exception.newLimit
            endif
        endif

        if threshold <= 0 then
            return GetForbiddenErrorMessage(this)
        elseif geTcount(index) >= threshold then
            return GetLimitErrorMessage(this, threshold)
        endif

        return null
    endmethod

    method filter takes unit whichUnit, item whichItem returns boolean
        return test(whichUnit, whichItem) == null
    endmethod

    // Returns null (not allowed), empty list (no restrictions) or
    // non-empty list (restrictions to increase count for).
    // Caller is responsible for destroying retrieved list if any
    private static method evaluateRestrictions takes unit u, item itm returns ItemRestrictionList
        local ItemRestrictionList result = ItemRestrictionList.create()
        local ItemRestrictionList restrictions = getRestrictions(GetItemTypeId(itm))
        local ItemRestrictionListItem iter
        local ItemRestriction restriction
        local string errorMessage

        if restrictions != 0 then
            set iter = restrictions.first
            loop
                exitwhen iter == 0
                set restriction = iter.data
                set errorMessage = restriction.test(u, itm)

                if errorMessage != null then      
                    call PrintErrorMessage(GetOwningPlayer(u), errorMessage)
                    call result.destroy()
                    set result = 0
                    exitwhen true
                endif

                call result.push(restriction)
                set iter = iter.next
            endloop
        endif

        return result
    endmethod

    private static method onPickup takes nothing returns nothing
        local item itm = GetManipulatedItem()
        local unit u
        local integer index
        local ItemRestrictionList associated
        local ItemRestrictionListItem iter
        local trigger t

        if not IsItemPowerup(itm) then
            set u = GetTriggerUnit()
            set associated = evaluateRestrictions(u, itm)

            if associated != 0 then
                set index = GetUnitId(u)
                set iter = associated.first

                loop
                    exitwhen iter == 0
                    call iter.data.incCount(index)
                    set iter = iter.next
                endloop
                call associated.destroy()
            else
                set t = GetAnyPlayerUnitEventTrigger(EVENT_PLAYER_UNIT_DROP_ITEM)
                call DisableTrigger(t)
                call UnitRemoveItem(u, itm)
                call EnableTrigger(t)
                set t = null
            endif

            set u = null
        endif
        set itm = null
    endmethod

    private static method onDrop takes nothing returns nothing
        local ItemRestrictionList restrictions = getRestrictions(GetItemTypeId(GetManipulatedItem()))
        local ItemRestrictionListItem iter
        local integer index
        local integer count
        local ItemRestriction restriction

        if restrictions != 0 then
            set index = GetUnitId(GetTriggerUnit())
            set iter = restrictions.first

            loop
                exitwhen iter == 0
                set restriction = iter.data
                set count = restriction.geTcount(index)

                if count > 0 then
                    call restriction.decCount(index)
                endif
                set iter = iter.next
            endloop
        endif
    endmethod

    private static method onTargetOrder takes nothing returns nothing
        local item itm = GetOrderTargetItem()
        local unit u
        local ItemRestrictionList associated

        if GetIssuedOrderId() == 851971 and itm != null then // order smart
            set u = GetTriggerUnit()
            set associated = evaluateRestrictions(u, itm)

            if associated == 0 then
                if not IsUnitPaused(u) then
                    call PauseUnit(u, true)
                    call IssueImmediateOrderById(u, 851972) // order stop
                    call PauseUnit(u, false)
                endif
            else
                call associated.destroy()
            endif
            set u = null
        endif
        set itm = null
    endmethod

    private static method onDeindex takes nothing returns nothing
        local integer index = GetIndexedUnitId()
        local ItemRestrictionList restrictions = getRestrictions(0)
        local ItemRestrictionListItem iter
        local ItemRestriction restriction

        if restrictions != 0 then
            set iter = restrictions.first
            loop
                exitwhen iter == 0
                set restriction = iter.data
                if restriction.table.has(index) then
                    call restriction.table.flush()
                endif
                set iter = iter.next
            endloop
        endif
    endmethod

    implement ItemRestrictionInit
endstruct

endlibrary