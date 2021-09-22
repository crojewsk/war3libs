library RectsTest requires Rects, Real2D

struct RectsForCellActionTest extends array
    static method forCell takes real x, real y returns nothing
        call CreateItem('crys', x, y)
    endmethod

    implement RectsForCellActionModule
endstruct

struct RectsTest extends array
    static method draw_rect takes Rects rec, string lightType returns nothing
        call AddLightning(lightType, true, rec.minX, rec.minY, rec.minX, rec.maxY)
        call AddLightning(lightType, true, rec.maxX, rec.minY, rec.maxX, rec.maxY)

        call AddLightning(lightType, true, rec.minX, rec.minY, rec.maxX, rec.minY)
        call AddLightning(lightType, true, rec.minX, rec.maxY, rec.maxX, rec.maxY)
    endmethod

    static method wait takes real period returns nothing
        call TriggerSleepAction(period)
    endmethod

    static method print takes real period, string what returns nothing
        call DisplayTimedTextToPlayer(Player(0), 0, 0, period, what)
        call wait(period)
    endmethod

    static method onInit takes nothing returns nothing
        local Coord pt = Coord.create(-200, -300)
        local Size sz = Size.create(700, 800)
        local Rects rec = Rects.createFromCoordSize(pt, sz)
        local Rects rec2 = 0

        call wait(2)
        call draw_rect(rec, "CLPB")
        call print(5, "Initial rect |c000080FF(blue)|r: " + R2S(rec.minX) + " " + R2S(rec.minY) + " " + R2S(rec.maxX) + " " +R2S(rec.maxY) )

        call rec.forEach(RectsForCellActionTest.create(), 50)
        call print(5, "\nFilled with Crystal Balls..")

        call print(5, "Now, lets create second rect nearby and use it to intersect with our initial one.")
        set rec2 = Rects.create(300, 300, 800, 800)
        call draw_rect(rec2, "LEAS")
        call print(5, "\nOur second rect |c00FF8000(orange)|r: " + R2S(rec2.minX) + " " + R2S(rec2.minY) + " " + R2S(rec2.maxX) + " " +R2S(rec2.maxY) )

        call print(5, "Lets intersect it and see the results:")
        call rec.intersect(rec2)
        call draw_rect(rec, "AFOD")
        call print(5, "\nIntersected rect |c00FF0000(red)|r: " + R2S(rec.minX) + " " + R2S(rec.minY) + " " + R2S(rec.maxX) + " " +R2S(rec.maxY) )

        call pt.setXY(200, 200)
        set sz.width = 300

        call rec.coord.setXY(pt.x, pt.y)
        call rec.size.setWH(sz.width, sz.height)
        call rec.refresh()

        call print(5, "Time to resize our rect. New width: 300; point: (200, 200).")
        call draw_rect(rec, "DRAL")
        call print(5, "\nResized rect |c0000FF00(green)|r: " + R2S(rec.minX) + " " + R2S(rec.minY) + " " + R2S(rec.maxX) + " " +R2S(rec.maxY) )

        call print(5, "Before we finish, perform inflate method. Values: 150, 275.")
        call rec.inflate(150, 275)
        call draw_rect(rec, "HWPB")
        call print(5, "\nInflated rect |c00FFFF00(yellow)|r: " + R2S(rec.minX) + " " + R2S(rec.minY) + " " + R2S(rec.maxX) + " " +R2S(rec.maxY) )

        call print(5, "Thank you for your undivided attention.")
    endmethod

endstruct

endlibrary