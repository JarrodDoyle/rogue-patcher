/* ------------------------------------------------------
/* 			Dark Animation Tools
/*		Custom attributes definitions
/* 			Motions Import/Export
/* ------------------------------------------------------
/* author: Juliusz Kaczmarek
/* ver. 0.01
/* Nov. 2012
/*
/* tools for importing and exporting
/* rigged characters and their motions
/* from and to dark engine games. 
/*
/* thanks for help on dark engine files structure
/* to Volca, Shadowspawn, Weyoun, Telliamed
/* ------------------------------------------------------
*/

format " - Loading... CustomAttributes definitions\n"

CharManCA = attributes CharMan attribID:#(0x600436eb, 0xf355a80)  
(
	parameters main rollout:params
	(
		AIname type:#string default:""
		calibration type: #float ui:SP_cal default:1
		creaType type:#integer
		modelName type:#string default:"" 						-- original .BIN file name
		bonesMap type: #intTab tabSizeVariable:true
 		rotationRef type: #maxObjectTab tabSizeVariable:true	
 		skinBones type: #maxObjectTab tabSizeVariable:true
		ikBones type:  #maxObjectTab tabSizeVariable:true
		fkctrls type: #maxObjectTab tabSizeVariable:true 
		ikctrls type: #maxObjectTab tabSizeVariable:true 
		otherctrls type: #maxObjectTab tabSizeVariable:true
		helpers type: #maxObjectTab tabSizeVariable:true
		lgsjoints type: #maxObjectTab tabSizeVariable:true
		buttHeight type: #float default:1.0
		rootctrl type: #maxObject
		geo type: #maxObject
		buttctrl type: #maxObject
	)
	
	rollout params "Character data:"
	(
		spinner SP_cal "Calibration:" fieldwidth:50 range:[0.001,999,1] align:#right enabled:false
		edittext ET_creatype "Creature Type:" text:AIstructure[creaType].longName enabled:false
		group "Rig components:"
		(
			listbox LB_skinBones "Skin bones:" height:8 
			listbox LB_rotationRef "Rotation reference:" height:8 
			listbox LB_ikBones "IK bones:" height:8
			listbox LB_fkctrls "FK CTRLS:" height:8
			listbox LB_ikctrls "IK CTRLS:" height:8
			listbox LB_otherctrls "Other CTRLS:" height:8
			listbox LB_helpers "Helpers:" height:8
			listbox LB_lgsjoints "LGS-style joints:" height:8
		)
		
		on params open do
		(
			items=#()
			for i=1 to skinBones.count do
			(
				if skinBones[i]==undefined then items[i]="---"
					else	items[i] = (skinBones[i].node.name )
			)
			LB_skinBones.items = items
			
			items=#()
			for i=1 to rotationRef.count do
			(
				if rotationRef[i]==undefined then items[i]="---"
					else	items[i] = (rotationRef[i].node.name )
			)
			LB_rotationRef.items = items
			
			items=#()
			for i=1 to ikbones.count do
			(
				if ikbones[i]==undefined then items[i]="---"
					else	items[i] = (ikbones[i].node.name )
			)
			LB_ikbones.items = items
			
			items=#()
			for i=1 to fkctrls.count do
			(
				if fkctrls[i]==undefined then items[i]="---"
					else	items[i] = (fkctrls[i].node.name )
			)
			LB_fkctrls.items = items
			
			items=#()
			for i=1 to ikctrls.count do
			(
				if ikctrls[i]==undefined then items[i]="---"
					else	items[i] = (ikctrls[i].node.name )
			)
			LB_ikctrls.items = items
			
			items=#()
			for i=1 to otherctrls.count do
			(
				if otherctrls[i]==undefined then items[i]="---"
					else	items[i] = (otherctrls[i].node.name )
			)
			LB_otherctrls.items = items
			
			items=#()
			for i=1 to helpers.count do
			(
				if helpers[i]==undefined then items[i]="---"
					else	items[i] = (helpers[i].node.name )
			)
			LB_helpers.items = items
			
			items=#()
			for i=1 to lgsjoints.count do
			(
				if lgsjoints[i]==undefined then items[i]="---"
					else	items[i] = (lgsjoints[i].node.name )
			)
			LB_lgsjoints.items = items
		)
	)
)

rollout showAnimInfo "Anim Information"
(
	editText et_text "Animation Info:" width:400 height:220 labelOnTop:true
	button bt_close "OK" width:100 height:30
	
	on showAnimInfo open do
	(
		info = "MIfilename: " + currentAnimInfo.MIfilename 
		append info ("\nMCfilename: " + currentAnimInfo.MCfilename)
		try (append info ("\nMotion Name: " + currentAnimInfo.name)); catch(append info ("\nMotion Name: ---"))
		append info ("\nFrame Count: " + currentAnimInfo.frameCount as string)
		append info ("\nCreature Type: " + currentAnimInfo.creatureType as string)
		append info ("\nChar. Manager: " + currentAnimInfo.charMan as string)
		append info ("\nTracks no.: " + currentAnimInfo.tracksNum as string)
		append info ("\nFlags no.: " + currentAnimInfo.flagsNum as string)
		append info ("\nunknown: " + currentAnimInfo.unknown as string)
		et_text.text = info
	)

	on bt_close pressed do (
		DestroyDialog showAnimInfo
	)
)

rollout importMotion "Import Motion" width:250 --height:230
(
	local minHeight   				-- stores the default min height
	local AIlistboxHeight			-- default height of the listbox
	local controlsDefaultPos = #()		-- default positions of controls
	local MIfileName
	local GFScaption = "Get Motion from Schema"
	local GFFcaption = "Load Motion file from folder"
	local tracksNum = 0
	
	local offset
	
	local interactiveMode = false	-- whether we can playback motions by scrubbing the frame slider
	local liveMode = false			-- whether to playback motions automatically (PLAY) 
	local previewFrame = 0.0
	local prevAnimOffset

	local charMans = #()
	
	fn getAIList = (
		charMans = $*_charManager_Hlp as array
		charNames = #()
		for CM in charMans do (
			append charNames CM.AIname 
		)
		return charNames
	)

	fn getAI = (
		findItem charMans currentAnimInfo.charMan				
	)

	fn getCreatureTypes = (
		list = for i = 1 to DC.number collect AIstructure[i].longName
		insertItem "* Same as in file" list 1
		insertItem "* Current creature type" list 2
		return list
	)

	fn SwitchToFKMode =
	(
		for ikctrl in currentAnimInfo.charMan.ikctrls do
		(
			try (
				keys = ikctrl.node.modifiers[1].fkikblend.keys
				if keys.count == 0 then (
					ikctrl.node.modifiers[1].fkikblend = 0
				)
				else 
					with animate on
						at time startFrame
							ikctrl.node.modifiers[1].fkikblend = 0							
				)
			catch()
		)
	)

	fn TurnInteractiveModeOn =
	(
		SwitchToFKMode()
		interactiveMode = true
	)

	--group "Select a character:" (	
	listbox lb_aiList "" items:(getAIList()) selection:(getAI()) width:155 height:5 across:2 offset:[0,16]
	button bt_refresh "Refresh" width:60 height:70 align:#right offset:[0,16]
	groupBox gb_Select "Select a character:" pos:[5,5] width:240 height:(lb_aiList.height + 25)

	on lb_aiList selected val do (
		-- currentAnimInfo = AnimInfoStruct()
		try (						
			currentAnimInfo.charMan = charMans[val]
			lb_aiList.selection = getAI()
			SwitchToFKMode()
			format  "Selecting new AI: %" charMans[val].AIname
		) 
		catch (
			format "Character '%' no longer exists." lb_aiList.selection
			lb_aiList.items = getAIList()
			lb_aiList.selection = 0
		)
	)

	on bt_refresh pressed do (
		lb_aiList.items = getAIList()
		lb_aiList.selection = getAI()

	)
	--)
	group "Select motion file:" (
		button getFromSchema "Get Motion from Schema" width:200 height:30 --pos:[20,22]
		button getFromFile "Load Motion file from folder" width:200 height:30 --pos:[20,60]
		dropdownList getRecent "Recent motions:" width:200 height:10 --pos:[20,95]
	)	
	group "Motion preview:" (
		label lb_ct "Intended for:" align:#left across:3 
		label lb_ctName "" style_sunkenedge:true width:140 height:16 align:#left
		button bt_dummy1 "" width:25 height:20 align:#right visible:False
		label lb_remapCt "    Change to:" align:#left across:3 offset:[0, -5]
		dropdownlist dpl_remapCt "" width:140 height:(DC.number+3) items:(getCreatureTypes()) offset:[0, -5]
		button bt_remapInfo "I" width:25 height:20 align:#right offset:[0, -5] visible:false
		label lb_frameCount "Frame count:" align:#left across:2 offset:[0,10]
		button bt_moreInfo "more info..." width:100 height:20 align:#right  visible:DAT.advmode offset:[0,10] --pos:[130,152] 
		checkbutton bt_play ">" width:22 height:22 align:#left enabled:false across:3 offset:[0,3] --pos:[240,10] -- visible:DAT.advmode-- change to 'false' when done with testing
		label lb_frame "0" align:#left offset:[-45,8]		
		slider sl_frame "" type:#integer ticks:5 align:#right width:180 enabled:false offset:[10,0] --pos:[370,20] 				
		timer clock "Frame Timer" interval:10 active:liveMode
		label lb_fps "0 fps" align:#left
	)	
	group "Import settings:" (
		button bt_curFrame "Current frame" height:20 align:#left across:2 --pos:[10,178]
		spinner setStartFrame "Start Frame:" fieldwidth:60 type:#integer range:[-999,99999,1] align:#right -- pos:[100,180]
		spinner setRepeat       "       Repeat:" fieldwidth:60 type:#integer range:[1,999,1] align:#right --pos:[100,200]
		checkbox setRelative "Relative position" checked:false align:#left across:2 --pos:[10,220]
		checkbox setRelativeRot "Relative orientation" checked:true --pos:[120,220]
	)
	button accept "Apply" width:100 height:30 across:2 align:#left enabled:false --pos:[20,250] 
	button cancel "Close" width:100 height:30 align:#right --pos:[130,250]
		
	fn refreshRollout =
	(	
		try
			lb_ctName.caption = "  " + AIstructure[(MItoCTmap.get currentAnimInfo.creatureType)].longName
		catch ()
		labelText = "Frame count: "+((currentAnimInfo.frameCount as integer) as string)	
		lb_frameCount.caption = labelText
		if setRelative.state == false then
			setRelativeRot.enabled = false
		else
			setRelativeRot.enabled = true
	)
	
	fn importMotionFile currentAnimInfo =
	(
		animInfo = currentAnimInfo
		local MIfilename = animInfo.MIfilename
		local MCfilename = animInfo.MCfilename
		
		MIfile = fOpen MIfilename "rb"
	
		FSeek MIfile 4 #seek_cur	-- 0 value
		animInfo.creatureType = ReadLong MIfile #unsigned		
		animInfo.frameCount = ReadFloat MIfile
		animInfo.frameRate = ReadLong MIfile #unsigned
		animInfo.unknown = ReadLong MIfile #unsigned
		animInfo.name = ReadBString MIfile 16
		Fseek MIfile 60 #seek_cur	-- 15 zeros
		animInfo.tracksNum = ReadLong MIfile #unsigned
		FSeek MIfile 4 #seek_cur	-- unknown
		animInfo.flagsNum = ReadLong MIfile #unsigned
		FSeek MIfile 4 #seek_cur	-- unknown
		animInfo.trackMapping = #()
		for i = 1 to animInfo.tracksNum do
		(
			TrackType = ReadLong MIfile #unsigned				
			JointNumber = (ReadLong MIfile #signed) + 1		-- Maxscript array index start with 1 (not 0)
			if JointNumber == 0 then JointNumber = 1	-- this is to cover an exception where the root joint is referenced as -1 sometimes...
			TrackNumber = ReadLong MIfile #unsigned			
			animInfo.trackMapping[i] = TrackMappingStruct TrackType:TrackType  JointNumber:JointNumber TrackNumber:TrackNumber					
		)
		animInfo.flags = #()
		if animInfo.flagsNum > 0 then
		(			
			for i = 1 to animInfo.flagsNum do
			(				
				FrameNumber = ReadLong MIfile #unsigned
				FlagType = ReadLong MIfile #unsigned
				animInfo.flags[i] = FlagStruct FrameNumber:FrameNumber FlagType:FlagType
			)
		)
		fClose MIfile
		
		--
		-- Loading animation data now
		--
		local prevQuatRot = Quat 0 0 0 1
		local prevEulerRot = EulerAngles 0 0 0
		if (doesFileExist MCfilename) == true then
		(			
			MCfile = fOpen MCfilename "rb"
			local tracksNum = ReadLong MCfile #unsigned
			local dataStart = #()
			for i=1 to tracksNum do
				dataStart[i] = ReadLong MCfile #unsigned
			local eulerRot
			
			animInfo.channels = #()
			for track = 1 to tracksNum do
			(			
				local channelData = #()
				fSeek MCfile dataStart[track] #seek_set
				local trackInfo = animInfo.trackMapping[track]
				local trackType = trackInfo.TrackType
							
				if trackType == TType.ROTATIONAL then
				(	
					--format "Track: %   Joint name: %\n" track AIstructure[MItoCTmap.get animInfo.creatureType].jointNames[currentAnimInfo.trackMapping[track].JointNumber]
					for frame = 1 to animInfo.frameCount do
					(
						try (
							local quatRot = (quat (ReadFloat MCfile) (ReadFloat MCfile) (ReadFloat MCfile) (ReadFloat MCfile))
							local eulerRot = quatToEuler quatRot order:AxisOrder.XYZ
							append channelData (eulerRot)
						) 
						catch (
							format "\\\\ERROR: Error reading motion data file: %\n" MCfilename
						) 
					)
				)
				else 	--transitional
				(				
					for frame = 1 to animInfo.frameCount do
					(
						pos = [(ReadFloat MCfile), (ReadFloat MCfile), (ReadFloat MCfile)]
						append channelData pos					
					)
				)				
				append animInfo.channels channelData				
			)
			fClose MCfile				
			result = true
		)
		else 
		(
			format "\\\\ERR: Motion loading failed.\n\\\\ERR: File % does not exist.\n" MCfilename
			result = false
		)		
		result		
	)


	fn loadAnimation currentAnimInfo fileSource MotionName =
	(
		format "\\\\INFO: Loading motion % to memory.\n"	MotionName		
		
		importMotionFile currentAnimInfo --- currentAnimInfo.MIfilename currentAnimInfo.MCfilename 
				
		-- UI update --		
		accept.enabled = true
		bt_play.enabled = true		
		tracksNum = currentAnimInfo.tracksNum
		sl_frame.enabled = true
		sl_frame.range = [1,currentAnimInfo.frameCount,1]
		previewFrame = 1
		
		-- recent items
		items = getRecent.items
		try (deleteItem items (findItem items MotionName)); catch()
		insertItem MotionName items 2			
		getRecent.items = items
		delINIsetting DATconfig.DarkINIfile "Recent motions" MotionName	-- these two lines are supposed to change the order.
		setINIsetting DATconfig.DarkINIfile "Recent motions" MotionName ""		
		
		-- labels / motion names
		getFromFile.caption = GFFcaption
		getFromSchema.caption = GFScaption
		getRecent.selection = 1
		case fileSource of (
			#file:getFromFile.caption = (getFileNameFile currentAnimInfo.MIfileName)
			#schema:getFromSchema.caption = (getFileNameFile currentAnimInfo.MIfileName)			
			#recent:getRecent.selection = 2
		)	
	)
	
	fn resetFKPose CharMan =
	(		
		local jointObjs = CharMan.fkctrls as array
		for obj = 1 to jointObjs.count do
		(				
			if jointObjs[obj] != undefined then
			(				
				local curObj = jointObjs[obj].node
				CurObj.rotation.controller[2].rotation = quat 0 0 0 1  	-- this is faster. and no need to reset position 
			)
		)
	)
	
	fn applyFrame animInfo frame animOffset mode:#normal ctRemap:1 =
	(	
		-- suspendEditing()
		local charMan = animInfo.Charman		
		local ct = charMan.creaType	-- creature Type the motion is loaded onto
		local mct					-- motion file's creature Type
		
		if ctRemap == 1 then (		
			-- no remapping - creature type is taken from the motion file	
			mct = MItoCTmap.get animInfo.creatureType			
		) else if ctRemap == 2 then (
			-- auto-remapping - motion tracks are remapped to the current AI's type
			mct = ct
		) else (
			-- remapping of tracks for the user specified creature type
			mct = ctRemap - 2
		)		
		resetFKPose CharMan	-- the pose is set "from scratch" for every frame		
		for track = 1 to animInfo.tracksNum do
		(							
			local actualtrack = AIstructure[mct].trackOrder[track]		-- the order of rotation matters - within limbs - from child to parent.								
			-- format "Track / Actual track: %, %\n" track actualtrack
			if actualtrack!=undefined then (
				local trackInfo = animInfo.trackMapping[actualtrack]			
				if trackInfo!= undefined then (
					local jointNo = trackInfo.jointNumber
					local curObj				
										
					try (						
						local jointName = AIstructure[mct].jointNames[jointNo]
						jointNumRemapped = findItem AIstructure[ct].jointNames jointName		
						-- jointNameRemapped = AIstructure[ct].jointNames[jointNumRemapped]
						curObj = charMan.fkctrls[jointNumRemapped].node					
						-- format "Joint numbers: % ==> %\n" jointNo jointNumRemapped
						-- format "Joint Names: % ==> %\n" jointName jointNameRemapped
					)
					catch (
						format "\\\\WARNING: Unrecognized joint: %\n" jointName
						curObj = undefined
					)
					
					if curObj!=undefined then (
						local trackType = trackInfo.TrackType		
						local rotAxisNode
						
						rotAxisNode = CharMan.helpers[2].node -- AIorient helper
						
						if trackType == TType.ROTATIONAL then
						(                							
							fileEulerRot = animInfo.channels[actualtrack][frame]
							-- dark engine to 3dsmax convertion				
							eulerRot = eulerAngles -fileEulerRot.z fileEulerRot.y -(fileEulerRot.x-180)				
											
							in coordsys rotAxisNode rotate CurObj eulerRot				
							if (curObj == charMan.buttCtrl.node) then
								if (setRelative.state == true) and (setRelativeRot.state == true) then
								(					
									eulerOffsetRot = eulerAngles 0 0 -(animOffset.rotation as eulerAngles).z
									in coordsys rotAxisNode rotate CurObj eulerOffsetRot
								)
						)	 			
						else 	--transitional track
						(
							position = animInfo.channels[actualtrack][frame] * charMan.calibration  
							if (setRelative.state == true) then --and (setRelativeRot.state == true) then
							(
								offsetPosition = position * animOffset.transform
								CurObj.position.controller[2].position = offsetPosition 
							)
							else					
								CurObj.position.controller[2].position = (animOffset.pos + position) 
						)
					) 
				) else (
					format "\\\\ERROR: Missing track number: %\n" actualtrack
				)
			) else (
				format "\\\\ERROR: Missing track number: %\n" actualtrack
			)
		)
		-- Flags
		if mode == #normal then (
			local root = CharMan.rootctrl.node
			flagsNumber = animInfo.flags.count 
			if flagsNumber > 0 then
			(
				flags = animInfo.flags
				for j = 1 to flagsNumber do
					if flags[j].frameNumber == frame then
					(
						root.modifiers[1].flags = flags[j].flagType					-- a key with flags set
						-- format "\\\\INFO:setting up a flag at frame %\n" frame
					)
			)
		)

		-- resumeEditing()
		
	)
	
	fn createOffsetHelper animInfo atFrame =
	(
		animOffset = point name:("animOffsetTemp_f." + (atFrame as string)) size:2
		at time (atFrame - 1)
		(
			if setRelative.state == true then
			(
				butt_CTRL = animInfo.charman.buttctrl.node	
				rootT = animInfo.charMan.rootctrl.node.transform
				if setRelativeRot.state == true then 
				(
					-- Relative position and rotation
					buttRelT = butt_CTRL.transform * inverse rootT
					buttRelTX = buttRelT.row1
					offTZ = [0,0,1]
					offTY = normalize (cross offTZ buttRelTX)
					offTX = normalize (cross offTY offTZ)
					offT = Matrix3 offTX offTY offTZ butt_CTRL.position.controller[2].position
				) 
				else 
				(
					-- Relative position only
					offT = Matrix3 [1,0,0] [0,1,0] [0,0,1] butt_CTRL.position.controller[2].position
				)
				animOffset.transform = offT
			)			
		)
		-- format "\\\\INFO: Relative position and rotation are: % and %\n" animOffset.pos (animOffset.rotation as eulerAngles)
		animOffset	
	)
	
	fn getCreatureTypeByMotions animInfo = 
	(
		creatureNames = ""
		for i = 1 to DC.number do
			if animInfo.tracksNum == AIstructure[i].motionTracks then
				if creatureNames == "" then creatureNames = AIstructure[i].longName
					else creatureNames += " or " + AIstructure[i].longName	
		creatureNames
	)		
	
	fn applyAnimation animInfo startFrame repeats =
	(
		local ct 
		local currFrame
		local answer
		-- creature type check - to be done later
		ct = animInfo.charMan.creaType
		
		if animInfo.tracksNum != AIstructure[ct].motionTracks then
		(
			cNames = getCreatureTypeByMotions animInfo
			message = "Number of motion tracks does not match the creature type.\n\nThis motion is designed for " + cNames + "."
			question = "\nDo you want to continue anyway?"	
			format ("\\\\ERROR: " + message)
			answer = querybox (message+question) title:"Motion Import Error"			
		) else (
			answer = true
		)
		
		if answer==True then
		(
			-- Frame rate check and correction
			if frameRate!=animInfo.frameRate then
			(
				query = "Current frame rate ("+(frameRate as string)+") does not match the file frame rate ("+(animInfo.frameRate as string)+"). \nDo you want to change it? (recommended)"
				if querybox query == true then frameRate = animInfo.frameRate
			)
			fullMotionCount = animInfo.frameCount * repeats + (startFrame - 1)
			if (AnimationRange.end )< fullMotionCount then animationRange = interval animationRange.start fullMotionCount
			
			
			for j = 1 to repeats do
			(					
				animOffset = createOffsetHelper animInfo startFrame
				with animate on
				(
					for frame = 1 to animInfo.frameCount do
					(
						currFrame = frame + (startFrame - 1)
						at time currFrame
							applyFrame animInfo frame animOffset mode:#normal ctRemap:dpl_remapCt.selection
					)
					startFrame = currFrame + 1
					delete animOffset
				)
			)
			
			-- Switch to FK mode
			SwitchToFKMode()
		)
		-- else 
		
	)
	
	fn MotionFilePicked MfilePicked = 
	(
		format "Selected a motion file from MSE Browser: %\n" MfilePicked
		if MfilePicked != undefined then
		(
			previewFrame = 0
			MIfileName = DATconfig.Motions() + "\\" + MfilePicked + ".mi"	
			MotionName = MfilePicked-- (getFileNameFile currentAnimInfo.MIfileName)										
			MotionPath = getFileNamePath MIfileName
			MCfileName =  MotionPath + MotionName + "_.mc"
			MIfileName = MotionPath + MotionName + ".mi"
			currentAnimInfo.MCfilename = MCfileName
			currentAnimInfo.MIfileName = MIfileName
			
			if doesFileExist MCfileName then 
			(					
				loadAnimation currentAnimInfo #schema  MotionName															
			)
			else format "\\\\ERROR: .MC file is missing for this motion. %\n" MIfileName				
		)		
		RefreshRollout()
	)

	fn UpdatePose =
	(			
		with animate on (
			applyFrame currentAnimInfo previewFrame prevAnimOffset mode:#interactive ctRemap:dpl_remapCt.selection
		)		
	)

	/*
	/* -------------------------------------------- E V E N T S 
	*/
	local lastTickTime = 0.0
	local timePassed = 0.0

	on clock tick do (	
		thisTickTime = timeStamp()	
		timeDelta = thisTickTime - lastTickTime	
		timePassed = timePassed + timeDelta
		--format "delta: %    passed: %\n" timeDelta timePassed
		if timePassed >= 33 then (			
			disableSceneRedraw()
			try
				undo off (		
					previewFrame += timePassed / 33.0
					lb_frame.caption = (previewFrame as integer) as string
					if previewFrame > sl_frame.range.y then (
						previewFrame = 1
					)
					sl_frame.value = previewFrame
					lb_fps.caption = ("FPS: " + ((1000/timePassed) as string))
					try (
						applyFrame currentAnimInfo previewFrame prevAnimOffset mode:#interactive ctRemap:dpl_remapCt.selection
					)
					catch
					(
						-- enableSceneRedraw()	
						format "ERROR updating pose!\n"		
						format "*** % ***\n" (getCurrentException())
					)
					if timeDelta > 33 then 
						timePassed = 0
					else
						timePassed = timePassed - 33
				)
			catch
				enableSceneRedraw()
			enableSceneRedraw()
		)
		
		lastTickTime = thisTickTime
	)
	
	
	on getFromSchema pressed do
	(
		MotionSchemaEditor.mode = #browse
		createDialog MotionSchemaEditor lockwidth:false lockheight:false style:#(#style_titlebar, #style_border, #style_sysmenu, #style_resizing)
	)
	
	
	on getFromFile pressed do
	(
		MIfileName = getOpenFileName caption:"Select a motion file to load:" \
		filename:(DATconfig.Motions() + "\\") \
		types:"MotionInfo files (*.mi)|*.mi" \
		historyCategory:"MotionFiles"		

		if MIfileName!=undefined then
		(
			currentAnimInfo.MIfileName = MIfilename
			MotionName = (getFileNameFile currentAnimInfo.MIfileName)										
			MotionPath = getFileNamePath currentAnimInfo.MIfileName
			MCfileName =  MotionPath + MotionName + "_.mc"			
			if doesFileExist MCfileName then 
			(						
				currentAnimInfo.MCfilename = MCfileName 
				loadAnimation currentAnimInfo #file MotionName
			)
			else format "\\\\ERROR: .MC file is missing for this motion. %\n" MIfileName				
		)		
		RefreshRollout()
	)
	
	on bt_moreInfo pressed do
	(
		try (destroyDialog showAnimInfo); catch()
		createDialog showAnimInfo 420 300
	)
	
	on getRecent selected val do
	(
		if val>1 then
		(
			MotionName = getRecent.items[val]
			MIfileName = DATconfig.Motions() + "\\" + MotionName + ".mi"	
			MCfileName = DATconfig.Motions() + "\\" + MotionName + "_.mc"
			
			if doesFileExist MCfileName then
			(
				currentAnimInfo.MCfilename = MCfileName
				currentAnimInfo.MIfileName = MIfileName

				loadAnimation currentAnimInfo #recent MotionName
			)
			else format "\\\\ERROR: .MC file is missing for this motion. %\n" MIfileName				
		)
		RefreshRollout()
	)
	
	on bt_CurFrame pressed do
	(
		setStartFrame.value = SliderTime.frame
	)

		
	on setRelative changed val do
	(
		RefreshRollout()
	)
		
	
	on bt_play changed val do (
		if currentAnimInfo.charMan!=undefined then (
			case val of (
				true:
				(				
					bt_play.caption = "||"
					TurnInteractiveModeOn()
					liveMode = true
					prevAnimOffset = createOffsetHelper currentAnimInfo setStartFrame.value
					-- disableSceneRedraw()
				)
				false:
				(				
					bt_play.caption = ">"
					liveMode = false
					if prevAnimOffset != undefined then (
						delete prevAnimOffset
						prevAnimOffset = undefined
					)	
					enableSceneRedraw()			
				)
			)
			clock.active = liveMode
			sliderTime = setStartFrame.value		
			refreshRollout()
		)
	)
	
	on sl_frame changed val do
	(		
		if currentAnimInfo.charMan!=undefined then (
			if interactiveMode == false then (			
				TurnInteractiveModeOn()
			)
			-- Live mode off
			bt_play.caption = ">"
			bt_play.checked = false
			liveMode = false
			clock.active = false	
			enableSceneRedraw()	
			-- 
			previewFrame = val
			lb_frame.caption = previewFrame as string
			if prevAnimOffset == undefined then (
				prevAnimOffset = createOffsetHelper currentAnimInfo setStartFrame.value
			)
			try
				UpdatePose()
			catch (
				print "ERROR updating pose!"
				throw()
			)
			if prevAnimOffset != undefined then (
				delete prevAnimOffset
				prevAnimOffset = undefined
			)
		)
	)		


	on accept pressed do
	(
		EnableSceneRedraw()
		if currentAnimInfo.charMan!=undefined then (		
			timeStart = timeStamp()
			startFrame = setStartFrame.value
			repetitions = setRepeat.value
			applyAnimation currentAnimInfo startFrame repetitions
			timeEnd = timeStamp()
			format "Loaded motion in: % ms\n" (timeEnd - timeStart)
			destroyDialog importMotion	
		)
	)
	
	on cancel pressed do (	
		destroyDialog importMotion
	)

	fn ResizeRollout newHeight = (
		local difference = newHeight - minHeight
		ImportMotion.controls[1].height =  AIlistboxHeight + difference
		ImportMotion.controls[3].height =  AIlistboxHeight + difference + 25
		for i = 4 to ImportMotion.controls.count do (
			ImportMotion.controls[i].pos = [controlsDefaultPos[i].x, controlsDefaultPos[i].y + difference]
		)
	)
		
	on importMotion open do 
	(
		PosX = getINISetting DATconfig.darkINIfile "ImportMotionRollout" "PosX"
		PosY = getINISetting DATconfig.darkINIfile "ImportMotionRollout" "PosY"
		if PosX!="" and PosY!="" then
		(	
			pos = [(PosX as integer), (PosY as integer)]	
			SetDialogPos importMotion pos	
		)
		-- interactive resizing related. (defualt values)
		minHeight = ImportMotion.height
		AIlistboxHeight = lb_aiList.height
		for ctrl in ImportMotion.controls do (
			append controlsDefaultPos ctrl.pos
		)
		local customHeight = getINISetting DATconfig.darkINIfile "ImportMotionRollout" "Height"
		if customHeight!="" then (
			ImportMotion.height = (customHeight as integer)
			ResizeRollout (customHeight as integer)			
		)
		-- recent motions etc:
		local recent, items = #()
		recent = getINIsetting DATconfig.DarkINIfile "Recent motions"
		if recent.count > 0 then
		(
			items = invertArray recent
			-- Limit number of recent motions to 'maxRecentMotions' config value
			if items.count > DATconfig.maxRecentMotions then (
				for i = items.count to (DATconfig.maxRecentMotions + 1) by -1 do (
					motionName = items[i]
					delINISetting DATconfig.darkINIfile "Recent Motions" motionName
					deleteItem items i
				)
			)
		)
		insertItem "Select from the list:" items 1
		getRecent.items = items
		
		--offset = getOffset()
		
		refreshRollout()
	)

	on ImportMotion resized newSize do (
		if newSize.y < minHeight then (
			newSize.y = minHeight
			ImportMotion.height = minHeight
		)
		ResizeRollout newSize.y		
	)

	on ImportMotion close do (
		-- INI settings
		local pos = GetDialogPos ImportMotion
		setINISetting DATconfig.darkINIfile "ImportMotionRollout" "PosX" (pos.x as string)
		setINISetting DATconfig.darkINIfile "ImportMotionRollout" "PosY" (pos.y as string)
		setINISetting DATconfig.darkINIfile "ImportMotionRollout" "Height" (ImportMotion.height as string)
		-- cleanup	
		animOffsetHelpers = $animOffsetTemp* as Array
		delete animOffsetHelpers

		destroyDialog MotionSchemaEditor
		destroyDialog MotionSelector
	)
	
	
)

rollout exportMotion "Export Motion"
(
	group "Frame Range:" 
	(
		spinner firstFrame "First Frame:" type:#integer range:[-99999,99999,1] align:#right fieldwidth:60 
		spinner lastFrame "Last Frame:" type:#integer range:[-99999,99999,1] align:#right fieldwidth:60 
	)
	group "Motion Name (inside .mi file):"
	(
		radiobuttons motnameSource "" labels:#("Same as file name (default)", "Custom") align:#left columns:1
		edittext motname "max. 16 char.:" fieldwidth:140
	)
	button bt_exportMotion "Export Motion" width:160 height:40 offset:[0,30]
	
	fn exportMotionFile currentAnimInfo start end =
	(		
		local frameCount 
		local creatureType = currentAnimInfo.charMan.creaType
		local unknown
		local charMan = currentAnimInfo.charMan

 		-- Exporting motion info to .MI file

		MIfile = fOpen currentAnimInfo.MIfilename "wb"
	
		WriteLong MIfile 0		-- first value always 0		
		-------------------------------------------------------------------------------------------------------------------------------------------------
		WriteLong MIfile (CTtoMImap.get creatureType) 	
		-------------------------------------------------------------------------------------------------------------------------------------------------
		frameCount = End - Start + 1							-- frame count of the motion
		currentAnimInfo.frameCount = frameCount
		WriteFloat  MIfile (frameCount as float)
		WriteLong MIfile 30 											-- frame rate always 30
		if currentAnimInfo.unknown == undefined then unknown = 0
			else unknown = currentAnimInfo.unknown
		WriteLong MIfile unknown 									-- another unknown. Let's make it 0
		WriteBString MIfile currentAnimInfo.name 16			-- motion name
		for i = 1 to 15 do WriteLong MIfile 0 #unsigned 	-- 15 zeros
		
		currentAnimInfo.tracksNum = AIstructure[creatureType].motionTracks
		WriteLong MIfile currentAnimInfo.tracksNum
		
		WriteLong MIfile 0												-- unknown
		
		try
			currentAnimInfo.flagsNum = $.modifiers[1].flags.keys.count	-- numbers of flags set
		catch
			try
				currentAnimInfo.flagsNum = $.modifiers[1].flags.controller[flags.controller.active].keys.count	-- numbers of flags set on an active layer
			catch
				currentAnimInfo.flagsNum = 0
		WriteLong MIfile currentAnimInfo.flagsNum 
		
		WriteLong MIfile 0												-- unknown
				
		currentAnimInfo.trackMapping = #()
		for i = 1 to currentAnimInfo.tracksNum do
		(
			if i == 1 then TrackType = 1 else TrackType = 0
			JointNumber = AIstructure[creatureType].motionTracksMap[i]
			--if JointNumber == 0 then JointNumber = 1	-- this is to cover an exception where the root joint is referenced as -1 sometimes...
			TrackNumber = i			
			currentAnimInfo.trackMapping[i] = TrackMappingStruct TrackType:TrackType  JointNumber:JointNumber TrackNumber:TrackNumber
			WriteLong MIfile TrackType #signed
			WriteLong MIfile (JointNumber-1) #signed
			WriteLong MIfile (TrackNumber-1) #signed
		)
		currentAnimInfo.flags = #()
		if currentAnimInfo.flagsNum > 0 then
		(			
			try 
				flagskeys = $.modifiers[1].flags.controller.keys
			catch
				flagskeys = $.modifiers[1].flags.controller[flags.controller.active].keys	
			for i = 1 to currentAnimInfo.flagsNum do
			(				
				FrameNumber = flagsKeys[i].time.frame
				FlagType = flagsKeys[i].value
				currentAnimInfo.flags[i] = FlagStruct FrameNumber:FrameNumber FlagType:FlagType
				WriteLong MIfile FrameNumber #signed
				WriteLong MIfile FlagType 
			)
		)
		fClose MIfile
		format "\\\\INFO: Succesfully exported .MI file: %\n" currentAnimInfo.MIfilename
		--
		--  Exporting motion channels info - ._MC files
		--
		MCfile = fOpen currentAnimInfo.MCfilename "wb"
		WriteLong MCfile currentAnimInfo.tracksNum #unsigned		-- number of channell tracks
		-- offsets for channel data. 
		-- There are a few fields spare, filled with zeroes. A gap between this chunk and the next one, sort of...
		-- it shouldn't really matter, as long as the offsets point into the right place in the files.
		
		local spareFields = 5 							-- this might change per creature (or not be used at all, if it doesn't break anything)
		
		local dataStart = #()
		dataStart[1] = (1 + currentAnimInfo.tracksNum + sparefields) * 4 	
		WriteLong MCfile dataStart[1] #unsigned						-- start of the first track
		dataStart[2] = dataStart[1] + frameCount * 3 * 4		-- transitional channel length
		WriteLong MCfile dataStart[2] #unsigned 						-- start of the second track
				
		for i=3 to currentAnimInfo.tracksNum do
		(
			dataStart[i] = dataStart[i-1] + frameCount * 4 * 4	-- rotational channel length
			--print dataStart[i]
			WriteLong MCfile dataStart[i] #unsigned
		)		
		
		for i = 1 to spareFields do WriteLong MCfile 0	-- just zeroes
		
		-- motion channels data:
		local channelData = #()
		local trackInfo, trackType
		local actualTrack
		local root, joint, ref, rotMatrix, eulerRot, fileEulerRot, quatRot
		
		-- Calculate channels data first: 
		-- Going backwards - from Parent to Child		<--- this is no longer true? Replaced by the trackMapping maybe? (Sept. 2017)
		currentAnimInfo.channels = #()
		--for track = currentAnimInfo.tracksNum to 1 by -1 do
		for track = 1 to currentAnimInfo.tracksNum do
		(			
			trackInfo = currentAnimInfo.trackMapping[track]
			trackType = trackInfo.TrackType
			channelData = #()
						
			if trackType == TType.ROTATIONAL then
			(		
				--joint = charMan.skinBones[trackInfo.JointNumber].node
				try 
					ref = charMan.rotationRef[trackInfo.JointNumber].node				
				catch
					ref = undefined
				for frame = 1 to currentAnimInfo.frameCount do
				(	
					at time frame
					(
						if ref != undefined then 
						(
							rotMatrix = ref.transform * inverse ref.parent.transform		-- relative joint rotation as matrix
							eulerRot = rotMatrix as eulerAngles							-- relative joint rotation in euler angles
							-- 3dsmax to Dark Engine conversion:
							fileEulerRot = eulerAngles -eulerRot.z eulerRot.y -(eulerRot.x-180)
							quatRot = fileEulerRot as quat
						)
						else
						(
							if AIstructure[creatureType].swapSide < 0 then
								quatRot = quat 1 0 0 0
							else
								quatRot = quat 0
						)
					---
						channelData[frame-start+1] = quat quatRot.x quatRot.y quatRot.z quatRot.w
					)
				)
			)
			else 	--transitional
			(				
				root = charMan.rootctrl.node
				joint = charMan.skinbones[trackInfo.JointNumber].node				
				/* at time start 
				(
					rootTrans = root.transform
					jointTrans = joint.transform											
					exportTransMat = jointTrans * inverse rootTrans	
					zOffset = exportTransMat.row4.z 					
				) */				
				zOffset = charman.buttHeight
				for frame = start to end do
				(
					at time frame 
					(
						rootTrans = root.transform
						jointTrans = joint.transform											
						exportTransMat = jointTrans * inverse rootTrans			-- translation relative to RootCTRL position and orientation						
						exportTrans = exportTransMat.row4						
						exportTrans.z = exportTrans.z - zOffset							-- taking out the Z offset from the actual movement data
						exportTrans = exportTrans / charMan.calibration			-- take out the calibration factor (AI size)
						
					
						channelData[frame-start+1] = exportTrans
					)
				)
			)	
			currentAnimInfo.channels[track] = channelData
		) -- end for track
		
		-- Export channels data to file
		for track = 1 to currentAnimInfo.tracksNum do
		(				
			fSeek MCfile dataStart[track] #seek_set
			trackInfo = currentAnimInfo.trackMapping[track]
			trackType = trackInfo.TrackType
			channelData = currentAnimInfo.channels[track]
			--print channelData
						
			if trackType == TType.ROTATIONAL then
			(				
				for frame = 1 to currentAnimInfo.frameCount do
				(					
					quatRot = channelData[frame]
					WriteFloat MCfile quatRot.z
					WriteFloat MCfile quatRot.w
					WriteFloat MCfile quatRot.x					
					WriteFloat MCfile quatRot.y
				)
			)
			else 	--transitional
			(	
				for frame = 1 to currentAnimInfo.frameCount do
				(
					exportTrans = channelData[frame]
					WriteFloat MCfile exportTrans.x
					WriteFloat MCfile exportTrans.y
					WriteFloat MCfile exportTrans.z
				)
			)			
		) -- end for track
		
		fClose MCfile		
		format "\\\\INFO: Succesfully exported .MC file: %\n" currentAnimInfo.MCfilename
		
	
	) -- end fn exportMotionFile
	
	fn updateCurrentAnimInfo = 
	(
		
	)
		
	on bt_exportMotion pressed do
	(
		MIfileName = getSaveFileName caption:"Export motion to a file:" \
		filename:(DATconfig.Motions() + "\\") \
		types:"MotionInfo files (*.mi)|*.mi" \
		historyCategory:"MotionFiles"
		if  MIfilename != undefined then
		(
			currentAnimInfo.MIfileName = MIfilename
			MotionFileNoExt = (getFileNameFile currentAnimInfo.MIfileName)										
			MotionPath = getFileNamePath currentAnimInfo.MIfileName
			MCfileName =  MotionPath + MotionFileNoExt + "_.mc"
			currentAnimInfo.MCfilename = MCfileName 
			format "MC filename: %\n" MCfilename
			
			currentAnimInfo.name = case motNameSource.state of
			(
				(1):MotionFileNoExt
				(2):motName.text
			)
			
			
			exportMotionFile currentAnimInfo firstframe.value lastframe.value
			---
			--copyfile 
			---
			destroyDialog exportMotion
		)
	)  -- end exportMotion pressed
	
	on motNameSource changed state do
	(
		motName.enabled = case state of
		(
			(1):false
			(2):true
			default:false
		)
	)
	
	on motName changed val do
	(
		if val.count>16 then motName.text = substring val 1 16
	)
	
	on exportMotion open do
	(
		firstframe.value = animationRange.start.frame
		lastFrame.value = animationRange.end.frame
		try (motname.text = currentAnimInfo.name); catch (motname.text = "")
		motname.enabled = false
	)
		
) -- end exportMotion rollout




AIRootCA = attributes AIRoot attribID:#(0x281c9c92, 0x33ddf1b6)
(		
	parameters main rollout:controls
	(
		charMan type:#maxobject
	)
	
	parameters flagparams rollout:flagcontrols
	(
		flags type:#integer default:1
	)

	fn resetAnimation CharMan =
	(		
		undo  "Reset Animation" on
		(
			-- reset controls transforms
			local animCTRLS = (CharMan.fkctrls as array) + (CharMan.ikctrls as array) + (CharMan.otherctrls as array)
			
			for obj = 1 to animCTRLS.count do
			(				
				if animCTRLS[obj] != undefined then
				(				
					local curObj = animCTRLS[obj].node
					rotController = CurObj.rotation.controller[2]				
					deleteKeys rotController #allKeys
					CurObj.rotation.controller[2].x_rotation = 0
					CurObj.rotation.controller[2].y_rotation = 0
					CurObj.rotation.controller[2].z_rotation = 0				
					
					posController = CurObj.position.controller[2]
					
					deleteKeys posController #allKeys
					CurObj.Position.controller[2].x_Position = 0
					CurObj.Position.controller[2].y_Position = 0
					CurObj.Position.controller[2].z_Position = 0
				)
			)
			-- reset custom attributes
			animCTRLS = (CharMan.ikctrls as array) 
			append animCTRLS CharMan.rootctrl
			for obj in animCTRLS do
			(
				ca = undefined
				try (
					ca = custAttributes.get obj.node.modifiers[1] 1				
				); catch()
				if ca != undefined then
				(
					for i = 1 to ca.numSubs do
					(
						try (deleteKeys ca[i].keys #allKeys); catch()
						case (classof ca[i].value) of (
							Float:ca[i].value = 0.0
							Integer:ca[i].value = 0
							BooleanClass:ca[i].value = false
							default:(format "Can't reset value of % - % / %\n" ca[i] (classof ca[i].value) ca[i].value)
						)
					)
				)			
			)
			--
			currentAnimInfo = AnimInfoStruct()
			currentAnimInfo.charMan = charMan
		) -- end undo
	) -- end fn ResetAnimation

	--	
	-- 	Rollout definition
	--	
	rollout controls "Character Controls"
	(
 		editText AIname "Name:" fieldwidth:105 align:#left 
 		button rename "Rename character" width:120 height:30
		
		group "Animation"
		(
			button animImport "Import Motion" width:120 height:30
			button animTest "Test in Dromed" width:120 height:30 enabled:false
			button animExport "Export Motion" width:120 height:30			
			button reset "Reset" width:120 offset:[0,10]
		)
		group "Rig elements selection"
		(
			button selectCM "Character Manager" width:120 height:20 visible:DAT.advmode
			button selectSkin "Skin bones" width:120 height:20 visible:DAT.advmode
			button selectIKbones "IK bones" width:120 height:20 visible:DAT.advmode
			button selecthelpers "Helpers" width:120 height:20 visible:DAT.advmode
			button selectfkctrls "FK CTRLs" width:120 height:20 offset:[0, -96 * (bool2int (not DAT.advmode))]
			button selectikctrls "IK CTRLs" width:120 height:20
		)
		group "Delete AI"
		(
			button deleteMe "Delete Me" width:120 height:25
		)
		
		fn getAllAIObjects chM =
		(
			allObjects = #()
			for ntm in (chM.rotationRef as array) where ntm!=undefined do
				append allObjects ntm.node
			for ntm in (chM.skinBones as array)  where ntm!=undefined do
				append allObjects ntm.node
			for ntm in (chM.ikBones as array)  where ntm!=undefined do
				append allObjects ntm.node
			for ntm in (chM.fkctrls as array)  where ntm!=undefined do
				append allObjects ntm.node
			for ntm in (chM.ikctrls as array)  where ntm!=undefined do
				append allObjects ntm.node
			for ntm in (chM.otherctrls as array)  where ntm!=undefined do
				append allObjects ntm.node
			for ntm in (chM.helpers as array)  where ntm!=undefined do
				append allObjects ntm.node
			for ntm in (chM.lgsjoints as array)  where ntm!=undefined do
				append allObjects ntm.node
			append allObjects chM.rootctrl.node
			append allObjects chM.geo.node
			allObjects
		)
		
		on rename pressed do
		(	
			undo "Rename Character" on
			(
				oldName = charMan.node.AIname			
	-- 				print oldName
				toBeRenamed = getAllAIObjects charMan.node
				for obj in toBeRenamed do
				(				
					newName = replace obj.name 1 oldName.count AIname.text				
					obj.name = newName				
				)
				charMan.node.AIname = AIname.text
				LM = LayerManager
				for suffix in #("_CTRLs", "_Rig", "_Mesh") do (
					LayerName = oldName + suffix
					lyr = LM.getLayerFromName LayerName
					if lyr != undefined then (
						newName = replace LayerName 1 oldName.count AIname.text
						lyr.setName newName
					)
				)
			)
		)

		
		on animImport pressed do
		(	
			currentAnimInfo = AnimInfoStruct()
			currentAnimInfo.charMan = charMan.node
			importMotionDialog = createDialog importMotion lockwidth:true lockheight:false style:#(#style_titlebar, #style_border, #style_sysmenu, #style_resizing)
		)

		on animTest pressed do 
		(
			MotionTester = _MotionTester charMan:charMan.node
			MotionTester.testCurrentMotion()
		)

		on animExport pressed do
		(	
			if currentAnimInfo == undefined then currentAnimInfo = AnimInfoStruct()
			currentAnimInfo.charMan = charMan.node
			exportMotionDialog = createDialog exportMotion 250 250 lockwidth:false lockheight:false modal:true
		)
		
		on reset pressed do
		(
 			if (queryBox "Are you sure you want to delete all the animation?" title:"Reset Animation") == true then
			(
				resetAnimation CharMan.node
			)
		)
		
		on selectSkin pressed do
		(
			local objs = #()
			local skinBones = CharMan.node.skinBones as array
			for i = 1 to skinBones.count do 
				skinBones[i] = skinBones[i].node
			for o in skinBones where (isValidNode o == true) do append objs o 
			select objs
		)
		
		on selectIKbones pressed do
		(
			local objs = #()
			local ikBones = CharMan.node.ikBones as array
			for o in ikBones where o!=undefined do 
				append objs o.node
			select objs
		)
		
		on selectfkctrls pressed do
		(
			local objs = #()
			local fkctrls = CharMan.node.fkctrls as array
			for i = 1 to fkctrls.count do 
				if fkctrls[i] != undefined then
					fkctrls[i] = fkctrls[i].node
			for o in fkctrls where (isValidNode o == true) do append objs o 
			select objs
		)
		
		on selectikctrls pressed do
		(
			local objs = #()
			local ikctrls = CharMan.node.ikctrls as array
			for i = 1 to ikctrls.count do 
				if ikctrls[i] != undefined then
					ikctrls[i] = ikctrls[i].node
			for o in ikctrls where (isValidNode o == true) do append objs o 
			select objs
		)
		
		on selectHelpers pressed do
		(
			local objs = #()
			local hlprs = CharMan.node.helpers as array
			for i = 1 to hlprs.count do 
				hlprs[i] = hlprs[i].node
			for o in hlprs where (isValidNode o == true) do append objs o 
			select objs
		)		
			
		on selectCM pressed do
			select CharMan.node
		
		on deleteMe pressed do
		(
			undo "Delete Character" on
			(
				chM = charMan.node
				toBeDeleted = #()
				toBeDeleted = getAllAIObjects chM
				-- collect layers
				layers = #()
				for obj in toBeDeleted do (
					appendIfUnique layers obj.layer.name
				)
				-- delete them all! --
				delete toBeDeleted	
				-- delete empty layers
				LM = LayerManager
				for layer in layers do (
					LM.deleteLayerByName layer
				)			
			)
		)
		
		on controls open do
		(
			AIname.text = charMan.node.AIname
			--gfdg
		)
	)

	fn RefreshRollout =
	(			
		local ctrls = this.flagControls.controls
		local keys = #()
		
		try
			keys = for k in flags.keys collect k.time
		catch
		(
			keys = for k in flags.controller[flags.controller.active].keys collect k.time				
		)	
		
		if (findItem keys currentTime) > 0 then 
		(
			local flagTemp = flags				
			for i = 20 to 1 by -1 do
			(
				flagValue  = 2 ^ (i-1)
				if flagTemp >= flagValue then 
				(
					ctrls[i].state= true 
					flagTemp = flagTemp - flagValue 
				)
				else ctrls[i].state = false				
			)
			--print "Just updated the flags...\n"
		)
		else 
		for i = 1 to 20 do ctrls[i].state = false
		
	)
	
	rollout flagControls "Flags"
	(	
		checkbutton flag01 "Standing" width: 150 height:25
		checkbutton flag02 "LeftFootfall" width: 150 height:25 offset:[0,-4]
		checkbutton flag03 "RightFootfall" width: 150 height:25 offset:[0,-4]
		checkbutton flag04 "LeftFootUp" width: 150 height:25 offset:[0,-4]
		checkbutton flag05 "RightFootUp" width: 150 height:25 offset:[0,-4]
		checkbutton flag06 "FireRelease" width: 150 height:25 offset:[0,-4]
		checkbutton flag07 "CanInterrupt" width: 150 height:25 offset:[0,-4]
		checkbutton flag08 "StartMotionHere" width: 150 height:25 offset:[0,-4]
		checkbutton flag09 "EndMotionHere" width: 150 height:25 offset:[0,-4]
		checkbutton flag10 "BlankTag1" width: 150 height:25 offset:[0,-4]
		checkbutton flag11 "BlankTag2" width: 150 height:25 offset:[0,-4]
		checkbutton flag12 "BlankTag3" width: 150 height:25 offset:[0,-4]
		checkbutton flag13 "Trigger1" width: 150 height:25 offset:[0,-4]
		checkbutton flag14 "Trigger2" width: 150 height:25 offset:[0,-4]
		checkbutton flag15 "Trigger3" width: 150 height:25 offset:[0,-4]
		checkbutton flag16 "Trigger4" width: 150 height:25 offset:[0,-4]
		checkbutton flag17 "Trigger5" width: 150 height:25 offset:[0,-4]
		checkbutton flag18 "Trigger6" width: 150 height:25 offset:[0,-4]
		checkbutton flag19 "Trigger7" width: 150 height:25 offset:[0,-4]
		checkbutton flag20 "Trigger8" width: 150 height:25 offset:[0,-4]
		button clearAll "Clear All" width:140 height:30 offset:[0,10]
		
		
		
		
		fn setFlag flagNo state =
		(
			local keys = #()
			try
				keys = for k in flags.keys collect k.time
			catch 
			(
				keys = for k in flags.controller[flags.controller.active].keys collect k.time				
			)
			if state == true then
			(
				with animate on
				(
					if (findItem keys currentTime) == 0 then flags = 0
					
					flags = flags + 2 ^ (flagNo - 1)
				)
			)			
			if state == false then
			(
				with animate on
					flags = flags - 2 ^ (flagNo - 1)
				
				if flags == 0 then 
				(
					try
						deleteKey flags.keys (findItem keys currentTime)
					catch
						deleteKey flags.controller[flags.controller.active].keys (findItem keys currentTime)
				)
			)
			RefreshRollout()
		)
		
		fn clearAllFlags =
		(
			local keys 
			
			with animate on flags = 0
				
			try
			(
				keys = for k in flags.keys collect k.time
				deleteKey flags.keys (findItem keys currentTime)
			)
			catch
			(
				keys = for k in flags.controller[flags.controller.active].keys collect k.time				
				deleteKey flags.controller[flags.controller.active].keys (findItem keys currentTime)
			)			
			RefreshRollout()
		)
		
		fn registerFlagsCallback =
		(
			registerTimeCallback RefreshRollout
		)
		
		fn unregisterFlagsCallback =
		(
			unRegisterTimeCallback RefreshRollout
		)
		
		on flag01 changed state do setFlag 1 state
		
		on flag02 changed state do setFlag 2 state
			
		on flag03 changed state do setFlag 3 state
			
		on flag04 changed state do setFlag 4 state
			
		on flag05 changed state do setFlag 5 state
			
		on flag06 changed state do setFlag 6 state
			
		on flag07 changed state do setFlag 7 state
		
		on flag08 changed state do setFlag 8 state
		
		on flag09 changed state do setFlag 9 state
		
		on flag10 changed state do setFlag 10 state
		
		on flag11 changed state do setFlag 11 state
		
		on flag12 changed state do setFlag 12 state
			
		on flag13 changed state do setFlag 13 state
			
		on flag14 changed state do setFlag 14 state
			
		on flag15 changed state do setFlag 15 state
			
		on flag16 changed state do setFlag 16 state
			
		on flag17 changed state do setFlag 17 state
		
		on flag18 changed state do setFlag 18 state
		
		on flag19 changed state do setFlag 19 state
		
		on flag20 changed state do setFlag 20 state
			
		on clearAll pressed do 
			undo "Clear All Flags" on
				clearAllFlags()
		
		on flagcontrols open do 
		(
			registerFlagsCallback()
			RefreshRollout()
		)
		
		on flagcontrols close do 
		(
			unregisterFlagsCallback()
		)
	)
)

struct CAfunctions 
( 
	fn twistFKCTRL twistAngle keys =
	(
		if $selection.count > 0 then (
			for obj in ($selection as array) do (
				if matchPattern obj.name pattern:"*FKCTRL*" then (
					correctTwist obj twistAngle keys
				)
			)
		)
	)
)
CAfuncs = CAfunctions()

/* Foot custom attributes.
*/
FootCA = attributes FootCTRL attribID:#(0xb85c128, 0x3d677201) 
(
	Parameters main rollout:params
	(
		fkikblend Type:#float UI:ui_FKIKblend Default:1.0
		swivel Type:#float UI:ui_swivel Default:0.0
		footLift Type:#float UI:ui_footLift Default:0.0
		footBanking Type:#float UI:ui_footBanking Default:0.0
		heelPivot Type:#float UI:ui_heelPivot Default:0.0
		toesPivot Type:#float UI:ui_toesPivot Default:0.0
		fkList type:#maxObjectTab tabSizeVariable:true
		ikList type:#maxObjectTab tabSizeVariable:true
		ikctrl type:#maxObject
		ikPos type:#integer
		rotDiff type:#matrix3		-- the difference in rotation betwen the Ankle joint and the IKctrl. Used for snapping IK to FK
	)

	Rollout Params "Foot Controls"
	(
		group "FK / IK:" 
		(
			spinner ui_FKIKblend "FK / IK blend:" fieldwidth:40 Height:16 Align:#Right Offset:[0,0] Type:#float Range:[0,1,0] scale:0.01
			slider sl_fkikblend "" ticks:1 range:[0,1,0] type:#float scale:0.01		
			button ui_FKtoIK "FK --> IK" width:100 height:30 
			button ui_IKtoFK "IK --> FK" width:100 height:30
		)		
		group "Controls:"
		(
			spinner ui_swivel "Swivel:" fieldWidth:40 Height:16 Align:#Right Offset:[0,10] Type:#float Range:[-1,1,0] scale:0.01
			spinner ui_footLift "Foot Lift:" fieldWidth:40 Height:16 Align:#Right Offset:[0,10] Type:#float Range:[-1,1,0] scale:0.01
			spinner ui_footBanking "Foot Banking:" fieldWidth:40 Height:16 Align:#Right Offset:[0,0] Type:#float Range:[-1,1,0] scale:0.01
			spinner ui_heelPivot "Heel Pivot:" fieldWidth:40 Height:16 Align:#Right Offset:[0,0] Type:#float Range:[-1,1,0] scale:0.01
			spinner ui_toesPivot "Toes Pivot:" fieldWidth:40 Height:16 Align:#Right Offset:[0,0] Type:#float Range:[-1,1,0]	scale:0.01
			button ui_groundFoot "Ground Foot" width:120 height:30
		)

		include "include\DAT_UI_TwistJointGroup.ms"

		group "Reset:"
		(
			button ui_reset "Reset Leg Pose" width:120 height:30
		)
		
		on ui_FKIKblend changed val do
			sl_fkikblend.value = val

		on sl_fkikblend changed val do
			ui_fkikblend.value = val

		on ui_FKtoIK pressed do
		(		
  			undo "Snap FK to IK" on
 			(
				for i = 1 to fkList.count do
					fkList[i].node.transform = ikList[i].node.transform
 			)
		)
		
		on ui_IKtoFK pressed do
		(
			undo "Snap IK to FK" on 
			(
				local fkCtrl = fkList[ikPos]
				IKCtrl.node.rotation = fkCtrl.node.rotation
				in coordsys fkCtrl.node rotate IKCtrl.node rotDiff.rotationPart				
				IKCtrl.node.position = fkCtrl.node.position	
				footLift = 0
				footBanking = 0
				heelPivot = 0
				toesPivot = 0	
			)
		)
		
		-- Projects foot flat on the ground, maintaining its orientation.
		on ui_groundFoot pressed do (			
			undo "Ground Foot" on (
				with animate on (
					-- position
					if classof ikctrl.node.position.controller == position_list then (
						ikctrl.node.position.z = ikctrl.node.position.controller[1].position.z
					) else if classof ikctrl.node.position.controller == position_layer then (
						ikctrl.node.position.z = ikctrl.node.position.controller[1][1].position.z
					)
					-- rotation
					if classof ikctrl.node.rotation.controller == rotation_list then (
						currentRot = ikctrl.node.rotation.controller[2].rotation as eulerAngles
						ikctrl.node.rotation.controller[2].rotation = (eulerAngles 0 0 currentRot.z) as quat
					) else if classof ikctrl.node.rotation.controller == rotation_layer then (
						-- activeCtrl = ikctrl.node.rotation.controller.active
						activeCtrl = getActiveController ikctrl.node.rotation.controller
						currentRot = activeCtrl.rotation as eulerAngles
						activeCtrl.rotation = (eulerAngles 0 0 currentRot.z) as quat
					)			
				)	
			)
		)

		on ui_reset pressed do
		(				
  			undo "Reset Leg Pose" on
			(
				for fk in fkList do fk.node.rotation.controller[2].rotation = eulerAngles 0 0 0
				IKCtrl.node.rotation.controller[2].rotation = eulerAngles 0 0 0			
				IKCtrl.node.position.controller[2].position = [0,0,0]
				swivel = 0
				footLift = 0
				footBanking = 0
				heelPivot = 0
				toesPivot = 0
			)
		)		
		
		on Params open do
			sl_fkIKblend.value = ui_fkIKblend.value
	)
)

/* A general purpose arm with different numbers of bones */
/* Should cover human arm (hand), droid arm and bugbeast arm */
ArmCA = attributes ArmCTRL attribID:#(0x454b8c27, 0x3a5fab97)
(
	
	Parameters main rollout:params
	(
		fkikblend Type:#float UI:ui_FKIKblend Default:0.0 
		swivel Type:#float UI:ui_Swivel Default:0.0
		hasClaw type:#boolean Default:False		
		clawAngleX type:#float UI:ui_ClawAngleX Default:0.0
		clawAngleY type:#float UI:ui_ClawAngleY Default:0.0
		clawAngleZ type:#float UI:ui_ClawAngleZ Default:0.0
		fkList type:#maxObjectTab tabSizeVariable:true
		ikList type:#maxObjectTab tabSizeVariable:true
		IKCtrl type:#maxObject 
		fkRef type:#maxObject
		ikPos type:#integer
	)

	Rollout Params "Arm Controls"
	(	
		group "FK / IK:" 		
		(
			spinner ui_FKIKblend "FK / IK blend:" fieldwidth:40 Height:16 Align:#Right Offset:[0,10] Type:#float Range:[0,1,0] scale:0.01
			slider sl_fkikblend "" ticks:1 range:[0,1,0] type:#float scale:0.01
			button ui_FKtoIK "FK --> IK" width:100 height:30 
			button ui_IKtoFK "IK --> FK" width:100 height:30
		)	
		group "Controls:"
		(
			spinner ui_Swivel "Swivel:" fieldwidth:40 height:16 Align:#Right Type:#float Range:[-1,1,0] scale:0.01		
			spinner ui_ClawAngleX "Claw Twist:" fieldwidth:40 height:16 Align:#Right Type:#float Range:[-360,360,0] scale:0.01 enabled:hasClaw
			spinner ui_ClawAngleY "Claw Turn:" fieldwidth:40 height:16 Align:#Right Type:#float Range:[-360,360,0] scale:0.01 enabled:hasClaw
			spinner ui_ClawAngleZ "Claw Curl:" fieldwidth:40 height:16 Align:#Right Type:#float Range:[-360,360,0] scale:0.01 enabled:hasClaw
		)
		group "Reset"
		(
			button ui_resetPose "Reset Arm Pose" width:120 height:30
			button ui_reset "Delete Arm Animation" width:120 height:30
		)

		include "include\DAT_UI_TwistJointGroup.ms"		
		
		fn resetPose =
		(				
			for fk in fkList do fk.node.rotation.controller[2].rotation = eulerAngles 0 0 0
			IKCtrl.node.rotation.controller[2].rotation = eulerAngles 0 0 0			
			IKCtrl.node.position.controller[2].position = [0,0,0]
			swivel = 0
			clawAngleX = 0
			clawAngleY = 0
			clawAngleZ = 0
		)	
		
		on ui_FKIKblend changed val do
			sl_fkikblend.value = val

		on sl_fkikblend changed val do
			ui_fkikblend.value = val

		on ui_FKtoIK pressed do
		(		
 			undo "Snap FK to IK" on
			(
				for i = 1 to fkList.count do
					fkList[i].node.transform = ikList[i].node.transform
			)
		)
		
		on ui_IKtoFK pressed do
		(
 			undo "Snap IK to FK" on (
				IKCtrl.node.transform = fkList[ikPos].node.transform
				if hasClaw then (
					clawAngleX = fkList[ikPos+1].node.rotation.controller[2].controller[#X_Rotation].value
					clawAngleY = fkList[ikPos+1].node.rotation.controller[2].controller[#Y_Rotation].value
					clawAngleZ = fkList[ikPos+1].node.rotation.controller[2].controller[#Z_Rotation].value
				)
			)
		)
		
		on ui_resetPose pressed do
		(				
			undo "Reset Arm Pose" on resetPose()
		)
		
		on ui_reset pressed do
		(
			if (queryBox "Are you sure you want to delete all the arm animation?" title:"Delete Arm Animation") == true then (
				undo "Delete Arm Animation" on
				(
					for fk in fkList do 
						deleteKeys fk.node #allKeys
					deleteKeys IKCtrl.node #allKeys
					deleteKeys fkikblend.controller #allKeys
					deleteKeys swivel.controller  #allKeys
					if hasClaw then (
						deleteKeys clawAngleX.controller  #allKeys
						deleteKeys clawAngleY.controller  #allKeys
						deleteKeys clawAngleZ.controller  #allKeys
					)
				)
			)
		)

		
		
		on Params open do
		(
			sl_fkIKblend.value = ui_fkIKblend.value
		)
	)
)

SpiderFootCA = attributes SpiderFootCTRL attribID:#(0x1e88e710, 0x19130217)
(
	Parameters main rollout:params
	(
		fkikblend Type:#float UI:ui_FKIKblend Default:0.0 
		swivel Type:#float UI:ui_Swivel Default:0.0
		
		fk1 type:#maxObject  
		fk2 type:#maxObject  
		fk3 type:#maxObject  
		fkRef type:#maxObject			-- this is not an animatable control. It's more like a reference point for the tip of the leg in FK mode
		ik1 type:#maxObject  
		ik2 type:#maxObject  
		ik3 type:#maxObject  
		IKCtrl type:#maxObject 		
	)
	
	Rollout Params "Spider Foot Controls"
	(		
		spinner ui_FKIKblend "FK / IK blend:" fieldwidth:40 Height:16 Align:#Right Offset:[0,10] Type:#float Range:[0,1,0] scale:0.01
		slider sl_fkikblend "" ticks:1 range:[0,1,0] type:#float scale:0.01
		group "FK / IK snap" 
		(
			button ui_FKtoIK "FK --> IK" width:100 height:30 
			button ui_IKtoFK "IK --> FK" width:100 height:30
		)	
		spinner ui_Swivel "Swivel:" fieldwidth:40 height:16 Align:#Right Type:#float Range:[-1,1,0] scale:0.01
		button ui_groundFoot "Ground Foot" width:120 height:30

		include "include\DAT_UI_TwistJointGroup.ms"

		group "Reset"
		(
			button ui_resetPose "Reset Leg Pose" width:120 height:30
			button ui_reset "Delete Leg Animation" width:120 height:30
		)

		fn resetPose =
		(				
			fk1.node.rotation.controller[2].rotation = eulerAngles 0 0 0
			fk2.node.rotation.controller[2].rotation = eulerAngles 0 0 0
			fk3.node.rotation.controller[2].rotation = eulerAngles 0 0 0
			IKCtrl.node.rotation.controller[2].rotation = eulerAngles 0 0 0			
			IKCtrl.node.position.controller[2].position = [0,0,0]
			swivel = 0
		)	
		
		on ui_FKIKblend changed val do 
		(
			sl_fkikblend.value = val
		)

		on sl_fkikblend changed val do 
		(
			ui_fkikblend.value = val
		)


		on ui_FKtoIK pressed do
		(		
 			undo "Snap FK to IK" on
			(
				fk1.node.transform = ik1.node.transform
				fk2.node.transform = ik2.node.transform
				fk3.node.transform = ik3.node.transform
			)
		)
		
		on ui_IKtoFK pressed do
		(
 			undo "Snap IK to FK" on
				IKCtrl.node.position = fkRef.node.position
		)

		on ui_groundFoot pressed do (
			undo "Ground Foot" on (
				with animate on (
					-- position
					if classof ikctrl.node.position.controller == position_list then (
						ikctrl.node.position.z = ikctrl.node.position.controller[1].position.z
					) else if classof ikctrl.node.position.controller == position_layer then (
						ikctrl.node.position.z = ikctrl.node.position.controller[1][1].position.z
					)
					-- rotation
					if classof ikctrl.node.rotation.controller == rotation_list then (
						currentRot = ikctrl.node.rotation.controller[2].rotation as eulerAngles
						ikctrl.node.rotation.controller[2].rotation = (eulerAngles 0 0 currentRot.z) as quat
					) else if classof ikctrl.node.rotation.controller == rotation_layer then (
						-- activeCtrl = ikctrl.node.rotation.controller.active
						activeCtrl = getActiveController ikctrl.node.rotation.controller
						currentRot = activeCtrl.rotation as eulerAngles
						activeCtrl.rotation = (eulerAngles 0 0 currentRot.z) as quat
					)			
				)	
			)
		)
		
		on ui_resetPose pressed do
		(				
			undo "Reset Leg Pose" on resetPose()
		)
		
		on ui_reset pressed do
		(
			if (queryBox "Are you sure you want to delete all the leg animation?" title:"Delete Leg Animation") == true then (
				undo "Delete Leg Animation" on
				(
					deleteKeys fk1.node #allKeys
					deleteKeys fk2.node #allKeys
					deleteKeys fk3.node #allKeys
					deleteKeys IKCtrl.node #allKeys
					deleteKeys 	fkikblend.controller #allKeys
					deleteKeys 	swivel.controller  #allKeys
				)
			)
		)
		
		on Params open do
		(
			sl_fkIKblend.value = ui_fkIKblend.value
		)
	)
)

GenericCA = attributes GenericCTRL attribID:#(0x368aa8ea, 0x51b2d901)
(	
	Parameters main rollout:params
	(		
		fkList type:#maxObjectTab tabSizeVariable:true
	)

	Rollout Params "Generic Limb Controls"
	(	
		include "include\DAT_UI_TwistJointGroup.ms"
		
		group "Reset"
		(
			button ui_resetPose "Reset Limb Pose" width:120 height:30
			button ui_reset "Delete Limb Animation" width:120 height:30
		)		
		
		fn resetPose =
		(				
			for fk in fkList do fk.node.rotation.controller[2].rotation = eulerAngles 0 0 0
		)	
		
		on ui_resetPose pressed do
		(				
			undo "Reset Generic Limb Pose" on resetPose()
		)
		
		on ui_reset pressed do
		(
			if (queryBox "Are you sure you want to delete all the limb animation?" title:"Delete Limb Animation") == true then (
				undo "Delete Generic Limb Animation" on
				(
					for fk in fkList do 
						deleteKeys fk.node #allKeys
				)
			)
		)		
	)
)

TorsoCA = attributes TorsoCTRL attribID:#(0x17e7785, 0x377e3ece)
(	
	Parameters main rollout:params
	(
		isMain type:#boolean default:false		
		defHeight type:#float default:0.0
		torsoCtrl type:#maxObject
		auxCtrl type:#maxObject
	)

	Rollout Params "Torso Controls"
	(	
		group "Reset"
		(
			button ui_resetPose "Reset Torso Pose" width:120 height:30
			button ui_reset "Delete Torso Animation" width:120 height:30
		)		
		
		fn resetPose =
		(	
			if isMain == true then (
				torsoCtrl.node.position.controller[2].position = [0, 0, 0]
			)
			torsoCtrl.node.rotation.controller[2].rotation = eulerAngles 0 0 0
			auxCtrl.node.rotation.controller[2].rotation = eulerAngles 0 0 0			
		)	
		
		on ui_resetPose pressed do
		(				
			undo "Reset Generic Limb Pose" on resetPose()
		)
		
		on ui_reset pressed do
		(
			if (queryBox "Are you sure you want to delete all the torso animation?" title:"Delete Torso Animation") == true then (
				undo "Delete Torso Animation" on
				(
					for ctrl in #(torsoCtrl, auxCtrl) do 
						deleteKeys ctrl.node #allKeys
				)
			)
		)		
	)
)
