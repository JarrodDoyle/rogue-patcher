/* ------------------------------------------------------
/* 			Dark Animation Tools
/* 		motion schemas functions
/* ------------------------------------------------------
/* author: Juliusz Kaczmarek
/* ver. 0.01
/* Nov. 2013
/*
/* tools for importing and exporting
/* rigged characters and their motions
/* from and to dark engine games. 
/*
/* this script was possible thanks to the knowledge and experience 
/* of Volca, Shadowspawn, Weyoun, Telliamed
/* ------------------------------------------------------
*/
--global schemas = #()		-- all schemas


------------------------------------------------------------------------------------------------------------------------

format " - Loading... Motion Selector (old)\n"

rollout MotionSelector "Choose motion from schema:" width:660 height:460
(	
	local gap = 10
	local filteredSchemas = #()
	local filteredMSNames = #()
	
	dropdownlist Mtorso "Torsos:" width:150 items:MOTDB.Mtorsos pos:[gap,gap] tooltip:"Filter by torso type"
	checkbutton torsoLock "L" width:25 height:25 pos:[170,gap+16] checked:true
	dropdownlist types "Motion type:" items:MOTDB.Mtypes width:150 height:(15) pos:[250,gap]
	button getTags ">>>" width:60 height:25 pos:[430,gap+16]
	multilistbox tags "Motion tags:" items:MOTDB.Mtags width:140 pos:[510,gap] height:27
	listbox	schemaList "Schemas:" items:(MOTDB.MSNames()) width:480 height:10 pos:[gap,60]
	checkbox autoMotion "auto load first motion" checked:true pos:[gap,225]
	listbox motionList "Motions:" width:180 height:11 pos:[gap,245]
	radiobuttons tagsLogic "" labels:#("Any","All","Exclude") default:1 align:#left  pos:[510, 392]
	button accept "OK" width:80 height:30 pos:[gap,415] 
	button cancel "Cancel" width:80 height:30 pos:[100,415]
	button tagAll "All" width:40 height:30 pos:[510,415]
	button tagNone "None" width:40 height:30 pos:[555,415]
	button tagInv "Invert" width:40 height:30 pos:[600,415]	
	groupBox gb1 "Info:" pos:[200,240] width:290 height:165	
	label FilterInfo pos:[210,260] align:#left
	label schemaInfo "Selected schema:" pos:[210,290] align:#left
	label info1 pos:[210,310] align:#left
	label info2 pos:[210,325] align:#left
	label info3 pos:[210,340] align:#left
	label motInfo1 pos:[210,380] align:#left
	button dumpInfo	"Dump Info" width:80 height:30 pos:[200,415]
	
	
	local lytHorizontal1 = #()

	fn dumpMotInfo =
	(
		allMotfiles = #()
		allMotfiles = getFiles (DATconfig.Motions() + "\\*.mi")
		if allMotFiles.count >0 then
		try (
			format "\\\\INFO: Outputting motion info to a .CSV file"
			testAnimInfo = AnimInfoStruct()
			CSVfileName = DATconfig.Motions() + "\\MotionInfoDumpExt.csv"
			CSVfile = openFile CSVfileName mode:"wt"
			row = "File name,Motion name,Creature Code,Creature Name,Frame Count,Frame Rate,Unknown,Tracks Num,Flags Num"
			for i = 1 to 40 do
				row = row + ",Track " + (i as string)
			for i = 1 to 20 do
				row = row + ",Flag" + (i as string)
			format "%\n" row to:CSVfile
			
			for m =1 to allMotFiles.count do
			(
				testAnimInfo.MIfilename = allMotFiles[m]
				MotionName = (getFileNameFile testAnimInfo.MIfileName)										
				MotionPath = getFileNamePath testAnimInfo.MIfileName
				MCfileName =  MotionPath + MotionName + "_.mc"		
				testAnimInfo.MCfilename = MCfilename
				
				importResult = importMotion.importMotionFile testAnimInfo
				if importResult == true then
				(	
					creatureName = creaTypeNames[MItoCTmap.get testAnimInfo.creatureType]
					format "%,%,%,%,%,%,%,%,%" MotionName testAnimInfo.name testAnimInfo.creatureType creatureName (testAnimInfo.frameCount as integer) testAnimInfo.frameRate testAnimInfo.unknown testAnimInfo.tracksNum testAnimInfo.flagsNum to:CSVfile
					for i = 1 to testAnimInfo.tracksNum do
						format ",%" testAnimInfo.trackMapping[i].JointNumber to:CSVfile
					for i = 1 to (40-testAnimInfo.tracksNum) do
						format "," to:CSVfile
					for i = 1 to testAnimInfo.flagsNum do
						format ",%" testAnimInfo.flags[i].FlagType to:CSVfile
					format "\n" to:CSVfile
				)
				else 
				(
					format "\\\\ERROR: %. % importing failed.\n" m MotionName
					format "\\\\ERROR: %,%\n" MotionName "Failed"
				)
			)
			
			close CSVfile
			message = "Motion files info saved out into a file:\n" + CSVfileName
			messagebox message title:"Motion Info Dump"
		)
		catch (
			close CSVfile
			throw			
		)
	)
	
	fn MotionSelected = (
		if motionList.selected != undefined then (
			MfilePicked = motionList.selected 
			ImportMotion.MotionFilePicked MfilePicked
		)
	)

	fn updateMotions val = 
	(
		motList = #()		
		if val>0 then
		(
			schMotList = MOTDB.schemas[filteredSchemas[val]].motionList
			if schMotList.count >0 then
			(
				for i = 1 to schMotList.count do
					append motList schMotList[i].name
			)
		)
		motionList.items = motList		
		if autoMotion.checked == true then (
			if motList.count > 0 then
				motionList.selection = 1
			else
				motionList.selection = 0
			MotionSelected()
		) else (
			motionList.selection = 0
		)
	)
	
	fn filterSchemas =
	(
		filteredMSnames = #()
		filteredSchemas = #()
		-- prepare active tags list
		tagsActive = #()
			for k = 1 to tags.items.count do
				if tags.selection[k]==true then append tagsActive tags.items[k]
					
		for i = 1 to MOTDB.schemas.count do
		(
			-- torso filter
			if Mtorso.selected == MOTDB.schemas[i].torso then
			(
				-- motion type filter
				if ((types.selected=="All" ) or (types.selected==MOTDB.schemas[i].type)) then
				(
					-- tag filter
					if tagsActive.count > 0 then
					(
						schema = MOTDB.schemas[i]
						stags = schema.tags
						j = 1
						tagsMatch = false
						tagsFound = 0
						do
						(
							if (findItem tagsActive stags[j].name) >0 then 							
							(
								tagsFound = tagsFound + 1
								if tagsLogic.state == 1 then tagsMatch = true  -- Any selected tags
								else 	
									if tagsLogic.state == 2 then
									(										
										if tagsFound == tagsActive.count then tagsMatch = true	-- All selected tags
									)
									else tagsMatch = true
									
							)
							
							
							j=j+1
						)
						while j<=stags.count --and tagsMatch==false
						
						if (tagsMatch == true and tagsLogic.state < 3) or (tagsMatch == false and tagsLogic.state == 3)  then								
						(
							append filteredSchemas i
							append filteredMSnames (MOTDB.MSNames())[i]
						)
					)
					else
					(
						append filteredSchemas i
						append filteredMSnames (MOTDB.MSNames())[i]
					)
				)
			)
		)
		if schemaList.selection > filteredMSnames.count then
			schemaList.selection = filteredMSnames.count
		schemaList.items = filteredMSnames		
		updateMotions schemaList.selection
	)
	
	fn refreshRollout = 
	(		
		local caption, caption1
		if torsoLock.checked then Mtorso.enabled = false
			else Mtorso.enabled = true
		if tags.selection.numberSet==0 then tagNone.enabled = false
			else tagNone.enabled = true
		-- filter info
		if tags.selection.NumberSet == 0 then caption = "" else caption = " Tag filter active."
		caption1 = "Showing " + ((schemaList.items.count) as string) + " of " + ((MOTDB.schemas.count) as string) + " motion schemas." + caption
		FilterInfo.caption = caption1
		-- schema info
		if schemaList.selection > 0 then
		(
			schema = MOTDB.schemas[filteredSchemas[schemaList.selection]]
			caption = "Motion Type: " + schema.type
			info1.caption = caption
			caption = "Time scale: " + schema.timescale as string
			info2.caption = caption
			caption = "XYZ scale: " + schema.xyzScale as string
			info3.caption = caption
		)
		else 
		(
			caption = ""
			Info1.caption = caption
			Info2.caption = caption
			Info3.caption = caption
		)
		-- motion info				
		if motionList.selection > 0 then
		(
			try (
				mot = schema.motionList[motionList.selection]
				caption = "Motion parameters: " + mot.value1 + "    " + mot.value2
				motInfo1.caption = caption
			)
			catch ()
		)
		else 
		(
			caption = ""
			motInfo1.caption = caption
		)
	)

	on autoMotion changed state do 
	(
		setINISetting DATconfig.darkINIfile "MotionSchemasRollout" "autoMotion" (state as string)
	)
	
	on torsoLock changed state do
	(
		setINISetting DATconfig.darkINIfile "MotionSchemasRollout" "torsoLock" (state as string)
		RefreshRollout()
	)
	
	on Mtorso selected val do
	(
		setINISetting DATconfig.darkINIfile "MotionSchemasRollout" "Mtorso" (val as string)
		filterSchemas()
		refreshRollout()
	)
	
	on types selected val do
	(		
		setINISetting DATconfig.darkINIfile "MotionSchemasRollout" "types" (val as string)
		filterSchemas()
		refreshRollout()
	)
	
	fn saveTagsToINI = (
		tagString = ""
		for nr in tags.selection do (
			tagString += nr as string + ","
		)
		setINISetting DATconfig.darkINIfile "MotionSchemasRollout" "tags" tagString
	)

 	on tags selected val do
	(
		filterSchemas()
		saveTagsToINI()
		refreshRollout()
	)
	
	on SchemaList selected val do
	(
		setINISetting DATconfig.darkINIfile "MotionSchemasRollout" "SchemaList" (val as string)
		updateMotions val
		refreshRollout()
	)

	on motionList selected val do
	(
		setINISetting DATconfig.darkINIfile "MotionSchemasRollout" "motionList" (val as string)
		MotionSelected()			
		refreshRollout()
	)
	
	on motionList rightclick val do
	(
		setclipboardText motionList.items[val]
	)
	
	on tagsLogic changed state do
	(		
		setINISetting DATconfig.darkINIfile "MotionSchemasRollout" "tagsLogic" (state as string)
		filterSchemas()				
		refreshRollout()
	)
	
	on tagAll pressed do 
	(
		tags.selection = #All
		filterSchemas()
		saveTagsToINI()
		refreshRollout()
	)
	
	on tagNone pressed do 
	(
		tags.selection = #{}
		filterSchemas()
		saveTagsToINI()
		refreshRollout()
	)
		
	on tagInv pressed do 
	(
		tags.selection = -tags.selection
		filterSchemas()
		saveTagsToINI()
		refreshRollout()
	)
	
	on getTags pressed do
	(
		newTags = #{}
		newTagNames = #()
		if filteredSchemas.count > 0 then
		(
			for i = 1 to filteredSchemas.count do
			(
				schema = MOTDB.schemas[filteredSchemas[i]]
				stags = schema.tags
				for j = 1 to stags.count do 
				(
					appendIfUnique newTagNames stags[j].name
				)
			)
			for i = 1 to tags.items.count do
			(
				tagName = tags.items[i]
				if (findItem NewTagNames tagName) > 0  then newTags[i] = true
			)		
		)
		tags.selection = newTags
		filterSchemas()
		saveTagsToINI()
		refreshRollout()
	)
	
	on MotionSelector open do 
	(		
		PosX = getINISetting DATconfig.darkINIfile "MotionSchemasRollout" "PosX"
		PosY = getINISetting DATconfig.darkINIfile "MotionSchemasRollout" "PosY"
		if PosX!="" and PosY!="" then
		(	
			pos = [(PosX as integer), (PosY as integer)]	
			SetDialogPos MotionSelector pos	
		)

		MOTDB.readSchemas()
		Mtorso.items = MOTDB.Mtorsos
		types.items = MOTDB.Mtypes
		tags.items = sort (MOTDB.getTagNames full:false)
		
		val = getINISetting DATconfig.darkINIfile "MotionSchemasRollout" "torsoLock"
		if val != "" then 
			torsoLock.checked = val as BooleanClass

		val = getINISetting DATconfig.darkINIfile "MotionSchemasRollout" "Mtorso"
		if val != "" then 
			Mtorso.selection = val as integer		
		val = getINISetting DATconfig.darkINIfile "MotionSchemasRollout" "types"
		if val != "" then 
			types.selection = val as integer
		val = getINISetting DATconfig.darkINIfile "MotionSchemasRollout" "tags"
		if val != "" then (
			tagStrings = filterString val ","
			tags.selection = for nr in tagStrings collect (nr as integer)
		)
		val = getINISetting DATconfig.darkINIfile "MotionSchemasRollout" "tagsLogic"
		if val != "" then 
			tagsLogic.state = val as integer

		filterSchemas()

		val = getINISetting DATconfig.darkINIfile "MotionSchemasRollout" "SchemaList"
		if val != "" then 
			SchemaList.selection = val as integer
		
		val = getINISetting DATconfig.darkINIfile "MotionSchemasRollout" "autoMotion"
		if val != "" then 
			autoMotion.checked = val as BooleanClass
		
		val = getINISetting DATconfig.darkINIfile "MotionSchemasRollout" "motionList"
		if val != "" then 
			motionList.selection = val as integer

		refreshRollout()
	)
	
	on accept pressed do
	(
		if motionList.selected != undefined then
			ImportMotion.MotionFilePicked motionList.selected
		
		destroyDialog MotionSelector
	)
	
	on cancel pressed do 
	(
		destroyDialog MotionSelector
	)
	
	on MotionSelector close do
	(
		-- INI settings
		local pos = GetDialogPos MotionSelector
		setINISetting DATconfig.darkINIfile "MotionSchemasRollout" "PosX" (pos.x as string)
		setINISetting DATconfig.darkINIfile "MotionSchemasRollout" "PosY" (pos.y as string)
	)
	
	on dumpInfo pressed do
		dumpMotInfo()
)	


-------------------------------------------------------------------------------------------------------------------







