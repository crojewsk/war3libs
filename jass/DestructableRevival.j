/*****************************************************************************
*       ___  ___  ____
*      |   \| _ \/ __/                 Destructable Revival System
*      | \\ |   /\__ \                   by Bannar aka Spinnaker
*      |___/|_|\_\___/ v2.2.3.6
*
*    Revives dead destructables. Includes set of configurables to customize the process.
*
*    Special thanks to Bribe.
*
******************************************************************************
*
*    Requirements:
*    -------------
*
*       TimerUtils by Vexorian Magtheridon96 Bribe
*
*          hiveworkshop.com/forums/graveyard-418/system-timerutilsex-204500
*          wc3c.net/showthread.php?t=101322
*
*    Optional:
*    ---------
*       Note: IsDestructableTree is required if TREES_ONLY is set to true
*
*       Credits to PitzerMike for IsDestructableTree
*          wc3c.net/showthread.php?t=103927
*
*       Updated by BPower
*          hiveworkshop.com/forums/jass-resources-412/snippet-isdestructabletree-248054/
*
******************************************************************************
*
*    Configurables:
*    --------------
*
*       struct DestructableRevival:   static boolean enabled
*
*       private constant boolean TREES_ONLY
*          do we revive just trees?
*
*       private constant function FilterTypeId takes integer id returns boolean
*          choose which types should be revived
*
*       private constant function GetDelayForType takes integer id returns real
*          configure revive delay time for each type
*
*       private constant function IsAnimationForType takes integer id returns boolean
*          choose which types should have thier revive animation shown
*
*    Functions:
*    ----------
*
*       function RegisterDestructableRevival takes destructable d returns nothing
*          use this function in order to register revival of not pre-placed destructable
*
*****************************************************************************/
library DestructableRevival uses TimerUtils /*
                         */ optional IsDestructableTree

    globals
        private constant boolean TREES_ONLY = true
    endglobals

    private constant function FilterTypeId takes integer id returns boolean
        return true
    endfunction

    private constant function GetDelayForType takes integer id returns real
        return 5.
    endfunction

    private constant function IsAnimationForType takes integer id returns boolean
        return true
    endfunction

    /**
        Beginning of internal script
    */

    globals
        private trigger trig = CreateTrigger()
    endglobals

    function RegisterDestructableRevival takes destructable d returns nothing
        call TriggerRegisterDeathEvent(trig, d)
    endfunction

    private module DestructableRevivalInit
        private static method onInit takes nothing returns nothing
            call EnumDestructablesInRect(bj_mapInitialPlayableArea, null, function thistype.register)
            call TriggerAddCondition(trig, Condition(function thistype.onDeath))
        endmethod
    endmodule

    struct DestructableRevival extends array
        private static integer count = 0
        private thistype recycle

        static boolean enabled = true
        private destructable dest

        private static method create takes destructable d returns thistype
            local thistype this = thistype(0).recycle

            if this == 0 then
                set count = count + 1
                set this = count
            else
                set thistype(0).recycle = recycle
            endif

            set dest = d

            return this
        endmethod

        private method destroy takes nothing returns nothing
            set dest = null

            set recycle = thistype(0).recycle
            set thistype(0).recycle = this
        endmethod

        private static method onCallback takes nothing returns nothing
            local timer t = GetExpiredTimer()
            local thistype this = GetTimerData(t)
            local boolean flag = IsAnimationForType(GetDestructableTypeId(dest))

            call DestructableRestoreLife(dest, GetDestructableMaxLife(dest), flag)

            call ReleaseTimer(t)
            call destroy()
            set t = null
        endmethod

        private static method onDeath takes nothing returns boolean
            local destructable d = GetTriggerDestructable()
            local integer id = GetDestructableTypeId(d)
            local thistype this

            if ( enabled and FilterTypeId(id) ) then
                set this = create(d)
                call TimerStart(NewTimerEx(this), GetDelayForType(id), false, function thistype.onCallback)
            endif

            set d = null
            return false
        endmethod

        private static method register takes nothing returns nothing
            static if TREES_ONLY then
                static if LIBRARY_IsDestructableTree then
                    local destructable d = GetEnumDestructable()

                    if IsDestructableTree(d) then
                        call TriggerRegisterDeathEvent(trig, d)
                    endif

                    set d = null
                else
                    call TriggerRegisterDeathEvent(trig, GetEnumDestructable())
                endif
            else
                call TriggerRegisterDeathEvent(trig, GetEnumDestructable())
            endif
        endmethod

        implement DestructableRevivalInit
    endstruct

endlibrary