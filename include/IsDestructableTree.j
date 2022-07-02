library IsDestructableTree uses optional UnitIndexer /* v1.3.1
*************************************************************************************
*
*   Detect whether a destructable is a tree or not.  
*
***************************************************************************
*
*   Credits
*
*       To PitzerMike
*       -----------------------
*
*           for IsDestructableTree
*
*************************************************************************************
*
*    Functions
*
*       function IsDestructableTree takes destructable d returns boolean
*
*       function IsDestructableAlive takes destructable d returns boolean
*
*       function IsDestructableDead takes destructable d returns boolean
*
*       function IsTreeAlive takes destructable tree returns boolean
*           - May only return true for trees.          
*
*       function KillTree takes destructable tree returns boolean
*           - May only kill trees.
*
*/
    globals
        private constant integer HARVESTER_UNIT_ID = 'hpea'//*  human peasant
        private constant integer HARVEST_ABILITY   = 'Ahrl'//*  ghoul harvest
        private constant integer HARVEST_ORDER_ID  = 0xD0032//* harvest order ( 852018 )
        private constant player  NEUTRAL_PLAYER    = Player(PLAYER_NEUTRAL_PASSIVE)
        private unit harvester                     = null
    endglobals
    function IsDestructableTree takes destructable d returns boolean
        //*  851973 is the order id for stunned, it will interrupt the preceding harvest order.
        return (IssueTargetOrderById(harvester, HARVEST_ORDER_ID, d)) and (IssueImmediateOrderById(harvester, 851973))
    endfunction
    function IsDestructableDead takes destructable d returns boolean
        return (GetWidgetLife(d) <= 0.405)
    endfunction
    function IsDestructableAlive takes destructable d returns boolean
        return (GetWidgetLife(d) > .405)
    endfunction
    function IsTreeAlive takes destructable tree returns boolean
        return IsDestructableAlive(tree) and IsDestructableTree(tree)
    endfunction
    function KillTree takes destructable tree returns boolean
        if (IsTreeAlive(tree)) then
            call KillDestructable(tree)
            return true
        endif
        return false
    endfunction
    private function Init takes nothing returns nothing
        static if LIBRARY_UnitIndexer then//*  You may adapt this to your own indexer.
            set UnitIndexer.enabled = false
        endif
        set harvester = CreateUnit(NEUTRAL_PLAYER, HARVESTER_UNIT_ID, 0, 0, 0)
        static if LIBRARY_UnitIndexer then
            set UnitIndexer.enabled = true
        endif
        call UnitAddAbility(harvester, HARVEST_ABILITY)
        call UnitAddAbility(harvester, 'Aloc')
        call ShowUnit(harvester, false)
    endfunction
    //*  Seriously?
    private module Inits
        private static method onInit takes nothing returns nothing
            call Init()
        endmethod
    endmodule
    private struct I extends array
        implement Inits
    endstruct
   
endlibrary