/*****************************************************************************
*
*    ItemRecipe v1.1.0.2
*       by Bannar
*
*    Powerful item recipe creator.
*
******************************************************************************
*
*    Requirements:
*
*       Alloc - choose whatever you like
*          e.g.: by Sevion hiveworkshop.com/threads/snippet-alloc.192348/
*
*       ListT by Bannar
*          hiveworkshop.com/threads/containers-list-t.249011/
*
*       RegisterPlayerUnitEvent by Bannar
*          hiveworkshop.com/forums/jass-resources-412/snippet-new-table-188084/
*
*       SimError by Vexorian
*          wc3c.net/showthread.php?t=101260&highlight=SimError
*
******************************************************************************
*
*    Event API:
*
*       integer EVENT_ITEM_RECIPE_ASSEMBLING
*       integer EVENT_ITEM_RECIPE_ASSEMBLED
*
*       Use RegisterNativeEvent or RegisterIndexNativeEvent for event registration.
*       GetNativeEventTrigger and GetIndexNativeEventTrigger provide access to trigger handles.
*
*
*       function GetEventItemRecipe takes nothing returns ItemRecipe
*          Returns triggering item recipe.
*
*       function GetEventItemRecipeUnit takes nothing returns unit
*          Returns recipe triggering unit.
*
*       function GetEventItemRecipeItem takes nothing returns item
*          Returns reward item for triggering recipe.
*
*       function GetEventItemRecipeIngredients takes nothing returns RecipeIngredientVector
*          Returns collection of ingredients chosen to assemble the reward item,
*          where each index corresponds to triggering unit inventory slot.
*
*       function SetEventItemRecipeHandled takes boolean handled returns nothing
*          Sets value indicating if event should be propagated.
*
******************************************************************************
*
*    struct RecipeIngredient:
*
*       Fields:
*
*        | IntegerList itemTypeId
*        |    Item type of this ingredient.
*        |
*        | integer perishable
*        |    Whether ingredient is destroyed during assembly.
*        |
*        | integer charges
*        |    Number of charges required by ingredient.
*        |
*        | integer index
*        |    Indicates the slot which given ingredient occupies.
*
*
*    struct ItemRecipe:
*
*       Fields:
*
*        | readonly integer reward
*        |    Reward item type.
*        |
*        | boolean ordered
*        |    Whether recipe is ordered or unordered item inventory slot wise.
*        |
*        | boolean permanent
*        |    Determines if recipe can be disassembled.
*        |
*        | boolean pickupable
*        |    Whether recipe can be assembled when picking up items.
*        |
*        | integer charges
*        |    Number of charges to assign to reward item.
*        |
*        | optional UnitRequirement requirement
*        |    Criteria that unit needs to meet to assembly the recipe.
*        |
*        | readonly integer count
*        |    Total number of items required by the recipe.
*
*
*       General:
*
*        | static method create takes integer reward, integer charges, boolean ordered, boolean permanent, boolean pickupable returns thistype
*        |    Creates new instance of ItemRecipe struct.
*        |
*        | method destroy takes nothing returns nothing
*        |    Releases all resources this instance occupies.
*        |
*        | static method operator [] takes thistype other returns thistype
*        |    Copy contructor.
*        |
*
*
*       Access and modifiers:
*
*        | method isIngredient takes integer itemTypeId returns boolean
*        |    Whether specified item type is a part of the recipe.
*        |
*        | method getIngredients takes nothing returns RecipeIngredientList
*        |    Returns shallow copy of item recipe data.
*        |
*        | static method getRecipes takes integer itemTypeId returns ItemRecipeList
*        |    Returns recipes which reward matches specified item type.
*        |
*        | static method getRecipe takes integer itemTypeId returns ItemRecipe
*        |    Returns first recipe which reward matches specified item type.
*        |
*        | static method getRecipesForIngredient takes integer itemTypeId returns ItemRecipeList
*        |    Returns recipes that specified item is part of.
*        |
*        | static method getRecipesForAbility takes integer abilityId returns ItemRecipeList
*        |    Returns recipes that can be assembled by casting specified ability.
*        |
*        | method startBatch takes nothing returns thistype
*        |    Starts single-reference counted batch. Allows to assign multiple items to the same item slot.
*        |
*        | method endBatch takes nothing returns thistype
*        |    Closes current batch.
*        |
*        | method getAbility takes nothing returns integer
*        |    Retrieves id of ability thats triggers assembly of this recipe.
*        |
*        | method setAbility takes integer abilityId returns thistype
*        |    Sets or removes specified ability from triggering recipe assembly.
*        |
*        | method removeItem takes integer itemTypeId returns thistype
*        |    Removes all entries that match specified item type from recipe ingredient list.
*        |
*        | method addItem takes integer itemTypeId, boolean perishable, integer charges returns thistype
*        |    Adds new entry to recipe ingredient list.
*        |
*        | method addItemEx takes integer itemTypeId returns thistype
*        |    Adds new entry to recipe ingredient list.
*
*
*    Assembly & disassembly:
*
*        | method test takes unit whichUnit, ItemVector items returns RecipeIngredientVector
*        |    Checks if recipe can be assembled for specified unit given the ingredients list.
*        |
*        | method testEx takes unit whichUnit returns RecipeIngredientVector
*        |    Checks if recipe can be assembled for specified unit.
*        |
*        | method assembly takes unit whichUnit, ItemVector items returns boolean
*        |    Attempts to assembly recipe for specified unit given the ingredients list.
*        |
*        | method assemblyEx takes unit whichUnit returns boolean
*        |    Attempts to assembly recipe for specified unit.
*        |
*        | method disassembly takes unit whichUnit returns boolean
*        |    Reverts the assembly, removing the reward item and returning all ingredients to specified unit.
*
*
******************************************************************************
*
*    Functions:
*
*       function UnitAssemblyItem takes unit whichUnit, integer itemTypeId returns boolean
*          Attempts to assemble specified item type for provided unit.
*
*       function UnitDisassemblyItem takes unit whichUnit, item whichItem returns boolean
*          Reverts the assembly, removing the reward item and returning all ingredients to specified unit.
*
*****************************************************************************/
library ItemRecipe requires /*
                   */ Alloc /*
                   */ ListT /*
                   */ VectorT /*
                   */ RegisterPlayerUnitEvent /*
                   */ ExtensionMethods /*
                   */ optional InventoryEvent /*
				   */ optional ItemRestriction

globals
    private ItemRecipe eventRecipe = 0
    private unit eventUnit = null
    private item eventItem = null
    private RecipeIngredientVector eventIngredients = 0
    private boolean eventHandled = false

    private Table recipeMap
	
    integer EVENT_ITEM_RECIPE_ASSEMBLING
    integer EVENT_ITEM_RECIPE_ASSEMBLED
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

function GetEventItemRecipeIngredients takes nothing returns RecipeIngredientVector
    return eventIngredients
endfunction

function SetEventItemRecipeHandled takes boolean handled returns nothing
    set eventHandled = handled
endfunction

private function FireEvent takes integer evt, ItemRecipe recipe, unit u, item it, RecipeIngredientVector ingredients returns nothing
    local ItemRecipe prevRecipe = eventRecipe
    local unit prevUnit = eventUnit
    local item prevItem = eventItem
    local RecipeIngredientVector prevIngredients = eventIngredients

    set eventRecipe = recipe
    set eventUnit = u
    set eventItem = it
    set eventIngredients = ingredients

    call TriggerEvaluate(GetNativeEventTrigger(evt))
    call TriggerEvaluate(GetIndexNativeEventTrigger(GetPlayerId(GetOwningPlayer(u)), evt))

    set eventRecipe = prevRecipe
    set eventUnit = prevUnit
    set eventItem = prevItem
    set eventIngredients = prevIngredients

    set prevUnit = null
    set prevItem = null
endfunction

struct RecipeIngredient extends array
    integer itemTypeId
    boolean perishable
    integer charges
    // if != 0 then it's part of a batch i.e multiple items can fill its spot
	integer index

    implement Alloc

    static method create takes integer itemTypeId, boolean perishable, integer charges, integer index returns thistype
        local thistype this = allocate()
        set this.itemTypeId = itemTypeId
        set this.perishable = perishable
        set this.charges = charges
		set this.index = index
        return this
    endmethod

    method destroy takes nothing returns nothing
        set itemTypeId = 0
        set perishable = false
        set charges = 0
		set index = 0
        call deallocate()
    endmethod

    static method operator [] takes thistype other returns thistype
        if other <= 0 then
            debug call DisplayTimedTextFromPlayer(GetLocalPlayer(),0,0,60,"static $NAME$::operator [] failed. Argument 'other': "+I2S(other)+" is invalid.")
            return 0
        endif
        return create(other.itemTypeId, other.perishable, other.charges, other.index)
    endmethod
endstruct

//! runtextmacro DEFINE_VECTOR("", "ItemVector", "item")
//! runtextmacro DEFINE_STRUCT_VECTOR("", "RecipeIngredientVector", "RecipeIngredient")
//! runtextmacro DEFINE_STRUCT_LIST("", "RecipeIngredientList", "RecipeIngredient")
//! runtextmacro DEFINE_STRUCT_LIST("", "ItemRecipeList", "ItemRecipe")

private module ItemRecipeInit
    private static method onInit takes nothing returns nothing
        set EVENT_ITEM_RECIPE_ASSEMBLING = CreateNativeEvent()
        set EVENT_ITEM_RECIPE_ASSEMBLED = CreateNativeEvent()

        set recipeMap = Table.create()

        call RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_PICKUP_ITEM, function OnPickup)
        call RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_SPELL_EFFECT, function OnCast)
static if LIBRARY_InventoryEvent then
        call RegisterNativeEvent(InventoryEvent.MOVED, function OnMoved)
endif
static if LIBRARY_SmoothItemPickup then
        // Allow for smooth pickup for pickup-type unordered recipes
        call RegisterNativeEvent(EVENT_ITEM_SMOOTH_PICKUP, function OnSmoothPickup)
        call AddSmoothItemPickupCondition(RecipeSmoothPickupPredicate.create())
endif
    endmethod
endmodule

struct ItemRecipe extends array
    private RecipeIngredientList ingredients
    readonly integer reward
    boolean ordered
    boolean permanent
	boolean pickupable
    integer charges
    readonly integer count
    private integer abilityId
    private boolean batch

static if LIBRARY_ItemRestriction then
	readonly UnitRequirement requirement
endif
    implement Alloc

    static method create takes integer reward, integer charges, boolean ordered, boolean permanent, boolean pickupable returns thistype
        local thistype this = allocate()
        local ItemRecipeList recipes

        set ingredients = RecipeIngredientList.create()
        set this.reward = reward
		set this.charges = charges
        set this.ordered = ordered
        set this.permanent = permanent
		set this.pickupable = pickupable
static if LIBRARY_ItemRestriction then
        set requirement = 0
endif
        set abilityId = 0
        set count = 0

        if not recipeMap.has(-reward) then
            set recipes = ItemRecipeList.create()
            call recipes.push(this)
            set recipeMap[-reward] = recipes
        else
            set recipes = recipeMap[-reward]
            if recipes.find(this) == 0 then
                call recipes.push(this)
            endif
        endif

        return this
    endmethod

    method getAbility takes nothing returns integer
        return abilityId
    endmethod

    method setAbility takes integer abilityId returns thistype
        local ItemRecipeList recipes

        if this.abilityId == abilityId then
            return this
        endif

        if this.abilityId != 0 then
            set recipes = recipeMap[this.abilityId]
            call recipes.remove(recipes.find(this))
            if recipes.empty() then
                call recipes.destroy()
                call recipeMap.remove(this.abilityId)
            endif
        endif

        if abilityId > 0 then
            set this.abilityId = abilityId
            if not recipeMap.has(abilityId) then
                set recipes = ItemRecipeList.create()
                call recipes.push(this)
                set recipeMap[abilityId] = recipes
            else
                set recipes = recipeMap[abilityId]
                if recipes.find(this) == 0 then
                    call recipes.push(this)
                endif
            endif
        endif

        return this
    endmethod

    method destroy takes nothing returns nothing
		local RecipeIngredientListItem iter = ingredients.first
		local ItemRecipeList recipes
		local integer itemTypeId

        call setAbility(0)

        loop
            exitwhen iter == 0

            set itemTypeId = iter.data.itemTypeId
            set recipes = recipeMap[itemTypeId]
            call recipes.remove(recipes.find(this))
            if recipes.empty() then
                call recipes.destroy()
                call recipeMap.remove(itemTypeId)
            endif

            set iter = iter.next
        endloop

        set recipes = recipeMap[-reward]
        call recipes.remove(recipes.find(this))
        if recipes.empty() then
            call recipes.destroy()
            call recipeMap.remove(-reward)
        endif

        call ingredients.destroy()
        call deallocate()
    endmethod

    static method operator [] takes thistype other returns thistype
        local thistype this
        local RecipeIngredientListItem iter
        if other <= 0 then
            debug call DisplayTimedTextFromPlayer(GetLocalPlayer(),0,0,60,"static $NAME$::operator [] failed. Argument 'other': "+I2S(other)+" is invalid.")
            return 0
        endif

        set this = create(other.reward, other.charges, other.ordered, other.permanent, other.pickupable)
        set iter = other.ingredients.first
        loop
            exitwhen iter == 0
            call this.ingredients.push(RecipeIngredient[iter.data])
            set iter = iter.next
        endloop

        set this.count = other.count
        call this.setAbility(other.getAbility())
        set this.batch = other.batch
        return this
    endmethod

    method isIngredient takes integer itemTypeId returns boolean
        local RecipeIngredientListItem iter = ingredients.first

        loop
            exitwhen iter == 0
            if iter.data.itemTypeId == itemTypeId then
                return true
            endif
            set iter = iter.next
        endloop
        return false
    endmethod

    method getIngredients takes nothing returns RecipeIngredientList
        return RecipeIngredientList[ingredients]
    endmethod

    static method getRecipes takes integer itemTypeId returns ItemRecipeList
        if recipeMap.has(-itemTypeId) then
            return recipeMap[-itemTypeId]
        endif
        return 0
    endmethod

    static method getRecipe takes integer itemTypeId returns ItemRecipe
        local ItemRecipeList recipes = getRecipes(itemTypeId)
        if recipes != 0 then
            return recipes.front()
        endif
        return 0
    endmethod

    static method getRecipesForIngredient takes integer itemTypeId returns ItemRecipeList
        if recipeMap.has(itemTypeId) then
            return recipeMap[itemTypeId]
        endif
        return 0
    endmethod

    static method getRecipesForAbility takes integer abilityId returns ItemRecipeList
        if recipeMap.has(abilityId) then
            return recipeMap[abilityId]
        endif
        return 0
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
		if batch then
			set batch = false
			set count = count + 1
		debug else
			debug call DisplayTimedTextFromPlayer(GetLocalPlayer(),0,0,60,"ItemRecipe::endBatch failed. Called endBatch() without starting batch previously.")
		endif
		return this
	endmethod

    method removeItem takes integer itemTypeId returns thistype
        local RecipeIngredientListItem iter = ingredients.first
        local boolean found = false
        local ItemRecipeList recipes
        local RecipeIngredient ingredient

        loop
            exitwhen iter == 0

            if iter.data.itemTypeId == itemTypeId then
                set ingredient = iter.data

                // Decrement count only if this item is not part of any batch
                if (iter.prev == 0 or iter.prev.data.index != ingredient.index) and /*
                */ (iter.next == 0 or iter.next.data.index != ingredient.index) then
                    set count = count - 1
                endif

                call ingredients.remove(iter)
                set found = true
                exitwhen true
            endif
            set iter = iter.next
        endloop

        if found then
            set recipes = recipeMap[itemTypeId]
            call recipes.removeElem(this)
            if recipes.empty() then
                call recipes.destroy()
                call recipeMap.remove(itemTypeId)
            endif
        endif

        return this
    endmethod

    method addItem takes integer itemTypeId, boolean perishable, integer charges returns thistype
        local ItemRecipeList recipes
        local RecipeIngredient ingredient

        if itemTypeId <= 0 or itemTypeId == reward then
            return this
        elseif count >= bj_MAX_INVENTORY and not batch then
            return this
        endif

        if not recipeMap.has(itemTypeId) then
            set recipes = ItemRecipeList.create()
            call recipes.push(this)
            set recipeMap[itemTypeId] = recipes
        else
            set recipes = recipeMap[itemTypeId]
            if recipes.find(this) == 0 then
                call recipes.push(this)
            endif
        endif

        if charges < 0 then
            set charges = 0
        endif

        set ingredient = RecipeIngredient.create(itemTypeId, perishable, charges, count)
        call ingredients.push(ingredient)
        if not batch then
            set count = count + 1
        endif

        return this
    endmethod

    method addItemEx takes integer itemTypeId returns thistype
        return addItem(itemTypeId, true, 0)
    endmethod

    private method orderedSearch takes ItemVector items returns RecipeIngredientVector
        local integer slot = 0
        local boolean found = false
        local item itm
        local integer charges
        local RecipeIngredient ingredient
        local integer idx
        local RecipeIngredientVector resultIngredients = RecipeIngredientVector.create()
        local RecipeIngredientListItem iter = ingredients.first
        call resultIngredients.resize(count)

        loop
            exitwhen iter == 0
            set itm = items[slot]
            set charges = GetItemCharges(itm)
            set ingredient = iter.data
            set idx = ingredient.index

            loop
                exitwhen ingredient.index != idx
                if GetItemTypeId(itm) == ingredient.itemTypeId and charges >= ingredient.charges then
                    set resultIngredients[slot] = RecipeIngredient[ingredient]
                    set found = true
                    exitwhen true
                endif

                set iter = iter.next
                exitwhen iter == 0
                set ingredient = iter.data
            endloop

            if not found then
                call resultIngredients.destroy()
                set itm = null
                return 0
            else // seek node which is not part of this batch
                loop
                    exitwhen ingredient.index != idx
                    set iter = iter.next
                    exitwhen iter == 0 // batch was the last piece of recipe
                    set ingredient = iter.data
                endloop
            endif

            set slot = slot + 1
        endloop

        set itm = null
        return resultIngredients
    endmethod

    private method unorderedSearch takes ItemVector items returns RecipeIngredientVector
        local boolean found = false
        local RecipeIngredient ingredient
        local integer idx
        local integer slot = 0
        local integer size = items.size()
        local item itm
        local integer itemTypeId
        local integer charges
        local RecipeIngredientVector resultIngredients = RecipeIngredientVector.create()
        local RecipeIngredientListItem iter = ingredients.first
        call resultIngredients.resize(count)

        loop
            exitwhen iter == 0
            set found = false
            set ingredient = iter.data
            set idx = ingredient.index

            loop
                exitwhen ingredient.index != idx
                set slot = 0
                loop
                    exitwhen slot >= size
                    if resultIngredients[slot] == null then
                        set itm = items[slot]
                        set itemTypeId = GetItemTypeId(itm)
                        set charges = GetItemCharges(itm)

                        if GetItemTypeId(itm) == ingredient.itemTypeId and charges >= ingredient.charges then
                            set resultIngredients[slot] = RecipeIngredient[ingredient]
                            set found = true
                            exitwhen true
                        endif
                    endif
                    set slot = slot + 1
                endloop

                exitwhen found
                set iter = iter.next
                exitwhen iter == 0
                set ingredient = iter.data
            endloop

            if not found then
                call resultIngredients.destroy()
                set itm = null
                return 0
            else // seek node which is not part of this batch
                loop
                    exitwhen ingredient.index != idx
                    set iter = iter.next
                    exitwhen iter == 0 // batch was the last piece of recipe
                    set ingredient = iter.data
                endloop
            endif
        endloop

        set itm = null
        return resultIngredients
    endmethod

    method test takes unit whichUnit, ItemVector items returns RecipeIngredientVector
        if count <= 0 or count > items.size() then
            return 0
        endif
static if LIRABRY_ItemRestriction then
        if requirement != 0 and not requirement.filter(whichUnit) then
            return 0
        endif
endif

        if ordered then
            return orderedSearch(items)
        endif
        return unorderedSearch(items)
    endmethod

    method testEx takes unit whichUnit returns RecipeIngredientVector
        local integer slot = 0
        local integer size = UnitInventorySize(whichUnit)
        local ItemVector items = ItemVector.create()

        loop
            exitwhen slot >= size
            call items.push(UnitItemInSlot(whichUnit, slot))
            set slot = slot + 1
        endloop

        return test(whichUnit, items)
    endmethod

    method assembly takes unit whichUnit, ItemVector fromItems returns boolean
        local boolean prevHandled = eventHandled
        local integer size = fromItems.size()
        local RecipeIngredient ingredient
        local item itm
        local integer chrgs
        local RecipeIngredientVector resultIngredients = test(whichUnit, fromItems)
        local integer i = 0

        if resultIngredients == 0 then
            return false
        endif

        set eventHandled = false
        call FireEvent(EVENT_ITEM_RECIPE_ASSEMBLING, this, whichUnit, null, resultIngredients)
        if eventHandled then
            set eventHandled = prevHandled
            return false
        endif

        loop
            exitwhen i >= size

            if resultIngredients[i] != 0 then
                set ingredient = resultIngredients[i]
                set itm = fromItems[i]
                if ingredient.charges > 0 then
                    set chrgs = GetItemCharges(itm)
                    if chrgs > ingredient.charges and not ingredient.perishable then
                        call SetItemCharges(itm, chrgs - ingredient.charges)
                    else
                        call RemoveItem(itm)
                    endif
                elseif ingredient.perishable then
                    call RemoveItem(itm)
                endif
            endif

            set i = i + 1
        endloop

        set itm = CreateItem(reward, GetUnitX(whichUnit), GetUnitY(whichUnit))
        if charges > 0 then
            call SetItemCharges(itm, charges)
        endif
        call UnitAddItem(whichUnit, itm)

        set eventHandled = prevHandled
        call FireEvent(EVENT_ITEM_RECIPE_ASSEMBLED, this, whichUnit, itm, resultIngredients)
        set itm = null
        return true
    endmethod

    method assemblyEx takes unit whichUnit returns boolean
        local integer slot = 0
        local integer size = UnitInventorySize(whichUnit)
        local ItemVector items = ItemVector.create()

        loop
            exitwhen slot >= size
            call items.push(UnitItemInSlot(whichUnit, slot))
            set slot = slot + 1
        endloop

        return assembly(whichUnit, items)
    endmethod

    method disassembly takes unit whichUnit returns boolean
        local integer slot = 0
        local integer size = UnitInventorySize(whichUnit)
        local boolean found = false
        local item itm
        local RecipeIngredientListItem iter
        local RecipeIngredient ingredient

        if permanent then
            return false
        endif

        loop
            exitwhen slot >= size
            set itm = UnitItemInSlot(whichUnit, slot)
            if GetItemTypeId(itm) == reward then
                set found = true
                exitwhen true
            endif
            set slot = slot + 1
        endloop

        if not found then
            set itm = null
            return false
        endif

        set iter = ingredients.first
        loop
            exitwhen iter == 0
            set ingredient = iter.data
            if ingredient.perishable then
                set itm = CreateItem(ingredient.itemTypeId, GetUnitX(whichUnit), GetUnitY(whichUnit))
                if ingredient.charges > 0 then
                    call SetItemCharges(itm , ingredient.charges)
                endif
                call UnitAddItem(whichUnit, itm)
            endif
            set iter = iter.next
        endloop

        set itm = null
        return true
    endmethod
endstruct

function UnitAssemblyItem takes unit whichUnit, integer itemTypeId returns boolean
    local ItemRecipeList recipes = ItemRecipe.getRecipes(itemTypeId)
    local ItemRecipeListItem iter

    if recipes != 0 then
        set iter = recipes.first
        loop
            exitwhen iter == 0
            if iter.data.assemblyEx(whichUnit) then
                return true
            endif
            set iter = iter.next
        endloop
    endif
    return false
endfunction

function UnitDisassemblyItem takes unit whichUnit, item whichItem returns boolean
    local integer itemTypeId = GetItemTypeId(whichItem)
    local ItemRecipeList recipes = ItemRecipe.getRecipes(itemTypeId)

    if not UnitHasItem(whichUnit, whichItem) or recipes == 0 then
        return false
    elseif recipes.size() > 1 then
        // Disassembling item with multiple recipe variants is ambiguous
        return false
    endif
    
    return recipes.front().disassembly(whichUnit)
endfunction

private function OnInventoryChange takes unit u, item itm returns boolean
    local integer itemTypeId = GetItemTypeId(itm)
    local ItemRecipeList recipes = ItemRecipe.getRecipesForIngredient(itemTypeId)
    local ItemRecipeListItem iter
    local ItemRecipe recipe

    if recipes != 0 then
        set iter = recipes.first
        loop
            exitwhen iter == 0
            set recipe = iter.data
            if recipe.pickupable and recipe.assemblyEx(u) then
                exitwhen true
            endif
            set iter = iter.next
        endloop
    endif
    return false
endfunction

private function OnPickup takes nothing returns boolean
    return OnInventoryChange(GetTriggerUnit(), GetManipulatedItem())
endfunction

static if LIBRARY_InventoryEvent then
private function OnMoved takes nothing returns boolean
    return OnInventoryChange(GetEventInventoryUnit(), GetEventInventoryItem())
endfunction
endif

private function OnCast takes nothing returns nothing
    local unit u = GetTriggerUnit()
    local integer abilityId = GetSpellAbilityId()
    local ItemRecipeList recipes = ItemRecipe.getRecipesForAbility(abilityId)
    local ItemRecipeListItem iter

    if recipes != 0 then
        set iter = recipes.first
        loop
            exitwhen iter == 0
            if iter.data.assemblyEx(u) then
                exitwhen true
            endif
            set iter = iter.next
        endloop
    endif

    set u = null
endfunction

static if LIBRARY_SmoothItemPickup then
private function GetCheatRecipe takes unit u, item itm returns ItemRecipe
    local integer itemTypeId = GetItemTypeId(itm)
    local ItemRecipeList recipes = ItemRecipe.getRecipesForIngredient(itemTypeId)
    local ItemRecipeListItem iter
    local ItemRecipe recipe
    local integer slot = 0
    local integer size
    local ItemVector items
    local RecipeIngredientList ingredients
    local RecipeIngredientListItem ingredIter

    if recipes == 0 then
        return 0
    endif

    set size = UnitInventorySize(u)
    set items = ItemVector.create()
    loop
        exitwhen slot >= size
        call items.push(UnitItemInSlot(u, slot))
        set slot = slot + 1
    endloop

    set iter = recipes.first
    loop
        exitwhen iter == 0
        set recipe = iter.data

        if recipe.pickupable and not recipe.ordered then
            set ingredients = recipe.getIngredients()
            set ingredIter = ingredients.first
            loop
                exitwhen ingredIter == 0
                // At least one item has to removed, in order to fit recipe reward in
                if ingredIter.data.perishable and recipe.test(u, items) != 0 then
                    return recipe
                endif
                set ingredIter = ingredIter.next
            endloop
        endif

        set iter = iter.next
    endloop
    return 0
endfunction

private function OnSmoothPickup takes nothing returns nothing
    local unit u = GetSmoothItemPickupUnit()
    local item itm = GetSmoothItemPickupItem()
    local ItemRecipe recipe = GetCheatRecipe(u, itm)
    local ItemVector items
    local integer slot = 0
    local integer size

    if recipe != 0 then
        set size = UnitInventorySize(u)
        set items = ItemVector.create()

        loop
            exitwhen slot >= size
            call items.push(UnitItemInSlot(u, slot))
            set slot = slot + 1
        endloop
        call items.push(itm)
        call recipe.assembly(u, items)
    endif

    set u = null
    set itm = null
endfunction

private struct RecipeSmoothPickupPredicate extends array
    method canPickup takes unit whichUnit, item whichItem returns boolean
        return IsUnitInventoryFull(whichUnit) and GetCheatRecipe(whichUnit, whichItem) != 0
    endmethod

    implement optional SmoothPickupPredicateModule
endstruct
endif

endlibrary