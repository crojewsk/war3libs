struct ascii_demo extends array
    private static method onInit takes nothing returns nothing
        local integer a = 0xFF
        local integer b = 0x2A

        local integer c = a + b
        call DisplayTimedTextFromPlayer(GetLocalPlayer(), 0, 0, 60, I2HS(a, true) + " + " + I2HS(b, true) + " = " + I2HS(c, true))

        call DisplayTimedTextFromPlayer(GetLocalPlayer(), 0, 0, 60, "(string) 0x0 as integral: " + I2S(HS2I("0x0")))
        call DisplayTimedTextFromPlayer(GetLocalPlayer(), 0, 0, 60, "(int) 0x1F0748 converted to string: " + I2HS(0x1F0748, true))
    endmethod
endstruct