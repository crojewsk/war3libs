/*****************************************************************************
*       ___  ___  ____
*      |   \| _ \/ __/                 Destructable Revival System
*      | \\ |   /\__ \                    by Bannar
*      |___/|_|\_\___/ v3.0.0.0
*
*    Revives dead destructables.
*
*    Special thanks to Bribe.
*
******************************************************************************
*
*    Requirements:
*
*       Alloc - choose whatever you like
*          e.g.: by Sevion hiveworkshop.com/threads/snippet-alloc.192348/
*
*       ListT by Bannar
*          hiveworkshop.com/threads/containers-list-t.249011/
*
******************************************************************************
*
*    Interface DestructableRevivalFilter:
*
*       static method shouldRevive takes destructable whichDest returns boolean
*          Determinates whether destructable should be revived.
*
*       module DestructableRevivalFilterModule
*          Declares body for new filter type.
*
*    Interface DestructableRevivalCondition:
*
*       static method shouldExtend takes destructable whichDest returns real
*          Determinates whether destructable revival should be extended.
*          Returning value greater than 0 indicates that revival delay has to be extended by said amount.
*
*       module DestructableRevivalConditionModule
*          Declares body for new condition type.
*
*
*    Predicate implementation example:
*
*        | struct MyRevivalFilter extends array
*        |     static method shouldRevive takes destructable whichDest returns boolean
*        |         return IsDestructableTree(whichDest)
*        |     endmethod
*        |
*        |     implement DestructableRevivalFilterModule
*        | endstruct
*
******************************************************************************
*
*    Configurables:
*
*       struct DestructableRevival:   static boolean enabled
*
*    Functions:
*
*       function SetDestructableRevivalDelay takes integer destructableType, real delay returns nothing
*          Sets revival delay for specified destrutable type.
*
*       function GetDestructableRevivalDelay takes integer destructableType returns real
*          Retrieves revival delay for specified destructable type. Defaults to 60.0 seconds.
*
*       function EnableDestructableRevivalAnimation takes integer destructableType, boolean enable returns nothing
*          Enables or disables revival animation for specified destructable type.
*
*       function IsDestructableRevivalAnimation takes integer destructableType returns boolean
*          Whether revival animation is enabled for specified destructable type. Defaults to true.
*
*       function AddDestructableRevivalFilter takes DestructableRevivalPredicate filter returns nothing
*          Adds new filter for destructable to be revived.
*
*       function RemoveDestructableRevivalFilter takes DestructableRevivalPredicate filter returns nothing
*          Removes specified filter from predicate list.
*
*       function AddDestructableRevivalCondition takes DestructableRevivalPredicate condition returns nothing
*          Adds new condition for destructable to be revived. Invoked when revival delay elapses.
*
*       function RemoveDestructableRevivalCondition takes DestructableRevivalPredicate condition returns nothing
*          Removes specified condition from predicate list.
*
*       function RegisterDestructableRevival takes destructable whichDest returns nothing
*          Registers specified destructable to the system.
*          Can be used to register revival for destructables that were created after map initialization.
*
*****************************************************************************/
library DestructableRevival requires Alloc, ListT

globals
    private IntegerList filters = 0
    private IntegerList conditions = 0
    private IntegerList ongoing = 0
    private Table table = 0
    private timer looper = CreateTimer()
    private trigger trig = CreateTrigger()
    private trigger array triggers
    private destructable argDest = null
    private real retReal = 0.0
endglobals

function SetDestructableRevivalDelay takes integer destructableType, real delay returns nothing
    set table.real[destructableType] = delay
endfunction

function GetDestructableRevivalDelay takes integer destructableType returns real
    if table.real.has(destructableType) then
        return table.real[destructableType]
    endif
    return 60.0
endfunction

function EnableDestructableRevivalAnimation takes integer destructableType, boolean enable returns nothing
    set table.boolean[-destructableType] = enable
endfunction

function IsDestructableRevivalAnimation takes integer destructableType returns boolean
    if table.boolean.has(-destructableType) then
        return table.boolean[-destructableType]
    endif
    return true
endfunction

function AddDestructableRevivalFilter takes DestructableRevivalPredicate filter returns nothing
    if filter != 0 then
        call filters.push(filter)
    endif
endfunction

function RemoveDestructableRevivalFilter takes DestructableRevivalPredicate filter returns nothing
    if filter != 0 then
        call filters.erase(filters.find(filter))
    endif
endfunction

function AddDestructableRevivalCondition takes DestructableRevivalPredicate condition returns nothing
    if condition != 0 then
        call conditions.push(condition)
    endif
endfunction

function RemoveDestructableRevivalCondition takes DestructableRevivalPredicate condition returns nothing
    if condition != 0 then
        call conditions.erase(conditions.find(condition))
    endif
endfunction

function RegisterDestructableRevival takes destructable whichDest returns nothing
    call TriggerRegisterDeathEvent(trig, whichDest)
endfunction

struct DestructableRevivalPredicate extends array
    implement Alloc

    static method shouldRevive takes destructable whichDest returns boolean
        return true
    endmethod

    static method shouldExtend takes destructable whichDest returns real
        return 0.0
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

//! textmacro DESTRUCTABLE_REVIVAL_PREDICATE
    private delegate DestructableRevivalPredicate predicate

    static method create takes nothing returns thistype
        local thistype this = DestructableRevivalPredicate.create()
        set predicate = this
        call TriggerAddCondition(triggers[this], Condition(function thistype.onInvoke))
        return this
    endmethod

    method destroy takes nothing returns nothing
        call predicate.destroy()
    endmethod
//! endtextmacro

module DestructableRevivalFilterModule
    private static method onInvoke takes nothing returns boolean
        return thistype.shouldRevive(argDest)
    endmethod
    //! runtextmacro DESTRUCTABLE_REVIVAL_PREDICATE()
endmodule

module DestructableRevivalConditionModule
    private static method onInvoke takes nothing returns boolean
        set retReal = thistype.shouldExtend(argDest)
        return retReal > 0.0
    endmethod
    //! runtextmacro DESTRUCTABLE_REVIVAL_PREDICATE()
endmodule

private struct PeriodicData extends array
    destructable dest
    real remaining

    implement Alloc

    method destroy takes nothing returns nothing
        call table.remove(GetHandleId(dest))
        set dest = null

        call ongoing.erase(ongoing.find(this))
        if ongoing.empty() then
            call PauseTimer(looper)
        endif

        call deallocate()
    endmethod

    static method create takes destructable d returns thistype
        local thistype this = allocate()

        call ongoing.push(this)
        set this.dest = d
        set table[GetHandleId(d)] = this

        return this
    endmethod
endstruct

private function OnCallback takes nothing returns nothing
    local IntegerListItem iter = ongoing.first
    local IntegerListItem iterConditions
    local PeriodicData data
    local DestructableRevivalPredicate condition
    local boolean flag

    loop
        exitwhen iter == 0
        set data = iter.data
        if GetDestructableTypeId(data.dest) == 0 or GetDestructableLife(data.dest) > .405 then
            call data.destroy()
        else
            set data.remaining = data.remaining - 0.031250000

            if data.remaining <= 0 then
                set retReal = 0
                set argDest = data.dest
                set iterConditions = conditions.first

                loop
                    exitwhen iterConditions == 0
                    set condition = iterConditions.data
                    if not TriggerEvaluate(triggers[condition]) then
                        exitwhen true
                    endif
                    set iterConditions = iterConditions.next
                endloop

                if retReal > 0 then
                    set data.remaining = retReal
                else
                    set flag = IsDestructableRevivalAnimation(GetDestructableTypeId(data.dest))
                    call DestructableRestoreLife(data.dest, GetDestructableMaxLife(data.dest), flag)
                    call data.destroy()
                endif
            endif
        endif
        set iter = iter.next
    endloop
endfunction

private function OnDeath takes nothing returns boolean
    local IntegerListItem iter = filters.first
    local DestructableRevivalPredicate filter
    local PeriodicData data

    if not DestructableRevival.enabled then
        return false
    endif

    set argDest = GetTriggerDestructable()
    loop
        exitwhen iter == 0
        set filter = iter.data
        if not TriggerEvaluate(triggers[filter]) then
            return false
        endif
        set iter = iter.next
    endloop

    if not table.has(GetHandleId(argDest)) then
        if ongoing.empty() then
            call TimerStart(looper, 0.031250000, true, function OnCallback)
        endif
        set data = PeriodicData.create(argDest)
    else
        set data = table[GetHandleId(argDest)]
    endif
    set data.remaining = GetDestructableRevivalDelay(GetDestructableTypeId(argDest))

    return false
endfunction

private function RegisterEnumDestructableRevival takes nothing returns nothing
    call RegisterDestructableRevival(GetEnumDestructable())
endfunction

private module DestructableRevivalInit
    private static method onInit takes nothing returns nothing
        set filters = IntegerList.create()
        set conditions = IntegerList.create()
        set ongoing = IntegerList.create()
        set table = Table.create()

        call EnumDestructablesInRect(bj_mapInitialPlayableArea, null, function RegisterEnumDestructableRevival)
        call TriggerAddCondition(trig, Condition(function OnDeath))
    endmethod
endmodule

struct DestructableRevival extends array
    static boolean enabled = true

    implement DestructableRevivalInit
endstruct

endlibrary