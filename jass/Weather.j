/*****************************************************************************
*
*    Weather v1.1.0.0
*       by Bannar aka Spinnaker
*
*    Defines Weather struct family, for better weathereffect management.
*
******************************************************************************
*
*    Optional requirements:
*
*       Table by Bribe
*          hiveworkshop.com/forums/jass-resources-412/snippet-new-table-188084/
*
*       Alloc - choose whatever you like
*
******************************************************************************
*
*    Function:
*
*       function GetRectWeather takes rect r, WeatherType wt returns WeatherEffect
*          returns WeatherEffect instance (if exists) associated with rect r of type wt
*
******************************************************************************
*
*    struct WeatherType:
*
*       constant type    Rain
*       constant type    Shield
*       constant type    DungeonFog
*       constant type    Snow
*       constant type    Wind
*       constant type    Ray
*
******************************************************************************
*
*    struct WeatherStyle:
*
*       Fields:
*
*        | readonly integer effectId
*        |    static id of weathereffect style
*        |
*        | readonly WeatherType type
*        |    generic type of weathereffect
*
*       constant style    AshenvaleRainHeavy
*       constant style    AshenvaleRainLight
*       constant style    DalaranShield
*       constant style    DungeonBlueFogHeavy
*       constant style    DungeonBlueFogLight
*       constant style    DungeonGreenFogHeavy
*       constant style    DungeonGreenFogLight
*       constant style    DungeonRedFogHeavy
*       constant style    DungeonRedFogLight
*       constant style    DungeonWhiteFogHeavy
*       constant style    DungeonWhiteFogLight
*       constant style    LordaeronRainHeavy
*       constant style    LordaeronRainLight
*       constant style    NorthrendBlizzard
*       constant style    NorthrendSnowHeavy
*       constant style    NorthrendSnowLight
*       constant style    OutlandWindHeavy
*       constant style    OutlandWindLight
*       constant style    RaysOfLight
*       constant style    RaysOfMoonlight
*       constant style    WindHeavy
*
******************************************************************************
*
*    struct WeatherEffect:
*
*       Fields:
*
*        | readonly weathereffect weather
*        |    actual weathereffect handle
*        |
*        | readonly rect where
*        |    area which weathereffect is associated with
*        |
*        | readonly boolean enabled
*        |    indicates whether weathereffect is visible or not
*        |
*        | method operator style takes nothing returns WeatherStyle
*        | method operator style= takes WeatherStyle ws returns nothing
*        |    generic style of weathereffect
*
*       Methods:
*
*        | static method create takes rect r, WeatherStyle ws returns thistype
*        |    default ctor, creates new WeatherEffect given the rect and WeatherStyle
*        |
*        | method destroy takes nothing returns nothing
*        |    default dctor
*        |
*        | method enable takes nothing returns nothing
*        |    enables this weathereffect on associated rect
*        |
*        | method disable takes nothing returns nothing
*        |    disables this weathereffect on associated rect
*
*****************************************************************************/
library WeatherEffect uses optional Table, optional Alloc

struct WeatherType extends array
    readonly static thistype    Rain          = 1
    readonly static thistype    Shield        = 2
    readonly static thistype    DungeonFog    = 3
    readonly static thistype    Snow          = 4
    readonly static thistype    Wind          = 5
    readonly static thistype    Ray           = 6
endstruct

private module WeatherStyleInit
    private static method onInit takes nothing returns nothing
        set AshenvaleRainHeavy      = create('RAhr', WeatherType.Rain)
        set AshenvaleRainLight      = create('RAlr', WeatherType.Rain)
        set DalaranShield           = create('MEds', WeatherType.Shield)
        set DungeonBlueFogHeavy     = create('FDbh', WeatherType.DungeonFog)
        set DungeonBlueFogLight     = create('FDbl', WeatherType.DungeonFog)
        set DungeonGreenFogHeavy    = create('FDgh', WeatherType.DungeonFog)
        set DungeonGreenFogLight    = create('FDgl', WeatherType.DungeonFog)
        set DungeonRedFogHeavy      = create('FDrh', WeatherType.DungeonFog)
        set DungeonRedFogLight      = create('FDrl', WeatherType.DungeonFog)
        set DungeonWhiteFogHeavy    = create('FDwh', WeatherType.DungeonFog)
        set DungeonWhiteFogLight    = create('FDwl', WeatherType.DungeonFog)
        set LordaeronRainHeavy      = create('RLhr', WeatherType.Rain)
        set LordaeronRainLight      = create('RLlr', WeatherType.Rain)
        set NorthrendBlizzard       = create('SNbs', WeatherType.Snow)
        set NorthrendSnowHeavy      = create('SNhs', WeatherType.Snow)
        set NorthrendSnowLight      = create('SNls', WeatherType.Snow)
        set OutlandWindHeavy        = create('WOcw', WeatherType.Wind)
        set OutlandWindLight        = create('WOlw', WeatherType.Wind)
        set RaysOfLight             = create('LRaa', WeatherType.Ray)
        set RaysOfMoonlight         = create('LRma', WeatherType.Ray)
        set WindHeavy               = create('WNcw', WeatherType.Wind)
    endmethod
endmodule

struct WeatherStyle extends array
    private static integer count = 1 // up to 21
    readonly integer effectId
    readonly WeatherType type

    readonly static thistype    AshenvaleRainHeavy
    readonly static thistype    AshenvaleRainLight
    readonly static thistype    DalaranShield
    readonly static thistype    DungeonBlueFogHeavy
    readonly static thistype    DungeonBlueFogLight
    readonly static thistype    DungeonGreenFogHeavy
    readonly static thistype    DungeonGreenFogLight
    readonly static thistype    DungeonRedFogHeavy
    readonly static thistype    DungeonRedFogLight
    readonly static thistype    DungeonWhiteFogHeavy
    readonly static thistype    DungeonWhiteFogLight
    readonly static thistype    LordaeronRainHeavy
    readonly static thistype    LordaeronRainLight
    readonly static thistype    NorthrendBlizzard
    readonly static thistype    NorthrendSnowHeavy
    readonly static thistype    NorthrendSnowLight
    readonly static thistype    OutlandWindHeavy
    readonly static thistype    OutlandWindLight
    readonly static thistype    RaysOfLight
    readonly static thistype    RaysOfMoonlight
    readonly static thistype    WindHeavy

    private static method create takes integer id, WeatherType t returns thistype
        local thistype this = count
        set effectId = id
        set type = t

        set count = count + 1

        return this
    endmethod

    implement WeatherStyleInit
endstruct

static if LIBRARY_Table then
    private module WeatherBaseInit
        private static method onInit takes nothing returns nothing
            set table = TableArray[7]
        endmethod
    endmodule
endif

private struct WeatherBase extends array
    static if LIBRARY_Table then
        static TableArray table
        implement WeatherBaseInit
    else
        static hashtable table = InitHashtable()
    endif
endstruct

function GetRectWeather takes rect r, WeatherType wt returns WeatherEffect
    static if LIBRARY_Table then
        return WeatherBase.table[wt][GetHandleId(r)]
    else
        return LoadInteger(WeatherBase.table, wt, GetHandleId(r))
    endif
endfunction

struct WeatherEffect extends array
    readonly weathereffect weather
    readonly rect where
    readonly boolean enabled
    private WeatherStyle wstyle

    private method init takes WeatherStyle ws returns nothing // assumes all the checks already happened
        if ( wstyle != 0 ) then
            call RemoveWeatherEffect(weather)
        endif

        set weather = AddWeatherEffect(where, ws.effectId)
        call EnableWeatherEffect(weather, enabled)

        if ( ws.type != wstyle.type ) then
            static if LIBRARY_Table then
                call WeatherBase.table[wstyle.type].remove(GetHandleId(where))
                set WeatherBase.table[ws.type][GetHandleId(where)] = this
            else
                call RemoveSavedInteger(WeatherBase.table, wstyle.type, GetHandleId(where))
                call SaveInteger(WeatherBase.table, ws.type, GetHandleId(where), this)
            endif

            set wstyle = ws
        endif
    endmethod

    method operator style takes nothing returns WeatherStyle
        return wstyle
    endmethod

    method operator style= takes WeatherStyle ws returns nothing
        local WeatherEffect we

        if ( ws != wstyle ) then
            set we = GetRectWeather(where, wstyle.type)
            if ( we == 0 or we == this ) then
                call init(ws) // initializes actual weathereffect
            debug else
                debug call DisplayTimedTextToPlayer(GetLocalPlayer(), 0, 0, 60, "WeatherEffect::operator style= failed assigning new style. Area is already connected with WeatherEffect instance of type: " + I2S(ws.type) + ".")
            endif
        endif
    endmethod

    implement optional Alloc

    static if not thistype.allocate.exists then
        private static integer instances = 0
        private thistype recycle

        static method allocate takes nothing returns thistype
            local thistype this = thistype(0).recycle

            if (this == 0) then
                set instances = instances + 1
                set this = instances
            else
                set thistype(0).recycle = this.recycle
            endif

            return this
        endmethod

        method deallocate takes nothing returns nothing
            set this.recycle = thistype(0).recycle
            set thistype(0).recycle = this
        endmethod
    endif

    static method create takes rect r, WeatherStyle ws returns thistype
        local thistype this = GetRectWeather(r, ws.type)

        if ( this == 0 ) then
            set this = allocate()
            set where = r
            set enabled = false
            call init(ws) // initializes actual weathereffect
        debug else
            debug call DisplayTimedTextToPlayer(GetLocalPlayer(), 0, 0, 60, "WeatherEffect::create failed allocating new instance. Area is already connected with WeatherEffect instance of type: " + I2S(ws.type) + ".")
        endif

        return this
    endmethod

    method destroy takes nothing returns nothing
        static if LIBRARY_Table then
            call WeatherBase.table[wstyle.type].remove(GetHandleId(where))
        else
            call RemoveSavedInteger(WeatherBase.table, wstyle.type, GetHandleId(where))
        endif

        call RemoveWeatherEffect(weather)
        set weather = null
        set where = null
        set wstyle = 0

        call deallocate()
    endmethod

    method enable takes nothing returns nothing
        set enabled = true
        call EnableWeatherEffect(weather, enabled)
    endmethod

    method disable takes nothing returns nothing
        set enabled = false
        call EnableWeatherEffect(weather, enabled)
    endmethod
endstruct

endlibrary