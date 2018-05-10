scope ClickCoupleDemo initializer Init

private function OnDoubleClick takes nothing returns nothing
    call DisplayTimedTextToPlayer(GetLocalPlayer(), 0, 0, 60, GetPlayerName(GetEventClickingPlayer()) + " double clicked: " + GetUnitName(GetEventClickedUnit()))
endfunction

private function Init takes nothing returns nothing
    call RegisterNativeEvent(EVENT_PLAYER_DOUBLE_CLICK, function OnDoubleClick)
endfunction

endscope