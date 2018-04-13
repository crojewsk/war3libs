library UnitItemRestriction requires /*
                          */ Alloc /*
						  */ ListT /*
						  */ SimError /*  
						  */ RegisterPlayerUnitEvent

globals
	private Table Restrictions = 0
endglobals

private function GetUnitTypeErrorMessage takes integer unitId returns string
	return "This item can not be hold by this unit type."
endfunction

private function GetLevelErrorMessage takes integer level returns string
	return "This item requires level "+I2S(level)+" to be picked up."
endfunction

private function GetStatisticErrorMessage takes integer value, string statistic returns string
	return "This item requires "+I2S(value)+" "+statistic+"."
endfunction

private function GetLimitErrorMessage takes integer limit returns string
	return "This unit can not hold more items of this item type."
endfunction

private constant function GetExclusiveErrorMessage takes nothing returns string
	return "This unit has an item of exclusive type."
endfunction

private constant function GetForbiddenErrorMessage takes nothing returns string
	return "This item can not be picked up by this unit."
endfunction

private module ItemRestrictionInit
	private static method onInit takes nothing returns nothing
		/*set Restrictions = Table.create()
		set Requirements = Table.create()
		set Restrictions[0] = IntegerList.create() // global list
		set Requirements[0] = IntegerList.create() // global list
		set Restrictions[-1] = IntegerList.create() // association checking on pick up event

		call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_PICKUP_ITEM, function thistype.onPickUp)
		call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_DROP_ITEM, function thistype.onDrop)
		call RegisterPlayerUnitEvent(EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, function thistype.onOrder)
        call RegisterUnitIndexEvent(Condition(function thistype.onDeindex), EVENT_UNIT_DEINDEX)*/
	endmethod
endmodule

struct UnitRequirement extends array
	readonly IntegerList typeIds
	integer level
	integer strength
	integer agility
	integer intelligence
	boolean includeBonuses

	implement Alloc

	static method create takes nothing returns thistype
		local thistype this = allocate()

		set typeIds = IntegerList.create()
		set level = 0
		set strength = 0
		set agility = 0
		set intelligence = 0
        set includeBonuses = false

		return this
	endmethod

	method destroy takes nothing returns nothing
		call typeIds.destroy()
		call deallocate()
	endmethod

	method has takes integer unitTypeId returns boolean
		return typeIds.find(unitTypeId) != 0
	endmethod

	method requireStat takes integer str, integer agi, integer int returns thistype
		set strength = str
		set agility = agi
		set intelligence = int

		return this
	endmethod

	method test takes unit u returns string
		local integer unitTypeId = GetUnitTypeId(u)

		if (not typeIds.empty() and not has(unitTypeId)) then
			return GetUnitTypeErrorMessage(unitTypeId)
		elseif (level > 0 and GetHeroLevel(u) < level) then
			return GetLevelErrorMessage(level)
		elseif (strength > 0 and GetHeroStr(u, includeBonuses) < strength) then
			return GetStatisticErrorMessage(strength, "Strength")
		elseif (agility > 0 and GetHeroAgi(u, includeBonuses) < agility) then
			return GetStatisticErrorMessage(agility, "Agility")
		elseif (intelligence > 0 and GetHeroInt(u, includeBonuses) < intelligence) then
			return GetStatisticErrorMessage(intelligence, "Intelligence")
		endif

		return null
	endmethod

    method filter takes unit u returns boolean
        return test(u) == null
    endmethod
endstruct

struct LimitException extends array
    UnitRequirement requirement
    integer newLimit

    //implement Alloc

    static method create takes UnitRequirement requirement, integer newLimit returns thistype
        local thistype this = 0// allocate()

        set this.requirement = requirement
        set this.newLimit = newLimit

        return this
    endmethod
    
    method destroy takes nothing returns nothing
    endmethod
endstruct

struct ItemRestriction extends array
	private Table cache
	readonly IntegerList typeIds
	integer limit
	readonly IntegerList exceptions
	readonly IntegerList exclusives
    UnitRequirement requirement
	string name

	implement Alloc

	static method create takes string name, integer limit, UnitRequirement requirement returns thistype
		local thistype this = allocate()

		set cache = Table.create()
		set typeIds = IntegerList.create()
		set exceptions = IntegerList.create()
		set exclusives = IntegerList.create()
		set this.name = name
        set this.limit = limit
        set this.requirement = requirement

        call IntegerList(Restrictions[0]).push(this)

		return this
	endmethod

	method destroy takes nothing returns nothing
		local IntegerList restrictions
		local IntegerListItem node
		local IntegerListItem entry
		local ItemRestriction restriction

        set node = typeIds.first
        loop
            exitwhen node == 0
            set restrictions = Restrictions[node.data]
            set entry = restrictions.find(this)
            call restrictions.remove(entry)
            set node = node.next
        endloop

        set restrictions = Restrictions[0]
        set entry = restrictions.find(this)
        call restrictions.remove(entry)

		if not exclusives.empty() then
			set node = exclusives.first
			loop
				exitwhen node == 0
				set restriction = node.data
				set entry = restriction.exclusives.find(this)
				call restriction.exclusives.remove(entry)
				set node = node.next
			endloop
		endif

		call cache.destroy()
		call typeIds.destroy()
		call exceptions.destroy()
		call exclusives.destroy()
        set name = null
        set limit = 0

		call deallocate()
	endmethod

	method has takes integer itemTypeId returns boolean
		return typeIds.find(itemTypeId) != 0
	endmethod

	method removeTypeId takes integer itemTypeId returns thistype
		local IntegerListItem node = typeIds.find(itemTypeId)

		if node != 0 then
            call typeIds.remove(node)
		endif

		return this
	endmethod

	method addTypeId takes integer itemTypeId returns thistype
		local IntegerListItem node = 0
		local IntegerList restrictions

        if itemTypeId <= 0 then
            return this
        endif

		if node == 0 then
            call typeIds.push(itemTypeId)

			set restrictions = Restrictions[itemTypeId]
			if restrictions == 0 then
				set restrictions = IntegerList.create()
				call restrictions.push(this)
                set Restrictions[itemTypeId] = restrictions
			elseif restrictions.find(this) == 0 then
				call restrictions.push(this)
			endif
		endif

		return this
	endmethod

	method removeException takes UnitRequirement requirement returns thistype
		local IntegerListItem node = exceptions.first
        local LimitException exception

        loop
            exitwhen node == 0
            set exception = node.data
            if exception.requirement == requirement then
                call exceptions.remove(node)
                call exception.destroy()
                exitwhen true
            endif
            set node = node.next
        endloop

		return this
	endmethod

	method addException takes UnitRequirement requirement, integer newLimit returns thistype
		local IntegerListItem node = exceptions.first
        local LimitException exception
        local LimitException entry

        loop
            exitwhen node == 0
            set exception = node.data
            if exception.requirement == requirement then
                set entry = exception
                exitwhen true
            endif
            set node = node.next
        endloop

        if entry == 0 then
            call exceptions.push(LimitException.create(requirement, newLimit))
        endif
		return this
	endmethod

	method removeExclusive takes ItemRestriction restriction returns thistype
		local IntegerListItem node = exclusives.find(restriction)

		if ( node != 0 ) then
			call exclusives.remove(node)
			set node = restriction.exclusives.find(this)
			call restriction.exclusives.remove(node)
		endif

		return this
	endmethod

	method addExclusive takes ItemRestriction restriction returns thistype
		if exclusives.find(restriction) == 0 then
			call exclusives.push(restriction)
			call restriction.exclusives.push(this)
		endif

		return this
	endmethod

    method getCount takes unit u returns integer
        return cache[GetUnitId(u)]
    endmethod

    private method setCount takes unit u, integer count returns nothing
        set cache[GetUnitId(u)] = count
    endmethod

    private method getException takes unit u returns LimitException
        return cache[-GetUnitId(u)]
    endmethod

    private method setException takes unit u, LimitException exception returns nothing
        set cache[-GetUnitId(u)] = exception
    endmethod

	/*private method test takes unit u, item itm returns string
		local integer index = GetUnitId(u)
		local IntegerListItem node
		local ItemRestriction exclusive
		local UnitRequirement exception = 0
		local integer count
		local integer threshold = limit
        local string errorMessage

        if not has(GetItemTypeId(itm) then
            return null
        else if requirement != 0 then
            set errorMessage = requirement.test(u)
            if errorMessage != null
                return errorMessage
            endif
        endif

		set node = exclusives.first
		loop // checkout all exclusives linked with this restriction
			exitwhen node == 0
			set exclusive = node.data

			if ( exclusive.storage[index] > 0 ) then
				return GetExclusiveErrorMessage() // collapse, exclusive found
			endif

			set node = node.next
		endloop

		if ( not exceptions.empty() ) then
			set exception = storage[-index] // checkout out if exceptions is already stored for this unit

			if ( exception == 0 or exceptions.find(exception) == 0 ) then // else: hasn't been removed by user
				set storage[-index] = 0
				set node = exceptions.first // find new exception

				loop
					set exception = node.data
					exitwhen exception == 0

					if ( exception.match(u) == null ) then
						set storage[-index] = exception
						exitwhen true
					endif

					set node = node.next
				endloop
			endif
		endif

		if ( exception != 0 ) then // this is why in loop's above, i didn't use 'exitwhen node == 0'
			set threshold = storage[exception+8191]
		endif

		set count = storage[index]
		if ( threshold < 0 ) then
			return GetForbiddenErrorMessage() // collapse, not even 1 item allowed
		elseif ( threshold > 0 and count >= threshold ) then
			return GetLimitErrorMessage(threshold)
		endif

		return null
	endmethod

	private static method evaluateRestrictions takes unit u, item it returns IntegerList
		local IntegerList list
		local IntegerListItem node
		local ItemRestriction restriction
		local string message
		local IntegerList associated = Restrictions[-1] // error list

		call associated.clear()
		set list = Restrictions[0] // global list
		set node = list.first
		loop
			exitwhen node == 0
			set restriction = node.data
			set message = restriction.enforce(u)

			if ( message != null ) then
				call SimError(GetOwningPlayer(u), message)
				set message = null
				return 0
			else
				call associated.push(restriction)
			endif

			set node = node.next
		endloop

		set list = Restrictions[GetItemTypeId(it)]
        if ( list != 0 ) then
            set node = list.first
            loop
                exitwhen node == 0
                set restriction = node.data
                set message = restriction.enforce(u)

                if ( message != null ) then
                    call SimError(GetOwningPlayer(u), message)
                    set message = null
                    return 0
                else
                    call associated.push(restriction)
                endif

                set node = node.next
            endloop
        endif

		set message = null
		return associated
	endmethod

	private static method evaluateRequirements takes unit u, item it returns boolean
		local IntegerList list
		local IntegerListItem node
		local UnitRequirement requirement
		local string message

		set list = Requirements[0] // global item requirements
		set node = list.first
		loop
			exitwhen node == 0
			set requirement = node.data
			set message = requirement.match(u)

			if ( message != null ) then
				call SimError(GetOwningPlayer(u), message)
				set message = null
				return false
			endif

			set node = node.next
		endloop

		set list = Requirements[GetItemTypeId(it)]
        if ( list != 0 ) then
            set node = list.first
            loop
                exitwhen node == 0
                set requirement = node.data
                set message = requirement.match(u)

                if ( message != null ) then
                    call SimError(GetOwningPlayer(u), message)
                    set message = null
                    return false
                endif

                set node = node.next
            endloop
        endif

		set message = null
		return true
	endmethod

	private static method onPickUp takes nothing returns boolean
		local item it = GetManipulatedItem()
		local unit u
		local IntegerList associated
		local IntegerListItem node
		local ItemRestriction restriction
		local integer count
		local integer index
		local trigger t

		if ( not IsItemPowerup(it) ) then
			set u = GetTriggerUnit()
			set associated = evaluateRestrictions(u, it)

			if ( associated != 0 and evaluateRequirements(u, it) ) then
				if ( not associated.empty() ) then
					set index = GetUnitId(u)
					set node = associated.first

					loop // increase count only if all the checks succeeded
						exitwhen node == 0
						set restriction = node.data
						set count = restriction.storage[index]
						set restriction.storage[index] = count + 1
						set node = node.next
					endloop
				endif
			else
				set t = GetPlayerUnitEventTrigger(EVENT_PLAYER_UNIT_DROP_ITEM)
				call DisableTrigger(t)
				call UnitRemoveItem(u, it)
				call EnableTrigger(t)
				set t = null
			endif

			set u = null
		endif

		set it = null
		return false
	endmethod

	private static method onDrop takes nothing returns boolean
		local integer itemId = GetItemTypeId(GetManipulatedItem())
		local integer index = GetUnitId(GetTriggerUnit())
		local IntegerList restrictions
		local IntegerListItem node
		local integer count
		local ItemRestriction restriction

		set restrictions = Restrictions[0] // check out global list first
		set node = restrictions.first
		loop
			exitwhen node == 0
			set restriction = node.data
			set count = restriction.storage[index]

			if ( count > 0 ) then
				set restriction.storage[index] = count - 1
			endif

			set node = node.next
		endloop

		set restrictions = Restrictions[itemId]
        if ( restrictions != 0 ) then
            set node = restrictions.first
            loop
                exitwhen node == 0
                set restriction = node.data

                if ( restriction.belongs(itemId) ) then
                    set count = restriction.storage[index]
                    if ( count > 0 ) then
                        set restriction.storage[index] = count - 1
                    endif
                endif

                set node = node.next
            endloop
        endif

		return false
	endmethod

	private static method onOrder takes nothing returns boolean
		local item it = GetOrderTargetItem()
		local unit u

		if ( GetIssuedOrderId() == 851971 and it != null ) then // order 'Smart' on an item
			set u = GetTriggerUnit()

			if ( evaluateRestrictions(u, it) == 0 or not evaluateRequirements(u, it) ) then
				call PauseUnit(u, true)
				call IssueImmediateOrderById(u, 851972)
				call PauseUnit(u, false)
			endif

			set it = null
			set u = null
		endif

		return false
	endmethod

	implement ItemRestrictionInit*/
endstruct

endlibrary