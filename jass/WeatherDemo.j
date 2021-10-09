scope WeatherTest initializer Init

private function StartWeather takes nothing returns nothing
    local WeatherEffect we = WeatherEffect.create(bj_mapInitialPlayableArea, WeatherStyle.AshenvaleRainHeavy)
    local WeatherEffect we2 = WeatherEffect.create(bj_mapInitialPlayableArea, WeatherStyle.DalaranShield)

    call we.enable()
    call we2.enable()

    if ( we.enabled ) then
        set we.style = WeatherStyle.LordaeronRainLight
    endif

    call DestroyTimer(GetExpiredTimer())
endfunction

private function Init takes nothing returns nothing
    call TimerStart(CreateTimer(), 5, false, function StartWeather)
endfunction

endscope