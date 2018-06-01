scope DestructableRevivalDemo initializer Init

struct MyRevivalFilter extends array
    static method shouldRevive takes destructable whichDest returns boolean
        return IsDestructableTree(whichDest)
    endmethod

    implement DestructableRevivalFilterModule
endstruct

struct MyRevivalCondition extends array
    static method shouldExtend takes destructable whichDest returns real
        if GetClosestUnitInRange(GetDestructableX(whichDest), GetDestructableY(whichDest), 200, null) != null then
            return 4.0
        endif
        return 0.0
    endmethod

    implement DestructableRevivalConditionModule
endstruct

private function Init takes nothing returns nothing
    call AddDestructableRevivalFilter(MyRevivalFilter.create())
    call AddDestructableRevivalCondition(MyRevivalCondition.create())
endfunction

endscope