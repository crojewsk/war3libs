struct ConstructEventDemo extends array

    private static method onStart takes nothing returns nothing
        call DisplayTimedTextToPlayer( GetLocalPlayer(), 0, 0, 5, GetUnitName(GetEventBuilder())+" started construction of: "+/*
        */GetUnitName(GetEventStructure())+" builder index: "+I2S(GetEventBuilderId())+/*
        */" life pts: "+R2S(GetWidgetLife(GetEventBuilder())))
    endmethod

    private static method onCancel takes nothing returns boolean
        call DisplayTimedTextToPlayer( GetLocalPlayer(), 0, 0, 5, GetUnitName(GetEventBuilder())+" cancelled construction of: "+/*
        */GetUnitName(GetEventStructure())+" structure index: "+I2S(GetEventStructureId())+/*
        */" life pts: "+R2S(GetWidgetLife(GetEventBuilder())))
        return false
    endmethod

    private static method onInterrupt takes nothing returns boolean
        call DisplayTimedTextToPlayer( GetLocalPlayer(), 0, 0, 5, GetUnitName(GetEventBuilder())+" construction interrupted: "+/*
        */GetUnitName(GetEventStructure())+" structure index: "+I2S(GetEventStructureId())+/*
        */" life pts: "+R2S(GetWidgetLife(GetEventBuilder())))
        return false
    endmethod

    private static method onFinish takes nothing returns nothing
        call DisplayTimedTextToPlayer( GetLocalPlayer(), 0, 0, 5, GetUnitName(GetEventBuilder())+" finished construction of: "+/*
        */GetUnitName(GetEventStructure())+" structure index: "+I2S(GetEventStructureId())+/*
        */" life pts: "+R2S(GetWidgetLife(GetEventBuilder())))
    endmethod

    private static method onInit takes nothing returns nothing
        local trigger t = CreateTrigger()

        call TriggerRegisterConstructEvent(t, ConstructEvent.CANCEL)
        call TriggerAddCondition(t, Condition(function thistype.onCancel))
        set t = null

        call RegisterConstructEvent(function thistype.onStart, ConstructEvent.START)
        call RegisterConstructEvent(function thistype.onInterrupt, ConstructEvent.INTERRUPT)
        call RegisterConstructEvent(function thistype.onFinish, ConstructEvent.FINISH)
    endmethod

endstruct