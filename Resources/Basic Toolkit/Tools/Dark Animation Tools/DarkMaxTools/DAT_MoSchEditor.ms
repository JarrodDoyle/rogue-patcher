/* ------------------------------------------------------
/* 			Dark Animation Tools
/*  		Motion Schema Editor
/* ------------------------------------------------------
/* author: Juliusz Kaczmarek
/* ver. 1.2
/* Nov. 2017
/*
/* tools for importing and exporting
/* rigged characters and their motions
/* from and to dark engine games. 
/*
/* this script was possible thanks to the knowledge and experience 
/* of Volca, Shadowspawn, Weyoun, Telliamed
/* ------------------------------------------------------
*/

global MotionSchemaEditor

filein "DAT_MDE_Rollouts.ms"		-- some additional rollouts for the Motion Database Editor

format " - Loading... Motion Database Editor\n"

rollout MotionSchemaEditor "Motion Database Editor:" width:800 height:610
(	
	local mode = if mode == undefined then #edit else mode
	local tagIndices = #()
	/* I rue the day when I decided to do this re-sizeable dialog in MXS...
		So much pain to get it working and edit it afterwards... */

	local filteredSchemas = #()
	local filteredMSNames = #()
	local currentMOSfile = undefined
	local schMTypeCaption = "      MType: "
	local timeScaleCaption = "Time Scale: "
	local xyzScaleCaption = " XYZ Scale: "
	local motionParamsCaption = "Parameters: "

	local BUTTON_HEIGHT = 30
	local BUTTON_HEIGHTLOW = 22
	local EDITBUTTON_WIDTH = 75
    local FILTER_COLUMN_WIDTH = 160
	local SCHEMAS_COLUMN_WIDTH = 480
	local EDIT_BOX_WIDTH = 160
	local FLAG_BUTTON_WIDTH = 40
	local EDIT_COLUMN_WIDTH = EDIT_BOX_WIDTH + UIM.GAP + EDITBUTTON_WIDTH
	local EDIT_LISTS_WIDTH = EDIT_BOX_WIDTH - (UIM.Gaps 2)
    local FIXED_WIDTHS = UIM.BoxWidth(FILTER_COLUMN_WIDTH) + UIM.BoxWidth(EDIT_COLUMN_WIDTH) + UIM.Borders() + (UIM.Gaps 2)
    local FILTER_COLUMN_POS = [UIM.BORDER, UIM.BORDER]
    local ITEMBUTTON_WIDTH = UIM.GetSizeInLine FILTER_COLUMN_WIDTH 3 UIM.GAP
	local MAINBUTTON_WIDTH = (EDIT_COLUMN_WIDTH + UIM.GAP) / 2
	local EDITBUTTON_OFFSET = [0, BUTTON_HEIGHTLOW + UIM.GAP]
	local WIDEBUTTON_WIDTH = UIM.GetSizeInLine EDIT_COLUMN_WIDTH 2 UIM.GAP	-- width of buttons inside MOTDB Edit box

    local MIN_HEIGHT = 430
    local MIN_SCHEMASCOLUMN_WIDTH = 200
    local MIN_WIDTH = FIXED_WIDTHS + MIN_SCHEMASCOLUMN_WIDTH 
    
    
    groupBox gb_Filters "Filter by:" width:(UIM.BoxWidth(FILTER_COLUMN_WIDTH))
    radiobuttons rb_FilterType "" labels:#("MOS files", "Properties") default:1 

    fn isTagFilterActive = (
        if rb_FilterType.state == 1 then return false
        else return true
    )

    fn isMOSFilterActive = (
        if rb_FilterType.state == 1 then return true
        else return false
    )

    dropdownlist dd_Mtorso "Torsos:" width:FILTER_COLUMN_WIDTH items:#() tooltip:"Filter by torso type" visible:(isTagFilterActive())
    dropdownlist dd_Mtypes "Motion type:" items:#() width:FILTER_COLUMN_WIDTH height:(15) visible:(isTagFilterActive())
    multilistbox ml_tags "Tags:" items:#() width:FILTER_COLUMN_WIDTH height:20 visible:(isTagFilterActive())
    radiobuttons rb_tagsLogic "" labels:#("Any","All","Exclude") default:1 visible:(isTagFilterActive())
    listbox lb_mosfiles "" items:#() width:FILTER_COLUMN_WIDTH height:20 visible:(isMOSFilterActive())
    button bt_itemsAll "All" width:ITEMBUTTON_WIDTH height:BUTTON_HEIGHT visible:(isTagFilterActive())
	button bt_itemsNone "None" width:ITEMBUTTON_WIDTH height:BUTTON_HEIGHT visible:(isTagFilterActive())
	button bt_itemsInv "Invert" width:ITEMBUTTON_WIDTH height:BUTTON_HEIGHT visible:(isTagFilterActive())
    
    groupBox gb_Schemas "Schemas:" width:(UIM.BoxWidth(SCHEMAS_COLUMN_WIDTH))
    listbox	lb_schemaList "" items:#() 

	groupBox gb_Edit "Edit Schema:" width:(UIM.BoxWidth(EDIT_COLUMN_WIDTH))	
	groupBox gb_Edit_inner "" width:EDIT_BOX_WIDTH
	edittext et_schemaMosFile "" fieldwidth:EDIT_LISTS_WIDTH readOnly:true bold:true
	label ll_schMType  "      MType:" align:#left
	label ll_TimeScale "Time Scale:" align:#left
	label ll_XYZScale  " XYZ Scale:" align:#left	
	listbox lb_motionList "Motions:" width:EDIT_LISTS_WIDTH height:8 
	label ll_motionFlags "Flags:" align:#left  tooltip:"General motion flags"	
	checkbutton cb_neckIsFixed "Fxd Neck" width:FLAG_BUTTON_WIDTH tooltip:"Neck is Fixed"
	checkbutton cb_isTurn "Is Turn" width:FLAG_BUTTON_WIDTH tooltip:"Is Turn"
	checkbutton cb_inPlace "In Place" width:FLAG_BUTTON_WIDTH tooltip:"In Place"
	label ll_motionBlend  "Blend:" align:#left tooltip:"Motion blend duration"	
	editText et_blendDuration "" fieldwidth:40 tooltip:"Blend duration (in milliseconds)"
	button bt_selMOSfile "Go to" width:EDITBUTTON_WIDTH height:BUTTON_HEIGHTLOW tooltip:"Select the MOS file, that this schema is defined in."
	button bt_editSchema "Edit..." width:EDITBUTTON_WIDTH height:BUTTON_HEIGHTLOW tooltip:"Edit Schema Parameters"
	button bt_addMotion "+" width:EDITBUTTON_WIDTH height:BUTTON_HEIGHTLOW tooltip:"Add motion to the schema"
	button bt_removeMotion "-" width:EDITBUTTON_WIDTH height:BUTTON_HEIGHTLOW tooltip:"Remove selected motion from the schema"
	button bt_testMotion "Test..." width:EDITBUTTON_WIDTH height:BUTTON_HEIGHTLOW tooltip:"Test motion in Dromed" enabled:false
	checkbox ch_autoMotion "auto Select" tooltip:"Auto-select first motion when switching schemas" checked:true
	button bt_editMotion "Edit Params..." width:EDITBUTTON_WIDTH height:BUTTON_HEIGHTLOW tooltip:"Edit motion parameters" visible:false
	button bt_motionUp "^" width:20 height:16 tooltip:"Move motion up"
	button bt_motionDown "v" width:20 height:16 tooltip:"Move motion down"

	groupBox gb_MOS "Edit MOS file:" width:(UIM.BoxWidth(EDIT_COLUMN_WIDTH))	
	groupBox gb_MOS_Inner "" width:EDIT_BOX_WIDTH
	edittext et_mosFile "" fieldwidth:EDIT_LISTS_WIDTH readOnly:true bold:true
	-- dropdownlist dd_mosTorso "Torso:" width:EDIT_LISTS_WIDTH items:MOTDB.Mtorsos
	-- dropdownlist dd_globalTag "Global tag:" width:(EDIT_LISTS_WIDTH - 35)
	-- edittext et_globalTagValue "" fieldWidth:30
	label ll_mosTorso  "     Torso:" align:#left
	label ll_globalTag "Global tag:" align:#left
	button bt_newSchema "New Schema" width:EDITBUTTON_WIDTH height:BUTTON_HEIGHTLOW tooltip:"Create new Schema in this MOS file"
	button bt_openMOSfile "Open MOS" width:EDITBUTTON_WIDTH height:BUTTON_HEIGHTLOW tooltip:"Open MOS file in an external text editor\n(specified in Configuration)"
	button bt_editMOSfile "Edit..." width:EDITBUTTON_WIDTH height:BUTTON_HEIGHTLOW tooltip:"Edit MOS file's global parameters"
	button bt_copySchema "Copy Schema" width:EDITBUTTON_WIDTH height:BUTTON_HEIGHTLOW tooltip:"Copy selected schema"
	button bt_deleteSchema "Delete Sch." width:EDITBUTTON_WIDTH height:BUTTON_HEIGHTLOW tooltip:"Mark selected schema for deletion"
	button bt_undeleteSchema "Undelete Sch." width:EDITBUTTON_WIDTH height:BUTTON_HEIGHTLOW tooltip:"Undelete selected schema"
	
	groupBox gb_MOTDB "Edit Motion Database:" width:(UIM.BoxWidth(EDIT_COLUMN_WIDTH))
	button bt_newMOSfile "New MOS" width:WIDEBUTTON_WIDTH height:BUTTON_HEIGHTLOW tooltip:"Create a new .MOS file"
	button bt_deleteMOSfile "Delete MOS file" width:WIDEBUTTON_WIDTH height:BUTTON_HEIGHTLOW tooltip:"Delete selected .MOS file"
	button bt_undeleteMOSfile "Undelete MOS file" width:WIDEBUTTON_WIDTH height:BUTTON_HEIGHTLOW tooltip:"Undelete selected .MOS file"
	button bt_editTags "Edit Tags..." width:WIDEBUTTON_WIDTH height:BUTTON_HEIGHTLOW tooltip:"Add, modify or delete Motion Tags"
	button bt_reload "Reload" width:WIDEBUTTON_WIDTH height:BUTTON_HEIGHTLOW tooltip:"Reload Motion Database, if it has been modified outside"
	button bt_export "MAKE MOTION DATABASE..." width:EDIT_COLUMN_WIDTH height:BUTTON_HEIGHTLOW tooltip:"Make motiondb.bin file in your working folder"
	
    button bt_Save "Save Changes" width:MAINBUTTON_WIDTH height:BUTTON_HEIGHT toolTip:"Saves changes to the disc"
    button bt_Cancel "Cancel" width:MAINBUTTON_WIDTH height:BUTTON_HEIGHT toolTip:"Leaves dialog without saving changes"
          
    local tagListControls = #(dd_Mtorso, dd_Mtypes, ml_tags, rb_tagsLogic, bt_itemsAll, bt_itemsNone, bt_itemsInv)
	local mosFilesControls = #(gb_MOS_Inner, lb_mosfiles, gb_MOS, et_mosFile, 
		ll_mosTorso, ll_globalTag, bt_newSchema, bt_openMOSfile, bt_editMOSfile, 
		bt_copySchema, bt_deleteSchema, bt_undeleteSchema)	
	local editControls = #(bt_newSchema, bt_editMOSfile, bt_deleteSchema, bt_copySchema, bt_undeleteSchema, bt_editMotion, bt_editSchema, bt_addMotion, bt_removeMotion,
		bt_newMOSfile, bt_deleteMOSfile, bt_editTags, bt_export, bt_Save, bt_motionUp, bt_motionDown, cb_neckIsFixed, cb_isTurn, cb_inPlace, et_blendDuration)
	local browseControls = #(ch_autoMotion)
	local schemaControls = #(bt_selMOSfile, bt_editSchema, bt_addMotion, bt_removeMotion,
		bt_editMotion, bt_motionUp, bt_motionDown, cb_neckIsFixed, cb_isTurn, cb_inPlace, et_blendDuration)
	local MOSRelatedControls = #(bt_newMOSfile, bt_deleteMOSfile, bt_undeleteMOSfile)
	local motionParamsControls = #(cb_neckIsFixed, cb_isTurn, cb_inPlace, et_blendDuration)

    fn ResizeDialog newSize:undefined = 
    (
		if newSize != undefined then 
		(
			-- Dialog size
			newSize = [bigger newSize.x MIN_WIDTH, bigger newSize.y MIN_HEIGHT]
			MotionSchemaEditor.width = newSize.x
			MotionSchemaEditor.height = newSize.y
		) 
		else (
			newSize = [MotionSchemaEditor.width, MotionSchemaEditor.height]
		)
        -- Main columns
        local FILTER_CONTENT_POS = FILTER_COLUMN_POS + [UIM.GROUPBOX_PADDING, UIM.GROUPBOX_PADDING_TOP]
        rb_FilterType.pos = FILTER_CONTENT_POS - [0,10]
        gb_Filters.pos = FILTER_COLUMN_POS
        gb_Filters.height = (newSize.y - UIM.BORDER * 2)
        local SCHEMAS_COLUMNS_POS = gb_Filters.pos + [gb_Filters.width + UIM.GAP, 0]
        local SCHEMAS_COLUMN_WIDTH = newSize.x - FIXED_WIDTHS
        gb_Schemas.pos = SCHEMAS_COLUMNS_POS
        gb_Schemas.width = SCHEMAS_COLUMN_WIDTH
		gb_Schemas.height = gb_Filters.height -- - BUTTON_HEIGHT - UIM.GAP
		
        -- Filter column
        dd_MTorso.pos = FILTER_CONTENT_POS + [0, 30]
        dd_Mtypes.pos = FILTER_CONTENT_POS + [0, 70]
        ml_tags.pos = FILTER_CONTENT_POS + [0, 110]        
        local TAGSLIST_HEIGHT = gb_Filters.height - 215
        ml_tags.height = TAGSLIST_HEIGHT
        rb_tagsLogic.pos = ml_tags.pos + [0, ml_tags.height] + [0, UIM.GAP]
        
        lb_mosfiles.pos = FILTER_CONTENT_POS + [0, 15]
        local MOSFILES_HEIGHT = gb_Filters.height - UIM.BORDER * 2 - 40
        lb_mosfiles.height = MOSFILES_HEIGHT

        local FILTER_BUTTONS_POS = (UIM.BoxContentBottomLeft gb_Filters) - [0,30]
        bt_itemsAll.pos = FILTER_BUTTONS_POS
        bt_itemsNone.pos = FILTER_BUTTONS_POS + [ITEMBUTTON_WIDTH + UIM.GAP,0]
        bt_itemsInv.pos = bt_itemsNone.pos + [ITEMBUTTON_WIDTH + UIM.GAP,0]
        
        -- Schemas list
        lb_SchemaList.pos = (UIM.BoxContentTopLeft gb_Schemas) - [0, 10]
        lb_SchemaList.width = UIM.BoxContentWidth gb_Schemas
        lb_SchemaList.height = UIM.BoxContentHeight gb_Schemas + 10
		
		-- EDIT BOXES:
		local EDIT_COLUMNS_POS = gb_Schemas.pos + [gb_Schemas.width + UIM.GAP, 0]		
		--> Edit schema --				
		gb_Edit.pos = EDIT_COLUMNS_POS -- + [0, (gb_MOS.height + UIM.GAP) * bool2int (isMOSFilterActive())]
		gb_Edit.height = 300
		gb_Edit_Inner.pos = gb_Edit.pos + [UIM.GROUPBOX_PADDING, UIM.GROUPBOX_PADDING * 2]
		gb_Edit_Inner.height = gb_Edit.height - UIM.GROUPBOX_PADDING * 3
		
		local EDIT_CONTENT_POS = (UIM.BoxContentTopLeft gb_Edit_Inner)
		et_schemaMosFile.pos = EDIT_CONTENT_POS + [0,-5]		
		ll_schMType.pos = et_schemaMosFile.pos + [0, UIM.LINE + UIM.GAP] 
		ll_timeScale.pos = ll_schMType.pos + [0, UIM.LINE]
		ll_XYZScale.pos = ll_timeScale.pos + [0, UIM.LINE]
		lb_motionList.pos = ll_XYZScale.pos + [0, UIM.LINE * 2] 
		ll_motionFlags.pos = lb_motionList.pos + [0, lb_motionList.height + UIM.GAP] 
		cb_neckIsFixed.pos = ll_motionFlags.pos + [33, -4]
		cb_isTurn.pos = ll_motionFlags.pos + [33 + FLAG_BUTTON_WIDTH, -4]
		cb_inPlace.pos = ll_motionFlags.pos + [33 + 2 * FLAG_BUTTON_WIDTH, -4]
		ll_motionBlend.pos = ll_motionFlags.pos + [0, UIM.LINE]
		et_blendDuration.pos = ll_motionBlend.pos + [33, 0]
		-- Buttons
		bt_selMOSfile.pos = (UIM.BoxContentTopRight gb_Edit) - [EDITBUTTON_WIDTH, -2]
		bt_editSchema.pos = bt_selMOSfile.pos + EDITBUTTON_OFFSET
		bt_addMotion.pos = [bt_selMOSfile.pos.x, lb_motionList.pos.y]
		bt_removeMotion.pos = bt_addMotion.pos + EDITBUTTON_OFFSET
		bt_testMotion.pos = bt_removeMotion.pos + EDITBUTTON_OFFSET
		ch_autoMotion.pos = bt_testMotion.pos + EDITBUTTON_OFFSET
		bt_editMotion.pos = [bt_selMOSfile.pos.x, ll_motionFlags.pos.y - UIM.GAP]
		bt_motionUp.pos = lb_motionList.pos + [EDIT_LISTS_WIDTH - 44, -18]
		bt_motionDown.pos = bt_motionUp.pos + [24, 0]

		--> Edit MOS file
		gb_MOS.pos = EDIT_COLUMNS_POS + [0, gb_Edit.height + UIM.GAP]
		gb_MOS.height = 155	
		gb_MOS_Inner.pos = gb_MOS.pos + [UIM.GROUPBOX_PADDING, UIM.GROUPBOX_PADDING * 2]
		gb_MOS_Inner.height = gb_MOS.height - UIM.GROUPBOX_PADDING * 3

		et_mosFile.pos = (UIM.BoxContentTopLeft gb_MOS_Inner) + [0,-5]		
		bt_openMOSfile.pos = (UIM.BoxContentTopRight gb_MOS) - [EDITBUTTON_WIDTH, 6]
		bt_editMOSfile.pos = bt_openMOSfile.pos + EDITBUTTON_OFFSET
		bt_newSchema.pos = bt_editMOSfile.pos + EDITBUTTON_OFFSET
		bt_copySchema.pos = bt_newSchema.pos + EDITBUTTON_OFFSET
		bt_deleteSchema.pos = bt_copySchema.pos + EDITBUTTON_OFFSET
		bt_undeleteSchema.pos = bt_deleteSchema.pos
		ll_mosTorso.pos = et_mosFile.pos + [0, UIM.LINE*2 + (UIM.Gaps 2)] 
		ll_globalTag.pos = ll_mosTorso.pos + [0, UIM.LINE + UIM.GAP] 
		-- et_globalTagValue.pos = dd_globalTag.pos + [dd_globalTag.width + UIM.GAP, 2]

		--> Edit MotionDatabase
		gb_MOTDB.pos = gb_MOS.pos + [0, (gb_MOS.height + UIM.GAP) * bool2int (isMOSFilterActive())]
		rows = 3
		gb_MOTDB.height = (UIM.BoxHeight (BUTTON_HEIGHTLOW * rows) + (rows-1) * UIM.GAP)
		bt_newMOSfile.pos = (UIM.BoxContentTopLeft gb_MOTDB)
		bt_deleteMOSfile.pos = bt_newMOSfile.pos + [WIDEBUTTON_WIDTH + UIM.GAP, 0]
		bt_undeleteMOSfile.pos = bt_deleteMOSfile.pos
		bt_editTags.pos = bt_newMOSfile.pos + EDITBUTTON_OFFSET
		bt_reload.pos = bt_editTags.pos + [WIDEBUTTON_WIDTH + UIM.GAP, 0]
		bt_export.pos = bt_editTags.pos + EDITBUTTON_OFFSET

		-- Global Buttons
        bt_Cancel.pos = [newSize.x - MAINBUTTON_WIDTH - UIM.BORDER, newSize.y - UIM.BORDER - BUTTON_HEIGHT]
        bt_Save.pos = bt_Cancel.pos - [MAINBUTTON_WIDTH + UIM.GAP, 0]
    )

	fn RefreshRollout = (
		-- nothing right now
	)   
	
	fn MotionSelected = (
		if mode == #browse then (
			if lb_motionList.selected != undefined then (
				MfilePicked = lb_motionList.selected 
				ImportMotion.MotionFilePicked MfilePicked
			)
		)
		-- bt_testMotion.enabled = true
	)

	fn UpdateMOSInfo mosFile = (		
		local mosFileName = "" 	
		local mosTorsoCaption =  "       Torso: "
		local globalTagCaption = "Global tag: "
		if mosFile != undefined then (			
			mosFileName = mosFile.FileName()	
			mosTorsoCaption += mosFile.globalTorso
			if mosFile.globalTag != undefined then (
				globalTagCaption += stringFormat "% %" v1:mosFile.globalTag.name v2:(mosFile.globalTag.value as string)
			) else (
				globalTagCaption += "---"
			)
			-- delete/undelete buttons
			bt_deleteMOSfile.visible = not mosFile.deleted
			bt_undeleteMOSfile.visible = not bt_deleteMOSfile.visible
		)
		et_mosFile.text = mosFileName
		ll_mosTorso.caption = mosTorsoCaption
		ll_globalTag.caption = globalTagCaption
	)
	
	fn UpdateMotionFlags motFlags = (
		if bit.and motFlags 1 > 0 then 
			cb_neckIsFixed.state = True
		else
			cb_neckIsFixed.state = False
		if bit.and motFlags 2 > 0 then 
			cb_isTurn.state = True
		else
			cb_isTurn.state = False
		if bit.and motFlags 4 > 0 then 
			cb_inPlace.state = True
		else
			cb_inPlace.state = False
	)	

	fn UpdateMotionInfo schema:undefined = 
	(
		if schema == undefined then (
			schema = filteredSchemas[lb_SchemaList.selection]	
		)
		if lb_motionList.selection > 0 then (
			motion = schema.motionList[lb_motionList.selection]
			UpdateMotionFlags motion.flags
			et_blendDuration.text = motion.blendTime as string
			if mode == #edit then
				UIM.EnableControls motionParamsControls
		) else (
			UIM.DisableControls motionParamsControls
		)
	)

	fn UpdateSchemaInfo schema motionIndex:undefined = 
	(
		if schema!=undefined then 		
		(	
			if mode == #edit then (
				UIM.EnableControls schemaControls
			) else (
				UIM.EnableControls #(bt_selMOSfile)
			)
			et_schemaMosFile.text = schema.mosFile.FileName()
			if rb_FilterType.state == 1 then (
				bt_deleteSchema.visible = not schema.deleted			
				bt_undeleteSchema.visible = not bt_deleteSchema.visible
			) else (
				bt_deleteSchema.visible = False
				bt_undeleteSchema.visible = False
			)
			-- Global stuff
			ll_schMtype.caption = (schMTypeCaption + schema.type)
			ll_TimeScale.caption = (timeScaleCaption + schema.timeScale as string)
			ll_XYZScale.caption = (xyzScaleCaption + schema.XYZScale as string)
			-- Motion list
			local motList = #()	
			schMotList = schema.motionList
			if schMotList.count > 0 then
			(
				for i = 1 to schMotList.count do
					append motList schMotList[i].name
			)
			lb_motionList.items = motList
			if motionIndex != undefined then (
				lb_motionList.selection = motionIndex
			) else (
				if ch_autoMotion.checked == true then (
					if schMotList.count > 0 then (
						lb_motionList.selection = 1
						MotionSelected()
					) else (
						lb_motionList.selection = 0
					)
				) else (
					lb_motionList.selection = 0
				)
			)
			if lb_motionList.selection > 0 then (
				UpdateMotionInfo schema:schema
			) else (
				UpdateMotionFlags 0
				et_blendDuration.text = ""
				UIM.DisableControls motionParamsControls
			)

			-- update MOS file too
			if isTagFilterActive() == True then (
				UpdateMOSInfo schema.mosFile
			)
		)	
		else (
			lb_motionList.items = #()
			et_schemaMosFile.text = ""
			lb_motionList.selection = 0
			ll_schMtype.caption = schMTypeCaption
			ll_TimeScale.caption = timeScaleCaption
			ll_XYZScale.caption = xyzScaleCaption
			cb_neckIsFixed.state = False
			cb_isTurn.state = False
			cb_inPlace.state = False
			et_blendDuration.text = ""
			UIM.DisableControls motionParamsControls
			UIM.DisableControls schemaControls
		)
		
		
	)

    fn filterSchemasByFiles = 
    (
        filteredMSnames = #()
        filteredSchemas = #()
		
		if MOTDB.mosFiles.count < 1 then (
			return()
		)
		local mosFile = MOTDB.mosFiles[lb_mosfiles.selection]        
		currentMOSfile = mosFile
        filteredSchemas = mosFile.schemas
        for schema in filteredSchemas do 
        (
            append filteredMSnames (schema.listName())
        )
        lb_SchemaList.items = filteredMSnames
		lb_SchemaList.selection = 1
		-- schema info update
		schema = undefined
		if filteredSchemas.count > 0 then
		(
			schema = filteredSchemas[lb_SchemaList.selection]			
		)				
		UpdateSchemaInfo schema
		UpdateMOSInfo mosFile
    )

    fn filterSchemasByTags = 
    (		
        filteredMSnames = #()
		filteredSchemas = #()
		-- prepare active tags list
		local tagsActive = #()
        for k = 1 to ml_tags.items.count do (
			actualTagName = MOTDB.MTags[tagIndices[k]].name
			-- print actualTagName
			if ml_tags.selection[k]==true then append tagsActive actualTagName 
		)
					
		for i = 1 to MOTDB.schemas.count do
		(
			schema = MOTDB.schemas[i]			
			-- torso filter
			if (dd_Mtorso.selected == schema.torso()) or (dd_Mtorso.selected == "All") then
			(
				-- motion type filter
				if ((dd_Mtypes.selected=="All" ) or (dd_Mtypes.selected==schema.type)) then
				(
					-- tag filter
					if tagsActive.count > 0 then
					(		
						stags = schema.allTags()
						j = 1
						tagsMatch = false
						tagsFound = 0
						do
						(
							if (findItem tagsActive stags[j].name) >0 then 							
							(
								tagsFound = tagsFound + 1
								if rb_tagsLogic.state == 1 then tagsMatch = true  -- Any selected tags
								else 	
								(
									if rb_tagsLogic.state == 2 then
									(										
										if tagsFound == tagsActive.count then tagsMatch = true	-- All selected tags
									)
									else tagsMatch = true									
								)
							)
							j=j+1
						)
						while j<=stags.count --and tagsMatch==false
						
						if (tagsMatch == true and rb_tagsLogic.state < 3) or (tagsMatch == false and rb_tagsLogic.state == 3)  then								
						(
							append filteredSchemas schema
							append filteredMSnames (schema.listName())							
						)
					)
				)
			)
		)
		-- if lb_SchemaList.selection > filteredMSnames.count then (
		-- 	lb_SchemaList.selection = 1
		-- )
		lb_SchemaList.items = filteredMSnames
		--lb_SchemaList.selection = 1
		gb_Schemas.caption = (stringFormat "Schemas: (showing % out of %)" v1:(filteredSchemas.count as string) v2:(MOTDB.schemas.count as string))
		-- schema info update	
		schema = undefined
		if filteredSchemas.count > 0 then (	
			if lb_SchemaList.selection == 0 then
				lb_SchemaList.selection = 1
			schema = filteredSchemas[lb_SchemaList.selection]
		)		
		UpdateSchemaInfo schema
	)
	
	fn FilterSchemas = (
		if isTagFilterActive() == true then 
			FilterSchemasByTags()
		else
			FilterSchemasByFiles()
	)

	fn selectSchema prevSchema = (
		-- attempt to select the same schema in a new list
		for id = 1 to filteredSchemas.count do (
			schema = filteredSchemas[id]
			if schema == prevSchema then (
				lb_schemaList.selection = id
				UpdateSchemaInfo schema
				exit()
			)
		)
	)

	fn switchFilterToProperties = (
		UIM.ShowControls(tagListControls)
		UIM.HideControls(mosFilesControls)
		UIM.DisableControls(MOSRelatedControls)
		filterSchemasByTags()
		ResizeDialog()
	)

	fn switchFilterToFiles = (
		UIM.ShowControls(mosFilesControls)
		UIM.HideControls(tagListControls)
		UIM.EnableControls(MOSRelatedControls)
		filterSchemasByFiles()
		ResizeDialog()
	)

	fn getCurrentSchema = (
		val = lb_schemaList.selection
		if val > 0 then (
			schema = filteredSchemas[val]
			return schema
		)
		undefined
	)

	
	fn SchemaModified schema motionIndex:undefined = (
		items = lb_schemaList.items 
		index = lb_schemaList.selection
		items[index] = schema.listName()
		lb_schemaList.items = items     
		-- update list of MOS files (dirty flag)
		lb_mosfiles.items = MOTDB.getMOSfilenames()
		UpdateSchemaInfo schema motionIndex:motionIndex
	)

    on rb_FilterType changed state do
    (
		prevSchema = getCurrentSchema()		
        case state of (
            1:(switchFilterToFiles())
            2:(switchFilterToProperties())
		)        
		if prevSchema != undefined then
			selectSchema prevSchema
    )

    on rb_tagsLogic changed state do
    (
        filterSchemasByTags()
        refreshRollout()
    )

    on bt_itemsAll pressed do 
    (
        if isTagFilterActive() then (
            ml_tags.selection = #All
            filterSchemasByTags()
        )
        else (
            lb_mosfiles.selection = #All
            filterSchemasByFiles()
        )
        refreshRollout()
    )
        
    on bt_itemsNone pressed do 
    (
        if isTagFilterActive() then (
            ml_tags.selection = #{}
            filterSchemasByTags()
        )
        else (
            lb_mosfiles.selection = #{}
            filterSchemasByFiles()
        )
        refreshRollout()
    )
        
    on bt_itemsInv pressed do 
    (
        if isTagFilterActive() then (
            ml_tags.selection = -ml_tags.selection
            filterSchemasByTags()
        )
        else (
            lb_mosfiles.selection = -lb_mosfiles.selection
            filterSchemasByFiles()
        )
        refreshRollout()
    )

    on dd_Mtorso selected val do
    (
        setINISetting DATconfig.darkINIfile "MotionSchemaEditor" "Mtorso" (val as string)
        filterSchemasByTags()
        refreshRollout()
    )
    
    on dd_Mtypes selected val do
    (		
        setINISetting DATconfig.darkINIfile "MotionSchemaEditor" "types" (val as string)
        filterSchemasByTags()
        refreshRollout()
    )
    
    fn saveTagsToINI = (
        tagString = ""
        for nr in ml_tags.selection do (
            tagString += nr as string + ","
        )
        setINISetting DATconfig.darkINIfile "MotionSchemaEditor" "tags" tagString
    )

    on ml_tags selectionEnd do
    (
        filterSchemasByTags()
        --saveTagsToINI()
        refreshRollout()
	)
	
	on ml_tags doubleClicked index do (
		TagEditorUI.preselection = (MOTDB.MTags[tagIndices[index]].name)
		createDialog TagEditorUI lockwidth:false style:#(#style_titlebar, #style_border, #style_sysmenu, #style_resizing) modal:true		
	)

    on lb_mosfiles selected val do
    (
        filterSchemasByFiles()
        refreshRollout()
    )

	-- on lb_schemaList rightclick val do
	

	on lb_schemaList selected val do 
	(
		if val>0 then 
		(
			schema = filteredSchemas[val]
			UpdateSchemaInfo schema
		)
	)

	on lb_schemaList doubleClicked val do (
		if val>0 then 
		(
			schema = filteredSchemas[val]
			EditSchemaUI.editedSchema = schema
			CreateDialog EditSchemaUI modal:true
			SchemaModified (getCurrentSchema())
		)
	)

	/* -------------------------------------------------- EDIT SCHEMA EVENTS -------------------------------------------------- */


	on bt_selMOSfile pressed do (
		selectedMosFile = et_mosFile.text		
		if selectedMosFile != "" then (	
			prevSchema = getCurrentSchema()					
			for i=1 to MOTDB.mosFiles.count do (
				mosFile = MOTDB.mosFiles[i]
				if selectedMosFile == mosFile.fileName() then (
					lb_mosfiles.selection = i
					exit()
				)
			)
			rb_filterType.state = 1
			switchFilterToFiles()	
			selectSchema prevSchema		
		)
	)

	on bt_editSchema pressed do (
		EditSchemaUI.mode = #edit
		EditSchemaUI.editedSchema = getCurrentSchema()
		CreateDialog EditSchemaUI modal:true
		SchemaModified (getCurrentSchema())
	)

	on lb_motionList selected val do
	(
		setINISetting DATconfig.darkINIfile "MotionSchemasRollout" "motionList" (val as string)		
		UpdateMotionInfo()
		MotionSelected()
	)

	on bt_addMotion pressed do (
		MIfileName = getOpenFileName caption:"Select a motion file to load:" \
		filename:(DATconfig.Motions() + "\\") \
		types:"MotionInfo files (*.mi)|*.mi" \
		historyCategory:"MotionFiles"		

		if MIfileName!=undefined then
		(
			motName = getFilenameFile MIfileName
			newMotion = MDBMotion name:motName flags:0 blendTime:500
			schema = getCurrentSchema()
			append schema.motionList newMotion
			schema.MarkAsDirty()
			SchemaModified schema
			lb_motionList.selection = lb_motionList.items.count
		)
	)

	on bt_removeMotion pressed do (
		motion = lb_motionList.selected
		if motion != undefined then (
			schema = getCurrentSchema()
			index = lb_motionList.selection
			deleteItem schema.motionList index
			schema.MarkAsDirty()
			SchemaModified schema
		)
	)

	on bt_motionUp pressed do (
		schema = getCurrentSchema()
		if schema.motionList.count < 2 then return()

		index = lb_motionList.selection
		if index < 2 then return()

		tempMotion = schema.motionList[index-1]
		schema.motionList[index-1] = schema.motionList[index]
		schema.motionList[index] = tempMotion		

		schema.MarkAsDirty()
		SchemaModified schema
		lb_motionList.selection = index-1
	)

	on bt_motionDown pressed do (
		schema = getCurrentSchema()
		motionCount = schema.motionList.count
		if motionCount < 2 then return()

		index = lb_motionList.selection
		if index >= motionCount then return()

		tempMotion = schema.motionList[index+1]
		schema.motionList[index+1] = schema.motionList[index]
		schema.motionList[index] = tempMotion

		schema.MarkAsDirty()
		SchemaModified schema
		lb_motionList.selection = index+1
	)
	
	fn SetMotionFlag val state = (
		schema = getCurrentSchema()
		index = lb_motionList.selection
		motion = schema.motionList[index]
		if state == True then 
			newFlags = bit.or motion.flags val
		else
			newFlags = bit.xor motion.flags val
		if motion.flags != newFlags then (
			motion.flags = newFlags
			schema.MarkAsDirty()
			SchemaModified schema motionIndex:index
		)
	)

	on cb_neckIsFixed changed state do (		
		SetMotionFlag 1 state		
	)

	on cb_isTurn changed state do (		
		SetMotionFlag 2 state		
	)

	on cb_inPlace changed state do (		
		SetMotionFlag 4 state		
	)

	on et_blendDuration entered val do (
		val = val as integer
		if val == undefined then (
			UpdateMotionInfo()
			return()
		)
		if (val < 0) or (val > 10000) then (
			UpdateMotionInfo()
			return()
		)
		schema = getCurrentSchema()
		index = lb_motionList.selection
		motion = schema.motionList[index]
		motion.blendTime = val
		schema.MarkAsDirty()
		SchemaModified schema motionIndex:index
	)

	/* -------------------------------------------------- EDIT MOS FILE EVENTS -------------------------------------------------- */
	fn getCurrentMOSFile = (
		index = lb_mosFiles.selection
		if index > 0 then (
			mosFile = MOTDB.mosFiles[index]
			return mosFile
		)
		undefined
	)

	fn MOSFileModified = (
		-- index = lb_mosfiles.selection
		-- name = lb_mosfiles.selected
		currentMOSFile = getCurrentMOSFile()
		lb_mosfiles.items = MOTDB.getMOSfilenames()
		index = FindItem lb_mosfiles.items (currentMOSFile.ListName())
		if index > 0 then (
			lb_mosfiles.selection = index
		) else (
			lb_mosfiles.selection = 1
		)
		UpdateMOSInfo (getCurrentMOSFile())
		filterSchemasByFiles()
	)

	on bt_openMOSfile pressed do (
		-- this will launch a text editor from a configured path
		command = (stringFormat "\"%\" \"%\"" v1:DATConfig.pathTextEditor v2:currentMOSfile.fullPath)
		substituteString command "\\" "\\\\"
		format "%\n" command
		HiddenDOSCommand ("\"" + command + "\"") doNotWait:true
	)

	on bt_editMOSFile pressed do (
		currentMOSFile = getCurrentMOSFile()
		if currentMOSFile != undefined then (
			EditMOSFileUI.editedMOSFile = currentMOSFile
			EditMOSFileUI.mode = #edit
			CreateDialog EditMOSFileUI modal:true
			if EditMOSFileUI.result != undefined then (
				MOSFileModified()
			)
		)
	)

	on bt_deleteSchema pressed do 
	(
		val = lb_schemaList.selection
		if val > 0 then (
			schema = filteredSchemas[val]        
			schema.markAsDeleted True
			SchemaModified schema
		)
	)

	on bt_undeleteSchema pressed do 
	(
		val = lb_schemaList.selection
		if val > 0 then (
			schema = filteredSchemas[val]        
			schema.markAsDeleted False
			SchemaModified schema
		)
	)

	on bt_copySchema pressed do (
		schema = getCurrentSchema()
		if schema != undefined then (
			-- let's copy schema and then its compound values except for reference to mosFile			
			newSchema = MDBSchema.CopySchema schema
			newSchema.mosFile.AddSchema newSchema
			newSchema.MarkAsDirty()
			-- UI side of things:			
			filterSchemasByFiles()
			lb_schemaList.selection = lb_schemaList.items.count
			SchemaModified newSchema			
		)
	)

	on bt_newSchema pressed do (		
		mosFile = getCurrentMOSFile()
		if mosFile != undefined then (
			newSchema = MDBSchema()
			newSchema.mosFile = mosFile
			--
			EditSchemaUI.mode = #create
			EditSchemaUI.editedSchema = newSchema
			CreateDialog EditSchemaUI modal:true
			if EditSchemaUI.result != undefined then (
				mosFile.AddSchema newSchema
				newSchema.dirty = true
				FilterSchemas()
				lb_schemaList.selection = lb_schemaList.items.count
				SchemaModified newSchema
			)			
		)
	)

	/* -------------------------------------------------- EDIT MOTION DATABASE EVENTS -------------------------------------------------- */

	on bt_newMOSfile pressed do (
		EditMOSFileUI.mode = #create
		CreateDialog EditMOSFileUI modal:true
		if EditMOSFileUI.result != undefined then (
			mosFile = EditMOSFileUI.result
			-- update list of MOS files
			MOSFileModified()
		)
	)

	on bt_deleteMOSfile pressed do (
		val = lb_mosfiles.selection
		if val > 0 then (
			mosFile = MOTDB.mosFiles[val]        
			mosFile.markAsDeleted True
			-- update list of MOS files (deleted mark)						
			MOSFileModified()
			
		)
	)

	on bt_undeleteMOSfile pressed do (
		val = lb_mosfiles.selection
		if val > 0 then (
			mosFile = MOTDB.mosFiles[val]        
			mosFile.markAsDeleted False
			-- update list of MOS files (remove 'deleted' mark)						
			MOSFileModified()
		)
	)

	on bt_editTags pressed do (
		if MOTDB.MTags.count > 0 then (
			createDialog TagEditorUI lockwidth:false style:#(#style_titlebar, #style_border, #style_sysmenu, #style_resizing) modal:true
		)
	)

	on bt_export pressed do (
		query = "Are you sure you want to export this Motion Database to motiondb.bin file?"
		if queryBox query title:"Export MDB" == true then (			
			MOTDB.MakeMDB()
		) 
	)

	/* -------------------------------------------------- GENERAL ROLLOUT EVENTS -------------------------------------------------- */


	fn UpdateUI = (	
		dd_Mtorso.items = #("All") + MOTDB.Mtorsos
		dd_Mtypes.items = #("All") + MOTDB.Mtypes
		tagNames = (MOTDB.getTagNames full:false)
		tagListNames = (MOTDB.getTagNames full:true)
		tagIndices = for i = 1 to MOTDB.MTags.count collect i
		qsort tagIndices indexSort valArray:tagNames
		sortedItems = for i = 1 to tagIndices.count collect tagListNames[tagIndices[i]]
		ml_tags.items = sortedItems
		lb_mosfiles.items = MOTDB.getMOSfilenames()
		FilterSchemas()
	)

	fn LoadSchemas = (
		MOTDB.readSchemas()
		if MOTDB.schemas.count > 0 then (
			UpdateUI()
		)
	)

	on bt_reload pressed do (
		if MOTDB.dirty == true then (
			msg = "There are some unsaved changes.\nReloading Motion Database will delete all your changes.\n\n"
			msg += "Do you want to Reload anyway?"
			proceed = queryBox msg 
		) else (
			proceed = true
		)
		if proceed == true then (
			LoadSchemas()
		)
	)

    on MotionSchemaEditor open do (		
        ResizeDialog()        
		LoadSchemas()
        
		/* Enable controls based on the MODE */
		format "Opening Motion Schema Editor in % mode.\n" (mode as string)
		MotionSchemaEditor.title = (stringFormat "Motion Schema Editor: (% MODE) " v1:(toUpper (mode as string) ))
		if mode == #edit then
			disableControls = browseControls
		else
			disableControls = editControls
		for ctrl in disableControls do (
			ctrl.enabled = False
		)
    )
    
    on MotionSchemaEditor resized newSize do (
        ResizeDialog newSize:newSize
    )

	on bt_Save pressed do (
		goAhead = False
		If MOTDB.dirty == True then (			
			query = "Are you sure you want to save your changes?\n(Make sure you have orignal MOS files backed-up)"
			if queryBox query == True then 
				goAhead = True
		) else (
			messageBox "No changes to save."
		)
		if goAhead == True then (
			result = MOTDB.SaveAll()
			message  = (stringFormat "MOS files modified: %\n" v1:result[1])
			message += (stringFormat "MOS files created:  %\n" v1:result[2])
			message += (stringFormat "MOS files deleted:  %\n" v1:result[3])
			messageBox message
			UpdateUI()
		)
	)
		
    on bt_Cancel pressed do 
    (
		goAhead = False
		If MOTDB.dirty == True then (			
			query = "There are some unsaved changes.\nDo you want to Quit without Saving?"
			if queryBox query == True then 
				goAhead = True
		) else (
			goAhead = True
		)
		if goAhead == True then (			
			-- INI settings
			local pos = GetDialogPos MotionSchemaEditor
			setINISetting DATconfig.darkINIfile "MotionSchemaEditor" "PosX" (pos.x as string)
			setINISetting DATconfig.darkINIfile "MotionSchemaEditor" "PosY" (pos.y as string)
			destroyDialog MotionSchemaEditor
		)
    )
)

