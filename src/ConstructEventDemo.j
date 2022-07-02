scope ConstructEventDemo initializer Init

private function OnStart takes nothing returns nothing
    call DisplayTimedTextToPlayer(GetLocalPlayer(), 0, 0, 5, GetUnitName(GetConstructingBuilder())+" started construction of: "+/*
    */GetUnitName(GetTriggeringStructure())+" builder index: "+I2S(GetConstructingBuilderId())+/*
    */" builder life pts: "+R2S(GetWidgetLife(GetConstructingBuilder())))
endfunction

private function OnCancel takes nothing returns boolean
    call DisplayTimedTextToPlayer(GetLocalPlayer(), 0, 0, 5, GetUnitName(GetConstructingBuilder())+" cancelled construction of: "+/*
    */GetUnitName(GetTriggeringStructure())+" structure index: "+I2S(GetTriggeringStructureId())+/*
    */" builder life pts: "+R2S(GetWidgetLife(GetConstructingBuilder())))
    return false
endfunction

private function OnFinish takes nothing returns nothing
    call DisplayTimedTextToPlayer(GetLocalPlayer(), 0, 0, 5, GetUnitName(GetConstructingBuilder())+" finished construction of: "+/*
    */GetUnitName(GetTriggeringStructure())+" structure index: "+I2S(GetTriggeringStructureId())+/*
    */" builder life pts: "+R2S(GetWidgetLife(GetConstructingBuilder())))
endfunction

private function OnInterrupt takes nothing returns boolean
    call DisplayTimedTextToPlayer(GetLocalPlayer(), 0, 0, 5, GetUnitName(GetConstructingBuilder())+" construction interrupted: "+/*
    */GetUnitName(GetTriggeringStructure())+" structure index: "+I2S(GetTriggeringStructureId())+/*
    */" builder life pts: "+R2S(GetWidgetLife(GetConstructingBuilder())))
    return false
endfunction

private function Init takes nothing returns nothing
    call RegisterNativeEvent(EVENT_UNIT_CONSTRUCTION_START, function OnStart)
    call RegisterNativeEvent(EVENT_UNIT_CONSTRUCTION_CANCEL, function OnCancel)
    call RegisterNativeEvent(EVENT_UNIT_CONSTRUCTION_FINISH, function OnFinish)
    call RegisterNativeEvent(EVENT_UNIT_CONSTRUCTION_INTERRUPT, function OnInterrupt)
endfunction

endscope