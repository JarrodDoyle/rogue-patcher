/* ------------------------------------------------------
/* 			Dark Animation Tools
/*  		Motion Schema Editor - Rollouts
/* ------------------------------------------------------
/* author: Juliusz Kaczmarek
/* May. 2018
/* 
/*
/* this script was possible thanks to the knowledge and experience 
/* of Volca, Shadowspawn, Weyoun, Telliamed
/* ------------------------------------------------------
*/

format " - Loading... Motion Database Editor Rollouts\n"

rollout NewTagUI "Add new tag" width:250 height:130
(
	local DataModel = if DataModel != undefined then DataModel else undefined
	local result = false
	local tagName = ""	

	edittext et_tagName "Enter tag name:" labelOnTop:true offset:[0, 10]
	label lb_valid "..." align:#left
	button bt_ok "OK" width:80 height:30 across:2 offset:[35, 10] enabled:false
	button bt_cancel "Cancel" width:80 height:30 offset:[15, 10]

	on et_tagName changed val do (		
		local valid = true
		local validationMsg = "OK"
		if val.count < 2 then (		
			valid = false
			validationMsg = "Tag is too short. (must be min. 2 characters)"
		)
		tagNames = for i = 1 to (DataModel.rowsCount()) collect (DataModel.GetItem i "tagName")
		if (findItem tagNames val) > 0 then (
			valid = false
			validationMsg = "Tag already exists. New tag must be unique."
		) 
		bt_ok.enabled = valid
		lb_valid.caption = validationMsg
	)

	on bt_ok pressed do (
		tagName = et_tagName.text
		result = true
		rowItems = #(tagName, 0, 1.0, false)
		row = DataModel.AddRow rowItems
		row.modified = true
		DataModel.UpdateItemsList()
		destroyDialog NewTagUI
	)

	on bt_cancel pressed do (
		DestroyDialog NewTagUI
	)
)

rollout TagEditorUI "Edit tags" width:430 height:450
(	
	local Table = TableView numRows:20
	local DataModel = undefined
	local preselection = if preselection != undefined then preselection else undefined 	-- start with this tag selected

	local BUTTON_HEIGHT = 25
	/* Table controls */
	/* Column 1*/
	editText et_header1 "" text:"" readonly:true 			-- column title
	button bt_sort1 "v" width:14 height:14 visible:true		-- sorting button
	listbox lb_column1 "" height:Table.numRows				-- actual column with table items

	/* Column 2*/
	editText et_header2 "" text:"" readonly:true
	button bt_sort2 "v" width:14 height:14 visible:true
	listbox lb_column2 "" height:Table.numRows

	/* Column 3*/
	editText et_header3 "" text:"" readonly:true		
	button bt_sort3 "v" width:14 height:14 visible:true
	listbox lb_column3 "" height:Table.numRows

	/* Column 4*/
	editText et_header4 "" text:"" readonly:true		
	button bt_sort4 "v" width:14 height:14 visible:true
	listbox lb_column4 "" height:Table.numRows

	/* Column 5*/
	editText et_header5 "" text:"" readonly:true 
	button bt_sort5 "v" width:14 height:14 visible:true 
	listbox lb_column5 "" height:Table.numRows tooltip:"Modified"
	
	/* Column 6*/
	editText et_header6 "" text:"" readonly:true 
	button bt_sort6 "v" width:14 height:14 visible:true 
	listbox lb_column6 "" height:Table.numRows tooltip:"Deleted"

	/* Scrollbar */
	progressBar pb_scrollBar "" orient:#vertical height:(Table.GetScrollBarHeight 20) width:20 color:[20,20,20]		-- vertical slider
	progressBar pb_scrollBar2 "" orient:#vertical height:(Table.GetScrollBarHeight 25) width:20 color:[20,20,20]	
	progressBar pb_scrollBar3 "" orient:#vertical height:(Table.GetScrollBarHeight 30) width:20 color:[20,20,20]	-- vertical slider
	button bt_scroll "=" width:20 height:20 enabled:false	-- slider button
	button bt_scrollUp "^" width:20 height:15				-- slider UP and DOWN buttons
	button bt_scrollDown "v" width:20 height:15	
	/* Edit controls */
	editText edit_String "" visible:false
	-- spinner edit_Int "" type:#integer step:1 visible:false
	-- spinner edit_Float "" type:#float step:0.1 visible:false
	checkbox edit_bool "" visible:false
	button edit_cancel "x" visible:false width:10 height:16

	/* Other controls */
	button bt_new "New Tag" width:80 height:25
	button bt_delete "Delete" width:80 height:25
	button bt_save "Save" width:80 height:25
	button bt_close "Close" width:80 height:25


	fn LayoutControls = (
		Table.SetPos 20 20
		Table.SetWidth (TagEditorUI.width - 135)
		TagEditorUI.height = Table.totalHeight + Table.pos.y + 20
		
		bt_new.pos = Table.pos + [Table.totalWidth, 0] + [UIM.GAP, 0]
		bt_delete.pos = bt_new.pos + [0, BUTTON_HEIGHT + UIM.GAP]
		bt_close.pos = Table.pos + [Table.totalWidth, Table.totalHeight] + [UIM.GAP, -BUTTON_HEIGHT]
		bt_save.pos = bt_close.pos - [0, BUTTON_HEIGHT + UIM.GAP]
	)

	fn SelectTagByName tagName = (
		rows = DataModel.FindRowsWhere "tagName" #is tagName
		if rows.count > 0 then (
			rowId = rows[1]
			Table.SelectRowById rowId
		)
	)

	on pb_scrollBar clicked val do (	Table.SetScrollBar (100-val)	)
	on bt_scrollDown pressed do (		Table.ScrollOneDown()			)
	on bt_scrollUp pressed do (			Table.ScrollOneUp()			)

	on edit_String entered val do (		Table.EditValue val	)
	on edit_bool changed state do (		Table.EditValue state )
	on edit_cancel pressed do ( 		Table.FinishEditing() )

	on lb_column1 selected id do (		Table.selectRow id	)
	-- on lb_column1 doubleClicked id do (	Table.StartEditing 1 id	)	
	on bt_sort1 pressed do (			Table.SetSorting true lb_column1 	)
	
	on lb_column2 selected id do (		Table.selectRow id	)
	on lb_column2 doubleClicked id do (	Table.StartEditing lb_column2 id	)
	on bt_sort2 pressed do (			Table.SetSorting true lb_column2 	)
	
	on lb_column3 selected id do (		Table.selectRow id	)
	on lb_column3 doubleClicked id do (	Table.StartEditing lb_column3 id	)
	on bt_sort3 pressed do (			Table.SetSorting true lb_column3 	)

	on lb_column4 selected id do (		Table.selectRow id	)
	on lb_column4 doubleClicked id do (	Table.StartEditing lb_column4 id	)
	on bt_sort4 pressed do (			Table.SetSorting true lb_column4 	)

	on lb_column5 selected id do (		Table.selectRow id	)
	on lb_column5 doubleClicked id do (	Table.StartEditing lb_column5 id	)
	on bt_sort5 pressed do (			Table.SetSorting true lb_column5 	)
	
	on lb_column6 selected id do (		Table.selectRow id	)
	on lb_column6 doubleClicked id do (	Table.StartEditing lb_column6 id	)
	on bt_sort6 pressed do (			Table.SetSorting true lb_column6 	)

	on TagEditorUI open do (		
		/* Setup the model first */		
		DataModel = TableModel() 	 
		newColumn = TableModelColumn name:"tagName" dataType:#string unique:true minLength:2
		DataModel.AddModelColumn newColumn
		newColumn = TableModelColumn name:"param1" dataType:#integer minValue:0
		DataModel.AddModelColumn newColumn
		newColumn = TableModelColumn name:"param2" dataType:#float minValue:0.0
		DataModel.AddModelColumn newColumn
		newColumn = TableModelColumn name:"deleted" dataType:#bool default:false
		DataModel.AddModelColumn newColumn

		/* Populate model with data */
		for tag in MOTDB.MTags do (
			rowItems = #(tag.name, (tag.param1 as integer), (tag.param2) as float, tag.deleted)
			row = DataModel.AddRow rowItems
			row.modified = tag.dirty
		)		
		Table.SetModel DataModel
		/* Then set up the table view */
		Table.SetScrollBarControls #(pb_scrollBar, bt_scroll, bt_scrollUp, bt_scrollDown)
		Table.SetEditControls edit_String edit_String edit_String edit_bool edit_cancel
		-- add columns in order from left to right
		Table.AddNewColumn header:et_header1 sorter:bt_sort1 body:lb_column1 title:"id" modelId:0 \
							defaultWidth: 35 stretchFactor:1 
		Table.AddNewColumn header:et_header5 sorter:bt_sort5 body:lb_column5 title:"Modified" modelId:-1 \
							defaultWidth: 25 stretchFactor:1 boolRepr:#("", " * ") 						
		Table.AddNewColumn header:et_header2 sorter:bt_sort2 body:lb_column2 title:"Tag names" modelId:1 \
							defaultWidth: 160 stretchFactor:8 editable: true 
		Table.AddNewColumn header:et_header3 sorter:bt_sort3 body:lb_column3 title:"Param1" modelId:2 \
							defaultWidth: 50 stretchFactor:2 editable: true
		Table.AddNewColumn header:et_header4 sorter:bt_sort4 body:lb_column4 title:"Param2" modelId:3 \
							defaultWidth: 50 stretchFactor:2 editable: true
		Table.AddNewColumn header:et_header6 sorter:bt_sort6 body:lb_column6 title:"Delete" modelId:4 \
							defaultWidth: 45 stretchFactor:1 editable: true boolRepr:#("", " DEL")
		Table.SetSorting true lb_column1 rev:false

		LayoutControls()
		Table.SetScrollBar 0
		Table.SetScrollBar 0
		if preselection != undefined then (
			SelectTagByName preselection
		)
	)

	on TagEditorUI resized newSize do (		
		LayoutControls()
	)

	on bt_new pressed do (
		NewTagUI.DataModel = DataModel
		CreateDialog NewTagUI modal:true	
		if NewTagUI.result == true then (	
			Table.refreshView()
			SelectTagByName NewTagUI.tagName
		)
	)

	on bt_delete pressed do (
		selectedRow = DataModel.selection
		if selectedRow > 0 then (
			DataModel.SetItem selectedRow 4 true
		)
		Table.refreshView()
	)

	on bt_save pressed do (
		local usedTags = #()
		local changed
		local original
		modifieds = (for row in DataModel._sourceRows where row.modified collect row.id)
		if modifieds.count > 0 then (
			query = stringFormat "Are you sure you want to save chagnes to % modified tags?" v1:(modifieds.count)
			if (queryBox query) == true then (
				format "Modified Tags:\n"
				for index in modifieds do (	
					row = DataModel._sourceRows[index]					
					changed = MDBTag name:row.items[1] param1:row.items[2] param2:row.items[3] dirty:row.modified deleted:row.items[4]
					if index > MOTDB.MTags.count then (
						-- new tag
						append MOTDB.MTags changed
						MOTDB.dirty = true
					) else (
						original = MOTDB.MTags[index]
						MOTDB.MTags[index] = changed					
						if changed.name != original.name then (
							MOTDB.RenameTagInMOSFiles original.name changed.name
						)								
						if changed.deleted == true then (
							if (MOTDB.IsTagUsed changed.name ) == true then (
								changed.deleted = false
								append usedTags changed.name
							)
						)
						MOTDB.dirty = true
					)							
				)				
				MotionSchemaEditor.UpdateUI()
				if usedTags.count > 0 then (
					msg = "Cannot delete tags, that are used in schemas:\n\n"
					for tagName in usedTags do (
						msg += tagName + "\n"
					)
					messageBox msg
				)
				DestroyDialog TagEditorUI
			)
		) else (
			messageBox "No changes to save."
		)
		
	)

	on bt_close pressed do (
		DestroyDialog TagEditorUI
	)

)

rollout EditSchemaUI "Edit Schema properites" width:500 height:260
(
	local editedSchema = if editedSchema == undefined then MDBSchema() else editedSchema		-- needs to be declared prior to rollout opening -- this is a source schema
	local mode = if mode == undefined then #edit else mode
	local result = undefined
	local schema																	-- this is a temp schema
	local maxTags = 6

	editText et_schemaName "Schema name:" labelOnTop:true fieldWidth:480 readOnly:true
	editText et_globalTag "Global Tag:" labelOnTop:true fieldWidth:160 readOnly:true
	dropdownlist dd_tagList "Tags:" width:160 height:21
	listbox lb_Tags "" width:160 height:maxTags
	listbox lb_Values "" width:30 height:maxTags
	
	edittext et_tagValue "" type:#integer range:[0, 99, 0] width:32 visible:false
	button bt_cancelValue "X" width:20 height:18 visible:false
	button bt_addTag "+" width:30 height:20 tooltip:"Add new tag to the schema name"
	button bt_removeTag "-" width:30 height:20 tooltip:"Remove selected tag from schema name"
	button bt_tagUp "^" width:30 height:20 tooltip:"Move tag up the list"
	button bt_tagDown "v" width:30 height:20 tooltip:"Move tag down the list"
	dropdownlist dd_motionType "MotionType:" width:130 height:10 toolip:"Pre-defined motion type (motion group)"
	spinner et_timeScale "Time Scale:" type:#float range:[0.0, 100.0, 0.0] fieldWidth:60 scale:0.01
	spinner et_XYZScale "XYZ Scale:" type:#float range:[0.0, 100.0, 0.0] fieldWidth:60 scale:0.01
	groupBox gb_params "Schema parameters:" width:170 height:110
	button bt_OK "Save" width:80 height:30 
	button bt_cancel "Cancel" width:80 height:30

	local valueControls = #(et_tagValue, bt_cancelValue)
	local tagControls = #(lb_tags, lb_values, bt_tagUp, bt_tagDown, bt_addTag, bt_removeTag)

	fn LayOutControls = (
		lb_tags.pos = dd_tagList.pos + [0, 20]
		lb_values.pos = lb_Tags.pos + [160, 0]
		bt_addTag.pos = dd_tagList.pos + [220, 5]
		bt_removeTag.pos = bt_addTag.pos + [0, 25]
		bt_tagUp.pos = bt_removeTag.pos + [0,25]
		bt_tagDown.pos = bt_tagUp.pos + [0, 25]
		gb_params.pos = bt_addTag.pos + [85, -10]
		dd_motionType.pos = bt_removeTag.pos + [105, 0]
		et_timeScale.pos = dd_motionType.pos + [120, 25]
		et_XYZScale.pos = et_timeScale.pos + [0, 25]
		bt_cancel.pos = [EditSchemaUI.width, EditSchemaUI.height] - [90, 40]
		bt_OK.pos = bt_cancel.pos - [90, 0]		
	)

	fn UpdateSchemaTagsList = (
		et_schemaName.text = schema.name()
		tagItems = #()
		tagValueItems = #()
		for tag in schema.tags do (
			append tagItems tag.name
			append tagValueItems (tag.value as string)
		)
		lb_tags.items = tagItems
		lb_values.items = tagValueItems
	)

	on bt_addTag pressed do (
		if schema.tags.count < maxTags then (
			tagNum = dd_tagList.selection
			if tagNum > 1 then (
				tagName = dd_tagList.items[tagNum]
				
				isUnique = True
				if schema.mosFile.globalTag != undefined then (
					if schema.mosFile.globalTag.name == tagName then (
						isUnique = False
					)
				)
				for tag in schema.tags do (
					if tag.name == tagName then
						isUnique = False
				)
				if isUnique == true then (
					newTag = SCHTag name:tagName value:0
					append schema.tags newTag	
					schema.dirty = true			
				) else (
					print "Tags cannot repeat."
				)
			)
		) else (
			print "Too many tags."
		)
		UpdateSchemaTagsList()
	)

	on bt_removeTag pressed do (
		if schema.tags.count > 1 then (
			tagNum = lb_tags.selection
			deleteItem schema.tags tagNum
			schema.dirty = true
			UpdateSchemaTagsList()
			if tagNum > lb_tags.items.count then 
				lb_tags.selection = lb_tags.items.count
				lb_values.selection = lb_tags.selection
		) else (
			messageBox "Schema must have at least one tag defined."
		)
	)

	on bt_tagUp pressed do (
		if schema.tags.count < 2 then return()

		index = lb_tags.selection
		if index < 2 then return()

		tempTag = schema.tags[index-1]
		schema.tags[index-1] = schema.tags[index]
		schema.tags[index] = tempTag

		schema.dirty = true
		UpdateSchemaTagsList()
		lb_tags.selection = index-1
		lb_values.selection = lb_tags.selection
	)

	on bt_tagDown pressed do (
		if schema.tags.count < 2 then return()

		index = lb_tags.selection
		if index >= schema.tags.count then return()

		tempTag = schema.tags[index+1]
		schema.tags[index+1] = schema.tags[index]
		schema.tags[index] = tempTag

		schema.dirty = true
		UpdateSchemaTagsList()
		lb_tags.selection = index+1
		lb_values.selection = lb_tags.selection
	)

	on lb_tags selected id do (
		lb_values.selection = id
	)

	on lb_values selected id do (
		lb_tags.selection = id
		UIM.HideControls valueControls
	)

	on lb_values doubleClicked id do (
		et_tagValue.pos = lb_values.pos + [1, (id - 1) * 14]
		bt_cancelValue.pos = et_tagValue.pos + [30, 0]
		et_tagValue.text = (schema.tags[id].value as string)
		UIM.ShowControls valueControls
		UIM.DisableControls tagControls
	)

	fn GoOutOfValueEditMode = (
		UIM.HideControls valueControls
		UIM.EnableControls tagControls
	)

	on et_tagValue entered val do (	
		GoOutOfValueEditMode()
		val = val as integer	
		if val != undefined then (			
			if (val>=0) and (val<99) then (
				schema.tags[lb_values.selection].value = val
				schema.dirty = true
			)		
			UpdateSchemaTagsList()
		)
	)

	on bt_OK pressed do (
		if schema.tags.count > 0 then (
			-- Save changes:
			editedSchema.tags = deepcopy schema.tags
			editedSchema.type = dd_motionType.selected
			editedSchema.timeScale = et_timeScale.value
			editedSchema.XYZScale = et_XYZScale.value
			if schema.dirty == true then (
				editedSchema.MarkAsDirty()
			)
			result = editedSchema
			DestroyDialog EditSchemaUI
		) else (
			messageBox "Schema must have at least one tag!"
		)		
	)

	on et_timeScale changed val do (
		schema.dirty = true
	)

	on et_XYZScale changed val do (
		schema.dirty = true
	)

	on dd_motionType selected val do (
		schema.dirty = true
	)

	on bt_cancel pressed do (
		result = undefined
		DestroyDialog EditSchemaUI
	)

	on bt_cancelValue pressed do (
		GoOutOfValueEditMode()
	)

	on EditSchemaUI open do (
		LayOutControls()
		if mode == #create then (
			EditSchemaUI.title = "Create New Schema"
			bt_OK.caption = "Create New"
		)
		-- List of tags:
		tagItems = #()
		for tag in MOTDB.MTags do (
			if tag.deleted == false then (
				append tagItems (tag.name)
			)
		)
		sort tagItems
		insertItem "--------" tagItems 1
		dd_tagList.items = tagItems

		dd_motionType.items = MOTDB.MTypes		
		--		
		schema = MDBSchema.CopySchema editedSchema
		UpdateSchemaTagsList()
		if schema.mosFile.globalTag != undefined then (
			et_globalTag.text = schema.mosFile.globalTag.str()
		) else (
			et_globalTag.text = "---"
		)
		dd_motionType.selection = (findItem dd_motionType.items schema.type)
		et_timeScale.value = schema.timeScale
		et_XYZScale.value = schema.XYZScale
	)

	
	on EditSchemaUI close do (
		editedSchema = undefined
		mode = undefined
	)
)

rollout EditMOSFileUI "Edit MOS file" width:230
(
	local mode = if mode == undefined then #edit else mode
	local editedMOSFile = if editedMOSFile == undefined then MDBMOSFile() else editedMOSFile
	local result = undefined

	edittext ed_fileName "File name:" text:"" fieldWidth:200 labelOnTop:true enabled:false
	dropdownlist dp_torso "Torso:" items:MOTDB.Mtorsos width:200 toolTip:"Torso needs to be specified for the MOS file" 
	dropdownlist dp_globalTag "Global Tag:" width:160 across:2 toolTip:"Global tag is optional. If specified, it will be added as the first tag in Schemas names" 
	spinner sp_tagValue ""  fieldWidth:30 offset:[0,20] type:#integer range:[0, 99, 0] enabled:false toolTip:"Tag value. Typically 0."
	button bt_OK "Save" width:100 height:30 across:2
	button bt_cancel "Cancel" width:100 height:30


	on dp_torso selected id do (
		editedMOSFile.globalTorso = dp_torso.selected
		editedMOSFile.dirty = true
	)

	on dp_globalTag selected id do (
		if id > 1 then (
			sp_tagValue.enabled = true
			if editedMOSFile.globalTag == undefined then (			
				editedMOSFile.globalTag = SCHTag name:dp_globalTag.selected value:sp_tagValue.value			
				editedMOSFile.dirty = true
			) else (
				if editedMOSFile.globalTag.name != dp_globalTag.selected then (
					editedMOSFile.globalTag.name = dp_globalTag.selected
					editedMOSFile.dirty = true
				)				
			)
		) else (
			sp_tagValue.enabled = false
			if editedMOSFile.globalTag != undefined then (
				editedMOSFile.globalTag = undefined
				editedMOSFile.dirty = true
			)
		)		
	)

	on sp_tagValue changed val do (
		editedMOSFile.globalTag.value = val
		editedMOSFile.dirty = true
	)

	on bt_OK pressed do (
		if mode == #create then (
			fileName = ed_fileName.text
			if fileName.count > 0 then (
				filePath = DATconfig.MSchema() + "\\" + fileName + ".mos"
				if doesFileExist filePath == true then (
					messageBox ("File " + fileName + ".mos already exists!")
					return ()
				)

				if dp_torso.selection < 1 then (
					messageBox ("You need to specify a torso for this .mos file")
					return()
				)
				print ("Creating new MOS file" + filePath)
				editedMOSFile.fullPath = filePath 
				editedMOSFile.globalTorso = dp_torso.selected
				if dp_globalTag.selection > 1 then (
					editedMOSFile.globalTag = SCHTag name:dp_globalTag.selected value:sp_tagValue.value
				)				
				editedMOSFile.MarkAsDirty
				MOTDB.AddMOSFile editedMOSFile				
			)					
		)		
		if editedMOSFile.dirty == true then (
			MOTDB.dirty = true
		)		
		result = editedMOSFile
		DestroyDialog EditMOSFileUI
	)

	on bt_cancel pressed do (
		result = undefined
		DestroyDialog EditMOSFileUI
	)

	on EditMOSFileUI open do (
		if mode == #create then (
			EditMOSFileUI.title = "Create New MOS file"
			bt_OK.caption = "Create"
			ed_fileName.enabled = true			
		) else (
			ed_fileName.text = editedMOSFile.fileName()
			print "Editing " + editedMOSFIle.fileName()
		)
		-- List of tags:
		tagItems = #()
		for tag in MOTDB.MTags do (
			if tag.deleted == false then (
				append tagItems (tag.name)
			)
		)
		sort tagItems
		insertItem "--------" tagItems 1
		dp_globalTag.items = tagItems

		-- Set values of edited MOS file:
		if editedMOSFile != undefined then (
			dp_torso.selection = (findItem dp_torso.items editedMOSFile.globalTorso)
			if editedMOSFile.globalTag != undefined then (
				dp_globalTag.selection = (findItem dp_globalTag.items editedMOSFile.globalTag.name)			
				sp_tagValue.value = editedMOSFile.globalTag.value
				sp_tagValue.enabled = true
			)
		)
	)

	on EditMOSFileUI close do (
		mode = undefined
		editedMOSfile = undefined
	)
)


