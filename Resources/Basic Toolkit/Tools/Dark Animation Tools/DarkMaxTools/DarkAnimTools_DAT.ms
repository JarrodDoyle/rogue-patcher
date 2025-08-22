/* ------------------------------------------------------
/* 			Dark Animation Tools
/*					DAT struct
/* ------------------------------------------------------
/* author: Juliusz Kaczmarek
/* ver. 0.01
/* Nov. 2012, 2013
/*
/* tools for importing and exporting
/* rigged characters and their motions
/* from and to dark engine games. 
/*
/* this script was possible thanks to the knowledge and experience 
/* of Volca, Shadowspawn, Weyoun, Telliamed
/* ------------------------------------------------------
*/

format " - Loading... DAT\n"

struct DATLayers (
	Mesh,
	Rig,
	CTRL,
	Temp,
	LGS
)
DATlayer = DATLayers()

struct DarkAnimTools (

	version = 2.00,
	
	fn getModeFromINI mode =
	(	
		getMode = getINIsetting DATconfig.DarkINIfile "Configuration" (mode as string)
		try
			return (getMode as BooleanClass)
		catch
			return false
	),
	
	advmode = getModeFromINI #advmode,
	devmode = getModeFromINI #devmode,	
	
	-- bones' widths
	FKcontrolWidth, 
	IKboneWidth, 
	SKBoneWidth,
	
	Rig = customRig(),
	doIK = true,
		
--   This scales the bone width and height to accomodate different sizes of creatures
	fn scaleBoneSize CT =
	(		
		StandardFKcontrolWidth = 0.5
		StandardIKboneWidth = 0.12
		StandardSkinboneWidth= 0.2

		FKcontrolWidth = StandardFKcontrolWidth * boneSizeMult[CT]
		IKboneWidth = StandardIKboneWidth * boneSizeMult[CT]
		SKboneWidth = StandardSkinboneWidth * boneSizeMult[CT]
	),

	fn duplicateCALtorso num CALnum =
	(
		CAL.mapTorsos[CALnum] = num
		AI.torsos[num] = TorsoStruct root:CAL.CALtorsos[CALnum].root\
			parent:CAL.CALtorsos[CALnum].parent \
			fixedCount:CAL.CALtorsos[CALnum].fixedCount 
		AI.torsos[num].fixedJoints = #()
		AI.torsos[num].fixedJoints_coord = #()
		for i=1 to CAL.CALtorsos[CALnum].fixedCount do (
			append AI.torsos[num].fixedJoints CAL.CALtorsos[CALnum].fixedJoints[i]
			append AI.torsos[num].fixedJoints_coord CAL.CALtorsos[CALnum].fixedJoints_coord[i]
		)
	),

	-- Reads the AI CAL file and stores information in torso and limbs variables
	fn readCALfile fileName =
	(
		local t, j, l, s 
		local tn
		
		CAL.numJoints = 0		-- this counts number of unique joints present in CAL file	
		CAL.mapTorsos = #()  -- this is mapping of CALtorso numbers onto torsos array 
		CAL.CALtorsos = #()
		AI.torsos = #()
		AI.limbs = #()
		
		local CALfile = fopen fileName "rb"	-- opens CAL file in 'read binary' mode
				
		---- read HEADER ---
		CAL.version = ReadLong CALfile #unsigned	-- version
		CAL.numCALTorsos = ReadLong CALfile #unsigned		-- number of torsos
		CAL.numLimbs = ReadLong CALfile #unsigned		-- number of limbs
		
		--
		unused_joints = #()  -- for detecting 'pseudo limbs'

		--- read TORSOS ---	
		for t = 1 to CAL.numCALTorsos do
		(		
			-- joint number,  0 based, needs to be 1 based for MaxScript arrays			
			-- torso number,  0 based, needs to be 1 based for MaxScript arrays		\
			CAL.CALtorsos[t] = torsoStruct root:((ReadLong CALfile #unsigned)+1) \				
				parent:((ReadLong CALfile #signed)+1) 	\					
				fixedCount:(ReadLong CALfile #unsigned) -- adding number of fixed joints
			CAL.CALtorsos[t].fixedJoints = #()
			fixedCount = CAL.CALtorsos[t].fixedCount
			for j=1 to fixedCount do
				CAL.CALtorsos[t].fixedJoints[j] = ((ReadLong CALfile #unsigned) +1)
			for j=1 to 16-fixedCount do 
				ReadLong CALfile #unsigned -- read and forget			
			CAL.CALtorsos[t].fixedJoints_coord = #()
			for j=1 to fixedCount do
				CAL.CALtorsos[t].fixedJoints_coord[j] = [ReadFloat CALfile, ReadFloat CALfile, ReadFloat CALfile]
			for j=1 to (16-fixedCount) * 3 do (
				ReadFloat CALfile  -- read and forget
			)
					
		)
		-- But it's not that straightforward - spiders have torso definition split into 4 torsos, but limbs refer to them as one and the same
		-- so we want to combine them into one actual torso object.
		-- Burricks have 1 of the torsos split into 2 (in CAL file) as well... :/
		
		tn = 1	-- actual torsos amount 	
		for t = 1 to CAL.numCALTorsos do
		(		
			if t < 2 then duplicateCALtorso 1 1  -- first torso is always unique
			else			
			(
				tn = tn + 1
				sameTorso = false
				for i = 1 to AI.torsos.count do 	
				(
					if AI.torsos[i].root == CAL.CALtorsos[t].root then -- checks if previous torsos have the same root
					(
						tn = i   
						sameTorso = true
					)
				)
				if sameTorso == false then duplicateCALtorso tn t	-- unique torso - just copy it
				else	-- add torso joints to the existing one
				(
					CAL.mapTorsos[t] = tn
					fc = CAL.CALtorsos[t].fixedCount
					AI.torsos[tn].fixedCount = AI.torsos[tn].fixedCount + fc
					for i=1 to fc do (
						append AI.torsos[tn].fixedJoints CAL.CALtorsos[t].fixedJoints[i]
						append AI.torsos[tn].fixedJoints_coord CAL.CALtorsos[t].fixedJoints_coord[i]
					)
				)
			)
		)				
		CAL.numTorsos = tn   -- for most of AI this matches numCALTorsos, for spiders this should be 1, for Burricks - 2
		for t = 1 to tn do (			
			append unused_joints #( t, deepcopy (AI.torsos[t].fixedJoints))
		)
		-- joint counting 
		CAL.numJoints = 1--numTorsos
		for i = 1 to CAL.numTorsos do
			CAL.numJoints = CAL.numJoints + AI.torsos[i].fixedcount

		-- read LIMBS ---
		for l = 1 to CAL.numLimbs do
		(
			AI.limbs[l] = limbStruct torso:CAL.mapTorsos[((ReadLong CALfile #unsigned) +1)]  -- torsos mapping
			AI.limbs[l].Rig = this.Rig
			ReadLong CALfile #unsigned	-- unknown value
			AI.limbs[l].segmentsCount = (ReadLong CALfile #unsigned) 
			AI.limbs[l].segments = #()
		-- 	append AI.limbs[l].segments (ReadShort CALfile #unsigned)
			for s=1 to 17 do 															-- this combines attachment joint with the segments - same as the list in .MJO file
				append AI.limbs[l].segments ((ReadShort CALfile #unsigned) +1) -- joint numbers are 0 based, needs to be 1 based for Maxscript arrays
			AI.limbs[l].segments_coord = #()
			for s=1 to 16 do
				append AI.limbs[l].segments_coord [ReadFloat CALfile, ReadFloat CALfile, ReadFloat CALfile]
			AI.limbs[l].lengths = #()
			for s=1 to 16 do
				append AI.limbs[l].lengths (ReadFloat CALfile)

			CAL.numJoints = CAL.numJoints + AI.limbs[l].segmentsCount 
		)
		
		-- Calibration Value
		CAL.calibration = ReadFloat CALfile		--  this is the creature size ratio compared to the motion capture actor size. Used to calculate translation values of motions.
		
		Fclose CALfile

		--- Post processing
		-- Removing torsos' root joint from the list of unused fixed joints
		for ait in AI.torsos do (
			for t in unused_joints do (
				index = findItem t[2] ait.root 
				if index > 0 then (
					-- format "\\\\DEBUG: Removing used root joint from the list: %\n" ait.root
					deleteItem t[2] index
				)
			)
		)
		-- Removing limbs' attachment joint from the list of unused fixed joints
		for ail in AI.limbs do (
			for t in unused_joints do (
				index = findItem t[2] ail.segments[1]
				if index > 0 then (
					-- format "\\\\DEBUG: Removing used root joint from the list: %\n" ail.segments[1]
					deleteItem t[2] index
				)
			)
		)
		-- Store list of unused joints per torso as 'pseudoLimbs'
		-- We need to add a dummy object to be skinnable (bloody burrsm.bin!!!)
		for tuj in unused_joints do (
			AI.torsos[tuj[1]].unusedFixedJoints = tuj[2]
		)		
	),

	-- Create a set of layers for an imported character
	-- If layer exists (character reloaded) - an existing layer is used
	fn createLayers =
	(
		LM=layerManager
		DATLayer.Mesh = LM.newLayerFromName (AI.name+"_Mesh")
		if DATLayer.Mesh==undefined then DATLayer.Mesh = LM.getLayerFromName (AI.name+"_Mesh")
		DATLayer.Mesh.wirecolor = red
		-- 	DATLayer.Mesh.isfrozen  = true
		DATLayer.Rig = LM.newLayerFromName (AI.name+"_Rig")
		if DATLayer.Rig==undefined then DATLayer.Rig = LM.getLayerFromName (AI.name+"_Rig")
		DATlayer.Rig.wirecolor = blue
		DATlayer.CTRL = LM.newLayerFromName (AI.name+"_CTRLs")
		if DATLayer.CTRL==undefined then DATLayer.CTRL = LM.getLayerFromName (AI.name+"_CTRLs")
		DATlayer.CTRL.wirecolor = yellow	
	),

	-- Deletes all the object from the characters mesh, rigs and controls layer
	fn cleanLayers =
	(
		deselect $*
		DATlayer.Mesh.select on		
		DATlayer.Rig.select on
		DATlayer.CTRL.select on
	
		delete selection
	),

	fn FreezeTransforms objs =
	(	
		suspendEditing which:#motion
		if classof objs != Array then
		(
			temp = objs
			objs = #()
			objs[1] = temp
		)
		
		for i=1 to objs.count do
		(
			if objs[i]!=undefined then
			(					
				local curObj = objs[i]
				try
				(
					if classof CurObj.rotation.controller != Rotation_Layer do
					(
						---
						-- freeze rotation		
						CurObj.rotation.controller = Euler_Xyz() 		
						CurObj.rotation.controller = Rotation_list() 			
						CurObj.rotation.controller.available.controller = Euler_xyz() 		
					
						CurObj.rotation.controller.setname 1 "Frozen Rotation"
						CurObj.rotation.controller.setname 2 "Zero Euler XYZ"
						
						CurObj.rotation.controller.SetActive 2 
					)
					if classof CurObj.position.controller != Position_Layer do
					(	
						-- freeze position
						CurObj.position.controller = Bezier_Position() 			
						CurObj.position.controller = position_list() 			
						CurObj.position.controller.available.controller = Position_XYZ() 	
						
						CurObj.position.controller.setname 1 "Frozen Position"
						CurObj.position.controller.setname 2 "Zero Pos XYZ"
								
						CurObj.position.controller.SetActive 2 		
			
						-- position to zero
						CurObj.Position.controller[2].x_Position = 0
						CurObj.Position.controller[2].y_Position = 0
						CurObj.Position.controller[2].z_Position = 0					
					)
				)
				catch (format "\\\\ERROR: Error while freezing transforms of %\n" CurObj.name)
			)
		)
		
		resumeEditing which:#motion
	),

	fn OrientConstrain slave master keepOffset =
	(
		oc = orientation_constraint relative:keepOffset
		if isValidnode master == true then oc.appendtarget master 100 	-- master can be a node
		if classof master == Array then														-- or an array of nodes
			for i = 1 to master.count do
				oc.appendtarget master[i] (100.0 / master.count)
			
		slave.rotation.controller.available.controller = oc
	),
	
	fn PosConstrain slave master = 
	(
		pc = position_constraint()
		pc.appendtarget master 100
		slave.position.controller.available.controller = pc
	),		
	
	fn CreateEndBone AIbone =
	(
		-- this isn't the cleanest, I suppose...
 		jointSt = AIbone.pos + AIbone.length * AIbone.transform.row1
 		jointEnd = jointSt + AIbone.width * AIbone.transform.row1		
 		endBone = BoneSys.createBone jointSt jointEnd [0,0,1]
		endBone.width = endBone.height = AIbone.width
		endBone.taper = AIbone.taper
		endBone.wirecolor = AIbone.wirecolor
		endBone.transform = AIbone.transform
		endBone.pos = endBone.pos + AIbone.length * AIbone.transform.row1
		endBone.parent = AIbone
		
		endBone		
	),
	
	fn ControlsProperties &ctrl name colorIndex =
	(
		ctrl.name = name
		ctrl.wirecolor = rigMats[colorIndex].color
		ctrl.material = rigMats[colorIndex].mat
		ctrl.render_displayRenderMesh = true
		ctrl.render_thickness = Rig.ctrlThickness
		ctrl.sides = 4
		ctrl.showFrozenInGray = false
	),
	
	fn CircleControls name radius colorIndex =
	(
		ln = Circle radius:radius steps:4
-- 		convertToSplineShape ln;
		ControlsProperties &ln name colorIndex
		return ln
	),
	
	fn FlowerControls name radius colorIndex =
	(
		ln = Star radius1:(radius*0.8) radius2:radius numPoints:16 fillet1:(0.05*radius) fillet2:(radius*0.05) steps:2
-- 		convertToSplineShape ln;
		ControlsProperties &ln name colorIndex
		return ln
	),
	
	fn RoundControls name radius colorIndex = 
	(
		ln = splineShape  step:4;
		splIdx = addNewSpline ln;
			addKnot ln splIdx #bezier #curve [1 * radius,0,0] [1 * radius,-0.551786 * radius,0] [1 * radius,0.551786 * radius,0];
			addKnot ln splIdx #bezier #curve [0,1 * radius,0] [0.551786 * radius,1 * radius,0] [-0.551786 * radius,1 * radius,0];
			addKnot ln splIdx #bezier #curve [-1 * radius,0,0] [-1 * radius,0.551786 * radius,0] [-1 * radius,-0.551786 * radius,0];
			addKnot ln splIdx #bezier #curve [0,-1 * radius,0] [-0.551786 * radius,-1 * radius,0] [0.551786 * radius,-1 * radius,0];
		close ln splIdx;
		splIdx = addNewSpline ln;
			addKnot ln splIdx #bezier #curve [1 * radius,0,0] [1 * radius,0,0.551786 * radius] [1 * radius,0,-0.551786 * radius];
			addKnot ln splIdx #bezier #curve [0,0,-1 * radius] [0.551786 * radius,0,-1 * radius] [-0.551786 * radius,0,-1 * radius];
			addKnot ln splIdx #bezier #curve [-1 * radius,0,0] [-1 * radius,0,-0.551786 * radius] [-1 * radius,0,0.551786 * radius];
			addKnot ln splIdx #bezier #curve [0,0,1 * radius] [-0.551786 * radius,0,1 * radius] [0.551786 * radius,0,1 * radius];
		close ln splIdx;
		splIdx = addNewSpline ln;
			addKnot ln splIdx #bezier #curve [0,-1 * radius,0] [0,-1 * radius,0.551786 * radius] [0,-1 * radius,-0.551786 * radius];
			addKnot ln splIdx #bezier #curve [0,0,-1 * radius] [0,-0.551786 * radius,-1 * radius] [0,0.551786 * radius,-1 * radius];
			addKnot ln splIdx #bezier #curve [0,1 * radius,0] [0,1 * radius,-0.551786 * radius] [0,1 * radius,0.551786 * radius];
			addKnot ln splIdx #bezier #curve [0,0,1 * radius] [0,0.551786 * radius,1 * radius] [0,-0.551786 * radius,1 * radius];
		close ln splIdx;
		updateShape ln;
		animateVertex ln #all
		convertToSplineShape ln;
		ControlsProperties &ln name colorIndex
		return ln
	),
	
	fn CrossControls name size colorIndex =
	(
		ln = splineShape()
		splIdx = addNewSpline ln
			addKnot ln splIdx #corner #curve [0,0.5 * size,0]
			addKnot ln splIdx #corner #curve [0,-0.5 * size,0]
		open ln splIdx
		splIdx = addNewSpline ln
			addKnot ln splIdx #corner #curve [0.5 * size,0,0]
			addKnot ln splIdx #corner #curve [-0.5 * size,0,0]
		open ln splIdx
		splIdx = addNewSpline ln
			addKnot ln splIdx #corner #curve [0,0,0.5 * size]
			addKnot ln splIdx #corner #curve [0,0,-0.5 * size]
		open ln splIdx
		updateShape ln
		animateVertex ln #all
		convertToSplineShape ln
		ControlsProperties ln name colorIndex
		return ln;
	),
	
	fn RootArrowControls name sizeMult colorIndex =
	(		
		ln = splineShape step:0;
		splIdx = addNewSpline ln;
			addKnot ln splIdx #corner #curve ([0.429347,-1.21222,0] * sizeMult);
			addKnot ln splIdx #corner #curve ([0.421447,-1.7114,0] * sizeMult);
			addKnot ln splIdx #corner #curve ([2.25646,0,0] * sizeMult);
			addKnot ln splIdx #corner #curve ([0.421447,1.7114,0] * sizeMult);
			addKnot ln splIdx #corner #curve ([0.429348,1.21222,0] * sizeMult);
			addKnot ln splIdx #corner #curve ([-0.888836,1.21222,0] * sizeMult);
			addKnot ln splIdx #corner #curve ([-0.888836,-1.21222,0] * sizeMult);
		close ln splIdx;
		updateShape ln;
		animateVertex ln #all
		convertToSplineShape ln;
		ln.wireColor = (color 145 28 177);
		ln.name = name
		ControlsProperties ln name colorIndex		
		select ln;
		return ln;
	),
	
	fn RectangularControls name len wid colorIndex =
	(
		ln = Rectangle length:len width:wid cornerradius:(0.15 * (smaller len wid)) steps:4
-- 		convertToSplineShape ln;
		ControlsProperties &ln name colorIndex
		return ln
	),
		
	fn CreatureHasLegs =
	(
		local hasLegs = false
		local AIstruct = AIstructure[AI.type]
		local limbsNumber = AIstruct.limbsNo
		while limbsNumber > 0 do
		(
			if (AIstruct.limbType[limbsNumber] == #leg) or (AIstruct.limbType[limbsNumber] == #dogleg) then hasLegs = true
			limbsNumber -= 1
		)
		hasLegs
	),
	
	fn CalculateJointsPositions =
	-- calculates joint positions and build joint hierarchy	
	(			
		AI.jointPos = #()
		AI.jointPosCAL = #()
		AI.jointParent = #()	
		
		for t=1 to CAL.numTorsos do
		(
			torso = AI.torsos[t]
			root = torso.root 
			
			if torso.parent == 0 then 
			(
				AI.jointPosCAL[root]=[0,0,0]
			)
			--else AI.jointPosCAL[root] = AI.jointPosCAL[root] + AI.jointPosCAL[AI.torsos[torso.parent].root] 
			
			for j=1 to torso.fixedCount do
			(
				AI.jointPosCAL[torso.fixedJoints[j]] = torso.fixedJoints_coord[j] + AI.jointPosCAL[root]
 				AI.jointParent[torso.fixedJoints[j]] = root
			)
		)
		
		
		for j=1 to CAL.numLimbs do
		(
			limb = AI.limbs[j]
			torso = AI.torsos[limb.torso]
	 		--jointRotAxisJoint[limb.segments[1]]=torsos[torso].root
			for s =1 to limb.segmentsCount do
			(			
				AI.jointPosCAL[limb.segments[s+1]] = AI.jointPosCAL[limb.segments[s]] + (limb.segments_coord[s] * limb.lengths[s])
 				AI.jointParent[limb.segments[s+1]]=limb.segments[s]
			)
		)
		
		tempArray = deepcopy AI.jointPosCAL
		AI.jointPos = tempArray				-- make a copy of CAL joint positions for the rig adjustments
				
		-- Rig fixes: --
		-- Knee corrections for IK purposes 
		if (DATImport.ch_fixKnees.state == true) and (creatureHasLegs()==true) then
		(			
			format "\\\\INFO: Correcting inverted knees.\n"
			-- unifying x and y coordinates of leg joints to fix the inverted knees problems.
			-- NOTE: this will introduce slight inacurracy in the imported/exported animations, 
			-- when played back on the original, uncorrected skeletons.
			leg1 = AI.limbs[1]
			leg2 = AI.limbs[2]
			for seg = 1 to leg1.segmentsCount-1 do (		-- -1 means leave feet as they are - they do not cause IK issues
				x1 = AI.jointPos[leg1.segments[seg]].x
				x2 = AI.jointPos[leg2.segments[seg]].x
				betterX = case (mod seg 2) as integer of (
					0:(bigger x1 x2)
					1:(smaller x1 x2)
				)				
				AI.jointPos[leg1.segments[seg]].x = AI.jointPos[leg2.segments[seg]].x = betterX

				z1 = AI.jointPos[leg1.segments[seg]].z
				z2 = AI.jointPos[leg2.segments[seg]].z
				betterZ = bigger z1 z2				
				AI.jointPos[leg1.segments[seg]].z = AI.jointPos[leg2.segments[seg]].z = betterZ
			)
			-- side-bent knees fix
			if leg1.type == #leg then (
				for i = 1 to 2 do
				(
					LegSegs = AI.limbs[i].segments
					numSegs = AI.limbs[i].segmentsCount
					JntFirst = AI.jointPos[LegSegs[1]]
					JntLast = AI.jointPos[LegSegs[numSegs]]
					for seg=2 to numSegs-1 do (				
						Jnt = AI.jointPos[LegSegs[seg]]
						Jnt.y = ( JntLast.y - JntFirst.y ) * ( JntFirst.z - Jnt.z ) / ( JntFirst.z - JntLast.z ) + JntFirst.y				
						AI.jointPos[LegSegs[seg]].y = Jnt.y
					)
				)
			)
		)
	),
	
	fn lockTransforms who which =
	(
		case which of (
			#m:setTransformLockFlags who #{1,2,3}
			#r:setTransformLockFlags who #{4,5,6}
			#s:setTransformLockFlags who #{7,8,9}
			#mr:setTransformLockFlags who #{1,2,3,4,5,6}
			#ms:setTransformLockFlags who #{1,2,3,7,8,9}
			#rs:setTransformLockFlags who #{4,5,6,7,8,9}
			#mrs:setTransformLockFlags who #{1,2,3,4,5,6,7,8,9}
			default:setTransformLockFlags who #none
		)
	),
	
	fn createRootCTRL calib =
	(
		DATlayer.CTRL.current = true
		RootCTRL = RootArrowControls (AI.name+"_Root_CTRL") calib ColorCode.ROOT
		lockTransforms RootCTRL #s
		
		xf = xForm name:"Scale"
		xf.gizmo.scale = [Rig.rootSize, Rig.rootSize, 1]
		xf.gizmo.position = [Rig.rootOffset, 0, 0]
		addModifier RootCTRL xf
		
		em = emptyModifier name:"AI controls"	
		custAttributes.add em AIRootCA 		
		em.charMan = nodeTransformMonitor node:AI.charMan
		em.flags.controller = bezier_float()
		addModifier RootCTRL em				
		AI.charman.rootctrl = nodeTransformMonitor node:RootCTRL
		return RootCTRL
	),
	
	fn setFootIKctrlSize limb=
	(
		CTRLsize = 1.2 * limb.ikbones[3].length 
		limb.ikctrl.width = CTRLsize * Rig.footIKlength 
		limb.ikctrl.length = 0.4 * CTRLsize * Rig.footIKwidth
	),	
	
	fn GetArmFKsize num steps =
	(
		local CTRLsize = (interpolate 0.6 0.35 num steps) * AI.charman.calibration 
		CTRLsize
	),

	fn SetTorsoMatrix &torsoHelper torsoLookAtPoint = 
	(		
		-- construct new transform Matrix for the torso
		vwrld = [0,0,1] 													-- world UP vector
		vzn = normalize (torsoLookAtPoint - torsoHelper.pos)  	-- normalized Z vector	

		vyn = normalize (cross vwrld vzn)
		vxn = normalize (cross vyn vzn)									-- normalized X vector
		torsoMatrix = torsoHelper.transform
		newMatrix = Matrix3 vxn vyn vzn (torsoMatrix.row4)
		return newMatrix
	),

	fn SetupGenericCTRL &limb side =
	(
		local numBones = limb.segmentsCount
		em = emptyModifier name:"GenericLimb Controls"					
		custAttributes.add em GenericCA 
		for i=1 to numBones do (
			em.fkList[i] = nodeTransformMonitor node:limb.fkctrls[i]
		)		
		for i=1 to numBones do 
			addModifier limb.fkctrls[i] em
	),

	fn SetupArmCTRL &limb side =
	(						
		local numBones = limb.segmentsCount
		newCTRL = crossControls (AI.name + side + "Wrist_IK_CTRL") 0.55 ColorCode.IK
		newCTRL.transform = limb.ikbones[limb.ikPos].transform
		append AI.charman.ikctrls (nodeTransformMonitor node:newCTRL)
		limb.ikctrl = newCTRL
		
		xf = xform name:"Scale"
		CTRLscale = Rig.handIKsize
		xf.gizmo.scale = [CTRLscale, CTRLscale, CTRLscale]					
		addModifier newCTRL xf	
		
		em = emptyModifier name:"Arm Controls"					
		custAttributes.add em ArmCA 
		for i=1 to numBones do (
			em.fkList[i] = nodeTransformMonitor node:limb.fkctrls[i]
			em.ikList[i] = nodeTransformMonitor node:limb.ikbones[i]
		)		
		em.ikctrl = nodeTransformMonitor node:newCTRL
		em.fkRef = nodeTransformMonitor node:limb.fkRef
		em.ikPos = limb.ikPos
		em.hasClaw = (limb.type == #armwithclaw)
		addModifier newCTRL em
		for i=1 to numBones do 
			addModifier limb.fkctrls[i] em
		-- IK goal
		DATlayer.Rig.current = true
		ArmIKGoal = IKsys.ikChain limb.ikbones[1] limb.ikbones[limb.ikPos] "IKHISolver"
		ArmIKGoal.name = (AI.name + side + "Arm_IKgoal")
		ArmIKGoal.transform.controller.goalSize = 0.5
		ArmIKGoal.transform.controller.posThresh = 0.01
		ArmIKGoal.transform.controller.rotThresh = 0.01
		setTransformLockFlags ArmIKGoal #all
		limb.HandIK = ArmIKGoal					
		append AI.charman.helpers (nodeTransformMonitor node:ArmIKGoal)		
	),
	
	fn SetupLegCTRL &limb side = 
	(				
		local lsegs = limb.segments
		local numBones = limb.segmentsCount
		-- Foot CTRL		
		CTRLpos = average AI.jointpos[lsegs[numBones]] AI.jointPos[lsegs[numBones+1]]				
		newCTRL = RectangularControls (AI.name + side + "Foot_CTRL") 1 1 ColorCode.IK 
		newCTRL.pos = limb.ikbones[limb.ikPos].pos
		newCTRL.objectOffsetPos = - ( limb.ikbones[limb.ikPos].pos - [CTRLpos.x, CTRLpos.y, 0] )
		append AI.charman.ikctrls (nodeTransformMonitor node:newCTRL)
		limb.ikctrl = newCTRL
		setFootIKctrlSize limb
		-- Foot CTRL offset
		xf = xform name:"Offset"
		xf.gizmo.position = [Rig.footIKoffsetX, Rig.footIKoffsetY * limb.side, 0]
		addModifier newCTRL xf
		-- Foot Custom Attributes
		em = emptyModifier name:"Foot Controls"					
		custAttributes.add em FootCA 
		for i=1 to numBones do (
			em.fkList[i] = nodeTransformMonitor node:limb.fkctrls[i]
			em.ikList[i] = nodeTransformMonitor node:limb.ikbones[i]
		)
		em.ikctrl = nodeTransformMonitor node:newCTRL
		em.ikPos = limb.ikPos
		-- rotation difference between ankle joint and the IKctrl (used for IK to FK snapping)
		-- local diffMatrix = 
		em.rotDiff = newCTRL.transform * limb.fkCtrls[limb.ikPos].transform
		addModifier newCTRL em
		for i=1 to numBones do 
			addModifier limb.fkctrls[i] em
		-- helpers
		DATlayer.Rig.current = true
		hlps=#()
		hlps[1] = point name:(AI.name + side + "Foot_hlp") size:0.3 box:true cross:false wirecolor:green
		hlps[2] = point name:(AI.name + side + "heel_hlp") size:0.1 box:true cross:true wirecolor:green 
		hlps[3] = point name:(AI.name + side + "toes_hlp") size:0.1 box:true cross:true wirecolor:green 
		hlps[4] = point name:(AI.name + side + "footout_hlp") size:0.1 box:true cross:true wirecolor:green 
		hlps[5] = point name:(AI.name + side + "footin_hlp") size:0.1 box:true cross:true wirecolor:green 
		for hlp in hlps do append AI.charman.helpers (nodeTransformMonitor node:hlp)
		limb.footHelpers = hlps
		limb.setHelpersPositions()
		setTransformLockFlags hlps[1] #all
		setTransformLockFlags hlps[2] #{3..9}
		setTransformLockFlags hlps[3] #{3..9}
		setTransformLockFlags hlps[4] #{3..5,7..9}
		setTransformLockFlags hlps[5] #{3..5,7..9}
		-- Foot swivel control
		swivelTarget = point name:(AI.name + side + "FootSwivel_target") size:0.4 box:false cross:true wirecolor:green
		swivelTarget.position = limb.ikctrl.position
		swivelTarget.position.y -= 0.25  	-- does not need to be precise - as long as it's negative,
		limb.swivelTarget = swivelTarget
		append AI.charman.helpers (nodeTransformMonitor node:swivelTarget)
		-- IK goals
		LegikGoal = IKsys.ikChain limb.ikbones[1] limb.ikbones[limb.ikPos] "IKHISolver"
		LegikGoal.name = (AI.name + side + "Leg_IKgoal")
		LegikGoal.transform.controller.goalSize = 0.5
		LegikGoal.transform.controller.posThresh = 0.01
		LegikGoal.transform.controller.rotThresh = 0.01
		limb.legIK = LegIKGoal					
		append AI.charman.helpers (nodeTransformMonitor node:LegIKGoal)
		FootikGoal = IKsys.ikChain limb.ikbones[limb.ikPos] limb.ikbones[limb.ikPos+1] "IKHISolver"
		FootikGoal.name = (AI.name + side + "Foot_IKgoal")
		FootikGoal.transform.controller.posThresh = 0.01
		FootikGoal.transform.controller.rotThresh = 0.01
		FootikGoal.transform.controller.SAParent = 0	-- IK goal parent space
		limb.footIK = FootikGoal
		append AI.charman.helpers (nodeTransformMonitor node:FootikGoal)					
	),

	fn SetupSpiderlegCTRL &limb side limbNumber =
	(		
		local numBones = limb.segmentsCount				
		newCTRL = CircleControls (AI.name + side + "Foot" + limbNumber + "_CTRL") 0.07 ColorCode.IK
		newCTRL.position = limb.ikbones[limb.ikPos].position
		append AI.charman.ikctrls (nodeTransformMonitor node:newCTRL)
		limb.ikctrl = newCTRL
		
		xf = xform name:"Scale"
		CTRLscale = Rig.footIKwidth
		xf.gizmo.scale = [CTRLscale, CTRLscale, CTRLscale]					
		addModifier newCTRL xf	
		
		em = emptyModifier name:"Spider Foot Controls"					
		custAttributes.add em SpiderFootCA 
		em.fk1 = nodeTransformMonitor node:limb.fkctrls[1]
		em.fk2 = nodeTransformMonitor node:limb.fkctrls[2]
		em.fk3 = nodeTransformMonitor node:limb.fkctrls[3]
		em.ik1 = nodeTransformMonitor node:limb.ikbones[1]
		em.ik2 = nodeTransformMonitor node:limb.ikbones[2]
		em.ik3 = nodeTransformMonitor node:limb.ikbones[3]	
		em.ikctrl = nodeTransformMonitor node:newCTRL
		em.fkRef = nodeTransformMonitor node:limb.fkRef
		addModifier newCTRL em
		for i=1 to numBones do 
			addModifier limb.fkctrls[i] em
		-- IK goal
		DATlayer.Rig.current = true
		FootIKGoal = IKsys.ikChain limb.ikbones[1] limb.ikbones[4] "IKHISolver"
		FootIKGoal.name = (AI.name + side + "Foot" + limbNumber + "_IKgoal")
		FootIKGoal.transform.controller.goalSize = 0.5
		FootIKGoal.transform.controller.posThresh = 0.01
		FootIKGoal.transform.controller.rotThresh = 0.01
		setTransformLockFlags FootIKGoal #all
		limb.footIK = FootIKGoal					
		append AI.charman.helpers (nodeTransformMonitor node:FootIKGoal)
	),

	----------------------------------------------------------------------------------------------------------------------------
	-- Main function - creates the animation rig from the information
	-- previously read from the CAL file
	----------------------------------------------------------------------------------------------------------------------------
	fn CreateRig =
	(		
		deselect $*
		
		local jointNames = AIstructure[AI.type].jointNames
		local jointsNum = AI.jointsNumber
		local calib = CAL.calibration
		
		ScaleBoneSize AI.type		-- this needs to be replaced with something more customized
			
		-- Create Character Manager
		DATlayer.Rig.current = true				-- switch current layer to Rig
		AI.charMan = point name:(AI.name+"_charManager_Hlp") size:0.5 wirecolor:yellow pos:[0,0,AI.Zoffset]
		lockTransforms AI.charMan #mrs
		custAttributes.add AI.charMan CharManCA
		AI.charMan.AIName = AI.name
		AI.charMan.calibration = calib
		AI.charMan.creaType = AI.type
		AI.charMan.buttHeight = AI.charMan.pos.z
		append AI.charman.Helpers (nodeTransformMonitor node:AI.charMan)
		AI.charman.geo = nodeTransformMonitor node:AI.mesh
		
		-- Create AI orientation helper creation
		AI.orient = point name:(AI.name + "_AIorient_Hlp") size:0.4 box:true wirecolor:green pos:[0,0,AI.Zoffset]
		lockTransforms AI.orient #mrs
		append AI.charman.Helpers (nodeTransformMonitor node:AI.orient)
		
		RootCTRL = createRootCTRL calib
		AI.RootCTRL = nodeTransformMonitor node:(RootCTRL)
		
		-- freezing transforms
		FreezeTransforms #(AI.orient, AI.charman)				
		
		--- Torsos				
		for t = 1 to AI.torsos.count do
		(
			DATlayer.Rig.current = true			
			-- torso - rig			
			torso = AI.torsos[t]
			torsoType = AIstructure[AI.type].torsoType[t]
			torso.type = torsoType
			jointSt = torso.root
			
			-- Create torso helper object  (used for skinning)
			torsoHelper = Dummy name:(AI.name+"_Torso"+jointNames[jointSt]+"_Skin") boxsize:([0.6,0.6,0.6]*boneSizeMult[AI.type]) pos:AI.jointPos[jointSt]				
			-- orient the torso
			-- find the LookAt point first
			local torsoLookAtPoint = undefined
			case torsoType of (
				#root:(
					-- orient towards its child torso
					for i = 1 to torso.fixedCount do
					(
						nextTorsoRoot = AI.torsos[t+1].root
						if torso.fixedJoints[i] == nextTorsoRoot then (
							torsoLookAtPoint = AI.jointPos[nextTorsoRoot]							
							torsoLookAtPoint.y = torsoHelper.pos.y
						)

					)
					if torsoLookAtPoint == undefined then format "\\\\WARN: torsoLookAtPoint not calculated properly for torso %.\n" TorsoHelper.name
				)
				#abdomen:(
					-- orient towards pos of 'head' joint, but keep the same Y coordinate
					jointNames = AIstructure[AI.type].jointNames
					for i = 1 to jointNames.count do (
						if jointNames[i] == "head" then (
							torsoLookAtPoint = AI.jointPos[i]
							torsoLookAtPoint.y = torsoHelper.pos.y
						)
					)
				)
				#flat:(
					-- keep it flat - used by player arms types of "creatures" or creatures with 1 torso only		
					torsoLookAtPoint = torsoHelper.position + [0,0,1]
				)
				#arm:(
					-- torsoLookAtPoint = AI.jointPos[torso.fixedJoints[1]]
					-- orient to average pos of fixed bones
					print AIstructure[AI.type].jointNames[torso.root]
					jointsPosArray = #()
					for i = 1 to torso.fixedCount do (						
						-- print AIstructure[AI.type].jointNames[torso.fixedJoints[i]]
						append jointsPosArray AI.jointPos[torso.fixedJoints[i]]
					)
					torsoLookAtPoint = averageArray jointsPosArray		
				)
				default:(
					format "\\\\WARN: Torso type not recognized: %" torsoType
				)
			)
			torsoHelper.transform = SetTorsoMatrix torsoHelper torsoLookAtPoint
			
			---- 
			lockTransforms torsoHelper #mrs
			torso.hub = torsoHelper
			AI.charman.skinBones[JointSt] = (nodeTransformMonitor node:torsoHelper)
			-- format "\\\\DEBUG: skin bone: % - %\n" JointSt AI.charman.skinBones[JointSt]
			if torso.parent > 0 then 
			(
				torso.hub.parent = AI.torsos[torso.parent].hub
			)
			-- Create torso's rotation reference point
			rotRef = point name:(AI.name + "_" + jointNames[jointSt] + "_RefWorld") size:0.3 box:true wirecolor:orange
			lockTransforms rotRef #mrs
			rotRef.pos = AI.jointPos[JointSt]
			torso.rotRef = nodeTransformMonitor node:rotRef
			AI.charman.rotationRef[JointSt] = (nodeTransformMonitor node:rotRef)						
			-- Deal with unused fixed joints (pseudo limbs)
			for jntId in torso.unusedFixedJoints do (
				AI.jointPos[jntId]
				-- Create helper object  (used for skinning)
				pseudoLimbHelper = Dummy name:(AI.name+"_"+jointNames[jntId]+"_Skin") boxsize:([0.6,0.6,0.6]*boneSizeMult[AI.type]) pos:AI.jointPos[jntId]
				append torso.pseudoLimbs (nodeTransformMonitor node:pseudoLimbHelper)
				AI.charman.skinBones[jntId] = (nodeTransformMonitor node:pseudoLimbHelper)
			)		
			-- torso - controls
			DATlayer.CTRL.current = true
			MainCTRL = CircleControls (AI.name + "_" + jointNames[jointSt] + "_CTRL") calib ColorCode.SPINE
			-- scaling  and offset
			CTRLsize = (interpolate Rig.torsoStartSize Rig.torsoEndSize t AI.torsos.count )
			xf = xform name:"Offset and scale"
			xf.gizmo.scale = [CTRLsize, CTRLsize, CTRLsize]			
			xf.gizmo.position = case torsoType of (
				#arm:[0,0,0]
				default:[Rig.torsoOffsetX, 0, 0]
			)
			addModifier MainCTRL xf
			-- Torso Custom Attributes
			em = emptyModifier name:"Torso Controls"
			-- em = emptyModifier name:"Foot Controls"					
			custAttributes.add em TorsoCA
			em.torsoCtrl = nodeTransformMonitor node:MainCTRL
			if t == 1 then (
				em.defHeight = AI.Zoffset
				em.isMain = true
			)
			-- auxCtrl to be added later			
			addModifier MainCTRL em
			--
			MainCTRL.transform = torsoHelper.transform
			torso.ctrl = nodeTransformMonitor node:MainCTRL
			if t == 1 then
				AI.charman.buttctrl = nodeTransformMonitor node:MainCTRL
			AI.charman.fkctrls[JointSt] = (nodeTransformMonitor node:MainCTRL)
			
			--CTRLsize = (0.95 * calib * (interpolate Rig.torsoStartSize Rig.torsoEndSize t AI.torsos.count ))
			AuxCTRL = FlowerControls (AI.name + "_" + jointNames[jointSt] + "AuxCTRL") calib ColorCode.AUX
			-- scaling  and offset
			xf = xform name:"Offset and scale"
			xf.gizmo.scale = [CTRLsize, CTRLsize, CTRLsize] * 0.95
			xf.gizmo.position = case torsoType of (
				#arm:[0,0,0]
				default:[Rig.torsoOffsetX, 0, 0]
			)
			addModifier AuxCTRL xf
			auxem = emptyModifier() 			
			addModifier AuxCTRL auxem
			--
			AuxCTRL.transform = torsoHelper.transform
			torso.auxctrl = nodeTransformMonitor node:AuxCTRL
			em.auxCtrl = nodeTransformMonitor node:AuxCTRL	
			
			append AI.charman.otherctrls (nodeTransformMonitor node:AuxCTRL)		
					
		)
		
		PosConstrain AI.orient AI.torsos[1].hub
		PosConstrain AI.charman AI.charman.FKctrls[AI.torsos[1].root].node
				
		--- Limbs
		local last
		local lastBone, newBone, jointSt, jointEnd
		local lastJointVector
		local limbType
		local limb
		local side, y
		
		for l = 1 to AI.limbs.count do
		(
			limbType = AIstructure[AI.type].limbType[l]
					
			limb = AI.limbs[l]
			limb.FKctrls= #()
			limb.IKbones = #()
			limb.SKbones = #()
			limb.type = limbType
			-- Limb number is used only for creatures with more than 1 leg/hand on each side
			limbNumber = case limbType of (
				#spiderleg:
				(
					if l<7 then 
						(l-2) as string
					else 
						(l-6) as string
				)
				default:""
			)

			torsoNode = AI.torsos[limb.torso].hub
			lsegs = limb.segments
			-------- Bone setup --------
			boneVector = case limbType of (
								/* #leg:case i of (
									3:[0,0,1]
									default:(normalize [1,0,1])
									) */
								#leg:(normalize [1,0,1]) -- was [1,0,1]
								#head:[1,0,0]
								default:[0,0,1]
							)	
			limb.ikPos = case limbType of (			-- if and how many IK bones a limb needs
				#leg:3
				#hand:3
				#spiderleg:4
				#dogleg:4
				#droidarm:2
				#armwithclaw:3
				default:0
			)
			newIKbone = undefined
				
			-------- Guess side ---------
			Y = AI.jointPos[limb.segments[1]].y
			-- swap sides for spiders and overlord
			Y = Y * AIstructure[AI.type].swapSide
			
			if Y < 0 then 
			(
				side = "_R_" 
				limb.side = -1
			)
			else 
			(
				side = "_L_"
				limb.side = 1
			)			
			DATlayer.Rig.current = true
			-- Create limb Locator helper
			limbLocator = point name:(AI.name + side + (limb.type as string) + "_Locator") size:0.3 box:false cross:true wirecolor:green
			lockTransforms limbLocator #mrs
			limbLocator.pos = AI.jointPos[lsegs[1]]
			append AI.charman.helpers (nodeTransformMonitor node:limbLocator)
			limb.locator = limbLocator
			------- Create Skin bones chain, IK bones chain and Rot Reference helpers ------------			
			
			for i = 1 to limb.segmentsCount do
			(										
				jointName = trimLeft jointNames[lsegs[i]] "lr"
				-- Create rotation reference point
				rotRef = point name:(AI.name + side +jointName + "_RefWorld") size:0.25 box:true cross:false wirecolor:orange
				lockTransforms rotRef #mrs
				rotRef.pos = AI.jointPos[lsegs[i]]
				AI.charman.rotationRef[lsegs[i]] = (nodeTransformMonitor node:rotRef)
				
				-- Create bones
				jointSt = AI.jointPos[lsegs[i]]
				jointEnd = AI.jointPos[lsegs[i + 1]]
				newBone = BoneSys.createBone jointSt jointEnd boneVector
				jointName = trimLeft jointNames[lsegs[i]] "lr"
				newBone.name = AI.name + side + jointName + "_Skin"
				newBone.width = SKBoneWidth
				newBone.height = SKBoneWidth
				newBone.taper = 90
				newBone.showFrozenInGray = false
				
				AI.charman.skinBones[lsegs[i]] = nodeTransformMonitor node:newBone
				append limb.SKBones newBone
				-- parenting and freezing				
				if i ==1 then 
				(
					newBone.parent = torsoNode
					rotRef.parent = AI.charman.rotationRef[AI.jointParent[lsegs[i]]].node
				)
				else 
				(
					newBone.parent = AI.charman.skinBones[lsegs[i-1]].node
					rotRef.parent = AI.charman.rotationRef[lsegs[i-1]].node
				)
				FreezeTransforms #(rotRef, newBone)
				
				-- constraints
				OrientConstrain rotRef newBone true
				---
				--if i <= limb.ikPos  then		NOTE: we need to build the IK chain till the very end.
				if limb.ikPos > 0 then
				(
					newIKBone = BoneSys.createBone jointSt jointEnd boneVector
					newIKBone.name = AI.name + side + jointName + "_IK"
					newIKBone.width = IKBoneWidth
					newIKBone.height = IKBoneWidth
					newIKBone.taper = 50
					newIKBone.wirecolor = rigMats[ColorCode.IKBONE].color
					newIKBone.showFrozenInGray = false
										
					if i == 1 then 
						newIKBone.parent = torsoNode
					else 
						newIKBone.parent = AI.charman.IKBones[lsegs[i-1]].node
					FreezeTransforms newIKbone
					AI.charman.IKBones[lsegs[i]] = nodeTransformMonitor node:newIKBone
					append limb.IKBones newIKbone
				)
			)
			endBoneNumber = limb.segmentsCount+1
			endBone = createEndBone newBone 
			jointName = trimLeft AIstructure[AI.type].jointNames[lsegs[endBoneNumber]] "lr"
			endBone.name = AI.name + side + jointName + "_SkinEnd"
			FreezeTransforms endBone
			AI.charman.skinBones[lsegs[endBoneNumber]] = nodeTransformMonitor node:endBone
			append limb.SKBones endBone
					

			--
			if limb.ikPos > 0 then
			(
				-- additional reference point helper to mark the tip of the wristless/footless limbs in the FK mode
				-- used for snapping IK to FK
				if (findItem #(#spiderleg, #hand, #droidarm, #armwithclaw) limb.type) > 0 then (				
					fkRefPoint = point name:(AI.name + side + jointName + "_FKtoIKReference") size:0.2 box:true cross:true wirecolor:green
					fkRefPoint.position = limb.SKBones[limb.ikPos].position
					append AI.charman.helpers (nodeTransformMonitor node:fkRefPoint)
					limb.fkRef = fkRefPoint
				)
				
				endBoneNumber = limb.segmentsCount + 1
				endBone = createEndBone newIKBone 
				jointName = trimLeft AIstructure[AI.type].jointNames[lsegs[endBoneNumber]] "lr"
				endBone.name = AI.name + side + jointName + "_IKEnd"
				AI.charman.IKBones[lsegs[endBoneNumber]] = nodeTransformMonitor node:endBone
				append limb.IKBones endBone
			)
			
			------- FK chain ------------
			DATlayer.CTRL.current = true
			for i = 1 to limb.segmentsCount do
			(
				thisJointNo = lsegs[i]
				jointName = trimLeft jointNames[thisJointNo] "lr"
				CTRLsize = (this.getArmFKsize i limb.segmentsCount ) * FKcontrolWidth
				newCTRL = RoundControls (AI.name + side + jointName + "_FKCTRL") CTRLsize ColorCode.FK
				newCTRL.transform = AI.charman.skinBones[thisJointNo].node.transform				
				xf = xform name:"Offset and scale"
				CTRLscale = case limb.type of
				(
					#hand:interpolate Rig.armFKStartSize Rig.armFKEndSize i limb.segmentsCount
					#armwithclaw:interpolate Rig.armFKStartSize Rig.armFKEndSize i limb.segmentsCount
					#droidarm:interpolate Rig.armFKStartSize Rig.armFKEndSize i limb.segmentsCount
					#generic:interpolate Rig.genFKStartSize Rig.genFKEndSize i limb.segmentsCount
					#head:Rig.headSize
					#leg:interpolate Rig.legFKStartSize Rig.legFKEndSize i limb.segmentsCount					
					#spiderleg:interpolate Rig.legFKStartSize Rig.legFKEndSize i limb.segmentsCount
					default:interpolate Rig.genFKStartSize Rig.genFKEndSize i limb.segmentsCount
				)
				xf.gizmo.scale = [CTRLscale, CTRLscale, CTRLscale]
				CTRLrot = case limb.type of (
					#head:(
						if Rig.headStraight == true then (													
							-- rot = newCTRL.rotation as eulerAngles
							-- newRot = eulerAngles 0 0 (-rot.x)
							Vx = newCTRL.transform.row1
							Vstraight = [Vx.x, 0, Vx.z]
							theAngle = acos(dot (normalize Vx) (normalize Vstraight))
							eulerAngles 0 0 theAngle
						) else (
							eulerAngles 0 0 0
						)
					)
					default:eulerAngles 0 0 0
				)
				xf.gizmo.rotation = CTRLrot
				CTRLoffset = case limb.type of
				(
					#head:[Rig.headOffsetX, Rig.headOffsetY, Rig.headOffsetZ]
					default:[0,0,0]
				)
				xf.gizmo.position = CTRLoffset				
				addModifier newCTRL xf
				-- em = emptyModifier()
				-- addModifier newCTRL em
				-- freezing and parenting				
				if i == 1 then
				(
					torsoFK = AI.torsos[limb.torso].root
					newCTRL.parent = AI.charman.fkctrls[torsoFK].node
				)
				else 
					newCTRL.parent = AI.charman.fkctrls[lsegs[i-1]].node
				FreezeTransforms newCTRL
				AI.charman.fkctrls[lsegs[i]] = nodeTransformMonitor node:newCTRL 
				append limb.fkctrls newCTRL
				lockTransforms newCTRL #ms		
			)
			------- IK controls and helpers ----------	
			if doIK==true then (
				DATlayer.CTRL.current = true
				case limbType of
				(
					#generic:SetupGenericCTRL &limb side
					#head:SetupGenericCTRL &limb side
					#leg:SetupLegCTRL &limb side
					#dogleg:SetupLegCTRL &limb side
					#hand:SetupArmCTRL &limb side
					#armwithclaw:SetupArmCTRL &limb side 
					#droidarm:SetupArmCTRL &limb side					
					#spiderleg:SetupSpiderlegCTRL &limb side limbNumber
				)			
			)
			
		)		
		deselect $*
	),
	
	-- Constraints - always follow this order:
	-- 1) Parenting,  2) Freezing,  3) Orient Constraint,  5) Wiring
	
	fn SetupArmConstraints &limb =
	(
		-- parenting
		limb.fkRef.parent = limb.FKctrls[limb.ikPos-1]
		limb.ikctrl.parent = AI.RootCTRL.node	
		--freezing
		FreezeTransforms limb.ikctrl
		FreezeTransforms limb.handIK
		FreezeTransforms limb.fkRef
		
		--constraints
		PosConstrain limb.handIK limb.ikctrl
		for i = 1 to limb.fkctrls.count do
		(
			if i != limb.ikPos then
				OrientConstrain limb.skbones[i] #(limb.fkctrls[i], limb.ikbones[i]) false
		)
		OrientConstrain limb.skbones[limb.ikPos] #(limb.fkctrls[limb.ikPos], limb.ikctrl) false
		OrientConstrain limb.ikbones[limb.ikPos] limb.ikctrl false
		-- controls rigging
		UIctrl = limb.ikctrl.modifiers[1]
		paramWire.connect UIctrl.ArmCTRL[#swivel] limb.handIK.transform.controller[#swivel_angle] ("swivel * (" + (limb.side as string) + ")")
		if limb.type == #armwithclaw then (
			paramWire.connect UIctrl.ArmCTRL[#clawAngleX] limb.ikbones[4].rotation.controller[2].controller[#X_Rotation] ("degToRad clawAngleX")
			paramWire.connect UIctrl.ArmCTRL[#clawAngleY] limb.ikbones[4].rotation.controller[2].controller[#Y_Rotation] ("degToRad clawAngleY")
			paramWire.connect UIctrl.ArmCTRL[#clawAngleZ] limb.ikbones[4].rotation.controller[2].controller[#Z_Rotation] ("degToRad clawAngleZ")
		)
		for i = 1 to (limb.skbones.count-1) do
		( 	
			paramWire.connect UIctrl.ArmCTRL[#fkikblend] limb.skbones[i].rotation.controller[3][1] "100 - (fkikblend * 100.0)"
			paramWire.connect UIctrl.ArmCTRL[#fkikblend] limb.skbones[i].rotation.controller[3][2] "fkikblend * 100.0"
		)					
	),

	fn SetupLegConstraints &limb = 
	(
		for i = 2 to 5 do
		(
			limb.footHelpers[i].parent = limb.footHelpers[i-1]
		)
		limb.legIK.parent = limb.footHelpers[5]
		limb.footIK.parent = limb.footHelpers[5]
		limb.swivelTarget.parent = limb.footHelpers[5]
		limb.footIK.transform.controller.VHTarget = limb.swivelTarget
		limb.footIK.transform.controller.useVHTarget = true
		-- auto correction of foot IK bones 
		-- without this, the foot would have random rotation around the X (lenght) axis.		
		error = 0.0001
		maxIterations = 100					
		fkM = limb.fkctrls[limb.ikPos].transform
		initialTargetOffset = transMatrix [0,-0.25,0]	
		diff = 100.0
		lastDiff = 1000.0
		iterations = 0
		step = 40 as float
		angl = 0.0						
		while (abs(diff) > error) and (iterations < maxIterations) do
		(
			iterations += 1
			rotM = eulerAngles angl 0 0 as Matrix3
			limb.swivelTarget.transform = initialTargetOffset * rotM * fkM
			
			ikM = limb.ikbones[limb.ikPos].transform
			lastDiff = abs(diff)
			diff = ikM[2][2] - fkM[2][2]
			if abs(diff) > lastDiff then step = -(step / 2)
			angl = angl + step	
		)
		--
		limb.ikctrl.parent = AI.RootCTRL.node
		-- freezing
		FreezeTransforms limb.ikctrl
		FreezeTransforms limb.footHelpers
		FreezeTransforms #(limb.legIK, limb.footIK )					
		-- constraints			
		PosConstrain limb.footHelpers[1] limb.ikctrl
		OrientConstrain limb.footHelpers[1] limb.ikctrl false
		for i = 1 to limb.fkctrls.count do
		(
			OrientConstrain limb.skbones[i] #(limb.fkctrls[i], limb.ikbones[i]) false	
		)					
		-- controls wiring
		UIctrl = limb.ikctrl.modifiers[1]
		paramWire.connect UIctrl.FootCTRL[#swivel] limb.legIK.transform.controller[#swivel_angle] ("-2 * swivel * (" + (limb.side as string) + ")")
		for i = 1 to (limb.skbones.count-1) do
		( 						
			paramWire.connect UIctrl.FootCTRL[#fkikblend] limb.skbones[i].rotation.controller[3][1] "100 - (fkikblend * 100.0)"
			paramWire.connect UIctrl.FootCTRL[#fkikblend] limb.skbones[i].rotation.controller[3][2] "fkikblend * 100.0"
		)
		paramWire.connect UIctrl.FootCTRL[#footLift] limb.footHelpers[2].rotation.controller[2][2] "((footLift - abs(footLift))/2) * 1.5"
		paramWire.connect UIctrl.FootCTRL[#footLift] limb.footHelpers[3].rotation.controller[2][2] "((footLift + abs(footLift))/2) * 1.5"
		paramWire.connect UIctrl.FootCTRL[#footBanking] limb.footHelpers[4].rotation.controller[2][1] ("-((footBanking + abs(footBanking))/2) * " + (limb.side as string))
		paramWire.connect UIctrl.FootCTRL[#footBanking] limb.footHelpers[5].rotation.controller[2][1] ("-((footBanking - abs(footBanking))/2) * " + (limb.side as string))
		paramWire.connect UIctrl.FootCTRL[#heelPivot] limb.footHelpers[2].rotation.controller[2][3] ("heelPivot * " + (limb.side as string))
		paramWire.connect UIctrl.FootCTRL[#toesPivot] limb.footHelpers[3].rotation.controller[2][3] ("-toesPivot * " + (limb.side as string))
	),

	fn SetupSpiderlegConstraints &limb =
	(	
		-- parenting
		limb.fkRef.parent = limb.FKctrls[3]
		limb.ikctrl.parent = AI.RootCTRL.node	
		--freezing
		FreezeTransforms limb.ikctrl
		FreezeTransforms limb.footIK
		FreezeTransforms limb.fkRef					
		--constraints
		PosConstrain limb.footIK limb.ikctrl
		for i = 1 to 3 do
		(
			OrientConstrain limb.skbones[i] #(limb.fkctrls[i], limb.ikbones[i]) false
		)					
		-- controls rigging
		UIctrl = limb.ikctrl.modifiers[1]
		paramWire.connect UIctrl.SpiderFootCTRL[#swivel] limb.footIK.transform.controller[#swivel_angle] ("swivel * (" + (limb.side as string) + ")")
		for i = 1 to 3 do
		( 						
			paramWire.connect UIctrl.SpiderFootCTRL[#fkikblend] limb.skbones[i].rotation.controller[3][1] "100 - (fkikblend * 100.0)"
			paramWire.connect UIctrl.SpiderFootCTRL[#fkikblend] limb.skbones[i].rotation.controller[3][2] "fkikblend * 100.0"
		)
	),

	fn CreateRigConstraints =
	(
		-- constraints
		OrientConstrain AI.orient AI.RootCTRL.node false	
		
		-- torsos 
		for t = 1 to AI.torsos.count do
		(
			torso = AI.torsos[t]
			MainCTRL = torso.ctrl.node
			AuxCTRL = torso.auxctrl.node
			torsoHelper = torso.hub
			rotRef = torso.rotRef.node
			-- parenting and locking
			AuxCTRL.parent = MainCTRL			
			lockTransforms AuxCTRL #ms
			if torso.parent>0 then
			(
				MainCTRL.parent = AI.torsos[torso.parent].ctrl.node
				lockTransforms MainCTRL #ms
				rotRef.parent = AI.torsos[torso.parent].rotRef.node		-- <-- parenting abdomen rotation reference to butt's rotation reference - FIX! (Sept. 2017)
			)
			else
			(
				MainCTRL.parent = AI.RootCTRL.node
				lockTransforms MainCTRL #s
				rotRef.parent = AI.orient
			)			
			for pseudo in torso.pseudoLimbs do (
				pseudo.node.parent = MainCTRL  				
			)
			
			-- freezing
			FreezeTransforms #(torsoHelper, MainCTRL, AuxCTRL, rotRef)
			FreezeTransforms (for fixed in torso.pseudoLimbs collect fixed.node)
			-- constraints
			OrientConstrain torso.Hub AuxCTRL false			
			OrientConstrain rotRef torsoHelper true
			if torso.parent == 0 then PosConstrain torsoHelper MainCTRL
		)
		
		-- limbs
		for l = 1 to AI.limbs.count do
		(
			limb = AI.limbs[l]
			limb.locator.parent = AI.torsos[limb.torso].hub
			FreezeTransforms #(limb.locator, limb.swivelTarget)
			PosConstrain limb.fkctrls[1] limb.locator
			-- IK setup
			if doIK==true then
			case limb.type of
			(
				#leg:SetupLegConstraints &limb
				#dogleg:SetupLegConstraints &limb
				#hand:SetupArmConstraints &limb
				#droidarm:SetupArmConstraints &limb
				#armwithclaw:SetupArmConstraints &limb
				#spiderleg:SetupSpiderlegConstraints &limb
				#head:
				(
					OrientConstrain limb.skbones[1] limb.fkctrls[1] false
				)
				#generic:
				(
					for i = 1 to limb.skbones.count do
						OrientConstrain limb.skbones[i] limb.fkctrls[i] false
				)
			)
		)
		deselect $*
		-- Final state of layers
		DATlayer.CTRL.current = true
		DATlayer.CTRL.isFrozen = false
		DATlayer.Rig.isFrozen = true -- will be true
		DATlayer.Mesh.isFrozen = true -- will be true
		DATlayer.Rig.isHidden = true
	),
		
	fn createRigDialog =
	(		
		local tryLoadingPresets = #failed
		tryLoadingPresets = Rig.loadPresets AI.rawname
		if (DATImport.ch_autoRig.checked) == true then
		(
			if tryLoadingPresets == #OK then
			(
				createRig()
				createRigConstraints()
			)
		)
		
		if ((DATImport.ch_autoRig.checked == false) or (tryLoadingPresets == #failed)) then
		(
			createDialog DATRig width:320 
		)
	),
	

	---------------------------------------------------------------------------------------------------------------
	--
	--               M E S H 
	--
	---------------------------------------------------------------------------------------------------------------

	-- debug function
	fn JointInfo =
	(
		for i=1 to AI.jointsNumber do
		(
			format "i:% \tname:%   \tposition:%     \tparent:%    \tobject:% \n" i AIstructure[AI.type].jointNames[i] AI.jointPos[i] AI.jointParent[i] AI.skinBones[i]
		)
	),

	-- debug function
	fn PrintVertices =
	(
		for v = 1 to BIN.numVertices do
		(
			
			format "% - XYZ: %, UV: %\n" v (meshop.GetVert AI.mesh v) (meshop.getMapVert AI.mesh 1 v)
		)
	),

	--  skinning debug function
	fn SelectFacesByVolume Vol = 
	(
	-- 	Vol = 1
		polys = #()
		stP = AI.volumes[Vol].startPoly+1
		nP = AI.volumes[Vol].numPolys
		polys  = for i = stP to (stP+np-1) collect i
		setFaceSelection AI.mesh polys
		format "Joint name: %   Type: %\n" JointMaps[AI.type][(AI.volumes[Vol].joint)] AI.volumes[Vol].type
	),

	-- skinning debug function
	fn SelectVerticesByVolume Vol = 
	(
	-- 	Vol = 1
		verts = #()
		stP = AI.volumes[Vol].startVert+1
		nP = AI.volumes[Vol].numVerts
		verts = for i = stP to (stP+np-1) collect i
		setVertSelection AI.mesh verts
		format "Joint name: %   Type: %\n" JointMaps[AI.type][(AI.volumes[Vol].joint)] AI.volumes[Vol].type
	),

	fn StandardMat matNo =
	(
		local newMat, txt, btmp, trans, opct
		txt = AI.mats[matNo].textureName
		filename = DATconfig.Txt16() + "\\" + txt
		if doesFileExist filename != true then (
			-- let's see if the texture lives in /txt/ folder by any chance
			filename8 = DATconfig.Txt() + "\\" + txt
			if doesFileExist filename8 then filename = filename8
		)
		btmp = bitmapTexture filename:filename
		newMat = Standard name:(substring txt 1 (txt.count-4)) diffusemap:btmp
		newMat.selfIllumAmount = AI.mats[matNo].illum * 100
		trans = AI.mats[matNo].trans
		if trans == 0 then opct = 100
		if trans == 1 then opct = 0
		if trans>0 and trans<1 then opct = 100-(100*trans)
		newMat.opacity = opct	
		showTextureMap newMat newMat.diffusemap true
		
		newMat
	),

	fn CreateMaterial =
	(
		local m
		AI.mats = #()
		-- Read materials from BIN file
		BINfile = fopen BIN.fileName "rb"  -- opens BIN file 	
		for m = 1 to BIN.numMats do
		(
			FSeek BINfile (BIN.offset_mats+(BIN.MatChunkSize[BIN.version]*(m-1))) #seek_set		-- material chunk size is different for BIN files version 1 and 2
			AI.mats[m] = MatStruct textureName:(ReadBString BINfile 16)
			if BIN.version == 2 then
			(
				FSeek BINfile 4 #seek_cur	-- skip flag reading (actually I might read them, if it turns out to be necessary)
				AI.mats[m].trans = ReadFloat BINfile		-- transparency
				AI.mats[m].illum = ReadFloat BINfile			-- self illumination 
			)
			else
			(
				AI.mats[m].trans = 0
				AI.mats[m].illum = 0
			)
		)
		FClose BINfile
		-- Create Materials and apply to the mesh
		if BIN.numMats > 1 then
		(
			newMat = Multimaterial name:(AI.name+"_MAT") numsubs:BIN.numMats
			for m = 1 to BIN.numMats do
			(						
				newMat[m] = StandardMat m
			)		
		)
		else 	newMat = StandardMat 1
		
		AI.mesh.material = newMat
	),
	
	-- loads BIN file and creates character mesh
	fn createMesh =
	(
		local result = false	
		local stVert, nVerts
		
		if doesFileExist BIN.fileName then
		(
			local BINfile = fopen BIN.fileName "rb"  -- opens BIN file 
			-- Header --
			if (ReadBString BINfile 4) == "LGMM" then -- sanity check. 
			(
				BIN.version = ReadLong BINfile #unsigned	-- 1 for Thief 1/Gold  or 2 for Thief 2
				
				-- Mesh Header
				for i = 1 to 3 do	ReadLong BINfile #unsigned		-- always 0
				ReadByte BINfile #unsigned								-- also 0
				BIN.numMappers = ReadByte BINfile #unsigned			
				BIN.numMats = ReadByte BINfile #unsigned
				BIN.numVolumes = ReadByte BINfile #unsigned
				BIN.numPolys = ReadShort BINfile #unsigned
				BIN.numVertices = ReadShort BINfile #unsigned
				BIN.numStretchy = ReadLong BINfile #unsigned
				
				BIN.offset_volumes_remap = ReadLong BINfile #unsigned -- ignore the volumes_remap chunk, as it seems to be useless (so far...)
				BIN.offset_mappers = ReadLong BINfile #unsigned
				BIN.offset_mats = ReadLong BINfile #unsigned
				BIN.offset_volumes = ReadLong BINfile #unsigned
				BIN.offset_poly = ReadLong BINfile #unsigned
				BIN.offset_norm = ReadLong BINfile #unsigned
				BIN.offset_vert = ReadLong BINfile #unsigned
				BIN.offset_uvmap = ReadLong BINfile #unsigned
				BIN.offset_blends = ReadLong BINfile #unsigned
				BIN.offset_U9 = ReadLong BINfile #unsigned				-- this can be ignored too - don't know what it is (always 0)
				
				-- Reading volumes information  --
				-- read mappersStruct first	
				
				for v =1 to BIN.numMappers do
				(
					Fseek BINfile (BIN.offset_mappers+4+(v-1)*20) #seek_set
					AI.mappers[v] = MapperStruct joint: ((ReadByte BINfile #unsigned) + 1)  -- adding 1 to the index for the Max Script arrays
					Fseek BINfile 2 #seek_cur
					AI.mappers[v].type = (ReadByte BINfile)
				)
				-- volumes now:
				Fseek BINfile BIN.offset_volumes #seek_set
				for v =1 to BIN.numVolumes do 
				(
					AI.volumes[v] = VolumeStruct numPolys: (ReadShort BINfile) startPoly: (ReadShort BINfile) \
					numVerts: (ReadShort BINfile) startVert: (ReadShort BINfile) startBlend: (ReadShort BINfile)
					Fseek BINfile 4 #seek_cur	-- skipping unknown values
					AI.volumes[v].mapperID = ((ReadShort BINfile) + 1) -- Maxscript arrays... +1
					AI.volumes[v].joint = AI.mappers[AI.volumes[v].mapperID].joint  -- copy value from AI.mappers to AI.volumes - for farther ease of use
					AI.volumes[v].type = AI.mappers[AI.volumes[v].mapperID].type  -- copy value from AI.mappers to AI.volumes - for farther ease of use				 
				)					
				-- 	for v in AI.volumes do print v
				
				-- Create a mesh object 			
				undo on
				(
					DATlayer.Mesh.current = true
					AI.mesh = mesh numverts:BIN.numVertices numpolys:BIN.numPolys			-- creates a mesh object				
					setMesh AI.mesh numverts:BIN.numVertices numfaces:BIN.numPolys
					AI.mesh.name = AI.name + "_Mesh"
					AI.mesh.showFrozenInGray = false
					AI.mesh.wirecolor = black
					meshop.setMapSupport AI.mesh 1 true						-- these are the UV map things
					meshop.setNumMapVerts AI.mesh 1 BIN.numVertices
					meshop.setNumMapFaces AI.mesh 1 BIN.numPolys
					format "\\\\INFO: Mesh triangles: %\n" (meshop.getNumFaces AI.mesh)					
					undo off
					(					
						-- We're going to go by volumes, not by vertices, as vertex position is volume/joint relative
						for i = 1 to BIN.numVolumes do
						(
							stVert = AI.volumes[i].startVert
							nVerts = AI.volumes[i].numVerts						
							if nVerts>0 then
							(
								VolumeOffset = AI.jointPosCAL[AI.volumes[i].joint] -- all vertices coordinates are relative to this one
				-- 							format "% % %\n" i AI.volumes[i].joint VolumeOffset 
								
								AI.volumes[i].verts = #{}
								Fseek BINfile (BIN.offset_vert+stVert*12) #seek_set
								for v=stVert+1 to stVert+nVerts do
								(
									append AI.volumes[i].verts v -- adds vertex number to the list
									newVert = [ReadFloat  BINfile, ReadFloat BINfile, ReadFloat BINfile] -- relative vert position
				-- 								format "% %\n" v newVert
									meshop.setvert AI.mesh v (VolumeOffset+newVert)
								)
								-- UVs --							
								FSeek BINfile (BIN.offset_uvmap+stVert*12) #seek_set
								for v=stVert+1 to stVert+nVerts do
								(
									newMapVert = [ReadFloat  BINfile, (1-ReadFloat BINfile), 0] 
									-- format "% %\n" v newMapVert
									meshop.setMapVert AI.mesh 1 v newMapVert
									FSeek BINfile 4 #seek_cur
								)
							)
						)
						-- polygons					
						polycount = meshop.getNumFaces AI.mesh
							meshop.setMapSupport AI.mesh 1 true
						Fseek BINfile BIN.offset_poly #seek_set
						for i = 1/* +polycount */ to BIN.numPolys/* +polycount */ do
						(
							verts=#()
							verts[1]=(ReadShort BINfile #unsigned)+1
							verts[2]=(ReadShort BINfile #unsigned)+1
							verts[3]=(ReadShort BINfile #unsigned)+1
							matID = (ReadShort BINfile #unsigned)+1
							setFace AI.mesh i [verts[1],verts[2],verts[3]] 
							setFaceMatID AI.mesh i matID
							setFaceSmoothGroup AI.mesh i 1						
							setEdgeVis AI.mesh i 1 true
							setEdgeVis AI.mesh i 2 true
							setEdgeVis AI.mesh i 3 true
							meshop.setMapFace AI.mesh 1 (i) [verts[1],verts[2],verts[3]] -- UV face
							Fseek BINfile 8 #seek_cur
						)				
						-- Adding polygons and blends arrays to the Volumes info
						-- vertices are added already
						for v = 1 to BIN.numVolumes do
						(
							Vol = AI.volumes[v]
							StPoly = Vol.startPoly
							numPoly = Vol.numPolys
							polys = #{}
							if numPoly>0 then
								for p = StPoly+1 to StPoly+numPoly do
									append polys p
							Vol.polys = polys
							
							blends = #()
							if Vol.type == 1 then -- stretchy
							(
								StBlend = Vol.startBlend
								numBlends = Vol.numVerts
								if numBlends>0 then 
								(
									Fseek BINfile (BIN.offset_blends+stBlend*4) #seek_set
									for b = StBlend+1 to StBlend+numBlends do
									(									
										append blends (ReadFloat BINfile)
									)
								)
								
							)
							Vol.blends = blends
						)
					
						
					)
					update AI.mesh					
					-- normals - NOT SURE IF IT MAKES ANY SENSE TO SET THEM UP.
					-- They seem to be identical to the one that Max calculates
					-- Better solution seems to be merging overlapping vertices.
					/*
					Fseek BINfile BIN.offset_norm #seek_set
					for i = 1 to BIN.numPolys do
					(
						currNorm = (getFaceNormal AI.mesh i)
						newNorm = [ReadFloat  BINfile, ReadFloat BINfile, ReadFloat BINfile]
						format "current: % 	new: %\n" currNorm newNorm
						setFaceNormal AI.mesh i newNorm
					)
					*/

				)
				-- 
				
				result = true
			)
			else 
			(
				messageBox "This is not a character BIN file!"
			)
			
			FClose BINfile
			
			CreateMaterial()
		)
		
		assert result message:"ERR:\\\\ BIN file does not exist.\nERR:\\\\ Aborting"
			
		result
	),

	-- This checks the creature type based on number of joints, torsos and limbs.
	fn GuessTheCreatureType = 
	(
		CrType = 0
		for i = 1 to DC.number do
		(
			if #(CAL.numJoints, CAL.numCALtorsos, CAL.numLimbs) as string == #(AIstructure[i].jointsNo, AIstructure[i].torsosNo, AIstructure[i].limbsNo) as string then 
			(
				CrType = i			
			)
		)	
		CrType
	),

	-- This places character on the ground, based on its bounding box (seems to be the way dark engine does it, I think...)
	--  2013-09-08 - Nope, the Z height is calculated like this: 3,375 * calibration (last value in CAL file) - found in Thief source
	--  but it's not as accurate (for unknown reason), so let's stick to the bounding box method
	fn FloorCharacter =
	(
		AI.jointsNumber = AIstructure[AI.type].jointsNo
		in coordsys world
		(
			local BBox = nodeLocalBoundingBox AI.mesh    
			AI.Zoffset = -(BBox[1].z)	
			move AI.mesh [0,0,AI.Zoffset]
 			for i = 1 to AI.jointsNumber do
			(
				AI.jointPos[i] = AI.jointPos[i] + [0,0,AI.Zoffset]
				AI.jointPosCAL[i] = AI.jointPosCAL[i] + [0,0,AI.Zoffset]
			)
		)		
	),

	fn ApplySkinWeights =
	(
		-- mesh volume types
		local Vrigid = 0
		local Vstretchy = 1
		
		local AIskin = skin()		-- Create new Skin modifier
		AIskin.filter_vertices = true
		AIskin.bone_limit = 2   -- vertices can blend between two bones only, so it's good to set that limit here, in case we modify weights
		AIskin.weightAllVertices = false
		
		setCommandPanelTaskMode mode:#modify
		addModifier AI.mesh AIskin
		select AI.mesh  -- apparently mesh must be selected for skinning to work...
				
		-- collecting skinnable joints numbers
		-- taken from the Volumes info from BIN file
		skinJoints = #()
		for i = 1 to AI.volumes.count do 
		(
			joint = AI.volumes[i].joint 
			appendIfUnique skinJoints joint
			parent = AI.jointParent[joint]
			if parent != undefined then appendIfUnique skinJoints parent 
		)
		
		toBeRemoved = #()
		for j in skinJoints do 
		(
			skBone = AI.charman.skinBones[j]
			if skBone != undefined then (
				skinops.addBone AIskin AI.charman.skinBones[j].node 1 -- adding bones to the Skin modifier
				-- format "\\\\DEBUG: % - Added skin bone %\n" j skBone.node
			) else (
				format "\\\\ERROR: % - %\n" j skBone				
				append toBeRemoved  j
			)
		)
		-- remove joints from skinJoints array, that were not added to Skin modifier 
		if toBeRemoved.count > 0 then (
			for i = toBeRemoved.count to 1 by -1 do (
				deleteItem skinJoints i
			)
		)
			
		completeRedraw () -- Must be here, otherwise Skin operations won't work!
		-- applying bone weights to the vertices
		for v = 1 to AI.volumes.count do
		(
			Vol = AI.volumes[v]
			stVert = Vol.startVert
			nVerts = Vol.numVerts	
			vBone = findItem skinJoints Vol.joint
			if vBone == 0 then continue

			if Vol.type == Vrigid then
			(			
				Weight = 1.0
				for vt = stVert + 1 to stVert + nVerts do			
					skinOps.ReplaceVertexWeights AIskin vt vBone Weight
			)
			else
			(
				for vt = stVert + 1 to stVert + nVerts do			
				(
	-- 				format "Volume: %   Vertex: %   SkinBoneIndex: %\n"  v vt vBone
					if Vol.blends.count > 0 then
					(
						Weights = #()
						vBones = #()
						vBones[1] = vBone
						Weights[1] = Vol.blends[vt-stVert]
						jointParent = findItem skinJoints AI.jointParent[Vol.joint]
						if jointParent > 0 then 
						(
							vBones[2] = jointParent
							Weights[2] = 1.0 - Weights[1]
						)
						skinOps.ReplaceVertexWeights AIskin vt vBones Weights	-- main bone				
					)
				)
			) 
			  
		)		
		deselect $*
	),

	fn MergeMeshVertices = 
	(
		-- Adds an Edit Poly modifier on top of the Skin modifier
		-- and merges overlapping vertices (=> with tolerance 0.001)
		msh = AI.mesh
		select msh
		max modify mode
		edpoly = Edit_Poly name:"Merge Overlapping Verts"
		addModifier msh edpoly
		subObjectLevel = 1
		edPoly.weldVertexThreshold = 0.001
		numVerts = edPoly.getnumVertices()
		edPoly.currentOperation = 22
		edPoly.SetSelection #Vertex #{1..numVerts}
		edPoly.Commit()
		subObjectLevel = 0
	),

	fn createCharacter rawAIName doRig doLGSRig =
	(	
		result = false
		max create mode	-- switch to Create panel		
		AI = CharacterStruct()
		AI.rawName = rawAIName		
		local AInumber = 0
		do
		(
			AInumber = AInumber + 1
			if AInumber < 10 then AI.name = rawAIName + "_0" + AInumber as string
				else	AI.name = rawAIName + "_" + AInumber as string
			queryNode = getNodeByName (AI.name + "_charManager_Hlp")
		)
		while isValidNode queryNode == true
		
		undo "Import a Character" on
		(
			createLayers()					-- create 3dsmax layers (rig, mesh, Ctrls)
			cleanLayers()						-- optional
			
			readCALfile CAL.FileName				
			
			AI.type = GuessTheCreatureType()
			
			if AI.type > 0 then
			(	
				format "\\\\INFO: Creature Type: %\n" creaTypeNames[AI.type]
				
				calculateJointsPositions()
				createMesh()
				floorCharacter()	-- calculates ZOffset							
				if doRig then (	
					createRigDialog()			
					ApplySkinWeights()
				)
				MergeMeshVertices()
				if doLGSRig then AI.createLGSjoints()			
				
				result = true
				select AI.rootctrl.node
			)
			else messageBox "ERROR: Sorry, creature type not recognized..."
		)
		result
	),
	
	fn scaleShape shp scl =
	(
		verts = shp[4][2][8]
		for i = 1 to (numKnots shp) do
		(
			trackNo = (i-1) * 3 + 2
			current = verts[trackNo].value 
			verts[trackNo].value = current * scl
		)
		updateShape shp
	),
		
	fn changeRigControlsThickness thickness =
	(
		CM = AI.charman
		for ctrl in CM.fkctrls where ctrl!=undefined do ctrl.node.thickness = thickness
		for ctrl in CM.ikctrls where ctrl!=undefined do ctrl.node.thickness = thickness
		for ctrl in CM.otherctrls where ctrl!=undefined do ctrl.node.thickness = thickness
		CM.rootctrl.node.thickness = thickness
	),

	fn GetSkinModifier obj = (
		skinmod = undefined
		for m in obj.modifiers do (
			if (ClassOf m) == Skin then 
				skinmod = m
		)
		return skinmod
	),

	-- Exports BIN and CAL files. Character needs to be zeroed out
	fn ExportBINandCAL skinMesh creature outpath filename export_geo:true export_rig:false = 
	(	
		-- Get Skin modifier
		skinmod = GetSkinModifier skinMesh
		if skinmod == undefined then 
		(
			messageBox "ERROR: this mesh is not skinned!"
			return false
		)

		-- Select Skin modifier in the Modify Panel (really backwards, isn't it?)
		max modify mode
		modPanel.setCurrentObject skinmod node:geo
		numBones = skinOps.getNumberBones skinmod
		for i=1 to numBones do (
			print (skinOps.getBoneName skinmod i 0)
		)
			
		-- Export CAL first, as this gives offsets for vertices
		CAL = CALStruct()
		CAL.filename = output + "/" + filename + ".cal"
		CAL.Save()

		-- Export BIN next
		BIN = BINStruct()
		BIN.filename = outpath + "/" + filename + ".bin"
		BINfile = fopen BIN.fileName "wb"  -- opens BIN file
		
		FClose BINfile		

		return true
	)
	
	
	
)


--------------------------------------------------------------------------------------------

global DAT = DarkAnimTools()					-- main struct with tools functions


