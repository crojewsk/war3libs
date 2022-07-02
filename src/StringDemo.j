struct StringTest extends array

    static method print takes string s returns nothing
        call DisplayTimedTextFromPlayer(GetLocalPlayer(), 0, 0, 60, s)
    endmethod

    static method onInit takes nothing returns nothing
        local String s = String.create("this is a test string.")

        call print(s.str)                                                // this is a test string.
        call s.replace(9,5,"n example")
        call print("\nAfter replacing pos 5 span 9: "+s.str)             // this is an example string.
        call s.destroy()

        call PolledWait(4.0)

        set s = String.create("question string?")
        call print("New string: "+s.str)                                 // question string?
        call s.insert(0, "hmm, ")
        call print("\nAfter inserting at possition 0 'hmm, ': "+s.str)   // hmm, question string?
        call print("Character at pos 8: "+s[8])                          // 's'

        set s[4] = "Xxxx"                                                // this also makes sure that only single char will be set
        call print("\nInserted 'Xxxx' value at pos 4: "+s.str)           // hmm,Xquestion string?

        call s.assign("some things are just worth fighting for")
        call print(s.str)                                                // some things are just worth fighting for

        call print("\nSearching for 'igh'")
        call print("found at pos: "+I2S(s.rfind("igh",String.npos)))     // found at pos: 28

        call s.assign("This is an example sentence.")
        call s.erase(10,8)
        call print("\nAfter erasing 8 characters starting from pos 10: "+s.str) // This is an sentence.

        call print("\nCharacter at pos 6: "+s[6])                        // s
        call print(s.upper())                                            // THIS IS AN SENTENCE.
        call print(s.lower())                                            // this is an sentence.
    endmethod

endstruct