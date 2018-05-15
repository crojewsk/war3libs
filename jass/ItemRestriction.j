/*****************************************************************************
*
*    ItemRestriction v1.1.1.0
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
*
******************************************************************************
*
*    Interface UnitRequirementPredicate:
*
*       method isMet takes unit whichUnit returns string
*          Returns null if criteria are met and error message if not.
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
*        |     implement SmoothPickupPredicateModule
*        | endstruct
*
******************************************************************************
*
*    struct UnitRequirement:
*
*       Fields:
*
*        | IntegerList typeIds
*        |    Unit type requirement, omitted if empty.
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
*        |
*        | string name
*        |    Name associated with requirement.
*
*
*       Methods:
*
*        | static method create takes string name returns thistype
*        |    Default ctor.
*        |
*        | method destroy takes nothing returns nothing
*        |    Default dctor.
*        |
*        | method has takes integer unitTypeId returns boolean
*        |    Whether specified unit type is a part of requirement.
*        |
*        | method requireStat takes integer str, integer agi, integer int returns thistype
*        |    Sets hero statistic requirements to specified values.
*        |
*        | method addCondition takes UnitRequirementPredicate predicate returns nothing
*        |    Adds new criteria to requirement criterias.
*        |
*        | method removeCondition takes UnitRequirementPredicate predicate returns nothing
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
*        | IntegerList typeIds
*        |    Item types that enforce this restriction.
*        |
*        | integer limit
*        |    Maximum number of items a unit can carry.
*        |
*        | LimitExceptionList exceptions
*        |    Collection of UnitRequirement instances that may define different limits.
*        |    Example: berserker may carry two 2H-weapons, rather than one.
*        |
*        | ItemRestrictionList exclusives
*        |    Collection of ItemRestriction instances that exclude each other from being picked.
*        |    Example: a unit cannot carry both 1H-weapons and 2H-weapons at the same time.
*        |
*        | UnitRequirement requirement
*        |    Requirement a unit must meet to hold items.
*        |
*        | string name
*        |    Name associated with restriction.
*
*
*       Methods:
*
*        | static method create takes string name, integer limit returns thistype
*        |    Default ctor.
*        |
*        | method destroy takes nothing returns nothing
*        |    Default dctor.
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
*        | method removeException takes UnitRequirement requirement returns thistype
*        |    Removes item limit exception for specified requirement.
*        |
*        | method addException takes UnitRequirement requirement, integer newLimit returns thistype
*        |    Adds new item limit exception for specified requirement.
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

private constant function GetExclusiveErrorMessage takes ItemRestriction first, ItemRestriction second returns string
    return "This unit cannot hold items of type \"" + first.name + "\" and \"" + second.name + "\" at the same time."
endfunction

private constant function GetForbiddenErrorMessage takes ItemRestriction restriction returns string
    return "This item can not be picked up by this unit."
endfunction

private function PrintError takes player whichPlayer, string message returns nothing
static if LIBRARY_SimError then
    call SimError(whichPlayer, message)
else
    call DisplayTimedTextToPlayer(whichPlayer, 0, 0, 2.0, message)
endif
endfunction

globals
    private unit argUnit = null
    private string retMessage = null
endglobals

struct UnitRequirementPredicate extends array
    readonly trigger trigger
    implement Alloc

    static method isMet takes unit whichUnit returns string
        return null
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

module UnitRequirementPredicateModule
    private delegate UnitRequirementPredicate predicate

    private static method onInvoke takes nothing returns boolean
        set retMessage = thistype.isMet(argUnit)
        return retMessage == null
    endmethod

    static method create takes nothing returns thistype
        local thistype this = UnitRequirementPredicate.create()
        set predicate = this
        call TriggerAddCondition(trigger, Condition(function thistype.onInvoke))
        return this
    endmethod

    method destroy takes nothing returns nothing
        call predicate.destroy()
    endmethod
endmodule

struct UnitRequirement extends array
    readonly IntegerList typeIds
    integer level
    integer strength
    integer agility
    integer intelligence
    boolean includeBonuses
    string name
    private IntegerList conditions

    implement Alloc

    static method create takes string name returns thistype
        local thistype this = allocate()

        set typeIds = IntegerList.create()
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
        call typeIds.destroy()
        call conditions.destroy()
        call deallocate()
    endmethod

    method has takes integer unitTypeId returns boolean
        return typeIds.find(unitTypeId) != 0
    endmethod

    method requireStat takes integer str, integer agi, integer int returns thistype
        set strength = str
        set agility = agi
        set intelligence = int

        return this
    endmethod

    method addCondition takes UnitRequirementPredicate predicate returns nothing
        if predicate != 0 then
            call conditions.push(predicate)
        endif
    endmethod

    method removeCondition takes UnitRequirementPredicate predicate returns nothing
        if predicate != 0 then
            call conditions.remove(conditions.find(predicate))
        endif
    endmethod

    method test takes unit whichUnit returns string
        local integer unitTypeId = GetUnitTypeId(whichUnit)
        local IntegerListItem iter
        local UnitRequirementPredicate condition

        if not typeIds.empty() and not has(unitTypeId) then
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
            if not TriggerEvaluate(condition.trigger) then
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

//! runtextmacro DEFINE_STRUCT_LIST("", "LimitExceptionList", "LimitException")
//! runtextmacro DEFINE_STRUCT_LIST("", "ItemRestrictionList", "ItemRestriction")

globals
    private Table restrictionTable = 0
endglobals

private module ItemRestrictionInit
    private static method onInit takes nothing returns nothing
        // For extra speed, each item type involved will have separate list assigned
        set restrictionTable = Table.create()
        // Global instance list for handling deindex event
        set restrictionTable[0] = ItemRestrictionList.create()

        call RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_PICKUP_ITEM, function thistype.onPickup)
        call RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_DROP_ITEM, function thistype.onDrop)
        call RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, function thistype.onTargetOrder)
        call RegisterUnitIndexEvent(Condition(function thistype.onDeindex), EVENT_UNIT_DEINDEX)
    endmethod
endmodule

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

struct ItemRestriction extends array
    private Table cache
    readonly IntegerList typeIds
    integer limit
    readonly LimitExceptionList exceptions
    readonly ItemRestrictionList exclusives
    UnitRequirement requirement
    string name

    implement Alloc

    static method create takes string name, integer limit returns thistype
        local thistype this = allocate()

        set cache = Table.create()
        set typeIds = IntegerList.create()
        set exceptions = LimitExceptionList.create()
        set exclusives = ItemRestrictionList.create()
        set this.name = name
        set this.limit = limit
        set this.requirement = 0

        call ItemRestrictionList(restrictionTable[0]).push(this)

        return this
    endmethod

    method destroy takes nothing returns nothing
        local ItemRestrictionList restrictions
        local ItemRestrictionListItem iter
        local ItemRestrictionListItem node
        local ItemRestriction exclusive

        set iter = typeIds.first
        loop
            exitwhen iter == 0
            set restrictions = restrictionTable[iter.data]
            set node = restrictions.find(this)
            call restrictions.remove(node)
            if restrictions.empty() then
                call restrictions.destroy()
                call restrictionTable.remove(iter.data)
            endif
            set iter = iter.next
        endloop

        set restrictions = restrictionTable[0]
        set node = restrictions.find(this)
        call restrictions.remove(node)

        if not exclusives.empty() then
            set iter = exclusives.first
            loop
                exitwhen iter == 0
                set exclusive = iter.data
                set node = exclusive.exclusives.find(this)
                call exclusive.exclusives.remove(node)
                set iter = iter.next
            endloop
        endif

        call cache.destroy()
        call typeIds.destroy()
        call exceptions.destroy()
        call exclusives.destroy()
        set name = null
        set limit = 0
        call deallocate()
    endmethod

    method has takes integer itemTypeId returns boolean
        return typeIds.find(itemTypeId) != 0
    endmethod

    method removeItem takes integer itemTypeId returns thistype
        local ItemRestrictionList restrictions
        local ItemRestrictionListItem node

        if has(itemTypeId) then
            call typeIds.remove(typeIds.find(itemTypeId))

            set restrictions = restrictionTable[itemTypeId]
            set node = restrictions.find(this)
            call restrictions.remove(node)
            if restrictions.empty() then
                call restrictions.destroy()
                call restrictionTable.remove(itemTypeId)
            endif
        endif

        return this
    endmethod

    method addItem takes integer itemTypeId returns thistype
        local ItemRestrictionList restrictions

        if itemTypeId <= 0 then
            return this
        endif

        if not has(itemTypeId) then
            call typeIds.push(itemTypeId)

            if not restrictionTable.has(itemTypeId) then
                set restrictions = ItemRestrictionList.create()
                call restrictions.push(this)
                set restrictionTable[itemTypeId] = restrictions
            else
                set restrictions = restrictionTable[itemTypeId]
                if restrictions.find(this) == 0 then
                    call restrictions.push(this)
                endif
            endif
        endif

        return this
    endmethod

    method removeException takes UnitRequirement requirement returns thistype
        local LimitExceptionListItem iter = exceptions.first
        local LimitException exception

        loop
            exitwhen iter == 0
            set exception = iter.data
            if exception.requirement == requirement then
                call exceptions.remove(iter)
                call exception.destroy()
                exitwhen true
            endif
            set iter = iter.next
        endloop

        return this
    endmethod

    method addException takes UnitRequirement requirement, integer newLimit returns thistype
        local LimitExceptionListItem iter = exceptions.first
        local LimitException exception
        local LimitException entry = 0

        loop
            exitwhen iter == 0
            set exception = iter.data
            if exception.requirement == requirement then
                set entry = exception
                exitwhen true
            endif
            set iter = iter.next
        endloop

        if entry == 0 then
            call exceptions.push(LimitException.create(requirement, newLimit))
        endif
        return this
    endmethod

    method removeExclusive takes ItemRestriction restriction returns thistype
        local ItemRestrictionListItem node = exclusives.find(restriction)

        if node != 0 then
            call exclusives.remove(node)
            set node = restriction.exclusives.find(this)
            call restriction.exclusives.remove(node)
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

    method getCount takes unit whichUnit returns integer
        return cache[GetUnitId(whichUnit)]
    endmethod

    private method setCount takes unit u, integer count returns nothing
        set cache[GetUnitId(u)] = count
    endmethod

    method getException takes unit whichUnit returns LimitException
        return cache[-GetUnitId(whichUnit)]
    endmethod

    private method setException takes unit u, LimitException exception returns nothing
        set cache[-GetUnitId(u)] = exception
    endmethod

    method test takes unit whichUnit, item whichItem returns string
        local LimitException exception
        local integer threshold = limit
        local string errorMessage
        local IntegerListItem iter
        local ItemRestriction exclusive

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
            if exclusive.getCount(whichUnit) > 0 then
                return GetExclusiveErrorMessage(this, exclusive)
            endif

            set iter = iter.next
        endloop

        if not exceptions.empty() then
            set exception = getException(whichUnit)
            if exception == 0 or exceptions.find(exception) == 0 then
                call cache.remove(-GetUnitId(whichUnit)) // clear assigned exception if any

                set iter = exceptions.first
                loop
                    exitwhen iter == 0
                    set exception = iter.data

                    if exception.requirement.filter(whichUnit) then
                        set threshold = exception.newLimit
                        call setException(whichUnit, exception)
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
        elseif getCount(whichUnit) >= threshold then
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
        local ItemRestrictionList associated = ItemRestrictionList.create()
        local ItemRestrictionListItem iter
        local ItemRestriction restriction
        local integer itemTypeId = GetItemTypeId(itm)
        local string errorMessage

        if not restrictionTable.has(itemTypeId) then
            return associated
        endif

        set iter = ItemRestrictionList(restrictionTable[itemTypeId]).first
        loop
            exitwhen iter == 0
            set restriction = iter.data
            set errorMessage = restriction.test(u, itm)

            if errorMessage != null then      
                call PrintError(GetOwningPlayer(u), errorMessage)
                call associated.destroy()
                return 0
            endif

            call associated.push(restriction)
            set iter = iter.next
        endloop

        return associated
    endmethod

    private static method onPickup takes nothing returns boolean
        local item itm = GetManipulatedItem()
        local integer count
        local unit u
        local ItemRestrictionList associated
        local ItemRestrictionListItem iter
        local ItemRestriction restriction
        local trigger t

        if not IsItemPowerup(itm) then
            set u = GetTriggerUnit()
            set associated = evaluateRestrictions(u, itm)

            if associated != 0 then
                set iter = associated.first
                loop
                    exitwhen iter == 0
                    set restriction = iter.data
                    set count = restriction.getCount(u)
                    call restriction.setCount(u, count + 1)
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
        return false
    endmethod

    private static method onDrop takes nothing returns boolean
        local integer itemTypeId = GetItemTypeId(GetManipulatedItem())
        local ItemRestrictionListItem iter
        local integer count
        local unit u
        local ItemRestriction restriction

        if not restrictionTable.has(itemTypeId) then
            return false
        endif

        set iter = ItemRestrictionList(restrictionTable[itemTypeId]).first
        set u = GetTriggerUnit()
        loop
            exitwhen iter == 0
            set restriction = iter.data
            set count = restriction.getCount(u)

            if count > 0 then
                call restriction.setCount(u, count - 1)
            endif

            set iter = iter.next
        endloop

        return false
    endmethod

    private static method onTargetOrder takes nothing returns boolean
        local item itm = GetOrderTargetItem()
        local unit u

        if GetIssuedOrderId() == 851971 and itm != null then // order smart
            set u = GetTriggerUnit()
            if evaluateRestrictions(u, itm) == 0 and not IsUnitPaused(u) then
                call PauseUnit(u, true)
                call IssueImmediateOrderById(u, 851972) // order stop
                call PauseUnit(u, false)
            endif

            set itm = null
            set u = null
        endif

        return false
    endmethod

    private static method onDeindex takes nothing returns nothing
        local integer index = GetIndexedUnitId()
        local ItemRestrictionListItem iter = ItemRestrictionList(restrictionTable[0]).first
        local ItemRestriction restriction

        loop
            exitwhen iter == 0
            set restriction = iter.data
            if restriction.cache.has(index) then
                call restriction.cache.flush()
            endif
            set iter = iter.next
        endloop
    endmethod

    implement ItemRestrictionInit
endstruct

endlibrary