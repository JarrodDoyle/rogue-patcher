/* A set of function to make managing the UI elements in rollouts a tad bit easier */

format " - Loading... UIManager\n"

struct UIManager (
    BORDER = 5,
    GAP = 5,
    LINE = 20,
    GROUPBOX_PADDING = 6,
    GROUPBOX_PADDING_TOP = 25,

    fn Borders = (
        return BORDER * 2
    ),

    fn Gaps amount = (
        return GAP * amount
    ),

    -- Returns the width of a GroupBox frame for the content of width equal to baseSize
    fn BoxWidth baseSize = (
        return baseSize + GROUPBOX_PADDING * 2
    ),

    -- Returns the height of a GroupBox frame for the content of height equal to baseSize
    fn BoxHeight baseSize = (
        return baseSize + GROUPBOX_PADDING + GROUPBOX_PADDING_TOP
    ),

    -- Calculate size of the group box content based on its width and height
    fn BoxContentHeight ctrl = (
        return ctrl.height - GROUPBOX_PADDING - GROUPBOX_PADDING_TOP
    ),

    fn BoxContentWidth ctrl = (
        return ctrl.width - GROUPBOX_PADDING * 2
    ),
    -- These functions calculate coordinates of GroupBox frame corners
    fn BoxContentTopLeft ctrl = (
        return ctrl.pos + [GROUPBOX_PADDING, GROUPBOX_PADDING_TOP]
    ),

    fn BoxContentTopRight ctrl = (
        return ctrl.pos + [ctrl.width - GROUPBOX_PADDING, GROUPBOX_PADDING_TOP]
    ),

    fn BoxContentBottomLeft ctrl = (
        return ctrl.pos + [GROUPBOX_PADDING, ctrl.height - GROUPBOX_PADDING]
    ),

    fn BoxContentBottomRight ctrl = (
        return ctrl.pos + [ctrl.width - GROUPBOX_PADDING, ctrl.height - GROUPBOX_PADDING]
    ),

    -- Hides an array of controls
    fn HideControls ctrls = (
        for ctrl in ctrls do (
            ctrl.visible = false
        )
    ),

    -- Shows an array of controls
    fn ShowControls ctrls = (
        for ctrl in ctrls do (
            ctrls.visible = true
        )
    ),

    -- Disables an array of controls
    fn DisableControls ctrls = (
        for ctrl in ctrls do (
            ctrl.enabled = false
        )
    ),

    -- Enables an array of controls
    fn EnableControls ctrls = (
        for ctrl in ctrls do (
            ctrls.enabled = true
        )
    ),

    -- Calculate size of elements
    fn getSizeInLine totalSize amount gapSize = (
        return ((totalSize - (amount - 1) * gapSize)) / amount
    )
    
)

global UIM = UIManager()

struct TableModelRow (
    id = 0,                     
    modified = false,
    items = #(),

    fn GetItem itemId = (
        if itemId == 0 then     -- special index value for 'id' value
            return this.id
        else if itemId == -1 then    -- speciald index value for 'modified' flag
            return this.modified
        else return this.items[itemId]
    ),

    fn SetModified state = (
        this.modified = state
    )
)

struct TableModelColumn (
/* Specifies the data type and its properties for each Item */
    name = "",                  -- column name
    dataType = #string,         -- #integer, #float, #string, #boolean, #enum
    reversed = false,           -- whether to sort in reversed order or not
    unique = false,             -- do the values need to be unique or not
    autoIncrement = true,       -- if a new item is not unique, it will be autonatically incremented. 
    -- Type specific settings:
    default = undefined,        -- default value, if not assigned
    minValue = 0,               -- min value (currently not used)
    maxValue = 9999999,         -- max value (currently not used)
    minLength = 0,              -- min string length 
    maxLength = 256             -- max string length (currently not used)
    
)

struct TableModel (
    view = undefined,
    colMinIndex = 1,
    colOffset = 0,
    _uniqueId = 0,
    columns = #(),
    _sourceRows = #(),      -- a full list of rows
    _rows = #(),            -- filtered and sorted list of rows - this is what a view is showing
    selection = 0,          -- an id of selected row
    sorting = false,
    sortColumn = 0,
    previousSortColumn = 0,
  
    fn GetItemType colId = (
        this.columns[colId + colOffset].dataType
    ),

    fn GetNextID = (
        this._uniqueId +=1
        this._uniqueId
    ),

    fn Items = (
        _rows    
    ),

    fn rowsCount = (
        _rows.count
    ),

    fn columnsCount = (
        /* Returns number of user defined columns */
        (this.columns.count - this.colOffset)
    ),

    fn AddRow rowItems = (
        if rowItems.count != columnsCount() then (
            print "Number of items does not match!"
            return()
        )        
        row = TableModelRow()
        row.id = this.GetNextId() 
        row.items = rowItems
        -- format "Adding row: %\n" row
        append _sourceRows row    
        row   
    ),

    fn columnSort v1 v2 colNum: secColNum: = (
    /*  Do a comparison of column items.
        Args:
            colNum: the primary column to sort the items 
            secColNum: secondary column - taken into account, in case of equal values from the primary one
    */
        local val1
        local val2
        local dataType = this.columns[colNum + this.colOffset].dataType
        case dataType of (
            #bool:(
                val1 = bool2int (_sourceRows[v1].GetItem colNum) 
                val2 = bool2int (_sourceRows[v2].GetItem colNum)
            )
            default:(
                val1 = _sourceRows[v1].GetItem colNum 
                val2 = _sourceRows[v2].GetItem colNum
            )
        )
        if val1 < val2 then return -1
        if val1 > val2 then return 1
        if val1 == val2 then (
            if secColNum != undefined then (
                result = columnSort v1 v2 colNum:secColNum secColNum:undefined
                return result
            ) else (
                return 0
            )
        )
    ),    

    fn UpdateItemsList = (        
    /* Applies sorting and filtering to the list of _soureRows 
        and outputs list of _rows - rows of items visible in the view */
        if this.sorting == false then
            this._rows = this._sourceRows
        else         
            this._rows = #()     
            
            local indexArray = for i = 1 to _sourceRows.count collect i
            qsort indexArray columnSort colNum:sortColumn secColNum:previousSortColumn
            if this.columns[sortColumn + this.colOffset].reversed == true then (
                indexArray = reverseArray indexArray
            )
            for i = 1 to indexArray.count do (
                this._rows[i] = _sourceRows[indexArray[i]]
            )            
            -- local sortedList = for row in _sourceRows collect row.GetItem sortColumn
            -- -- format "SORT COLUMN %\n" sortColumn
            -- sort sortedList
            -- -- print sortedList
            -- if this.columns[sortColumn + this.colOffset].reversed == true then (
            --     sortedList = reverseArray sortedList
            -- )
            -- for i = 1 to _sourceRows.count do (
            --     keyItem = _sourceRows[i].GetItem sortColumn
            --     index = findItem sortedList keyItem
            --     _rows[index] = _sourceRows[i]
            -- )        

    ),

    fn SetSorting state colNum reversed = (        
        this.sorting = state        
        this.previousSortColumn = this.sortColumn
        this.sortColumn = colNum
        this.columns[this.sortColumn + this.colOffset].reversed = reversed
        UpdateItemsList()
    ),

    fn getColumnByName colName = (
        colNum = undefined
        for i = 1 to this.columns.count do (
            if this.columns[i].name == colName then (
                colNum = i - this.colOffset
            )
        )        
        colNum
    ),

    fn getItem row col = (
        if classof col == String then (
            col = getColumnByName col
        )
        if (row > 0) and (row <= _rows.count) then
        -- local items = 
            return _rows[row].GetItem col
        else
            return #()
    ),    

    fn getItemByName row colName = (
        colNum = getColumnByName colName
        if colNum != undefined then (
            return (getItem row colNum)
        )
        undefined
    ),

    fn getRow row = (
        if row > 0 then 
            return _rows[row]
        else
            return #()
    ),

    fn getSelectedRow = (
        _rows[this.selection]
    ),

    fn getSelectedRowItem col = (
        if this.selection > 0 then (
            _rows[this.selection].GetItem col
        ) else (
            return undefined
        )
    ),

    fn SelectRowById selId = (
        for i = 1 to this._rows.count do (
            if this._rows[i].id == selId then (
                this.selection = i
                return this.selection
            )
        )
        this.selection
    ),

    fn IncrementValue col oldValue = (
        local column this.columns[col + this.colOffset]
        case column.dataType of (
            #string:(
                oldValue = "maps/nature/water_canals_water2_0_0_1009_depth_39"
                rgx = dotnetObject "System.Text.RegularExpressions.Regex" ""
                found = rgx.IsMatch str "[a-zA-Z]+([0-9]+)$"    -- looks for a group of digits at the end
                
            )
            -- TODO: finish this when you have time....
        )
    ),

    fn OKToChange row col newValue = (
    /* Checks whether a value meets column specifications, data type and whether is not undefined */
        itsOK = true
        local column = this.columns[col + this.colOffset]
        -- check ranges
        -- case column.dataType of (
        --     #string:(
        --         if 
        --     )
        -- )

        -- check for uniqueness
        if column.unique == true then (
            for i = 1 to this.rowsCount() do (
                if ((getItem i col) == newValue) then (                         
                    -- values are identical but should be unique, hence it's NOT OK to change <-- HOLD on! Implementing auto-increment now...
                    itsOK = false   
                    /*  -- sorry - not implementing yet...
                    if column.autoIncrement == true then (
                        case column.dataType of (
                            #bool:itsOK = false
                            #default:(
                                -- try incrementing until it's OK to do so.
                                attempts = 0
                                stopIncrementing = false
                                while stopIncrementing == true do ( 
                                    incremented = IncrementValue col newVal
                                    result = OKToChange row col incremented                                    
                                    itsOK = result[0]
                                    if itsOK == true then (
                                        newValue = incremented
                                        stopIncrementing = true                                        
                                    ) 
                                    attempts += 1
                                    if attempts > 100 then (
                                        stopIncrementing = true
                                    )                                    
                                )
                            )
                        )
                    ) else (
                        itsOK = false
                    )*/                    
                )
            )
        )
        -- check for undefined
        if newValue == undefined then (
            itsOK = false

        )
        #(itsOK, newValue)
    ),

    fn SetItem row col newValue = (
        local id
        local row
        local ISOK = 1
        local CORRECTED_VAL = 2
        if (row > 0) and (row <= rowsCount() ) then (
            if (col >= 1) and (col <= columnsCount() ) then (
                dataRow = getSelectedRow() 
                id = dataRow.id
                -- actualRow = 
                changed = false
                case this.columns[col + this.colOffset].dataType of (
                    #string:(
                        result = OKToChange id col newValue
                        if result[ISOK] == true then (
                            _sourceRows[id].items[col] = result[CORRECTED_VAL]
                            changed = true
                        )
                    )
                    #integer:(
                        newInt = newValue as integer
                        result = OKToChange id col newInt
                        if result[ISOK] == true then (
                            _sourceRows[id].items[col] = result[CORRECTED_VAL]
                            changed = true
                            newValue = result[CORRECTED_VAL]
                        )
                    )
                    #float:(
                        newFloat = newValue as float
                        result = OKToChange id col newFloat
                        if result[ISOK] == true then (
                            _sourceRows[id].items[col] = result[CORRECTED_VAL]
                            changed = true
                            newValue = result[CORRECTED_VAL]
                        )
                    )
                    #bool:(
                        result = OKToChange id col newValue
                        if result[ISOK] == true then (
                            _sourceRows[id].items[col] = newValue
                            changed = true
                        )
                    )
                )
                if changed == true then (
                    _sourceRows[id].SetModified true
                    UpdateItemsList()                
                    format "Succesfully changed item % in row % to '%'\n" col id (newValue as string)
                ) else (
                    format "Value did not change.\n"
                )
            ) else (
                format "Column number out of range: %\n" col
            )
        ) else (
            format "Row number out of range: %\n" row
        )
        #(changed, newValue)
    ),

    fn FindRowsWhere itemName operation itemValue = (
        /* Returns an array of rows, that meet the condition. 
        Example:
            FindRowsWhere "tagName" #is "Locomote"
            FindRowsWhere "param2" #isGreaterThan 1.0
            FindRowsWhere "uniqueId" #isLowerThan 100
        */
        local found = #()
        local colId = getColumnByName itemName
        if colId == undefined then (
            return found
        )     
        if (FindItem #(#is, #isNot, #isGreatherThan, #isLowerThan) operation) < 1 then (
            format "\\\\ERROR: Unknown operation: '%'\n" operation                    
            return #()
        )

        local dataType = this.columns[colId + this.colOffset].dataType
        if dataType == #bool then (
            itemValue = bool2int itemValue
        )

        for i = 1 to _rows.count do (
            item = _rows[i].GetItem colId
            if dataType == #bool then (
                item = bool2int item
            )
            case operation of (
                #is:(
                    if item == itemValue then append found i
                )
                #isnot:(
                    if item != itemValue then append found i 
                )
                #isGreaterThan:(
                    if item > itemValue then append found i
                )
                #islowerThan:(
                    if item < itemValue then append found i
                )                
            )
        )
        found
    ),

    fn SetNumberOfDefaultColumns num = (
        this.colMinIndex = 1 - num 
        this.colOffset = num
    ),

    fn AddModelColumn newColumn = (
        append this.columns newColumn
    ),

    on create do (        
        /* Add first two standard columns */
        newColumn = TableModelColumn name:"modified" dataType:#bool unique:false
        append this.columns newColumn
        newColumn = TableModelColumn name:"uniqueId" dataType:#integer unique:true minValue:1
        append this.columns newColumn       
        SetNumberOfDefaultColumns 2 
    )
)

struct TableColumn (
    id = 0,             -- unique table view id
    header,
    sorter,
    body,
    title = "Column",
    modelId = 0,
    defaultWidth = 100,
    width = 100,
    stretchFactor = 1,
    editControl = undefined,
    dataType = #string,
    editable = false,
    boolRepr = #("", " X ")     -- strings representing boolean values - false and true
)

struct TableView (
    public 
    /* const */
    COL_MIN_WIDTH = 40,
    SCROLL_BUTTON_HEIGHT = 16,
    /* model */
    model = undefined,       
    /* table structure variables */
    scrollBarHeight = 50, 
    numRows = 5,  
    columns = #(),
    _defaultWidth = 0,
    _stretchFactors = 0,
    /* standard controls */
    edit_String,
    edit_Int,
    edit_Float,
    edit_Bool,
    edit_cancel,
    pb_scrollBar,
    bt_scroll,
    bt_scrollUp,
    bt_scrollDown,    
    scrollBarControls = #(),        -- for convenience - list of the above scrollbar controls
    /* table state variables - these can change over life time */
    bodyWidth = 0,
    totalWidth = 0,    
    totalHeight = 0,
    pos = [10, 10],    
    scrollBarIndex = 0,
    _editMode = false,
    _editColumn = 0, 
    
    fn GetScrollBarHeight numRows = (
        return (numRows * 13 - (SCROLL_BUTTON_HEIGHT * 2) + 24)
    ),

    on create do (
        this.totalHeight = numRows * 13 + 24
        this.scrollBarHeight = GetScrollBarHeight this.numRows
        this.scrollBarIndex = 0        
    ),    

    fn SetPos x y = (                
        this.pos = [x, y]
    ), 

    fn SetScrollBarControls controlsList = (
        scrollBarControls = controlsList
        pb_scrollBar = controlsList[1]
        bt_scroll = controlsList[2]
        bt_scrollUp = controlsList[3]
        bt_scrollDown = controlsList[4]
    ),

    fn SetEditControls str int float bool cancel = (
        this.edit_String = str
        this.edit_Int = int
        this.edit_Float = float
        this.edit_Bool = bool
        this.edit_cancel = cancel
    ),
    
    fn AddNewColumn header:undefined sorter:undefined body:undefined title:"" \
                    modelId:0 defaultWidth:100 stretchFactor:1 editable:false boolRepr:undefined = (
        local newId = this.columns.count + 1
        local newColumn = TableColumn \
            id:newId \
            header:header \
            sorter:sorter \
            body:body \
            title:title \
            modelId:modelId \
            defaultWidth:defaultWidth \
            width:defaultWidth \
            stretchFactor:stretchFactor \
            editable:editable \        
        newColumn.dataType = this.model.GetItemType modelId
        if boolRepr != undefined then (
            newColumn.boolRepr = boolRepr
        )
        case newColumn.dataType of (
            #String:newColumn.editControl = this.edit_String
            #Integer:newColumn.editControl = this.edit_Int
            #Float:newColumn.editControl = this.edit_Float
            #Bool:newColumn.editControl = this.edit_Bool
        )        
        append this.columns newColumn
        if sorter != undefined then (
            sorter.visible = true
            sorter.toolTip = (stringFormat "Sort by '%'" v1:title)
            header.width = defaultWidth - 14            
        ) else (
            header.width = defaultWidth
        )
        header.text = title 
        body.width = defaultWidth

        this._defaultWidth += defaultWidth
        this._stretchFactors += stretchFactor
        
        newColumn
    ),

    fn numColumns = (
        return this.columns.count
    ),

    fn SetWidth desiredWidth = (
        local width
        local minWidth
        local defWidth
        local factor
        local stretchAmount
		minWidth = (this.numColumns()) * this.COL_MIN_WIDTH
		if desiredWidth < minWidth then 
            desiredWidth = minWidth		
        this.totalWidth = desiredWidth + 20
        this.bodyWidth = desiredWidth
        
        local widthDiff = this.bodyWidth - this._defaultWidth
        local columnOffset = 0        
        for i = 1 to this.numColumns() do (
            local column = this.columns[i]
            factor = column.stretchFactor
            if factor == 0 then (
                stretchAmount = 0
            ) else (
                stretchAmount = 1.0 * factor / this._stretchFactors * widthDiff
            )            
            width = column.defaultWidth + stretchAmount
            column.width = width
            -- Header
            column.header.pos = this.pos + [columnOffset, 0]
            if column.sorter != undefined then (
                column.header.width = width - 14             
                column.sorter.pos = column.header.pos + [width - 14, 0]
            ) else (
                column.header.width = width
            )
            -- Body
            column.body.width = width
            column.body.pos = column.header.pos + [0, 17]
            if (_editMode == true) and (_editColumn == i) then (
                case column.dataType of (
                    #string:(
                        column.editControl.width = width - 13
                    )
                    #integer:(
                        column.editControl.width = width - 13
                    )
                    #float:(
                        column.editControl.width = width - 13
                    )
                )                     
                column.editControl.pos.x = column.body.pos.x
                this.edit_Cancel.pos.x = column.editControl.pos.x + column.editControl.width
                
            )            
            -- 
            columnOffset += width
        )
        this.pb_scrollBar.pos = this.columns[this.numColumns()].header.pos + [this.columns[this.numColumns()].body.width, SCROLL_BUTTON_HEIGHT]
		this.bt_scrollUp.pos = this.pb_scrollBar.pos + [0, - SCROLL_BUTTON_HEIGHT]
        this.bt_scrollDown.pos = this.pb_scrollBar.pos + [0, this.scrollBarHeight]
        this.bt_scroll.pos = [this.pb_scrollBar.pos.x, this.bt_scroll.pos.y]
    ),

    fn RefreshView = (        
        if model == undefined then (
            return()
        )
        local tempItems = #()
        local itemRepr
        for x = 1 to this.numColumns() do (
            tempItems = #()
            modelColumn = columns[x].modelId
            for y = 1 to this.numRows do (
                modelRowIndex = this.scrollBarIndex + y
                itemValue = model.getItem modelRowIndex modelColumn
                itemRepr = case columns[x].dataType of (
                    #Bool:(columns[x].boolRepr[(bool2int itemValue) + 1])
                    default:(itemValue as string)
                )
                append tempItems itemRepr
            )
            this.columns[x].body.items = tempItems
        )
    ),

    fn SetModel model = (
        this.model = model
        this.model.view = this
        -- RefreshView()
    ),

    fn GetViewColumnId columnBody = (
        viewCol = 0
        for i = 1 to this.numColumns() do (
            if this.columns[i].body == columnBody then 
                viewCol = i
        )
        viewCol
    ),

    fn StartEditing columnBody id = (
        viewCol = GetViewColumnId columnBody
        
        if columns[viewCol].editable == false then
            return()

        this._editMode = true
        this._editColumn = viewCol
        column = this.columns[viewCol]
        modelCol = column.modelId
        editCtrl = column.editControl        
        editCancelCtrl = this.edit_Cancel
        
        itemValue = this.model.getSelectedRowItem modelCol
        editCtrl.pos = column.body.pos + [0, 13 * (id - 1) + 1]
        local editCtrlWidth = column.body.width - 13
        editCancelCtrl.pos = editCtrl.pos + [editCtrlWidth, 0]
        case column.dataType of (
            #string:(
                editCtrl.text = itemValue
                editCtrl.width = editCtrlWidth
            )
            #integer:(
                editCtrl.text = itemValue as string
                editCtrl.width = editCtrlWidth
            )
            #float:(
                editCtrl.text = itemValue as string
                editCtrl.width = editCtrlWidth
            )
            #bool:(
                editCtrl.checked = itemValue
                editCtrl.pos = editCtrl.pos + [(editCtrlWidth - 16) / 2, 0]
            )
        )                

        column.body.enabled = false
        -- UIM.DisableControls this.columns
        -- UIM.DisableControls this.scrollBarControls
        editCtrl.visible = true
        editCancelCtrl.visible = true
    ),

    fn FinishEditing = (  
        if this._editMode == false then return()

        editCtrl = this.columns[this._editColumn].editControl
        editCancelCtrl = this.edit_Cancel
        editCtrl.visible = false
        editCancelCtrl.visible = false
        -- UIM.EnableControls this.columns
        -- UIM.EnableControls this.scrollBarControls
        this.columns[_editColumn].body.enabled = true
        this._editMode = false
    ),

    fn EditValue newValue = (
        result = (model.SetItem model.selection columns[_editColumn].modelId newValue)  -- result is #(bool result, dynamicType newValue) -- newValue may be modified by min/max constraints
        FinishEditing()
        if result[1] == true then (
            RefreshView()
        )
        return #(result[1], model.selection, columns[_editColumn].modelId, result[2])
    ),

    fn GetItem viewRow viewCol = (
    /* Retrieves the value from the table item */
        modelRowIndex = this.scrollBarIndex + y
        modelColumn = this.columns[viewCol].modelId
        this.model.GetItem modelRowIndex modelColumn
    ),

    fn GetSelectedItem = (
    /* Gets item that is (about to) being edited */
        modelColumn = this.columns[_editColumn].modelId
        this.model.getSelectedRowItem modelColumn
    ),

    fn SetScrollBar invertedPercent = (
        percent = 100 - invertedPercent
		this.pb_scrollBar.value = percent
        this.bt_scroll.pos = this.pb_scrollBar.pos + [0, 0.01 * invertedPercent * (this.scrollBarHeight - 20) ]
                        
        if this.model != undefined then 
            rowCount = this.model.rowsCount()
        else
            rowCount = 0
		range = rowCount - this.numRows
        index = invertedPercent * range / 100 --+ 1
        if index < 0 then index = 0
        this.scrollBarIndex = index
        -- format "ScrollBarIndex: %\n" index
        if this.model != undefined then (
            RefreshView()
            -- now, shift selection....		
            newListIndex = this.model.selection - scrollBarIndex
            if (newListIndex < 1) or (newListIndex > this.numRows) then (
                if this._editMode == true then FinishEditing()
                newListIndex = 0
            ) else  (
                /* move editing controls */
                if this._editMode == true then (
                    column = this.columns[_editColumn]
                    column.editControl.pos.y = column.body.pos.y + (newListIndex - 1) * 13 + 1
                    this.edit_Cancel.pos.y = column.editControl.pos.y
                )
            )
            for col in this.columns do (
                col.body.selection = newListIndex
            )
        )
    ),
    
    fn ScrollOneUp = (
        percent = 100 - this.pb_scrollBar.value
		if percent > 0 then (
			SetScrollBar (percent-1)
        )
    ),

    fn ScrollOneDown = (
        percent = 100 - this.pb_scrollBar.value
		if percent < 100 then (
			SetScrollBar (percent+1)
		)
    ),
    
    fn SelectRow viewRowId = (        
        if this._editMode == true then 
            FinishEditing()
        
        for col in this.columns do (
            col.body.selection = viewRowId
        )
        this.model.selection = viewRowId + this.scrollBarIndex                    
    ),

    fn SelectRowById rowId = (          
        modelRowId = this.model.SelectRowById rowId        
        -- format "Selecting row with id: % - that is row % in the model.\n" rowId modelRowId
        rowCount = this.model.rowsCount()
        range = rowCount - this.numRows
        -- format "Range: %\n" range
        if modelRowId > this.scrollBarIndex + this.numRows then (
            this.scrollBarIndex = modelRowId - this.numRows
            viewRowId = this.numRows
        ) else if modelRowId <= this.scrollBarIndex then (
            this.scrollBarIndex = modelRowId - 1
            viewRowId = 1
        ) else (
            viewRowId = modelRowId - this.scrollBarIndex
        )
        -- format "The resulting view rowId is % and scrollBarIndex is %\n" viewRowId this.scrollBarIndex
        RefreshView()
        for col in this.columns do (
            col.body.selection = viewRowId
        )
        percent = 100.0 * this.scrollBarIndex / range
        -- format "Scrollbar percent is %.\n\n" percent
        this.pb_scrollBar.value = (100 - percent)
        this.bt_scroll.pos = this.pb_scrollBar.pos + [0, 0.01 * percent * (this.scrollBarHeight - 20) ]        
    ),

    fn UpdateSorters colNum rev = (
        for i = 1 to this.numColumns() do (
            column = this.columns[i]
            if column.sorter != undefined then (
                if i != colNum then (
                    column.sorter.text = "-"
                ) else if rev == true then (
                    column.sorter.text = "v"
                ) else (
                    column.sorter.text = "^"
                )
            )
        )
    ),

    fn SetSorting state columnBody rev:undefined = (
        viewCol = GetViewColumnId columnBody

        if this._editMode == true then 
            FinishEditing()

        modelCol = this.columns[viewCol].modelId
        if rev == undefined then 
            reversedState = (not this.model.columns[modelCol + this.model.colOffset].reversed)
        else 
            reversedState = rev
        selectedId = this.model.GetSelectedRowItem 0
        this.model.SetSorting state modelCol reversedState
        if selectedId != undefined then (
            this.SelectRowById selectedId
        )
        UpdateSorters viewCol reversedState
        RefreshView()
    )

    
)


