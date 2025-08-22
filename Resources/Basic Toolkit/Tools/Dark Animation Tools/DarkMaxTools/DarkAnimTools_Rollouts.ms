/* ------------------------------------------------------
/* 			Dark Animation Tools
/*					Rollouts
/* ------------------------------------------------------
/* author: Juliusz Kaczmarek
/* March 2015
/*
/* tools for importing and exporting
/* rigged characters and their motions
/* from and to dark engine games. 
/*
/* this script was possible thanks to the knowledge and experience 
/* of Volca, Shadowspawn, Weyoun, Telliamed
/* ------------------------------------------------------
*/
-------------------------------------------------------------------------------------------
-------- R O L L O U T    D E F I N I T I O N S -----------------------------------
-------------------------------------------------------------------------------------------

format " - Loading... Rollouts\n"

global DATPathConfiguration

rollout DATImport "Import"
(
	local RawAIName, AInumber

	group "Import AI"
	(
		dropDownList ddl_project "Project:" width:150 across:2
		button bt_config "Config..." width:60 height:30 offset:[0,10] align:#right
		dropDownList ddl_recent "Recently imported:" width:120 across:2
		button bt_recent "Import" width:80 height:30 offset:[0,10] align:#right
		button bt_browse "Browse and Import" width:210 height:30 offset:[0,10]	
	)
	group "Import options:"
	(
		checkbox ch_autoRig "auto load .rig file if exists" checked:true
		checkbox ch_fixKnees "Fix legs joints for IK" checked:true
		checkbox ch_LGSrig "LGS style joint markers" checked:false
	)
	
	fn datcfg =
	(
		createDialog DATPathConfiguration style:#(#style_toolwindow, #style_sysmenu) --width:500 modal:true
	)
	
	fn RefreshRollout =
	(
		items = for project in DATconfig.paths collect project.name
		ddl_project.items = items	
		ddl_recent.items = DATconfig.paths[DATconfig.projectId].recent
		if ddl_recent.items.count > 0 then (
			ddl_recent.enabled = true
			bt_recent.enabled = true
		) else (
			ddl_recent.enabled = False
			bt_recent.enabled = False
		)
	)

	fn AddToRecent AIName = (
		recent = DATconfig.paths[DATconfig.projectId].recent
		index = findItem recent AIName
		if index > 0 then (					
			deleteItem recent index
		)
		insertItem AIName recent 1
		if recent.count > DATconfig.maxRecentAIs then (
			for index = recent.count to (DATconfig.maxRecentAIs + 1) by -1 do 
			(
				deleteItem recent index
			)
		)
		ddl_recent.items = recent 
		ddl_recent.selection = 1
		DATconfig.savePresets()
	)

	on bt_browse pressed do
	(
		local AIfile = getOpenFileName caption:"Select a character to import:" \
		filename:(DATconfig.Mesh() + "\\") \
		types:"AI Mesh (*.bin)|*.bin|AI Joint Structure (*.cal)|*.cal|Custom rig (*.rig)|*.rig|" \
		historyCategory:"AI Meshes"

		if AIfile != undefined then
		(
			RawAIName = (getFileNameFile AIfile)			
			BIN_fileName =  RawAIName + ".bin"
			CAL_fileName = RawAIName + ".cal"	
						
			if not doesFileExist CAL_fileName then (
				format "\\\\ERROR: Couldn't find %.CAL file.\n" RawAIName
				return false
			)
			if not doesFileExist BIN_fileName then (
				format "\\\\ERROR: Couldn't find %.BIN file.\n" RawAIName
				return false
			)					
			-- add to recent:
			BIN.fileName = BIN_fileName
			CAL.fileName = CAL_fileName
			AddToRecent RawAIName
			-- import and create				
			DAT.createCharacter RawAIName true (ch_LGSrig.checked)
			RefreshRollout()
		) 		
	)

	on bt_recent pressed do
	(
		RawAIName = ddl_recent.selected
		if RawAIName!=undefined then
		(	
			BIN.fileName =  RawAIName + ".bin"
			CAL.FileName = RawAIName + ".cal"	
			
			sysInfo.currentdir = DATconfig.Mesh()
			if doesFileExist CAL.FileName then 
			(	
				AddToRecent RawAIName
				DAT.createCharacter RawAIName true (ch_LGSrig.checked)
				RefreshRollout()
			)
			else format "\\\\ERROR: Couldn't find %.CAL file.\n" RawAIName
		)
	)
	
	on ddl_project selected val do
	(
		DATconfig.projectId = val				
		RefreshRollout()
	)
	
	on bt_config pressed do
	(
		datcfg()
		RefreshRollout()
	)
	
	on DATImport open do
	(	
		for i = 1 to DATconfig.paths.count do
			if DATconfig.paths[i].isDefault == true then DATconfig.projectId = i
		ddl_project.selection = DATconfig.projectId
		ddl_recent.items = DATconfig.recent()
		RefreshRollout()		
	)
	
	on DATImport close do
	(
		local pos = GetDialogPos DATImport
		setINISetting DATconfig.darkINIfile "ImportRollout" "PosX" (pos.x as string)
		setINISetting DATconfig.darkINIfile "ImportRollout" "PosY" (pos.y as string)
	)
)

/* -------------------------------------------------------------------------------------------------------------------*/

rollout DATRigGeneric "Generic Limb" category: 4 (
	local ctrlOffset = 80
	local Rig = DAT.Rig
	spinner sp_genFKStartSize "Generic FK Start size:" type:#float range:[0.01, 10.0, Rig.genFKStartSize] fieldwidth:60 align:#right scale:0.01 offset:[-ctrlOffset ,0]
	spinner sp_genFKEndSize "Generic FK End size:" type:#float range:[0.01, 10.0, Rig.genFKEndSize] fieldwidth:60 align:#right scale:0.01 offset:[-ctrlOffset ,0]

	on sp_genFKStartSize changed val do
	(
		Rig.genFKStartSize = val
		DATRig.updateLimbFKSize #generic Rig.genFKStartSize Rig.genFKEndSize
	)
		
	on sp_genFKEndSize changed val do
	(
		Rig.genFKEndSize = val
		DATRig.updateLimbFKSize #generic Rig.genFKStartSize Rig.genFKEndSize
	)

)

rollout DATRigHead "Head" category: 3 (
	local ctrlOffset = 80
	local Rig = DAT.Rig

	spinner sp_headSize "Head CTRL Size:" type:#float range:[0.01, 10.0, Rig.headSize] fieldwidth:60 align:#right scale:0.01 offset:[-ctrlOffset, 0]
	spinner sp_headOffsetX "Head CTRL Offset:" type:#float range:[-3.0, 3.0, Rig.headOffsetX] fieldwidth:38 align:#right scale:0.01 offset:[-ctrlOffset-22, 0]
	spinner sp_headOffsetY "" type:#float range:[-3.0, 3.0, Rig.headOffsetY] fieldwidth:38 align:#right scale:0.01 offset:[-ctrlOffset+31, -21]
	spinner sp_headOffsetZ "" type:#float range:[-3.0, 3.0, Rig.headOffsetZ] fieldwidth:38 align:#right scale:0.01 offset:[4, -21]
	checkbox chb_headStraight "Straighten CTRL" checked:Rig.headStraight align:#right offset:[-47, 0]

	fn UpdateHeadSettings = (
		for l = 1 to AI.limbs.count do
		(
			limb = AI.limbs[l]
			if limb.type == #head then 
			(				
				xf = limb.fkctrls[1].modifiers[2]
				CTRLscale = Rig.headSize
				xf.gizmo.scale = [CTRLscale, CTRLscale, CTRLscale]
				CTRLrot = case Rig.headStraight of (						
					true:(								
						Vx = limb.fkctrls[1].transform.row1
						Vstraight = [Vx.x, 0, Vx.z]
						theAngle = acos(dot (normalize Vx) (normalize Vstraight))
						eulerAngles 0 0 theAngle
					)
					false:eulerAngles 0 0 0					
				)		
				xf.gizmo.rotation = CTRLrot
				CTRLoffset = [Rig.headOffsetX, Rig.headOffsetY, Rig.headOffsetZ]
				xf.gizmo.position = CTRLoffset
			)
		)	
	)

	on sp_headSize changed val do (
		Rig.headSize = val
		UpdateHeadSettings()
	)

	on sp_headOffsetX changed val do (
		Rig.headOffsetX = val
		UpdateHeadSettings()
	)

	on sp_headOffsetY changed val do (
		Rig.headOffsetY = val
		UpdateHeadSettings()
	)

	on sp_headOffsetZ changed val do (
		Rig.headOffsetZ = val
		UpdateHeadSettings()
	)

	on chb_headStraight changed state do (
		Rig.headStraight = state
		UpdateHeadSettings()
	)
)

rollout DATRigArms "Arms" category: 5 (
	local ctrlOffset = 80
	local Rig = DAT.Rig
	local supportedLimbs = #(#hand, #droidarm, #armwithclaw)
	spinner sp_armFKStartSize "Arm FK Start size:" type:#float range:[0.01, 10.0, Rig.armFKStartSize] fieldwidth:60 align:#right scale:0.01 offset:[-ctrlOffset ,0]
	spinner sp_armFKEndSize "Arm FK End size:" type:#float range:[0.01, 10.0, Rig.armFKEndSize] fieldwidth:60 align:#right scale:0.01 offset:[-ctrlOffset ,0]
	spinner sp_handIKsize "Hand IK size:" type:#float range:[0.01, 10.0, Rig.handIKsize] fieldwidth:60 align:#right scale:0.01 offset:[-ctrlOffset ,10]
		
	fn updateHandIKsize =
	(
		for l = 1 to AI.limbs.count do
		(
			limb = AI.limbs[l]
			if (findItem supportedLimbs limb.type) > 0  then 
			(
				xf = limb.ikctrl.modifiers[2]
				xf.gizmo.scale = [Rig.handIKsize, Rig.handIKsize, Rig.handIKsize]
			)
		)	
	)
	
	fn updateArmFKSize = (
		for armType in supportedLimbs do (
			DATRig.updateLimbFKSize armType Rig.armFKStartSize Rig.armFKEndSize
		)
	)

	on sp_armFKStartSize changed val do
	(
		Rig.armFKStartSize = val
		updateArmFKSize()
	)
		
	on sp_armFKEndSize changed val do
	(
		Rig.armFKEndSize = val
		updateArmFKSize()
	)
	
	on sp_handIKsize changed val do
	(
		Rig.handIKsize = val
		updateHandIKsize()
	)	
)

rollout DATRigSpiderLegs "Spider legs" category:8 (
	local ctrlOffset = 80
	local Rig = DAT.Rig

	spinner sp_legFKStartSize "Leg FK Start size:" type:#float range:[0.01, 10.0, Rig.legFKStartSize] fieldwidth:60 align:#right scale:0.01 offset:[-ctrlOffset ,0]
	spinner sp_legFKEndSize "Leg FK End size:" type:#float range:[0.01, 10.0, Rig.legFKEndSize] fieldwidth:60 align:#right scale:0.01 offset:[-ctrlOffset ,0]
	spinner sp_footIKwidth "Foot IK radius:" type:#float range:[0.01, 10.0, Rig.footIKwidth] fieldwidth:60 align:#right scale:0.01 offset:[-ctrlOffset ,10]

	on sp_LegFKStartSize changed val do
	(
		Rig.LegFKStartSize = val
		DATRig.updateLimbFKSize #spiderLeg Rig.legFKStartSize Rig.legFKEndSize		-- we're using the same rig preset settings as for normal legs.
	)
	
	on sp_LegFKEndSize changed val do
	(
		Rig.LegFKEndSize = val
		DATRig.updateLimbFKSize #spiderLeg Rig.legFKStartSize Rig.legFKEndSize
	)
		
	on sp_footIKwidth changed val do
	(
		Rig.footIKwidth = val
		for i = 1 to AI.limbs.count do
		(
			limb = AI.limbs[i]
			if limb.type == #spiderleg then limb.ikctrl.radius = 0.07 * Rig.footIKwidth
		)
	)
)

rollout DATRigLegs "Legs" category:10 (
	local ctrlOffset = 80
	local Rig = DAT.Rig
	local supportedLimbs = #(#leg, #dogleg)
	spinner sp_legFKStartSize "Leg FK Start size:" type:#float range:[0.01, 10.0, Rig.legFKStartSize] fieldwidth:60 align:#right scale:0.01 offset:[-ctrlOffset ,0]
	spinner sp_legFKEndSize "Leg FK End size:" type:#float range:[0.01, 10.0, Rig.legFKEndSize] fieldwidth:60 align:#right scale:0.01 offset:[-ctrlOffset ,0]
	spinner sp_footIKwidth "Foot IK width:" type:#float range:[0.01, 10.0, Rig.footIKwidth] fieldwidth:60 align:#right scale:0.01 offset:[-ctrlOffset ,10]
	spinner sp_footIKlength "Foot IK length:" type:#float range:[0.01, 10.0, Rig.footIKlength] fieldwidth:60 align:#right scale:0.01 offset:[-ctrlOffset ,0]
	spinner sp_footIKoffsetX "Foot CTRL offset:" type:#float range:[-10.00, 10.0, Rig.footIKoffsetX] fieldwidth:60 align:#right scale:0.01 offset:[-ctrlOffset ,0]
	spinner sp_footIKoffsetY "" type:#float range:[-10.00, 10.0, Rig.footIKoffsetY] fieldwidth:60 align:#right scale:0.01 offset:[0,-21]
		
	group "Foot IK helpers" (
		radiobuttons rb_legSide "" labels:#("LEFT", "RIGHT") default:1 columns:2 align:#center offset:[0,5]
		-- Left Leg
		spinner Lsp_h2offsetX "Heel helper offset:" type:#float range:[-10.00, 10.0, 0] fieldwidth:60 align:#right scale:0.01 offset:[-ctrlOffset, 5] visible:True
		spinner Lsp_h2offsetY "" type:#float range:[-10.00, 10.0, 0] fieldwidth:60 align:#right scale:0.01 offset:[0,-21] visible:True
		spinner Lsp_h3offsetX "Toes helper offset:" type:#float range:[-10.00, 10.0, 0] fieldwidth:60 align:#right scale:0.01 offset:[-ctrlOffset, 0] visible:True
		spinner Lsp_h3offsetY "" type:#float range:[-10.00, 10.0, 0] fieldwidth:60 align:#right scale:0.01 offset:[0,-21] visible:True
		spinner Lsp_h4offsetX "Foot Out helper offset:" type:#float range:[-10.00, 10.0, 0] fieldwidth:60 align:#right scale:0.01 offset:[-ctrlOffset, 0] visible:True
		spinner Lsp_h4offsetY "" type:#float range:[-10.00, 10.0, 0] fieldwidth:60 align:#right scale:0.01 offset:[0,-21] visible:True
		spinner Lsp_h4angle "angle:" type:#float range:[-45.00, 45.0, 0] fieldwidth:60 align:#right scale:0.1 offset:[-ctrlOffset ,0] visible:True
		spinner Lsp_h5offsetX "Foot In helper offset:" type:#float range:[-10.00, 10.0, 0] fieldwidth:60 align:#right scale:0.01 offset:[-ctrlOffset, 0] visible:True
		spinner Lsp_h5offsetY "" type:#float range:[-10.00, 10.0, 0] fieldwidth:60 align:#right scale:0.01 offset:[0,-21] visible:True
		spinner Lsp_h5angle "angle:" type:#float range:[-45.00, 45.0, 0] fieldwidth:60 align:#right scale:0.1 offset:[-ctrlOffset ,0] visible:True
		--Right Leg
		spinner Rsp_h2offsetX "Heel helper offset:" type:#float range:[-10.00, 10.0, 0] fieldwidth:60 align:#right scale:0.01 offset:[-ctrlOffset, -126] visible:False
		spinner Rsp_h2offsetY "" type:#float range:[-10.00, 10.0, 0] fieldwidth:60 align:#right scale:0.01 offset:[0,-21] visible:False
		spinner Rsp_h3offsetX "Toes helper offset:" type:#float range:[-10.00, 10.0, 0] fieldwidth:60 align:#right scale:0.01 offset:[-ctrlOffset, 0] visible:False
		spinner Rsp_h3offsetY "" type:#float range:[-10.00, 10.0, 0] fieldwidth:60 align:#right scale:0.01 offset:[0,-21] visible:False
		spinner Rsp_h4offsetX "Foot Out helper offset:" type:#float range:[-10.00, 10.0, 0] fieldwidth:60 align:#right scale:0.01 offset:[-ctrlOffset, 0] visible:False
		spinner Rsp_h4offsetY "" type:#float range:[-10.00, 10.0, 0] fieldwidth:60 align:#right scale:0.01 offset:[0,-21] visible:False
		spinner Rsp_h4angle "angle:" type:#float range:[-45.00, 45.0, 0] fieldwidth:60 align:#right scale:0.1 offset:[-ctrlOffset, 0] visible:False
		spinner Rsp_h5offsetX "Foot In helper offset:" type:#float range:[-10.00, 10.0, 0] fieldwidth:60 align:#right scale:0.01 offset:[-ctrlOffset, 0] visible:False
		spinner Rsp_h5offsetY "" type:#float range:[-10.00, 10.0, 0] fieldwidth:60 align:#right scale:0.01 offset:[0,-21] visible:False
		spinner Rsp_h5angle "angle:" type:#float range:[-45.00, 45.0, 0] fieldwidth:60 align:#right scale:0.1 offset:[-ctrlOffset, 0] visible:False
	)	
	
	/* ChangeHandler callback */
	fn helpersHaveBeenMoved = 
	(		
		--format "Helpers have been moved.\n"
		for i = 1 to AI.limbs.count do
		(
			limb = AI.limbs[i]
			if (findItem supportedLimbs limb.type) > 0  then 
			(
				limb.updateRigOffsetsForHelpers()
				DATRig.UpdateControlsValues false
			)			
		)		
	)
	
	fn registerHelpersChangeHandlers =
	(
		for i = 1 to AI.limbs.count do
		(
			limb = AI.limbs[i]
			if (findItem supportedLimbs limb.type) > 0  then 
			(
				--format "Registering ChangeHandler for limb no. % (%).\n" i limb.type
				footHelperChangeHandler = when transform limb.footHelpers changes id:#footHelpers do
				(
					helpersHaveBeenMoved()
				)
			)			
		)		
	)
	
	fn unRegisterHelpersChangeHandlers =
	(
		deleteAllChangeHandlers id:#footHelpers
	)	
		
	fn updateLegIKHelpers =
	(
		unRegisterHelpersChangeHandlers()
		for i = 1 to AI.limbs.count do
		(
			limb = AI.limbs[i]
			if (findItem supportedLimbs limb.type) > 0  then 
				limb.setHelpersPositions()
		)
		registerHelpersChangeHandlers()
	)
	
	on sp_LegFKStartSize changed val do
	(
		Rig.LegFKStartSize = val
		for legtype in supportedLimbs do
			DATRig.updateLimbFKSize legtype Rig.legFKStartSize Rig.legFKEndSize
	)
	
	on sp_LegFKEndSize changed val do
	(
		Rig.LegFKEndSize = val
		for legtype in supportedLimbs do
			DATRig.updateLimbFKSize legtype Rig.legFKStartSize Rig.legFKEndSize
	)	
	
	on sp_footIKwidth changed val do
	(
		Rig.footIKwidth = val
		for i = 1 to AI.limbs.count do
		(
			limb = AI.limbs[i]
			if (findItem supportedLimbs limb.type) > 0  then 
				DAT.setFootIKctrlSize limb
		)
	)
	
	on sp_footIKlength changed val do
	(
		Rig.footIKlength = val
		for i = 1 to AI.limbs.count do
		(
			limb = AI.limbs[i]
			if (findItem supportedLimbs limb.type) > 0  then 
				DAT.setFootIKctrlSize limb				
		)
	)
	
	on sp_footIKoffsetX changed val do
	(
		Rig.footIKoffsetX = val
		for i = 1 to AI.limbs.count do
		(
			local limb = AI.limbs[i]
			if (findItem supportedLimbs limb.type) > 0  then
			(
				xf = limb.ikctrl.modifiers[2]
				xf.gizmo.position.x = val				
			)
		)
	)
	
	on sp_footIKoffsetY changed val do
	(
		Rig.footIKoffsetY = val
		for i = 1 to AI.limbs.count do
		(
			local limb = AI.limbs[i]
			if (findItem supportedLimbs limb.type) > 0  then
			(
				xf = limb.ikctrl.modifiers[2]
				xf.gizmo.position.y = val * limb.side				
			)
		)
	)
	
	--on ddl_legSide selected val do
	on rb_legSide changed val do
	(		
		for i = 1 to DATRigLegs.controls.count do
		(
			ctrl = DATRigLegs.controls[i]
			try (nameElements = filterString ctrl.name "_"); catch (nameElements = #())
			if nameElements.count > 0 then
			(
				if nameElements[1] == "Lsp" then
				(
					ctrl.visible = case val of (
						(1):True
						(2):False
						)
				)
				if nameElements[1] == "Rsp" then
				(
					ctrl.visible = case val of (
						(1):False
						(2):True
						)
					)
			)
		)
		DATRig.UpdateControlsValues true
	)
	
	on Lsp_h2offsetX changed val do
	(
		Rig.footHelpers[1].h2offsetX = val
		updateLegIKHelpers()
	)
	
	on Lsp_h2offsetY changed val do
	(
		Rig.footHelpers[1].h2offsetY = val
		updateLegIKHelpers()
	)
	
	on Lsp_h3offsetX changed val do
	(
		Rig.footHelpers[1].h3offsetX = val
		updateLegIKHelpers()
	)
	
	on Lsp_h3offsetY changed val do
	(
		Rig.footHelpers[1].h3offsetY = val
		updateLegIKHelpers()
	)
	
	on Lsp_h4offsetX changed val do
	(
		Rig.footHelpers[1].h4offsetX = val
		updateLegIKHelpers()
	)
	
	on Lsp_h4offsetY changed val do
	(
		Rig.footHelpers[1].h4offsetY = val
		updateLegIKHelpers()
	)
	
	on Lsp_h4angle changed val do
	(
		Rig.footHelpers[1].h4angle = val
		updateLegIKHelpers()
	)
	
	on Lsp_h5offsetX changed val do
	(
		Rig.footHelpers[1].h5offsetX = val
		updateLegIKHelpers()
	)
	
	on Lsp_h5offsetY changed val do
	(
		Rig.footHelpers[1].h5offsetY = val
		updateLegIKHelpers()
	)
	
	on Lsp_h5angle changed val do
	(
		Rig.footHelpers[1].h5angle = val
		updateLegIKHelpers()
	)
	
	on Rsp_h2offsetX changed val do
	(
		Rig.footHelpers[2].h2offsetX = val
		updateLegIKHelpers()
	)
	
	on Rsp_h2offsetY changed val do
	(
		Rig.footHelpers[2].h2offsetY = val
		updateLegIKHelpers()
	)
	
	on Rsp_h3offsetX changed val do
	(
		Rig.footHelpers[2].h3offsetX = val
		updateLegIKHelpers()
	)
	
	on Rsp_h3offsetY changed val do
	(
		Rig.footHelpers[2].h3offsetY = val
		updateLegIKHelpers()
	)
	
	on Rsp_h4offsetX changed val do
	(
		Rig.footHelpers[2].h4offsetX = val
		updateLegIKHelpers()
	)
	
	on Rsp_h4offsetY changed val do
	(
		Rig.footHelpers[2].h4offsetY = val
		updateLegIKHelpers()
	)
	
	on Rsp_h4angle changed val do
	(
		Rig.footHelpers[2].h4angle = val
		updateLegIKHelpers()
	)
	
	on Rsp_h5offsetX changed val do
	(
		Rig.footHelpers[2].h5offsetX = val
		updateLegIKHelpers()
	)
	
	on Rsp_h5offsetY changed val do
	(
		Rig.footHelpers[2].h5offsetY = val
		updateLegIKHelpers()
	)
	
	on Rsp_h5angle changed val do
	(
		Rig.footHelpers[2].h5angle = val
		updateLegIKHelpers()
	)

	fn OpenRollout = (
		DATRig.UpdateControlsValues false
		
		LM = layerManager
		DATlayer.Temp = LM.newLayerFromName "RIG_Temporary"
		if DATlayer.Temp == undefined then DATlayer.Temp = LM.getLayerFromName "RIG_Temporary"
		DATlayer.Temp.current = true
		for l = 1 to AI.limbs.count do
			if (findItem supportedLimbs AI.limbs[l].type) > 0  then 
				for o = 2 to AI.limbs[l].footHelpers.count do DATlayer.Temp.addNode AI.limbs[l].footHelpers[o]

		registerHelpersChangeHandlers()
	)

	on DATRigsLegs open do (
		OpenRollout()
	)

	fn CloseRollout = (
		DATlayer.Temp.select true
		for footHelper in $selection do DATlayer.Rig.addNode footHelper
		deselect $*		
		LayerManager.deleteLayerByName "RIG_Temporary"

		unRegisterHelpersChangeHandlers()		
	)

	on DATRigLegs close do (
		CloseRollout()
	)
)

rollout DATRig "Rig building in progress..."
(
	local ctrlOffset = 80
	local rig = DAT.Rig
	local defLimbsHeight = 200
	local bottomControlsIndex = 13  --     <--- index of 'Rig presets' group

	group "Global"		
	(
		spinner sp_rootSize "Root Size:" type:#float range:[0.01, 10.0, Rig.rootSize] fieldwidth:60 align:#right scale:0.01 offset:[-ctrlOffset, 0]
		spinner sp_rootOffset "Root Offset:" type:#float range:[-5.0, 5.0, Rig.rootOffset] fieldwidth:60 align:#right scale:0.01 offset:[-ctrlOffset, 0]
		spinner sp_ctrlThickness "Controls thickness:" type:#float range:[0.001, 0.5, Rig.ctrlThickness] fieldwidth:60 align:#right scale:0.001 offset:[-ctrlOffset, 5]
	)
	group "Torsos" 
	(
		spinner sp_torsoStartSize "First torso size:" type:#float range:[0.01, 10.0, Rig.torsoStartSize] fieldwidth:60 align:#right scale:0.01 offset:[-ctrlOffset, 0]
		spinner sp_torsoEndSize "Last torso size:" type:#float range:[0.01, 10.0, Rig.torsoEndSize] fieldwidth:60 align:#right scale:0.01 offset:[-ctrlOffset, 0]
		spinner sp_torsoOffsetX "Offset in X axis:" type:#float range:[-3.0, 3.0, Rig.torsoOffsetX] fieldwidth:60 align:#right scale:0.01 offset:[-ctrlOffset, 0]
	)
	groupBox grp_limbs "Limbs" offset:[-8,0] width:(DATRig.width-10) height:defLimbsHeight
	subRollout sub_limbs "Limbs" offset:[0,-(defLimbsHeight-12)] height:(defLimbsHeight-22)
	group "Rig presets:"
	(
		button bt_saveRig "SAVE" width:140 height:50 across:2
		button bt_loadRig "LOAD" width:140 height:50
		button bt_saveAsDefault "Save as Default" width:290 height:30
		button bt_reset "Reset preset" width:290 height:30
	)
	group "Finalize building the rig:"
	(		
		button bt_buildRig "Done!" width:290 height:50
	)
	
	

	fn UpdateOneControl ctrlName propValue triggerEvents =
	(
		allRollouts = sub_limbs.rollouts
		append allRollouts DATRig
		for subRolloutObject in allRollouts do (
			if isProperty subRolloutObject ctrlName then (
				-- this updates the rollout fields values:
				ctrls = getProperty subRolloutObject ctrlName 
				oldCtrlValue = ctrls.value
				ctrls.value = propValue
				-- this updates the rig, if values are different				
				if (oldCtrlValue != propValue) and (triggerEvents == true) then
				(
					try 
					(
						ctrls.changed ctrls.value
						-- format "Envoking %\n" ctrls
					)
					catch(format "\\\\ERR: Couldn't invoke a 'changed' event on % control.\n\\\\ERR: Rig is not up-to-date.\n" ctrls.name)
				)									
				-- else (format "\\\\WARN: Cannot find a control: '%'' in a rollout: '%'.\n" ctrlName rolloutObject)	
			)
		)
	)
	
	fn UpdateControlsValues triggerEvents =
	(
		propNames = sort (getPropNames rig)
		for i = 1 to propNames.count do 
		(			
			propName = propNames[i]
			
			ctrlName = "sp_" + propName as string 
			propValue = getProperty rig propName		
 			-- format "propName: %, propValue: %, class: %\n" propName propValue (classof propValue)
			case (classof propValue) of 
			(
				Point2:()	-- not used
				MAXScriptFunction:()		
				Array:
				(		
					for leg = 1 to 2 do
					(
						itemNames = getPropNames propValue[leg]
	 					-- print itemNames
						for j = 1 to itemNames.count do
						(						
							itemName = itemNames[j]
	-- 						prefix = (Name as string) + "[" + (leg as string) + "]."
							itemValue = getProperty propValue[leg] itemName
							sidePrefix = case leg of (
								(1):"L"
								(2):"R"
							)								
							ctrlName = sidePrefix + "sp_" + itemName as string
	 	 					-- format "Leg no %. Updating Control %, its value %.\n" leg ctrlName itemValue

							
							UpdateOneControl ctrlName itemValue triggerEvents
						)
					)
					prefix = ""	
					
				)
				default:
				(
					UpdateOneControl ctrlName propValue triggerEvents
				)
			)			
		)
	)
	
	
	on sp_rootSize changed val do
	(
		Rig.rootSize = val
		AI.RootCTRL.node.modifiers[2].gizmo.scale = [val, val, 1]
	)

	on sp_rootOffset changed val do
	(
		Rig.rootOffset = val
		AI.RootCTRL.node.modifiers[2].gizmo.position = [val, 0, 0]
	)
	
	on sp_ctrlThickness changed val do
	(
		Rig.ctrlThickness = val
		DAT.changeRigControlsThickness val
	)
	
	fn UpdateTorsoSize = (
		for t = 1 to AI.torsos.count do
		(
			torso = AI.torsos[t]
			CTRLsize = (interpolate Rig.torsoStartSize Rig.torsoEndSize t AI.torsos.count)
			torso.ctrl.node.modifiers[2].gizmo.scale = [CTRLsize, CTRLsize, CTRLsize]
			torso.auxctrl.node.modifiers[2].gizmo.scale = [CTRLsize, CTRLsize, CTRLsize] * 0.95 
		)
	)

	fn updateLimbFKsize limbType StartSize EndSize =
	/* function shared across different rollouts for different limbs */
	(
		for l = 1 to AI.limbs.count do
		(
			limb = AI.limbs[l]
			if limb.type == limbType then 
			(
				segs = limb.segmentsCount				
				for i = 1 to segs do
				(
					xf = limb.fkctrls[i].modifiers[2]
					CTRLscale = interpolate StartSize EndSize i segs
					xf.gizmo.scale = [CTRLscale, CTRLscale, CTRLscale]
				)
			)
		)	
	)	

	on sp_torsoStartSize changed val do
	(
		Rig.torsoStartSize = val
		UpdateTorsoSize()
	)
	
	on sp_torsoEndSize changed val do
	(
		Rig.torsoEndSize = val
		UpdateTorsoSize()
	)		

	on sp_torsoOffsetX changed val do (
		Rig.torsoOffsetX = val		
		for t = 1 to AI.torsos.count do
		(
			torso = AI.torsos[t]			
			offset = case torso.type of (
				#arm:[0,0,0]
				default:[Rig.torsoOffsetX, 0, 0]
			)
			torso.ctrl.node.modifiers[2].gizmo.position = offset
			torso.auxctrl.node.modifiers[2].gizmo.position = offset
		)
	)
	
	on bt_buildRig pressed do
	(
		try DATRigLegs.unRegisterHelpersChangeHandlers(); catch()
		undo "Finalize building the rig." on
			DAT.createRigConstraints()
		destroydialog DATrig
	)
	
	on bt_saveRig pressed do
	(
		Rig.savePresets AI.rawname
	)
	
	on bt_loadRig pressed do
	(
		rigFileName = getOpenFileName caption:"Select a Rig Settings file:" \
		filename:(DATconfig.Mesh() + "\\" + AI.rawName + ".rig")\
		types:"Rig Settings (*.rig)|*.rig" \
		historyCategory:"AI Meshes"
		if rigFileName != undefined then
		(						
			Rig.loadPresets (getFileNameFile rigFileName)
			UpdateControlsValues true	
		)		
	)
	
	on bt_saveAsDefault pressed do
	(		
		Rig.savePresets ("Default_" + AIstructure[AI.type].shortName)
	)
	
	on bt_reset pressed do
	(		
		Rig = customRig()
		UpdateControlsValues true
	)
	
	fn addLimbRollout &rolloutObject &subRolloutsHeight = (
		if findItem sub_limbs.rollouts rolloutObject < 1 then (
			AddSubRollout sub_limbs rolloutObject					
			try rolloutObject.openRollout(); catch()
			subRolloutsHeight += rolloutObject.height + 30
		)
	)

	on DATRig open do
	(	
		with redraw off
		(	
			DAT.createRig()
			-- add subrollouts for limbs adjustments
			subRolloutsHeight = 0
			for l = 1 to AI.limbs.count do (
				case AI.limbs[l].type of (
					#head:addLimbRollout &DATRigHead &subRolloutsHeight
					#hand:addLimbRollout &DATRigArms &subRolloutsHeight
					#armwithclaw:addLimbRollout &DATRigArms &subRolloutsHeight
					#droidarm:addLimbRollout &DATRigArms &subRolloutsHeight
					#leg:addLimbRollout &DATRigLegs &subRolloutsHeight
					#dogleg:addLimbRollout &DATRigLegs &subRolloutsHeight
					#spiderleg:addLimbRollout &DATRigSpiderLegs &subRolloutsHeight
					#generic:addLimbRollout &DATRigGeneric &subRolloutsHeight
				)
			)	
			subRolloutsHeight = clamp subRolloutsHeight 100 400
			-- resize window and move controls to accomodate for the dynamic size of subrollouts area
			sub_limbs.height = subRolloutsHeight
			grp_limbs.height = subRolloutsHeight + 25			
			offset = defLimbsHeight - grp_limbs.height - 5
			ctrls = DATRig.controls
			for c=bottomControlsIndex to ctrls.count do (
				ctrl = ctrls[c]
				if classof ctrl != GroupEndControl then
					ctrl.pos -= [0, offset]
			)
			DATRig.height = DATRig.controls[bottomControlsIndex].pos.y + 230
			-- 
			bt_saveAsDefault.caption = (stringFormat "Save as default for '%'" v1:AIstructure[AI.type].longName)
			--
			
			DATlayer.CTRL.isFrozen = true
			DATlayer.Rig.isFrozen = true
			DATlayer.Rig.isHidden = true
			DATlayer.Mesh.isFrozen = true
		)
	)
	
	on DATRig close do
	(	
		DATlayer.CTRL.current = true 
	)
)

-------------------------------------------------------------------------------------------------------------------------------------------------------
rollout GeneralConfiguration "Configuration:" width:500 height:375
(
	-- tabs	
	imgTag BitmapImage bitmap:(bitmap 500 33 color:(color 8 8 8 255)) pos:[0,0] enabled:false 
	checkbutton tab2 "Paths" width:60 height:30 checked:true pos:[5,5] border:false highlightColor:(color 58 58 58)
	checkbutton tab1 "Other" width:60 height:30 checked:false pos:[65,5] border:false highlightColor:(color 68 68 68)  --enabled:false
	-- specific	
	group "Developer Settings:" (
		checkbox ch_advmode "Advanced mode" checked:DAT.advmode visible:DAT.devmode
	)
	group "Miscellaneous:" (
		spinner sp_maxRecentMot "Max recent motions:" range:[0, 999, 30] fieldWidth:80 type:#integer
		spinner sp_maxRecentAIs "Max recent AIs:" range:[0, 99, 15] fieldWidth:80 type:#integer
		dropdownlist dl_autoBackupMdb "Backup Motion Database on export:" items:#("Never", "Ask before", "Always") width:200
	)
	group "Other paths:"
	(
		-- editText et_pathTools "LGS tools:" fieldwidth:350 align:#right offset:[-30,5]	
		editText et_pathTextEditor "Text Editor:" fieldwidth:350 align:#right offset:[-30,5]	
		button bt_browseTextEditor "..." width:25 align:#right offset:[0,-24]
	)	
	-- shared
	button bt_save "Save" width:100 height:30 pos:[290,330] 
	button bt_close "Save & Close" width:100 height:30 pos:[395,330] 

	on tab1 changed state do (
		tab1.state = false
	)

	on tab2 changed state do (
		local dialogpos = getdialogpos GeneralConfiguration
		if DATPathConfiguration != undefined then
			createdialog DATPathConfiguration pos:dialogpos style:#(#style_toolwindow, #style_sysmenu)
		else
			print "Don't know what DATPathConfiguration is!... Strange, isn't it?"
		destroydialog GeneralConfiguration
	)

	on ch_advmode changed state do
	(
		DAT.advmode = state
		setINISetting DATconfig.DarkINIfile "Configuration" "advmode" (state as string)
	)

	on et_pathTextEditor entered val do
	(		
		DATconfig.pathTextEditor = val
	)
		
	on bt_browseTextEditor pressed do
	(		
		newPath = getOpenFileName caption:"Locate your favourite text editor:" filename:DATconfig.pathTextEditor
		if newPath != undefined then
		(
			et_pathTextEditor.text = newPath			
			DATconfig.pathTextEditor = newPath
		)		
	)

	on dl_autoBackupMdb selected choice do (
		DATConfig.autoBackupMdb = choice
	)

	on sp_maxRecentMot changed val do
	(
		DATconfig.maxRecentMotions = val
	)

	on sp_maxRecentAIs changed val do
	(
		DATconfig.maxRecentAIs = val
	)

	on bt_close pressed do
	(
		DATconfig.savePresets()
		destroydialog GeneralConfiguration
	)

	on bt_save pressed do
	(
		DATconfig.savePresets()
	)

	on GeneralConfiguration open do 
	(
		et_pathTextEditor.text = DATconfig.pathTextEditor
		--dl_autoBackupMdb.selection = DATConfig.GetUserPrefInt "Configuration" "autoBackupMdb" 2
		dl_autoBackupMdb.selection = DATconfig.autoBackupMdb
		sp_maxRecentMot.value = DATconfig.maxRecentMotions
		sp_maxRecentAIs.value = DATconfig.maxRecentAIs
	)
)

rollout DATInstallMDB "Set up Motion Database:" width:450
(
	local sourceFolder = GetDir #userScripts + "\\DarkMaxTools\\MotionDatabase\\"
	group "" 
	(
		label label1 "This tool will copy:" align:#left
		label label2 " - Motion Schemas for specified game" align:#left 
		dropdownlist dl_game "" items:#() width:150 pos:[200, 40]--align:#center offset:[0,20]
		button bt_doMSchemas "Do it" width:75 pos:[365, 40] enabled:false
		label label3 " - Motion files from RES\motions.crf from current project's game directory" align:#left
		button bt_doMotions "Do it" width:75 pos:[365, 65]
		label label4 " - Makmdb.exe file for building the new motion database" align:#left
		button bt_doMakmdbexe "Do it" width:75 pos:[365, 90]
		label label5 "to your project's work folder." align:#left		
		label label6 ""
	)	
	button bt_ok "Do All" width:120 height:30 across:3 offset:[0,20]
	button bt_open "Open folder" width:120 height:30 offset:[0,20]
	button bt_cancel "Cancel" width:120 height:30 offset:[0,20]

	fn CheckWorkingFolder = (
		if (doesFileExist (DATconfig.working()) == False) then (
			--format "ERROR: Working folder does not exist: %" (DATConfig.working())
			msg = stringFormat "Working folder does not exist:\n\n%" v1:(DATConfig.working())
			messageBox msg
			return False
		) else (
			return True
		)
	)

	fn CopyMakmdbexe = (
		--- Copy Makmdb.exe from the tool's folder to the working folder
		if (CheckWorkingFolder()) == True then (		
			destFolder = DATConfig.working()
			fileName = "\\Makmdb.exe"
			if (doesFileExist (destFolder + fileName)) == True then (
				format "INFO: Makmdb.exe already exists in the working folder."
				bt_doMakmdbexe.caption = "Done"
				bt_doMakmdbexe.enabled = false
				return()
			)		
			
			result = copyFile (sourceFolder + fileName) (destFolder + fileName)
			if result == True then (
				bt_doMakmdbexe.caption = "Done"
				bt_doMakmdbexe.enabled = false
			) else (
				format "ERROR: Error copying file\n from: %\n to: %" (sourceFolder + fileName) (destFolder + fileName)
				bt_doMakmdbexe.caption = "Error"
			)
		)
	)

	fn CopyMotionSchemas = (
		--- Copy Motion Schemas from the tool's folder to the working folder
		-- TODO: change this, when (if) you do an XML/JSON version of the Motion Database
		if (CheckWorkingFolder()) == True then (
			try (
				source = GetDir #userScripts + "\\DarkMaxTools\\MotionDatabase"
				schemaSource = source + "\\" + dl_game.selected + "\\MSchema"
				working = DATConfig.working()				
				copyFolder schemaSource working				
				bt_doMSchemas.caption = "Done"
				bt_doMSchemas.enabled = false
			)
			catch (
				format "ERROR: Error copying MSchema files to working folder.\n"
				bt_doMSchemas.caption = "Error"
				print (getCurrentException())
			)
		) else (
			bt_doMSchemas.caption = "Error"
		)
	)

	fn ExtractMotions = (
		--- Extract 'motions.crf' from the game folder to the working folder						
		if (CheckWorkingFolder()) == True then (
			res = DATConfig.root() + "\\RES\\motions.crf"
			dest = DATConfig.working() + "\\motions"
			DMTFolder = GetDir #userScripts + "\\DarkMaxTools"
			sevenZip = DMTFolder + "\\7z\\7za.exe"
			command = (stringFormat "\"%\" -y e \"%\" -o\"%\" " v1:sevenZip v2:res v3:dest)
			substituteString command "\\" "\\\\"
			format "Executing DOS command:\n%\n" command		
			HiddenDOSCommand ("\"" + command + "\"") doNotWait:false ExitCode:&errorCode
			if errorCode == 0 then (
				bt_doMotions.caption = "Done"
				bt_doMotions.enabled = false
			) else (
				format "ERROR: Error code % was returned from extracting motions.crf file operation. " errorCode
			)
		) else (
			bt_doMotions.caption = "Error"
		)
	)

	fn GoAll = (			
		if (CheckWorkingFolder()) == true then (
			if bt_doMSchemas.enabled == true then CopyMotionSchemas()
			ExtractMotions()
			CopyMakmdbexe()
		)
	)

	fn OpenWorkingFolder = (
		OpenFolder (DATConfig.working())
	)

	on dl_game selected index do (
		if index > 1 then (
			bt_doMSchemas.enabled = true
		) else (
			bt_doMSchemas.enabled = false
		)
	)

	on bt_doMSchemas pressed do (
		CopyMotionSchemas()
	)

	on bt_doMotions pressed do (
		ExtractMotions()
	)

	on bt_doMakmdbexe pressed do (
		CopyMakmdbexe()
	)

	on bt_ok pressed do (
		GoAll()
	)

	on bt_open pressed do (
		OpenWorkingFolder()
	)

	on bt_cancel pressed do (
		DestroyDialog DATInstallMDB
	)

	on DATInstallMDB open do (
		-- get folder names as game list
		dirs = getDirectories (sourceFolder + "*")
		dirNames = for dir in dirs collect (getLastDirectory dir)
		insertItem "- Pick -" dirNames 1
		dl_game.items = dirNames				
	)
)

rollout DATPathConfiguration "Configuration:" width:500 height:375
(	
	-- tabs	
	imgTag BitmapImage bitmap:(bitmap 500 33 color:(color 8 8 8)) pos:[0,0]  enabled:false
	checkbutton tab2 "Paths" width:60 height:30 checked:false pos:[5,5] border:false highlightColor:(color 68 68 68)
	checkbutton tab1 "Other" width:60 height:30 checked:true pos:[65,5] border:false highlightColor:(color 58 58 58)
	-- specific
	group "Presets:"
	(
		dropDownList ddl_project "Project:" width:150 toolTip:"Game / Mod / Fanmission"
		button bt_new "New" width:100 height:30 align:#left offset:[160,-30]
		button bt_delete "Delete" width:100 height:30 align:#left offset:[268,-35]
		button bt_default "Make Default" width:100 height:30 align:#left offset:[376,-35]
		editText et_name "Name:" fieldwidth:150 align:#right offset:[-230,10]
		editText et_pathRoot "Game root folder:" fieldwidth:350 align:#right offset:[-30,10]
		button bt_browseRoot "..." width:25 align:#right offset:[0,-24]
		editText et_pathMesh "AI meshes:" fieldwidth:350 align:#right offset:[-30,0]
		button bt_browseMesh "..." width:25 align:#right offset:[0,-24]
		checkbutton ch_txtLock "L" align:#left width:20 height:18 
		editText et_pathTxt16 "AI textures:" fieldwidth:350 align:#right offset:[-30,-22]
		button bt_browseTxt16 "..." width:25 align:#right offset:[0,-24]
		editText et_pathWorking "Work Folder:" fieldwidth:350 align:#right offset:[-30,0]
		button bt_browseWorking "..." width:25 align:#right offset:[0,-24]
		-- editText et_pathMotions "Motions:" fieldwidth:350 align:#right offset:[-30,0]
		-- button bt_browseMotions "..." width:25 align:#right offset:[0,-24]
		-- editText et_pathMSchema "Motion Schemas:" fieldwidth:350 align:#right offset:[-30,0]
		-- button bt_browseMSchema "..." width:25 align:#right offset:[0,-24]
		button bt_installTools "Set up Motion Database tools..." width:350 height:30 offset:[30, 10] toolTip:"Copies Makmdb.exe, motion schemas files and unzips motion.crf into the working folder."
	)
	
	-- shared
	button bt_save "Save" width:100 height:30 pos:[290,330] align:#right
	button bt_close "Save & Close" width:100 height:30 pos:[395,330] align:#right
	
	

	on tab2 changed state do (
		tab2.state = false
	)

	on tab1 changed state do (
		local dialogpos = getdialogpos DATPathConfiguration
		createdialog GeneralConfiguration pos:dialogpos style:#(#style_toolwindow, #style_sysmenu)
		destroydialog DATPathConfiguration
	)

	fn updatePresetFields =
	(
		project = DATconfig.projectId
		ddl_project.selection = project
		items = for each in DATconfig.paths collect each.name
		ddl_project.items = items
		et_name.text = items[project]
		et_pathRoot.text = DATConfig.paths[project].root
		et_pathMesh.text = DATConfig.paths[project].mesh
		ch_txtLock.checked = DATconfig.paths[project].txtLock
		if ch_txtLock.checked == true then 
		(
			DATconfig.paths[project].txt16 = DATConfig.paths[project].mesh + "\\txt16\\"
		)
		et_pathTxt16.text = DATConfig.paths[project].txt16
		et_pathWorking.text = DATConfig.paths[project].working
		-- et_pathMotions.text = DATConfig.paths[project].motions
		-- et_pathMSchema.text = DATConfig.paths[project].mschema
		et_pathTxt16.enabled = not DATconfig.paths[project].txtLock
		bt_browseTxt16.enabled = not DATconfig.paths[project].txtLock
	)
	
	fn RefreshRollout =
	(
		updatePresetFields()		
		bt_default.enabled = not DATConfig.paths[DATConfig.projectId].isDefault
		if DATconfig.paths.count < 2 then bt_delete.enabled = false
			else bt_delete.enabled = true
	)
		
	on ddl_project selected val do
	(
		DATconfig.projectId = val
		RefreshRollout()
	)
	
	on bt_new pressed do
	(
		preset = pathPreset()
		append DATconfig.paths preset
		projectCount = DATconfig.paths.count
		DATconfig.projectId = projectCount
		RefreshRollout()
	)
	
	on bt_delete pressed do
	(		
		project = DATconfig.projectId
		if DATConfig.paths[project].isDefault == false then
		(
			deleteItem DATconfig.paths project 
			if project > DATconfig.paths.count then project = DATconfig.paths.count
			DATconfig.projectId = project
			RefreshRollout()
		)
		else messageBox "Can't delete the Default Preset.\nMake another Preset a default one before deleting this one."
	)
	
	on bt_default pressed do
	(
		project = DATconfig.projectId
		for i = 1 to DATconfig.paths.count do
		(
			if i == project then 
			(
				DATconfig.paths[i].isDefault = true
			)
			else 
			(
				DATconfig.paths[i].isDefault = false
			)
		)
		RefreshRollout()
	)
	
	on et_name changed val do
	(
		project = DATconfig.projectId
		DATconfig.paths[project].name = val
		RefreshRollout()
	)
	
	on et_pathRoot entered val do
		(
			project = DATconfig.projectId
			DATconfig.paths[project].root = val
			RefreshRollout()
		)
		
	on bt_browseRoot pressed do
	(
		project = DATconfig.projectId		
		newPath = getSavePath caption:"Browse for the game's root folder:" initialDir:DATconfig.paths[project].root
		if newPath != undefined then
		(
			et_pathRoot.text = newPath			
			DATconfig.paths[project].root = newPath
			RefreshRollout()
		)		
	)

	on bt_browseRoot rightclick do 
	(
		OpenFolder (DATConfig.root())	
	)

	on et_pathMesh entered val do
	(
		project = DATconfig.projectId
		DATconfig.paths[project].mesh = val
		RefreshRollout()
	)
	
	on bt_browseMesh pressed do
	(
		project = DATconfig.projectId	
		newPath = getSavePath caption:"Browse for AI meshes folder:" initialDir:DATconfig.paths[project].mesh
		if newPath != undefined then
		(
			et_pathMesh.text = newPath			
			DATconfig.paths[project].mesh = newPath
			RefreshRollout()
		)		
	)

	on bt_browseMesh rightclick do (
		OpenFolder (DATConfig.mesh())
	)
	
	on et_pathtxt16 entered val do
	(
		project = DATconfig.projectId
		DATconfig.paths[project].Txt16 = val
		RefreshRollout()
	)
	
	on bt_browseTxt16 pressed do
	(
		project = DATconfig.projectId
		newPath = getSavePath caption:"Browse for AI textures folder:" initialDir:DATconfig.paths[project].Txt16
		if newPath != undefined then
		(
			et_pathTxt16.text = newPath			
			DATconfig.paths[project].Txt16 = newPath
			RefreshRollout()
		)		
	)

	on bt_browsetxt16 rightclick do (
		OpenFolder (DATConfig.Txt16())
	)
	
	-- on et_pathMotions entered val do
	-- (
	-- 	project = DATconfig.projectId
	-- 	DATconfig.paths[project].motions = val
	-- 	RefreshRollout()
	-- )
	
	-- on bt_browseMotions pressed do
	-- (
	-- 	project = DATconfig.projectId	
	-- 	newPath = getSavePath caption:"Browse for motion files folder:" initialDir:DATconfig.paths[project].Motions
	-- 	if newPath != undefined then
	-- 	(
	-- 		et_pathMotions.text = newPath			
	-- 		DATconfig.paths[project].Motions = newPath
	-- 		RefreshRollout()
	-- 	)		
	-- )
	
	-- on et_pathMSchema entered val do
	-- (
	-- 	project = DATconfig.projectId
	-- 	DATconfig.paths[project].mschema = val
	-- 	RefreshRollout()
	-- )
	
	-- on bt_browseMSchema pressed do
	-- (
	-- 	project = DATconfig.projectId	
	-- 	newPath = getSavePath caption:"Browse for motion schemas folder:" initialDir:DATconfig.paths[project].MSchema
	-- 	if newPath != undefined then
	-- 	(
	-- 		et_pathMSchema.text = newPath			
	-- 		DATconfig.paths[project].MSchema = newPath
	-- 		RefreshRollout()
	-- 	)		
	-- )

	on et_pathWorking entered val do
	(
		project = DATconfig.projectId
		DATconfig.paths[project].working = val
		RefreshRollout()
	)
	
	on bt_browseWorking pressed do
	(
		project = DATconfig.projectId	
		newPath = getSavePath caption:"Browse for motions working folder:" initialDir:DATconfig.paths[project].working
		if newPath != undefined then
		(
			et_pathWorking.text = newPath			
			DATconfig.paths[project].working = newPath
			RefreshRollout()
		)		
	)

	on bt_browseWorking rightclick do (
		OpenFolder (DATConfig.Working())
	)
	
	on ch_txtLock changed val do
	(
		project = DATconfig.projectId
		DATconfig.paths[project].txtLock = val		
		updatePresetFields()
	)

	on bt_installTools pressed do 
	(
		createDialog DATInstallMDB modal:true
	)
	
	on bt_close pressed do
	(
		DATconfig.savePresets()
		destroydialog DATPathConfiguration
	)

	on bt_save pressed do
	(
		DATconfig.savePresets()
	)
	
	on DATPathConfiguration open do
	(	
		DATconfig.configureDefPaths()
		
		RefreshRollout()
		
		--DATPathConfiguration.height = DATPathConfiguration.height + 10
	)
) 


rollout DATabout "About..."
(
	label lb1 " * Dark Max Tools *\n" align:#center offset:[0,5]
	label lb1a "" align:#center 
	label lb2 "A toolset for importing, editing and exporting assets\n" align:#left offset:[0,10]
	label lb3 "for Dark Engine based games.\n\n" align:#left
	label lb4 "Juliusz Kaczmarek, a.k.a 'PinkDot'  on TTLG Forums,  (C) 2012-2020\n" align:#left offset:[0,10]
	label lb5 "contact: juliusz_kaczmarek@yahoo.co.uk" align:#left
	button btOK "OK" width:100 height:30 align:#right offset:[0,20]	
	
	on btOK pressed do
		destroyDialog DATabout
	
	on DATabout open do
	(
		versionText = "version " + (DAT.version as string)
		lb1a.text = versionText
	)
		
)

