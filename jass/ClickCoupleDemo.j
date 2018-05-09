struct ClickCoupleDemo extends array
    private method onDoubleClick takes nothing returns nothing
        call DisplayTimedTextToPlayer(Player(this), 0, 0, 90000, GetPlayerName(clicker) + " double clicked: " + GetUnitName(clicked))
    endmethod

    private static method filterPlayer takes player p returns boolean
        if (GetLocalPlayer() == p) then
            call DisplayTextToPlayer(p, 0, 0, GetPlayerName(p) + " was filtered")
            return true
        endif
        return true
    endmethod

    implement ClickCoupleStruct

    private static method onClick takes nothing returns nothing
        call DisplayTimedTextToPlayer(GetLocalPlayer(), 0, 0, 90000, GetPlayerName(GetEventClickingPlayer()) + " double clicked: " + GetUnitName(GetEventClickedUnit()))
    endmethod

    private static method onInit takes nothing returns nothing
        call RegisterDoubleClickEvent(Player(0), function thistype.onClick)
    endmethod
endstruct