/*****************************************************************************
*
*    Real2D v1.1.0.3
*       by Bannar aka Spinnaker
*
*    Interpretation of coordinate and size objects usefull for graphic operations.
*
******************************************************************************
*
*    struct Coord:
*
*       real x
*       real y
*
*       static method create takes real xx, real yy returns thistype
*          default ctor
*
*       static method createFromLoc takes location l returns thistype
*          location ctor
*
*       static method operator[] takes thistype c returns thistype
*          copy ctor
*
*       method destroy takes nothing returns nothing
*          default dctor
*
*       method setXY takes real xx, real yy returns nothing
*          set both members of struct instance
*
*       method operator== takes thistype c returns boolean
*          equalTo operator
*
*       method project takes real dist, real angle returns thistype
*          projects coordinate by given distance towards specified angle
*
*       method offset takes real xx, real yy returns thistype
*          offsets coordinate by a vector(xx, yy)
*
*       method loc takes nothing returns location
*          returns location of Coord instance
*
******************************************************************************
*
*    struct Size:
*
*       real width
*       real height
*
*       static method create takes real ww, real hh returns thistype
*          default ctor
*
*       static method operator[] takes thistype s returns thistype
*          copy ctor
*
*       method destroy takes nothing returns nothing
*          default dctor
*
*       method setWH takes real ww, real hh returns nothing
*          set both members of struct instance
*
*       method operator== takes thistype s returns boolean
*          equalTo operator
*
*       method incTo takes thistype s returns thistype
*          increase width and height to s size
*
*       method decTo takes thistype s returns thistype
*          decrease width and height to s size
*
*       method incBy takes real dw, real dh returns thistype
*          increase size by specified values
*
*       method decBy takes real dw, real dh returns thistype
*          decrease size by specified values
*
*       method scale takes real wscale, real hscale returns thistype
*          rescale both width and height
*
******************************************************************************/
library Real2D

    struct Coord extends array
        private static integer count = 0
        private thistype recycle

        real x
        real y

        static method create takes real xx, real yy returns thistype
            local thistype this = thistype(0).recycle

            if ( this == 0 ) then
                set count = count + 1
                set this = count
            else
                set thistype(0).recycle = recycle
            endif

            set x = xx
            set y = yy

            return this
        endmethod

        static method createFromLoc takes location l returns thistype
            return create(GetLocationX(l), GetLocationY(l))
        endmethod

        static method operator[] takes thistype c returns thistype
            return create(c.x, c.y)
        endmethod

        method destroy takes nothing returns nothing
            set recycle = thistype(0).recycle
            set thistype(0).recycle = this
        endmethod

        method setXY takes real xx, real yy returns nothing
            set x = xx
            set y = yy
        endmethod

        method operator== takes thistype c returns boolean
            return ( x == c.x ) and ( y == c.y )
        endmethod

        method project takes real dist, real angle returns thistype
            set x = x + dist * Cos(angle * bj_DEGTORAD)
            set y = y + dist * Sin(angle * bj_DEGTORAD)
            return this
        endmethod

        method offset takes real xx, real yy returns thistype
            set x = x + xx
            set y = y + yy
            return this
        endmethod

        method loc takes nothing returns location
            return Location(x, y)
        endmethod
    endstruct

    struct Size extends array
        private static integer count = 0
        private thistype recycle

        real width
        real height

        static method create takes real ww, real hh returns thistype
            local thistype this = thistype(0).recycle

            if ( this == 0 ) then
                set count = count + 1
                set this = count
            else
                set thistype(0).recycle = recycle
            endif

            set width = ww
            set height = hh

            return this
        endmethod

        static method operator[] takes thistype s returns thistype
            return create(s.width, s.height)
        endmethod

        method destroy takes nothing returns nothing
            set recycle = thistype(0).recycle
            set thistype(0).recycle = this
        endmethod

        method setWH takes real ww, real hh returns nothing
            set width = ww
            set height = hh
        endmethod

        method operator== takes thistype s returns boolean
            return ( width == s.width ) and ( height == s.height )
        endmethod

        method incTo takes thistype s returns thistype
            if ( s.width > width ) then
                set width = s.width
            endif
            if ( s.height > height ) then
                set height = s.height
            endif

            return this
        endmethod

        method decTo takes thistype s returns thistype
            if ( s.width < width ) then
                set width = s.width
            endif
            if ( s.height < height ) then
                set height = s.height
            endif

            return this
        endmethod

        method incBy takes real dw, real dh returns thistype
            set width = width + dw
            set height = height + dh

            return this
        endmethod

        method decBy takes real dw, real dh returns thistype
            call incBy(-dw, -dh)
            return this
        endmethod

        method scale takes real wscale, real hscale returns thistype
            set width = width * wscale
            set height = height * hscale

            return this
        endmethod
    endstruct

endlibrary