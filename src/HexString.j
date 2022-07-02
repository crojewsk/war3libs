/*****************************************************************************
*
*    HexString v1.0.0.3
*       by Bannar aka Spinnaker
*
*    Performs conversions from hexadecimal numbers to strings and vice versa.
*
*       Credits to TheDamien for hash formula from original Ascii project
*
******************************************************************************
*
*    private constant boolean ADD_PREFIX
*       whether to add or not the "0x" prefix; used only in I2HS function
*
*
*    function I2HS takes integer hex, boolean upper returns string
*       returns hexadecimal representation of hex as string
*
*    function HS2I takes string s returns integer
*       returns integral number retrieved from s representing number in hexadecimal convention
*
*****************************************************************************/
library HexString

globals
    /**
        Config
    */
    private constant boolean ADD_PREFIX = true
endglobals

globals
    private string array Id2CharMap // (16)
    private integer array Int2IdMap // (16)
endglobals

function I2HS takes integer hex, boolean upper returns string
    local string s = ""
    local integer div

    loop
        set div = hex/16
        set s = Id2CharMap[hex - div * 16] + s
        set hex = div
        exitwhen hex == 0
    endloop

    if ( upper ) then
        set s = StringCase(s, true)
    endif
    static if ( ADD_PREFIX ) then
        set s = "0x" + s
    endif
    return s
endfunction

function HS2I takes string s returns integer
    local integer size = StringLength(s)
    local integer hex = 0
    local integer it = 0
    local integer key
    local string char

    if ( SubString(s, 0, 2) == "0x" ) then
        set s = SubString(s, 2, size)
        set size = size - 2
    endif

    loop
        exitwhen it == size

        set char = SubString(s, it, it+1)
        set key = Int2IdMap[StringHash(char) / 0x1F0748 + 0x3EA]

        debug if (key == 0) then
            debug call DisplayTimedTextToPlayer(GetLocalPlayer(), 0, 0, 60, "DEBUG: Hex::HS2I Invalid string character.")
            debug return -1
        debug endif

        set hex = hex*16 + (key-1)
        set it = it+1
    endloop

    return hex
endfunction

private module HexInit
    private static method onInit takes nothing returns nothing
        set Id2CharMap[0] = "0"
        set Id2CharMap[1] = "1"
        set Id2CharMap[2] = "2"
        set Id2CharMap[3] = "3"
        set Id2CharMap[4] = "4"
        set Id2CharMap[5] = "5"
        set Id2CharMap[6] = "6"
        set Id2CharMap[7] = "7"
        set Id2CharMap[8] = "8"
        set Id2CharMap[9] = "9"

        set Id2CharMap[10] = "a"
        set Id2CharMap[11] = "b"
        set Id2CharMap[12] = "c"
        set Id2CharMap[13] = "d"
        set Id2CharMap[14] = "e"
        set Id2CharMap[15] = "f"

        set Int2IdMap[883]  = 1
        set Int2IdMap[1558] = 2
        set Int2IdMap[684]  = 3
        set Int2IdMap[582]  = 4
        set Int2IdMap[668]  = 5
        set Int2IdMap[538]  = 6
        set Int2IdMap[672]  = 7
        set Int2IdMap[1173] = 8
        set Int2IdMap[71]   = 9
        set Int2IdMap[277]  = 10

        set Int2IdMap[222]  = 11
        set Int2IdMap[178]  = 12
        set Int2IdMap[236]  = 13
        set Int2IdMap[184]  = 14
        set Int2IdMap[1295] = 15
        set Int2IdMap[1390] = 16
    endmethod
endmodule

private struct Hex extends array
    implement HexInit
endstruct

endlibrary