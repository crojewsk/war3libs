/*****************************************************************************
*
*    ItemRecipe v1.1.2.1
*       by Bannar
*
*    Powerful item recipe creator.
*
******************************************************************************
*
*    Requirements:
*
*       ListT by Bannar
*          hiveworkshop.com/threads/containers-list-t.249011/
*
*       VectorT by Bannar
*          hiveworkshop.com/threads/containers-vector-t.248942/
*
*       RegisterPlayerUnitEvent by Bannar
*          hiveworkshop.com/threads/snippet-registerevent-pack.250266/
*
*
*    Optional requirements:
*
*       InventoryEvent by Bannar
*          hiveworkshop.com/threads/snippet-inventoryevent.287084/
*
*       ItemRestriction by Bannar
*          hiveworkshop.com/threads/itemrestriction.306012/
*
*       SmoothItemPickup by Bannar
*          hiveworkshop.com/threads/smoothitempickup.306016/
*
******************************************************************************
*
*    Event API:
*
*       integer EVENT_ITEM_RECIPE_ASSEMBLE
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
*        | integer charges
*        |    Number of charges to assign to reward item.
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
*        | optional UnitRequirement requirement
*        |    Criteria that unit needs to meet to assemble the recipe.
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
*
*
*       Access and modifiers:
*
*        | static method getRecipesForReward takes integer itemTypeId returns ItemRecipeList
*        |    Returns recipes which reward matches specified item type.
*        |
*        | static method getRecipesWithIngredient takes integer itemTypeId returns ItemRecipeList
*        |    Returns recipes that specified item is part of.
*        |
*        | static method getRecipesWithAbility takes integer abilityId returns ItemRecipeList
*        |    Returns recipes that can be assembled by casting specified ability.
*        |
*        | method getIngredients takes nothing returns RecipeIngredientList
*        |    Returns shallow copy of item recipe data.
*        |
*        | method isIngredient takes integer itemTypeId returns boolean
*        |    Whether specified item type is a part of the recipe.
*        |
*        | method getAbility takes nothing returns integer
*        |    Retrieves id of ability thats triggers assembly of this recipe.
*        |
*        | method setAbility takes integer abilityId returns thistype
*        |    Sets or removes specified ability from triggering recipe assembly.
*        |
*        | method startBatch takes nothing returns thistype
*        |    Starts single-reference counted batch. Allows to assign multiple items to the same item slot.
*        |
*        | method endBatch takes nothing returns thistype
*        |    Closes current batch.
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
*        | method assemble takes unit whichUnit, ItemVector items returns boolean
*        |    Attempts to assemble recipe for specified unit given the ingredients list.
*        |
*        | method assembleEx takes unit whichUnit returns boolean
*        |    Attempts to assemble recipe for specified unit.
*        |
*        | method disassemble takes unit whichUnit returns boolean
*        |    Reverts the assembly, removing the reward item and returning all ingredients to specified unit.
*
*
******************************************************************************
*
*    Functions:
*
*       function UnitAssembleItem takes unit whichUnit, integer itemTypeId returns boolean
*          Attempts to assemble specified item type for provided unit.
*
*       function UnitDisassembleItem takes unit whichUnit, item whichItem returns boolean
*          Reverts the assembly, removing the reward item and returning all ingredients to specified unit.
*
*****************************************************************************/
library ItemRecipe requires /*
                   */ ListT /*
                   */ VectorT /*
                   */ RegisterPlayerUnitEvent /*
                   */ optional InventoryEvent /*
                   */ optional ItemRestriction /*
                   */ optional SmoothItemPickup

globals
    integer EVENT_ITEM_RECIPE_ASSEMBLE
endglobals

globals
    private ItemRecipe eventRecipe = 0
    private unit eventUnit = null
    private item eventItem = null
    private ItemVector eventIngredients = 0

    private Table instanceTable = 0
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

function GetEventItemRecipeIngredients takes nothing returns ItemVector
    return eventIngredients
endfunction

private function FireEvent takes ItemRecipe recipe, unit u, item it, ItemVector ingredients returns nothing
    local ItemRecipe prevRecipe = eventRecipe
    local unit prevUnit = eventUnit
    local item prevItem = eventItem
    local ItemVector prevIngredients = eventIngredients
    local integer playerId = GetPlayerId(GetOwningPlayer(u))

    set eventRecipe = recipe
    set eventUnit = u
    set eventItem = it
    set eventIngredients = ingredients

    call TriggerEvaluate(GetNativeEventTrigger(EVENT_ITEM_RECIPE_ASSEMBLE))
    if IsNativeEventRegistered(playerId, EVENT_ITEM_RECIPE_ASSEMBLE) then
        call TriggerEvaluate(GetIndexNativeEventTrigger(playerId, EVENT_ITEM_RECIPE_ASSEMBLE))
    endif

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
    // If non 0, then it is part of a batch i.e multiple items can fill its spot
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
        return create(other.itemTypeId, other.perishable, other.charges, other.index)
    endmethod
endstruct

//! runtextmacro DEFINE_VECTOR("", "ItemVector", "item")
//! runtextmacro DEFINE_STRUCT_VECTOR("", "RecipeIngredientVector", "RecipeIngredient")
//! runtextmacro DEFINE_STRUCT_LIST("", "RecipeIngredientList", "RecipeIngredient")
//! runtextmacro DEFINE_STRUCT_LIST("", "ItemRecipeList", "ItemRecipe")

struct ItemRecipe extends array
    integer charges
    boolean ordered
    boolean permanent
    boolean pickupable
static if LIBRARY_ItemRestriction then
    UnitRequirement requirement
endif
    readonly integer reward
    readonly integer count
    private RecipeIngredientList ingredients
    private integer abilityId
    private boolean batch

    implement Alloc

    private static method saveRecipe takes integer index, ItemRecipe recipe returns nothing
        local ItemRecipeList recipes
        if not instanceTable.has(index) then
            set instanceTable[index] = ItemRecipeList.create()
        endif
        set recipes = instanceTable[index]
        if recipes.find(recipe) == 0 then
            call recipes.push(recipe)
        endif
    endmethod

    private static method flushRecipe takes integer index, ItemRecipe recipe returns nothing
        local ItemRecipeList recipes = instanceTable[index]
        call recipes.erase(recipes.find(recipe))
        if recipes.empty() then
            call recipes.destroy()
            call instanceTable.remove(index)
        endif
    endmethod

    private static method getRecipes takes integer index returns ItemRecipeList
        if instanceTable.has(index) then
            return instanceTable[index]
        endif
        return 0
    endmethod

    static method getRecipesForReward takes integer itemTypeId returns ItemRecipeList
        return getRecipes(-itemTypeId)
    endmethod

    static method getRecipesWithIngredient takes integer itemTypeId returns ItemRecipeList
        return getRecipes(itemTypeId)
    endmethod

    static method getRecipesWithAbility takes integer abilityId returns ItemRecipeList
        return getRecipes(abilityId)
    endmethod

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
        set batch = false
        call saveRecipe(-reward, this)

        return this
    endmethod

    method getAbility takes nothing returns integer
        return abilityId
    endmethod

    method setAbility takes integer abilityId returns thistype
        if this.abilityId != abilityId then
            if this.abilityId != 0 then
                call flushRecipe(abilityId, this)
            endif
            if abilityId > 0 then
                set this.abilityId = abilityId
                call saveRecipe(abilityId, this)
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
            call flushRecipe(iter.data.itemTypeId, this)
            set iter = iter.next
        endloop
        call flushRecipe(-reward, this)

        call ingredients.destroy()
        call deallocate()
    endmethod

    static method operator [] takes thistype other returns thistype
        local thistype this = create(other.reward, other.charges, other.ordered, other.permanent, other.pickupable)
        local RecipeIngredientListItem iter = other.ingredients.first

        loop
            exitwhen iter == 0
            call this.ingredients.push(RecipeIngredient[iter.data])
            set iter = iter.next
        endloop

        set this.count = other.count
        call this.setAbility(other.abilityId)
        set this.batch = other.batch
        return this
    endmethod

    method getIngredients takes nothing returns RecipeIngredientList
        return RecipeIngredientList[ingredients]
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

    method startBatch takes nothing returns thistype
        if not batch then
            set batch = true
        debug else
            debug call DisplayTimedTextFromPlayer(GetLocalPlayer(),0,0,60,"ItemRecipe::startBatch failed. Batch is already started.")
        endif
        return this
    endmethod

    method endBatch takes nothing returns thistype
        if batch then
            set batch = false
            set count = count + 1
        debug else
            debug call DisplayTimedTextFromPlayer(GetLocalPlayer(),0,0,60,"ItemRecipe::endBatch failed. No batch has been started.")
        endif
        return this
    endmethod

    method removeItem takes integer itemTypeId returns thistype
        local RecipeIngredientListItem iter = ingredients.first
        local boolean found = false
        local RecipeIngredient ingredient

        if batch then // removing item when batch is ongoing is forbidden
            return this
        endif
        loop
            exitwhen iter == 0
            if iter.data.itemTypeId == itemTypeId then
                set ingredient = iter.data

                // Decrement count only if this item is not part of any batch
                if (iter.prev == 0 or iter.prev.data.index != ingredient.index) and /*
                */ (iter.next == 0 or iter.next.data.index != ingredient.index) then
                    set count = count - 1
                endif

                call ingredients.erase(iter)
                set found = true
            endif
            set iter = iter.next
        endloop

        if found then
            call flushRecipe(itemTypeId, this)
        endif
        return this
    endmethod

    method addItem takes integer itemTypeId, boolean perishable, integer charges returns thistype
        local RecipeIngredient ingredient

        if itemTypeId != reward then
            set ingredient = RecipeIngredient.create(itemTypeId, perishable, IMaxBJ(charges, 0), count)
            call ingredients.push(ingredient)
            if not batch then
                set count = count + 1
            endif
            call saveRecipe(itemTypeId, this)
        endif

        return this
    endmethod

    method addItemEx takes integer itemTypeId returns thistype
        return addItem(itemTypeId, true, 0)
    endmethod

    private method orderedSearch takes ItemVector items returns RecipeIngredientVector
        local integer slot = 0
        local boolean found
        local item itm
        local integer charges
        local RecipeIngredient ingredient
        local integer idx
        local RecipeIngredientVector result = RecipeIngredientVector.create()
        local RecipeIngredientListItem iter = ingredients.first
        call result.assign(items.size(), 0)

        loop
            exitwhen iter == 0 // test() validated this.count against items size already
            set found = false
            set itm = items[slot]
            set charges = GetItemCharges(itm)
            set ingredient = iter.data
            set idx = ingredient.index

            loop
                exitwhen ingredient.index != idx // treats each part of recipe as possible batch
                if GetItemTypeId(itm) == ingredient.itemTypeId and charges >= ingredient.charges then
                    set result[slot] = RecipeIngredient[ingredient]
                    set found = true
                    exitwhen true
                endif

                set iter = iter.next
                exitwhen iter == 0
                set ingredient = iter.data
            endloop

            if not found then
                call result.destroy()
                set result = 0
                exitwhen true
            endif
            // Seek node which is not part of this batch
            loop
                set iter = iter.next
                exitwhen iter == 0 or iter.data.index != idx
            endloop
            set slot = slot + 1
        endloop

        set itm = null
        return result
    endmethod

    private method unorderedSearch takes ItemVector items returns RecipeIngredientVector
        local boolean found
        local RecipeIngredient ingredient
        local integer idx
        local integer slot = 0
        local integer size = items.size()
        local item itm
        local integer itemTypeId
        local integer charges
        local RecipeIngredientVector result = RecipeIngredientVector.create()
        local RecipeIngredientListItem iter = ingredients.first
        call result.assign(size, 0)

        loop
            exitwhen iter == 0
            set found = false
            set ingredient = iter.data
            set idx = ingredient.index

            // Attempt to find any matching items from given batch within items collection
            loop
                exitwhen ingredient.index != idx
                set slot = 0
                loop
                    exitwhen slot >= size
                    if result[slot] == 0 then
                        set itm = items[slot]
                        set itemTypeId = GetItemTypeId(itm)
                        set charges = GetItemCharges(itm)

                        if GetItemTypeId(itm) == ingredient.itemTypeId and charges >= ingredient.charges then
                            set result[slot] = RecipeIngredient[ingredient]
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
                call result.destroy()
                set result = 0
                exitwhen true
            endif
            // Seek node which is not part of this batch
            loop
                set iter = iter.next
                exitwhen iter == 0 or iter.data.index != idx
            endloop
        endloop

        set itm = null
        return result
    endmethod

    method test takes unit whichUnit, ItemVector items returns RecipeIngredientVector
        if items == 0 or items.size() < count then
            return 0
        endif
static if LIBRARY_ItemRestriction then
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
        local RecipeIngredientVector result

        loop
            exitwhen slot >= size
            call items.push(UnitItemInSlot(whichUnit, slot))
            set slot = slot + 1
        endloop
        set result = test(whichUnit, items)

        call items.destroy()
        return result
    endmethod

    method assemble takes unit whichUnit, ItemVector fromItems returns boolean
        local integer size = fromItems.size()
        local RecipeIngredient ingredient
        local item rewardItm
        local item itm
        local integer chrgs
        local RecipeIngredientVector fromIngredients = test(whichUnit, fromItems)
        local ItemVector usedItems
        local integer i = 0

        if fromIngredients == 0 then
            return false
        endif
        set rewardItm = CreateItem(reward, GetUnitX(whichUnit), GetUnitY(whichUnit))
        if charges > 0 then
            call SetItemCharges(rewardItm, charges)
        endif

        set usedItems = ItemVector.create()
        loop
            exitwhen i >= size
            if fromIngredients[i] != 0 then
                call usedItems.push(fromItems[i])
            endif
            set i = i + 1
        endloop

        call FireEvent(this, whichUnit, rewardItm, usedItems)

        set i = 0
        loop
            exitwhen i >= size
            set ingredient = fromIngredients[i]
            if ingredient != 0 then
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
        call UnitAddItem(whichUnit, rewardItm)

        call fromIngredients.destroy()
        call usedItems.destroy()
        set rewardItm = null
        set itm = null
        return true
    endmethod

    method assembleEx takes unit whichUnit returns boolean
        local integer slot = 0
        local integer size = UnitInventorySize(whichUnit)
        local ItemVector items = ItemVector.create()
        local boolean result

        loop
            exitwhen slot >= size
            call items.push(UnitItemInSlot(whichUnit, slot))
            set slot = slot + 1
        endloop
        set result = assemble(whichUnit, items)

        call items.destroy()
        return result
    endmethod

    method disassemble takes unit whichUnit returns boolean
        local integer slot = 0
        local integer size = UnitInventorySize(whichUnit)
        local boolean result = false
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
                call RemoveItem(itm)

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

                set result = true
                exitwhen true
            endif
            set slot = slot + 1
        endloop

        set itm = null
        return result
    endmethod
endstruct

function UnitAssembleItem takes unit whichUnit, integer itemTypeId returns boolean
    local ItemRecipeList recipes = ItemRecipe.getRecipesForReward(itemTypeId)
    local ItemRecipeListItem iter

    if recipes != 0 then
        set iter = recipes.first
        loop
            exitwhen iter == 0
            if iter.data.assembleEx(whichUnit) then
                return true
            endif
            set iter = iter.next
        endloop
    endif
    return false
endfunction

function UnitDisassembleItem takes unit whichUnit, item whichItem returns boolean
    local ItemRecipeList recipes

    if UnitHasItem(whichUnit, whichItem) then
        set recipes = ItemRecipe.getRecipesForReward(GetItemTypeId(whichItem))
        // Disassembling item with multiple recipe variants is ambiguous
        if recipes != 0 and recipes.size() == 1 then
            return recipes.front().disassemble(whichUnit)
        endif
    endif
    return false
endfunction

private function OnPickup takes nothing returns nothing
    local unit u
    local integer itemTypeId = GetItemTypeId(GetManipulatedItem())
    local ItemRecipeList recipes = ItemRecipe.getRecipesWithIngredient(itemTypeId)
    local ItemRecipeListItem iter
    local ItemRecipe recipe

    if recipes != 0 then
        set u = GetTriggerUnit()
        set iter = recipes.first

        loop
            exitwhen iter == 0
            set recipe = iter.data
            if recipe.pickupable and recipe.assembleEx(u) then
                exitwhen true
            endif
            set iter = iter.next
        endloop
        set u = null
    endif
endfunction

static if LIBRARY_InventoryEvent then
private function OnMoved takes nothing returns nothing
    local unit u
    local item itm = GetInventoryManipulatedItem()
    local ItemRecipeList recipes = ItemRecipe.getRecipesWithIngredient(GetItemTypeId(itm))
    local ItemRecipeListItem iter
    local ItemRecipe recipe
    local integer slot = 0
    local integer size
    local ItemVector items

    if recipes != 0 then
        set u = GetInventoryManipulatingUnit()
        set size = UnitInventorySize(u)
        set items = ItemVector.create()

        loop
            exitwhen slot >= size
            call items.push(UnitItemInSlot(u, slot))
            set slot = slot + 1
        endloop
        set items[GetInventorySlotFrom()] = GetInventorySwappedItem()
        set items[GetInventorySlotTo()] = itm

        set iter = recipes.first
        loop
            exitwhen iter == 0
            set recipe = iter.data
            if recipe.pickupable and recipe.assemble(u, items) then
                exitwhen true
            endif
            set iter = iter.next
        endloop

        call items.destroy()
        set u = null
    endif
    set itm = null
endfunction
endif

private function OnCast takes nothing returns nothing
    local unit u
    local ItemRecipeList recipes = ItemRecipe.getRecipesWithAbility(GetSpellAbilityId())
    local ItemRecipeListItem iter

    if recipes != 0 then
        set u = GetTriggerUnit()
        set iter = recipes.first

        loop
            exitwhen iter == 0
            if iter.data.assembleEx(u) then
                exitwhen true
            endif
            set iter = iter.next
        endloop
        set u = null
    endif
endfunction

static if LIBRARY_SmoothItemPickup then
private function GetCheatRecipe takes unit u, item itm returns ItemRecipe
    local ItemRecipeList recipes = ItemRecipe.getRecipesWithIngredient(GetItemTypeId(itm))
    local ItemRecipeListItem iter
    local ItemRecipe recipe
    local ItemRecipe result = 0
    local integer slot = 0
    local integer size
    local ItemVector items
    local RecipeIngredientList ingredients
    local RecipeIngredientListItem ingrIter

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
    call items.push(itm)

    set iter = recipes.first
    loop
        exitwhen iter == 0 or result != 0
        set recipe = iter.data

        if recipe.pickupable and not recipe.ordered then
            set ingredients = recipe.getIngredients()
            set ingrIter = ingredients.first
            loop
                exitwhen ingrIter == 0
                // At least one item has to removed, in order to fit recipe reward in
                if ingrIter.data.perishable and recipe.test(u, items) != 0 then
                    set result = recipe
                    exitwhen true
                endif
                set ingrIter = ingrIter.next
            endloop
        endif

        set iter = iter.next
    endloop

    call items.destroy()
    return result
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
        call recipe.assemble(u, items)
        call items.destroy()
    endif

    set u = null
    set itm = null
endfunction

private struct SmoothRecipeAssembly extends array
    static method canPickup takes unit whichUnit, item whichItem returns boolean
        return GetCheatRecipe(whichUnit, whichItem) != 0
    endmethod

    implement optional SmoothPickupPredicateModule
endstruct
endif

private module Init
    private static method onInit takes nothing returns nothing
        set EVENT_ITEM_RECIPE_ASSEMBLE = CreateNativeEvent()
        set instanceTable = Table.create()

        call RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_PICKUP_ITEM, function OnPickup)
        call RegisterAnyPlayerUnitEvent(EVENT_PLAYER_UNIT_SPELL_EFFECT, function OnCast)
static if LIBRARY_InventoryEvent then
        call RegisterNativeEvent(EVENT_ITEM_INVENTORY_MOVE, function OnMoved)
endif
static if LIBRARY_SmoothItemPickup then
        // Allow for smooth pickup for pickup-type unordered recipes
        call RegisterNativeEvent(EVENT_ITEM_SMOOTH_PICKUP, function OnSmoothPickup)
        call AddSmoothItemPickupCondition(SmoothRecipeAssembly.create())
endif
    endmethod
endmodule

private struct StructInit extends array
    implement Init
endstruct

endlibrary