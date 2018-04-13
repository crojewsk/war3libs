library ItemRecipe requires /*
                 */ Alloc /*
                 */ ListT /*
                 */ optional RegisterPlayerUnitEvent /*
                 */ optional ItemStacking /* allows to react on pseudo PICK_UP event generated during item stacking *//*
				 */ optional UnitItemRestriction

globals
    private ItemRecipe eventRecipe = 0
    private unit eventUnit = null
    private item eventItem = null

    private Table Recipes
	private IntegerList AbilityList
    private integer array SlotFlag

    private trigger array triggers
    private real caller = -1
endglobals

function GetEventItemRecipe takes nothing returns ItemRecipe
    return eventRecipe
endfunction

function GetEventItemRecipeUnit takes nothing returns unit
    return eventUnit
endfunction

function GetEventItemRecipeItem takes nothing returns item
    return eventItem
endfunction

private function RegisterAnyUnitEvent takes playerunitevent e, code c returns nothing
    static if LIBRARY_RegisterPlayerUnitEvent then
        static if RPUE_NEW_API then
            call RegisterAnyPlayerUnitEvent(e, c)
        else
            call RegisterPlayerUnitEvent(e, c)
        endif
    else
        local trigger t = CreateTrigger()
        call TriggerRegisterAnyUnitEventBJ(t, e)
        call TriggerAddCondition(t, Condition(c))
        set t = null
    endif
endfunction

private module ItemRecipeInit
    private static method onInit takes nothing returns nothing
        call RegisterAnyUnitEvent(EVENT_PLAYER_UNIT_PICKUP_ITEM, function thistype.onPickUp)

		static if LIBRARY_InventoryEvent then
			call RegisterInventoryEvent(function thistype.onMoved, InventoryEvent.MOVED)
			static if LIBRARY_ItemStacking then
				call RegisterItemStackingEvent(function thistype.onChargesAdded, ItemStacking.CHARGES_ADDED)
			endif
        endif

        set Recipes = Table.create()
		set AbilityList = IntegerList.create()

		static if LIBRARY_RealEvent then
			set triggers[ASSEMBLING] = CreateRealEventTrigger(SCOPE_PRIVATE + "caller", ASSEMBLING, null)
			set triggers[ASSEMBLED] = CreateRealEventTrigger(SCOPE_PRIVATE + "caller", ASSEMBLED, null)
		else
			set triggers[ASSEMBLING] = CreateTrigger()
			call TriggerRegisterVariableEvent(triggers[ASSEMBLING], SCOPE_PRIVATE + "caller", EQUAL, ASSEMBLING)
			set triggers[ASSEMBLED] = CreateTrigger()
			call TriggerRegisterVariableEvent(triggers[ASSEMBLED], SCOPE_PRIVATE + "caller", EQUAL, ASSEMBLED)
		endif
    endmethod
endmodule

private function UnflagSlots takes nothing returns nothing
    local integer i = 0
    loop
        set SlotFlag[i] = 0
        set i = i+1
        exitwhen i > bj_MAX_INVENTORY // +1 to save 'base' charges
    endloop
endfunction

struct ItemData extends array
    integer typeId
    boolean remove
    integer charges
	integer index // if != 0 then it's part of a batch i.e multiple items can fill its spot

    implement Alloc

    method destroy takes nothing returns nothing
        set typeId = 0
        set remove = false
        set charges = 0
		set index = 0
        call deallocate()
    endmethod

    static method create takes integer it, boolean flag, integer c, integer idx returns thistype
        local thistype this = allocate()
        set typeId = it
        set remove = flag
        set charges = c
		set index = idx
        return this
    endmethod
endstruct

struct ItemRecipe extends array
    readonly IntegerList list
    readonly integer result
	readonly real charges
    readonly integer count
	private boolean batch
    readonly boolean ordered
    readonly boolean pernament
	readonly boolean pickUp // flag - trigger on PICK_UP event or not?
	readonly integer baseId

    readonly static integer ASSEMBLING = 0
    readonly static integer ASSEMBLED = 1

    implement Alloc

static if LIBRARY_UnitItemRestriction then
	readonly UnitRequirement requirement

	method require takes UnitRequirement req returns nothing
		if ( req != requirement ) then
			set requirement = req // simple setter; allows for: invoke(<arg> 0) to reset the requirement
		endif
	endmethod
endif

    private static method fire takes integer ev, ItemRecipe recipe, unit u, item it returns nothing
        local ItemRecipe prevRecipe = eventRecipe
        local unit prevUnit = eventUnit
        local item prevItem = eventItem

        set eventRecipe = recipe
        set eventUnit = u
        set eventItem = it

        set caller = ev
        set caller = -1

        set eventRecipe = prevRecipe
        set eventUnit = prevUnit
        set eventItem = prevItem

        set prevUnit = null
        set prevItem = null
    endmethod

    static method create takes integer itemId, integer chrgs, boolean ordr, boolean pernt, boolean pkup returns thistype
        local thistype this = allocate()

        set list = IntegerList.create()
        set result = itemId
		set charges = I2R(chrgs)
        set ordered = ordr
        set pernament = pernt
		set pickUp = pkup
        set Recipes[-itemId] = this

        return this
    endmethod

    method destroy takes nothing returns nothing // clean up all the leaks first
		local IntegerListItem node
		local IntegerList recipes
		local IntegerListItem subNode
		local integer typeId

		if ( pickUp ) then
			set node = list.first
			loop
				exitwhen node == 0
				set typeId = ItemData(node.data).typeId
				set recipes = Recipes[typeId]
				set subNode = recipes.find(this)

				if ( subNode != 0 ) then // can be more then single item of the same type
					call recipes.remove(subNode)
				endif
				set node = node.next
			endloop
		else
			set node = AbilityList.first
			loop
				exitwhen node == 0
				set typeId = node.data
				set recipes = Recipes[typeId]
				set subNode = recipes.find(this)

				if ( subNode != 0 ) then
					call recipes.remove(subNode)
				endif
				set node = node.next
			endloop
		endif

        set Recipes[-result] = 0
		call list.destroy()
        set list = 0
        set result = 0
		set charges = 0
        set count = 0
        set pernament = false

        call deallocate()
    endmethod

	method removeAbility takes integer abilityId returns thistype
		local IntegerList recipes
		local IntegerListItem node

		if ( not pickUp ) then
			set recipes = Recipes[abilityId]

			if ( recipes != 0 ) then
				set node = recipes.find(this)
				if ( node != 0 ) then
					call recipes.remove(node)
				endif
			endif
		debug else
			debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,60,"Warning in ItemRecipe::removeAbility(). Attempted to unregister ability ("+I2S(abilityId)+") for PICK_UP based ItemRecipe ("+I2S(this)+").")
		endif

		return this
	endmethod

	method addAbility takes integer abilityId returns thistype
		local IntegerList recipes

		if ( not pickUp ) then
			set recipes = Recipes[abilityId]

			if ( recipes == 0 ) then
				set recipes = IntegerList.create()
				set Recipes[abilityId] = recipes
				call recipes.push(this)
			elseif ( recipes.find(this) == 0 ) then
				call recipes.push(this)
			endif
		debug else
			debug call DisplayTimedTextToPlayer(GetLocalPlayer(),0,0,60,"Warning in ItemRecipe::addAbility(). Attempted to register ability ("+I2S(abilityId)+") for PICK_UP based ItemRecipe ("+I2S(this)+").")
		endif

		return this
	endmethod

	method remove takes integer itemId returns thistype
		local IntegerListItem node
		local IntegerListItem temp
		local IntegerList recipes
		local ItemData data

		set node = list.first
		loop // remove all itemId types from this list
			exitwhen node == 0
			set data = node.data

			if ( data.typeId == itemId ) then
				set temp = node.next
				call list.remove(node)
				set node = temp
			else
				set node = node.next
			endif			
		endloop

		if ( pickUp ) then
			set recipes = Recipes[itemId]
			set node = recipes.find(this)
			call recipes.remove(node)
		endif

		return this
	endmethod

    method add takes integer itemId, boolean flag, integer chrgs returns thistype
        local IntegerList recipe
		local ItemData data

        if ( count >= bj_MAX_INVENTORY and not batch ) then
            debug call DisplayTimedTextFromPlayer(GetLocalPlayer(),0,0,60,"ItemRecipe::add failed to add an item "+I2S(itemId)+ ". Reached recipe size limit.")
            return this
        endif

		if ( pickUp ) then // itemtype 'itemId' becomes a node in a list of recipes that involve this item type
			set recipe = Recipes[itemId]
			if ( recipe == 0 ) then
				set recipe = IntegerList.create()
				set Recipes[itemId] = recipe
				call recipe.push(this)
			elseif ( recipe.find(this) == 0 ) then
				call recipe.push(this)
			endif
		endif

        if ( chrgs < 0 ) then
            set chrgs = 0
        endif
		set data = ItemData.create(itemId, flag, chrgs, count)
		call list.push(data)

		if not batch then
			set count = count+1 // item is not part of any batch
		endif

        return this
    endmethod

    method addEx takes integer itemId returns thistype
        return add(itemId, true, 0)
    endmethod

	method addBase takes integer itemId, integer chrgs, real multi returns thistype
		set charges = multi
		set baseId = itemId
		return add(itemId, true, chrgs)
	endmethod

	method startBatch takes nothing returns thistype
		if not batch then
			set batch = true
		debug else
			debug call DisplayTimedTextFromPlayer(GetLocalPlayer(),0,0,60,"ItemRecipe::startBatch failed. Method startBatch() invoked with previous batch not yet ended.")
		endif
		return this
	endmethod

	method endBatch takes nothing returns thistype
		if ( batch ) then
			set batch = false
			set count = count + 1
		debug else
			debug call DisplayTimedTextFromPlayer(GetLocalPlayer(),0,0,60,"ItemRecipe::endBatch failed. Called endBatch() without starting batch previously.")
		endif
		return this
	endmethod

    private method match takes unit u returns boolean
        local IntegerListItem itemNode
        local ItemData itemData
		local integer idx
        local integer slot = 0
        local integer size = UnitInventorySize(u)
        local boolean found
		local integer id
		local integer chrgs
        local item it

        if ( count > size ) then
            return false
	static if LIBRARY_UnitItemRestriction then
		elseif ( requirement != 0 and requirement.match(u) != null ) then
			return false // failed the requirement test
	endif
        endif

        set itemNode = list.first
		call UnflagSlots()

        if ( ordered ) then
            loop
                exitwhen itemNode == 0
                set it = UnitItemInSlot(u, slot)
				set id = GetItemTypeId(it)
				set chrgs = GetItemCharges(it)
				set found = false
				set itemData = itemNode.data
				set idx = itemData.index

				loop // treats each recipe part as possible batch
					if ( id == itemData.typeId and chrgs >= itemData.charges ) then
						set SlotFlag[slot] = itemData // can't be taken already because it's ordered-search
						set found = true
						exitwhen true
					endif

					set itemNode = itemNode.next
					exitwhen itemNode == 0
					set itemData = itemNode.data
					exitwhen itemData.index != idx // exit when batch has ended
				endloop

				if ( not found ) then
					return false
				else // seek node which is not part of this batch
					if ( id == baseId ) then
						if ( SlotFlag[6] < chrgs ) then
							set SlotFlag[6] = chrgs
						endif
					endif
					loop
						set itemNode = itemNode.next
						exitwhen itemNode == 0 // batch was the last piece of recipe
						set itemData = itemNode.data
						exitwhen itemData.index != idx
					endloop
				endif

                set slot = slot+1
            endloop
        else // unordered search
            loop
                exitwhen itemNode == 0
                set found = false
				set itemData = itemNode.data
				set idx = itemData.index

				loop // attempt to find any of item types from given batch within inventory
					set slot = 0
					loop
						exitwhen slot >= size
						set it = UnitItemInSlot(u, slot)
						set id = GetItemTypeId(it)
						set chrgs = GetItemCharges(it)

						if ( SlotFlag[slot] == 0 and id == itemData.typeId and chrgs >= itemData.charges ) then
							set SlotFlag[slot] = itemData
							set found = true
							exitwhen true
						endif

						set slot = slot+1
					endloop

					exitwhen found
					set itemNode = itemNode.next
					exitwhen itemNode == 0
					set itemData = itemNode.data
					exitwhen itemData.index != idx // exit when batch has ended
				endloop

				if ( not found ) then
					return false
				else // seek node which is not part of this batch
					if ( id == baseId ) then
						if ( SlotFlag[6] < chrgs ) then
							set SlotFlag[6] = chrgs
						endif
					endif
					loop
						set itemNode = itemNode.next
						exitwhen itemNode == 0 // batch was the last piece of recipe
						set itemData = itemNode.data
						exitwhen itemData.index != idx
					endloop
				endif
            endloop
        endif

        set it = null
        return true
    endmethod

    private static boolean vetoed = false

    static method veto takes boolean b returns nothing
        set vetoed = b
    endmethod

    method assembly takes unit u returns boolean
        local IntegerListItem itemNode
        local ItemData itemData
        local integer i = 0 // slot
        local integer size = UnitInventorySize(u)
        local item it
        local integer value
		local boolean prevVeto

        if ( match(u) ) then
			set prevVeto = vetoed
            set vetoed = false
            call fire(ASSEMBLING, this, u, null)

            if ( not vetoed ) then
				loop
					exitwhen i >= size
					set itemData = SlotFlag[i]
					set it = UnitItemInSlot(u, i)

					if ( itemData != 0 ) then // marked via match() method
						if ( itemData.charges > 0 ) then
							set value = GetItemCharges(it)
							if ( value > itemData.charges and not itemData.remove ) then
								call SetItemCharges(it, value - itemData.charges)
							else
								call RemoveItem(it)
							endif
						elseif ( itemData.remove ) then
							call RemoveItem(it)
						endif
					endif

					set i = i+1
				endloop

                set it = CreateItem(result, GetUnitX(u), GetUnitY(u))
				if ( charges > 0 ) then
					if ( SlotFlag[6] > 0 ) then // found base
						call SetItemCharges(it, SlotFlag[6] * R2I(charges))
					else
						call SetItemCharges(it, R2I(charges))
					endif
				endif
                call UnitAddItem(u, it)
                call fire(ASSEMBLED, this, u, it)

                set it = null
                return true
            endif

			set vetoed = prevVeto
        endif

        return false
    endmethod

    private static method onInventoryChange takes unit u, item it returns boolean
        local integer id = GetItemTypeId(it)
        local IntegerList recipeList = Recipes[id]
        local IntegerListItem node
        local ItemRecipe recipe

        set node = recipeList.first
        loop
            exitwhen node == 0
            set recipe = node.data // extract recipe from given node
            exitwhen ( recipe.assembly(u) )
            set node = node.next
        endloop

        return false
    endmethod

    private static method onPickUp takes nothing returns boolean
        return onInventoryChange(GetTriggerUnit(), GetManipulatedItem())
    endmethod

static if LIBRARY_InventoryEvent then
    private static method onMoved takes nothing returns nothing
        call onInventoryChange(GetEventInventoryUnit(), GetEventInventoryItem())
    endmethod

	static if LIBRARY_ItemStacking then
		private static method onChargesAdded takes nothing returns nothing
			call onInventoryChange(GetItemStackingUnit(), GetItemStackingItem())
		endmethod
	endif
endif

	private static method onCast takes nothing returns nothing
		local unit u
		local IntegerList recipes = Recipes[GetSpellAbilityId()]
		local IntegerListItem node
		local ItemRecipe recipe

		if ( recipes != 0 and not recipes.empty() ) then
			set u = GetTriggerUnit()

			if ( UnitInventorySize(u) != 0 ) then
				set node = recipes.first
				loop
					exitwhen node == 0
					set recipe = node.data
					exitwhen ( recipe.assembly(u) )
					set node = node.next
				endloop
			endif

			set u = null
		endif
	endmethod

    implement ItemRecipeInit
endstruct

function AssemblyItem takes unit u, integer itemId returns boolean
    local ItemRecipe recipe = Recipes[-itemId]

    if ( recipe != 0 ) then
        return recipe.assembly(u)
    endif

    return false
endfunction

function DisassemblyItem takes unit u, item it returns boolean
    local ItemRecipe recipe = Recipes[-GetItemTypeId(it)]
    local IntegerListItem node
    local ItemData itemData
    local real x
    local real y
    local item part

    if ( recipe != 0 and UnitHasItem(u, it) and not recipe.pernament ) then
        call RemoveItem(it)
        set node = recipe.list.first
        set x = GetUnitX(u)
        set y = GetUnitY(u)

        loop
            exitwhen node == 0
            set itemData = node.data

            if not itemData.remove then
                set part = CreateItem(itemData.typeId, x, y)
                if ( itemData.charges > 0 ) then
                    call SetItemCharges(part, itemData.charges)
                endif
                call UnitAddItem(u, part)
            endif

            set node = node.next
        endloop

        set part = null
        return true
    endif

    return false
endfunction

function RegisterItemRecipeEvent takes code c, integer ev returns nothing
    call TriggerAddCondition(triggers[ev], Condition(c))
endfunction

function TriggerRegisterItemRecipeEvent takes trigger t, integer ev returns nothing
    call TriggerRegisterVariableEvent(t, SCOPE_PRIVATE + "caller", EQUAL, ev)
endfunction

function GetItemRecipeEventTrigger takes integer whichEvent returns trigger
    return triggers[whichEvent]
endfunction

endlibrary