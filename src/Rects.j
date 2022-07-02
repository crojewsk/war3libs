/*****************************************************************************
*
*    Rects v2.0.1.1
*       by Bannar
*
*    Handly rectangle manipulation.
*
******************************************************************************
*
*    Requirements:
*
*       Alloc - choose whatever you like
*          e.g.: by Sevion hiveworkshop.com/threads/snippet-alloc.192348/
*
*
*    Optional requirement:
*
*       Real2D by Bannar
*          hiveworkshop.com/threads/snippet-real2d.249100/
*
******************************************************************************
*
*    Interface RectsForCellAction:
*
*       static method forCell takes real x, real y returns nothing
*          Performs action on specified rectangle cell.
*
*       module RectsForCellActionModule
*          Declares body for new action type.
*
*
*    Action implementation example:
*
*        | struct MyAction extends array
*        |     static method forCell takes real x, real y returns nothing
*        |         call CreateItem('crys', x, y)
*        |     endmethod
*        |
*        |     implement RectsForCellActionModule
*        | endstruct
*
******************************************************************************
*
*    struct Rect:
*
*       General:
*
*        | static method create takes real x, real y, real w, real h returns thistype
*        |    Default ctor.
*        |
*        | static method operator[] takes thistype other returns thistype
*        |    Copy ctor.
*        |
*        | method destroy takes nothing returns nothing
*        |    Default dctor.
*
*
*       Fields:
*
*        | real minX
*        | real minY
*        | real maxX
*        | real maxY
*        | real width
*        | real height
*        |
*        | readonly Coord coord
*        |    Coordinate object determining minX & minY. Requires Real2D.
*        |
*        | readonly Size size
*        |    Size object determining width & height. Requires Real2D.
*        |
*        | readonly real centerX
*        |    Center X of the rectangle.
*        |
*        | readonly real centerY
*        |    Center Y of the rectangle.
*        |
*        | readonly rect rect
*        |    Returns the underlying rect handle.
*
*
*       Methods:
*
*        | method refresh takes nothing returns nothing
*        |    Forces a refresh on the underlying rect handle.
*        |
*        | method moveTo takes real x, real y returns thistype
*        |    Center rect to specified coordinates.
*        |
*        | method empty takes nothing returns boolean
*        |    Checks whether rectangle is empty.
*        |
*        | method contains takes real x, real y returns boolean
*        |    Whether speficied value is within given rectangle.
*        |
*        | method containtsRect takes Rects r returns boolean
*        | method containsItem takes item itm returns boolean
*        | method containsUnit takes unit u returns boolean
*        | method containsDestructable takes destructable d returns boolean
*        |
*        | method inflate takes real dx, real dy returns thistype
*        |    Increases the size of the rectangle.
*        |
*        | method deflate takes real dx, real dy returns thistype
*        |    Decreases the rectangle size.
*        |
*        | method offset takes real dx, real dy returns thistype
*        |    Moves the rectangle by the specified offset.
*        |
*        | method intersect takes Rects r returns thistype
*        |    Modifies this rectangle to contain the overlapping portion of this rectangle and the one passed in as parameter.
*        |
*        | method getIntersecting takes Rects r returns thistype
*        |    Returns the overlapping portion of this rectangle and the one passed in as parameter.
*        |
*        | method intersects takes Rects r returns boolean
*        |    Returns true if this rectangle has a non-empty intersection with the rectangle rect and false otherwise.
*        |
*        | method union takes Rects r returns thistype
*        |    Modifies the rectangle to contain the bounding box of this rectangle and the one passed in as parameter.
*        |
*        | method forEach takes RectsForCellAction action, real radius returns thistype
*        |    Performs the specified action on each cell found within rectangle.
*
*
*       Methods requiring Real2D:
*
*        | static method createFromCoords takes Coord c1, Coord c2 returns thistype
*        | static method createFromCoordSize takes Coord c, Size s returns thistype
*        |    Factory ctors.
*        |
*        | method containsCoord takes Coord c returns boolean
*        | method offsetCoord takes Coord c returns thistype
*        |
*        | method inflateSize takes Size s returns thistype
*        | method deflateSize takes Size s returns thistype
*
*
*****************************************************************************/
library Rects requires Alloc optional Real2D

globals
    private trigger array triggers
    // iteration related globals
    private real argRadius = 0.0
    private Rects argRect = 0
endglobals

struct RectsForCellAction extends array
    implement Alloc

    static method forCell takes real x, real y returns nothing
        return
    endmethod

    static method create takes nothing returns thistype
        local thistype this = allocate()
        set triggers[this] = CreateTrigger()
        return this
    endmethod

    method destroy takes nothing returns nothing
        call DestroyTrigger(triggers[this])
        set triggers[this] = null
        call deallocate()
    endmethod
endstruct

module RectsForCellActionModule
    private delegate RectsForCellAction parent

    private static method onInvoke takes nothing returns nothing
        local real x = argRect.minX
        local real y

        loop
            set y = argRect.minY
            loop
                call thistype.forCell(x, y)
                set y = y + argRadius
                exitwhen y > argRect.maxY
            endloop

            set x = x + argRadius
            exitwhen x > argRect.maxX
        endloop
    endmethod

    static method create takes nothing returns thistype
        local thistype this = RectsForCellAction.create()
        set parent = this
        call TriggerAddCondition(triggers[this], Condition(function thistype.onInvoke))
        return this
    endmethod

    method destroy takes nothing returns nothing
        call parent.destroy()
    endmethod
endmodule

struct Rects extends array
    readonly rect rect

    implement Alloc

static if not LIBRARY_Real2D then
    real minX
    real minY
    real width
    real height
else
    readonly Coord coord
    readonly Size size

    method operator width takes nothing returns real
        return size.width
    endmethod

    method operator height takes nothing returns real
        return size.height
    endmethod

    method operator minX takes nothing returns real
        return coord.x
    endmethod

    method operator minY takes nothing returns real
        return coord.y
    endmethod

    method operator width= takes real w returns nothing
        set size.width = w
    endmethod

    method operator height= takes real h returns nothing
        set size.height = h
    endmethod

    method operator minX= takes real x returns nothing
        set coord.x = x
    endmethod

    method operator minY= takes real y returns nothing
        set coord.y = y
    endmethod
endif

    method operator maxX takes nothing returns real
        return minX + width
    endmethod

    method operator maxY takes nothing returns real
        return minY + height
    endmethod

    method operator centerX takes nothing returns real
        return minX + (width / 2)
    endmethod

    method operator centerY takes nothing returns real
        return minY + (height / 2)
    endmethod

    method operator maxX= takes real x returns nothing
        set width = x - minX
    endmethod

    method operator maxY= takes real y returns nothing
        set height = y - minY
    endmethod

    method refresh takes nothing returns nothing
        call SetRect(rect, minX, minY, maxX, maxY)
    endmethod

    method moveTo takes real x, real y returns thistype
        set minX = x - (width * 0.5)
        set minY = y - (height * 0.5)
        call refresh()
        return this
    endmethod

    method empty takes nothing returns boolean
        return width <= 0 or height <= 0
    endmethod

    static method create takes real x, real y, real w, real h returns thistype
        local thistype this = allocate()

        static if LIBRARY_Real2D then
            set coord = Coord.create(x, y)
            set size = Size.create(w, h)
        else
            set minX = x
            set minY = y
            set width = w
            set height = h
        endif

        set rect = Rect(x, y, x+w, y+h)

        return this
    endmethod

    static method operator[] takes thistype other returns thistype
        return create(other.minX, other.minY, other.width, other.height)
    endmethod

    method destroy takes nothing returns nothing
        call RemoveRect(rect)
        set rect = null

        static if LIBRARY_Real2D then
            call coord.destroy()
            call size.destroy()
            set coord = 0
            set size = 0
        endif

        call deallocate()
    endmethod

    method contains takes real x, real y returns boolean
        return x >= minX and y >= minY and (y - minY) < height and (x - minX) < width
    endmethod

    method containtsRect takes Rects r returns boolean
        return contains(r.minX, r.minY) and contains(r.maxX, r.maxY)
    endmethod

    method containsItem takes item itm returns boolean
        return itm != null and not IsItemOwned(itm) and contains(GetItemX(itm), GetItemY(itm))
    endmethod

    method containsUnit takes unit u returns boolean
        return u != null and contains(GetUnitX(u), GetUnitY(u))
    endmethod

    method containsDestructable takes destructable d returns boolean
        return d != null and contains(GetDestructableX(d), GetDestructableY(d))
    endmethod

    method inflate takes real dx, real dy returns thistype
        if (-2 * dx) > width then
            set minX = centerX
            set width = 0
        else
            set minX = minX - dx
            set width = width + (2 * dx)
        endif

        if (-2 * dy) > height then
            set minY = centerY
            set height = 0
        else
            set minY = minY - dy
            set height = height + (2 * dy)
        endif

        call refresh()
        return this
    endmethod

    method deflate takes real dx, real dy returns thistype
        return inflate(-dx, -dy)
    endmethod

    method offset takes real dx, real dy returns thistype
        set minX = minX + dx
        set minY = minY + dy
        call refresh()
        return this
    endmethod

    method intersect takes Rects r returns thistype
        local real x2 = maxX
        local real y2 = maxY

        if minX < r.minX then
            set minX = r.minX
        endif
        if minY < r.minY then
            set minY = r.minY
        endif
        if x2 > r.maxX then
            set x2 = r.maxX
        endif
        if y2 > r.maxY then
            set y2 = r.maxY
        endif

        set width = x2 - minX
        set height = y2 - minY

        if width <= 0 or height <= 0 then
            set width = 0
            set height = 0
        endif

        call refresh()
        return this
    endmethod

    method getIntersecting takes Rects r returns thistype
        local real x1 = minX
        local real y1 = minY
        local real x2 = maxX
        local real y2 = maxY
        local real w
        local real h

        if minX < r.minX then
            set x1 = r.minX
        endif
        if minY < r.minY then
            set y1 = r.minY
        endif
        if x2 > r.maxX then
            set x2 = r.maxX
        endif
        if y2 > r.maxY then
            set y2 = r.maxY
        endif

        set w = x2 - minX
        set h = y2 - minY

        if w <= 0 or h <= 0 then
            set w = 0
            set h = 0
        endif

        return create(x1, y1, w, h)
    endmethod

    method intersects takes Rects r returns boolean
        local Rects tmp = getIntersecting(r)
        local boolean result

        set result = (tmp.width != 0)
        call tmp.destroy()

        return result
    endmethod

    private static method min takes real x1, real x2 returns real
        if x1 <= x2 then
            return x1
        endif
        return x2
    endmethod

    private static method max takes real x1, real x2 returns real
        if x1 >= x2 then
            return x1
        endif
        return x2
    endmethod

    method union takes Rects r returns thistype
        local real x1
        local real y1
        local real x2
        local real y2

        if width == 0 or height == 0 then
            set minX = r.minX
            set minY = r.minY
            set width = r.width
            set height = r.height
        else
            set x1 = min(minX, r.minX)
            set y1 = min(minY, r.minY)
            set x2 = max(maxX, r.maxX)
            set y2 = max(maxY, r.maxY)

            set minX = x1
            set minY = y1
            set width = x2 - x1
            set height = y2 - y1
        endif

        call refresh()
        return this
    endmethod

    method forEach takes RectsForCellAction action, real radius returns thistype
        set argRadius = radius
        set argRect = this
        call TriggerEvaluate(triggers[action])
        return this
    endmethod

static if LIBRARY_Real2D then
    static method createFromCoords takes Coord c1, Coord c2 returns thistype
        local thistype this = allocate()

        set coord = Coord.create(c1.x, c1.y)
        set size = Size.create(c2.x - c1.x, c2.y - c1.y)

        if width < 0 then
            set size.width = -width
            set coord.x = c2.x
        endif

        if height < 0 then
            set size.height = -height
            set coord.y = c2.y
        endif

        set rect = Rect(minX, minY, maxX, maxY)
        return this
    endmethod

    static method createFromCoordSize takes Coord c, Size s returns thistype
        return create(c.x, c.y, s.width, s.height)
    endmethod

    method containsCoord takes Coord c returns boolean
        return contains(c.x, c.y)
    endmethod

    method offsetCoord takes Coord c returns thistype
        return offset(c.x, c.y)
    endmethod

    method inflateSize takes Size s returns thistype
        return inflate(s.width, s.height)
    endmethod

    method deflateSize takes Size s returns thistype
        return inflate(-s.width, -s.height)
    endmethod
endif
endstruct

endlibrary