/* -------------------------------------------
/* 			Dark Animation Tools
/* 					Header
/* -------------------------------------------
/* author: Juliusz Kaczmarek
/* ver. 0.01
/* Nov. 2012
/* ver. 1.1 - Sept. 2017
/*
/* tools for importing and exporting
/* rigged characters and their motions
/* from and to dark engine games. 
/*
/* thanks for help on dark engine files structure
/* to Volca, Shadowspawn, Weyoun, Telliamed
/* ------------------------------------------
*/

format " - Loading... Basic definitions\n"

-- axis order
struct AxisOrderEnum (
	XYZ = 1,
	XZY = 2,
	YZX = 3,
	YXZ = 4,
	ZXY = 5,
	ZYX = 6
)
global AxisOrder = AxisOrderEnum()

-- Path configuration
struct pathPreset (
	name = "newPreset",
	game = "Thief 2",
	isDefault = false,
	Root = "",
	Mesh = "",
	Txt16 = "",
	TxtLock = true,
	-- Motions = "",	-- these will be 'motions' and 'MSchema' subfolders of .working folder
	-- MSchema = "",
	working = "",
	recent = #()
)

struct DATconfigStruct (
	projectId = 1,
	paths = #(),
	fn getDMTPath =
	(
		sysEn = dotNetClass "System.Environment"
		speFo = dotNetClass "System.Environment+specialFolder"
		myDocuments = sysEn.getfolderPath speFo.MyDocuments		
		DMTpath = myDocuments + "\\DarkMaxTools"
		if not doesFileExist DMTpath then
			makeDir DMTpath
		DMTpath
	),	
	DMTpath = getDMTPath(),	
	DarkINIfile = DMTpath + "\\DarkAnimTools_Settings.ini",
	DATscriptsFolder = (getDir #userScripts) + "\\DarkMaxTools" ,
	pathTools = "",
	pathTextEditor = "",
	CSVFileName = "\\Data\\JointStructure_Data.csv",	
	maxRecentMotions,
	maxRecentAIs,
	autoBackupMdb,

	fn GetUserPref cat key default:"" = (
		if hasINISetting DarkINIfile cat key then (
			val = getINISetting DarkINIfile cat key		
		) else (
			val = default
		)
		val
	),

	fn GetUserPrefInt cat key default:0 = (
		if hasINISetting DarkINIfile cat key then (
			val = (getINISetting DarkINIfile cat key) as integer
		) else (
			val = default
		)
		val
	),

	fn GetUserPrefFloat cat key default:0.0 = (
		if hasINISetting DarkINIfile cat key then (
			val = (getINISetting DarkINIfile cat key) as float
		) else (
			val = default
		)
		val
	),

	fn GetUserPrefBool cat key default:false = (
		if hasINISetting DarkINIfile cat key then (
			val = (getINISetting DarkINIfile cat key) as booleanClass
		) else (
			val = default
		)
		val
	),

	fn SetUserPref cat key value = (
		value = value as string
		setINISetting DarkINIfile cat key value
	),
	
	fn loadPresets =
	(
		if not (doesFileExist DarkINIfile) then
		(
			format "\\\\WARN: Couldn't find the configuration file at:\n"
			format "\\\\WARN: %\n" DarkINIfile
		)
		paths = #()
		INIsections = getINIsetting DarkINIfile
		for sec in INIsections do
		(
			if (filterstring sec "_")[1] == "ConfigPreset" then
			(				
				preset = pathPreset()				
				propNames = getPropNames preset
				for propName in propNames do
				(					
					keyValue = getINIsetting DarkINIfile sec propName 
					prop = getProperty preset propName
					propValue = case (classof prop) of
					(
						BooleanClass:keyValue as booleanClass
						Array:(
							arrayFromString = #()
							for item in (filterString keyValue ",") do (
								if item.count > 0 then (
									append arrayFromString item
								)
							)
							arrayFromString
						)
						default:keyValue
					)
					setProperty preset propName propValue
				)
				append paths preset
			)
		)
		pathTools = getINIsetting DarkINIfile "Configuration" "pathTools" 
		pathTextEditor = getINIsetting DarkINIfile "Configuration" "pathTextEditor" 
		
		maxRecentMotions = GetUserPrefInt "Configuration" "maxRecentMotions" default:30
		maxRecentAIs = GetUserPrefInt "Configuration" "maxRecentAIs" default:15
		autoBackupMdb = GetUserPrefInt "Configuration" "autoBackupMdb" default:2
	),
	
	fn savePresets =
	(		
		if not (doesFileExist DMTPath) then getDMTPath
		
		INIsections = getINIsetting DarkINIfile
		for sec in INIsections do
		(
			if (filterstring sec "_")[1] == "ConfigPreset" then delINIsetting DarkINIfile sec 
		)
		for i = 1 to this.paths.count do
		(			
			preset = this.paths[i]
			sec = "ConfigPreset_" + (i as string)
			propNames = getPropNames preset
			for propName in propNames do
			(
				prop = getProperty preset propName				
				keyValue = case (classof prop) of
				(
					BooleanClass:prop as string
					Array:(
						stringFromArray = ""
						for item in prop do (
							stringFromArray += (item as string) + ","
						)
						stringFromArray
					)
					String:prop
				)
				setINIsetting DarkINIfile sec propName keyValue
			)
		)
		setINIsetting DarkINIfile "Configuration" "pathTools" this.pathTools
		setINIsetting DarkINIfile "Configuration" "pathTextEditor" this.pathTextEditor
		setINIsetting DarkINIfile "Configuration" "maxRecentMotions" (this.maxRecentMotions as string)
		setINIsetting DarkINIfile "Configuration" "maxRecentAIs" (this.maxRecentAIs as string)
		setINIsetting DarkINIfile "Configuration" "autoBackupMdb" (this.autoBackupMdb as string)

		if not (doesFileExist DarkINIfile) then
		(
			format "\\\\ERROR: The configuration was not created.\n"
			format "\\\\ERROR: %\n" DarkINIfile
		)
		else
		(
			format "\\\\INFO: Succesfully created/updated configuration file.\n"
			format "\\\\INFO: %\n" DarkINIfile
		)
	),
	
	fn configureDefPaths =
	(	
		loadPresets()
		if paths.count == 0 then
		(	--  no presets found			
			preset = pathPreset()
			preset.name = "Thief 2"			
			preset.isDefault = true
			preset.Root = ""	
			preset.Mesh = ""
			preset.Txt16 = ""
			preset.working = ""
			-- preset.Motions = ""
			-- preset.MSchema = ""
			paths[1] = preset
			projectId = 1			
		) else (
			-- Set the default project
			for id = 1 to paths.count do (
				if paths[id].isDefault == true then (
					projectId = id
				)
			)
		)
	),
	
	init = configureDefPaths(),

	-- convenience functions - always pointing at current project:
	fn name = (
		this.paths[this.projectId].name
	),

	fn root = (
		this.paths[this.projectId].root
	),
	
	fn mesh = (
		this.paths[this.projectId].mesh
	),

	fn Txt16 = (
		this.paths[this.projectId].Txt16
	),

	fn Txt = (
		path_txt16 = this.paths[this.projectId].Txt16 
		return (substituteString  path_txt16 "txt16" "txt")
	),

	fn Motions = (
		-- this.paths[this.projectId].Motions
		this.paths[this.projectId].working + "\\motions"
	),

	fn MSchema = (
		-- this.paths[this.projectId].MSchema
		this.paths[this.projectId].working + "\\MSchema"
	),

	fn Recent = (
		this.paths[this.projectId].recent
	),

	fn Working = (
		this.paths[this.projectId].working
	)

)
global DATconfig = DATconfigStruct()				-- paths to projects resource files


-- Joint structure data structs

struct torsoStruct (
	type,
	root, 						-- joint number
	parent, 					-- another torso number or 0 for the root torso (butt)
	fixedCount, 			    -- number of fixed joints (typically == limbs, but not always)
	fixedJoints = #(),			-- list of first joints for the limbs 
	fixedJoints_coord = #(), 	-- offset for the fixed joints
	unusedFixedJoints = #(),	-- fixed joints, that do not start any actual limb
	pseudoLimbs = #(),			-- pseudo limbs are dummy helpers for unused fixed joints
	hub, 						-- node - a helper object (used for skinning)
	ctrl,						-- main control object for the torso
	auxctrl,					-- auxiliary control 
	rotRef
	)
	
struct limbStruct (
	Rig,
	-- read from CAL file 
	torso, 					-- number of torso the limb belongs to
	segmentsCount, 		-- how many segments
	segments, 				-- joint numbers
	segments_coord, 	-- offsets from parent
	lengths, 				-- segments lengths
	-- rig related
	SKbones, 				-- skin bones list
	FKctrls, 					-- FK bones/controls list
	IKbones, 				-- IK bones/controls list
	ikPos,
	footHelpers = #(),
	locator,
	ikctrl,
	footIK,
	legIK,
	handIK,
	fkRef,				-- used only in spider leg type of limb - reference for a tip of the leg (foot) in FK mode
	type,
	side,
	swivelTarget,
	
	
	fn getDefaultHelpersPositions =
	(		
		defaultPos = #()
		defaultPos[2] = [(footHelpers[1].pos.x - 0.045), (footHelpers[1].pos.y + 0.016 * side), 0]
		defaultPos[3] = [(footHelpers[1].pos.x + 0.945), (footHelpers[1].pos.y + 0.016 * side), 0]
		defaultPos[4] = [(footHelpers[1].pos.x + 0.525), (footHelpers[1].pos.y + 0.203 * side), 0]
		defaultPos[5] = [(footHelpers[1].pos.x + 0.525), (footHelpers[1].pos.y - 0.193 * side), 0]		
		defaultPos
	),
	
	fn LegNumber =
	(
		case side of (
			(1):1
			(-1):2
		)		
	),	
	
	fn setHelpersPositions =
	(	
		leg = LegNumber()		
		footHelpers[1].pos = ikbones[ikPos].pos
		defPositions = getDefaultHelpersPositions()
		footHelpers[2].pos = (defPositions[2] + [Rig.footHelpers[leg].h2offsetX, Rig.footHelpers[leg].h2offsetY * side, 0])
		footHelpers[3].pos = (defPositions[3] + [Rig.footHelpers[leg].h3offsetX, Rig.footHelpers[leg].h3offsetY * side, 0])
		footHelpers[4].pos = (defPositions[4] + [Rig.footHelpers[leg].h4offsetX, Rig.footHelpers[leg].h4offsetY * side, 0])
		footHelpers[5].pos = (defPositions[5] + [Rig.footHelpers[leg].h5offsetX, Rig.footHelpers[leg].h5offsetY * side, 0])
		try
			footHelpers[4].rotation.controller[2].z_rotation =  (Rig.footHelpers[leg].h4angle)
		catch
			footHelpers[4].rotation.controller.z_rotation =  (Rig.footHelpers[leg].h4angle)
		try
			footHelpers[5].rotation.controller[2].z_rotation =  (Rig.footHelpers[leg].h5angle)
		catch
			footHelpers[5].rotation.controller.z_rotation =  (Rig.footHelpers[leg].h5angle)
	),
	
	fn updateRigOffsetsForHelpers =
	-- Reads values from helpers and applies them to the Rig preset. 
	-- Called during a callback, after user manipulates the helpers in the viewport
	(		
		leg = LegNumber()
		defPositions = getDefaultHelpersPositions()
		h2offset = footHelpers[2].pos - defPositions[2]
		h3offset = footHelpers[3].pos - defPositions[3]
		h4offset = footHelpers[4].pos - defPositions[4]
		h5offset = footHelpers[5].pos - defPositions[5]
		Rig.footHelpers[leg].h2offsetX = h2offset.x
		Rig.footHelpers[leg].h2offsetY = h2offset.y * side 
		Rig.footHelpers[leg].h3offsetX = h3offset.x
		Rig.footHelpers[leg].h3offsetY = h3offset.y * side
		Rig.footHelpers[leg].h4offsetX = h4offset.x
		Rig.footHelpers[leg].h4offsetY = h4offset.y * side
		Rig.footHelpers[leg].h5offsetX = h5offset.x
		Rig.footHelpers[leg].h5offsetY = h5offset.y * side
		
		Rig.footHelpers[leg].h4angle = case classof(footHelpers[4].rotation.controller) of (
			rotation_list:(
				try (				
					clamp footHelpers[4].rotation.controller[2].z_rotation -45.0 45.0
				)
				catch(
					clamp footHelpers[4].rotation.controller[1].z_rotation -45.0 45.0
				)
			)
			Euler_XYZ:(clamp footHelpers[4].rotation.controller.z_rotation -45.0 45.0)
			default:9.999
		)
		Rig.footHelpers[leg].h5angle = case classof(footHelpers[5].rotation.controller) of (
			rotation_list:(
				try (
					clamp footHelpers[5].rotation.controller[2].z_rotation -45.0 45.0
				)
				catch(
					clamp footHelpers[5].rotation.controller[1].z_rotation -45.0 45.0
				)
			)
			Euler_XYZ:(clamp footHelpers[5].rotation.controller.z_rotation -45.0 45.0)
			default:9.999
		)
	)
	
)
	
-- CAL file plus some auxiliary info
struct CALStruct (
	filename,
	version,
	numCALTorsos, 
	numTorsos, 
	numLimbs, 
	numJoints,
	CALtorsos = #(),
	mapTorsos = #(),
	limbs = #(),
	calibration,

	fn Save = --outFolder =
	(
		-- fullpath = outFolder + "\\" + filename
		file = fopen this.filename "wb" 
		-- Header
		WriteLong file version
		WriteLong file numCALTorsos
		WriteLong file numLimbs
		-- Torsos
		for torso in CALtorsos do 
		(

		)

		-- Limbs

		-- Calibration
		WriteFloat file calibration

		FClose file
	)
)




-- BIN AI mesh file structs
-- mesh volume struct
struct VolumeStruct (
	numPolys, 
	startPoly, 
	numVerts, 
	startVert, 
	startblend, 
	mapperID, 
	joint, 
	type, 
	polys, 
	verts, 
	blends
	)

-- joint mappin struct
struct MapperStruct (
	joint, 
	type
	)

	-- Material struct
struct MatStruct (
	textureName, 
	Trans, 
	Illum 
	)

struct BINfileStruct (
	filename,
	version,
	numMappers,
	numMats,
	numVolumes,
	numPolys,
	numVertices,
	numStretchy,
	offset_volumes_remap , 		-- volumes map? num_volumes elements
	offset_mappers, 			-- volumes to skeleton joints mapping
	offset_mats, 				-- material offset
	offset_volumes, 			-- per-volume Polygon info. Volumes are parts of mesh belonging to one joint and sharing one material. Volume can be rigid or stretchy.
	offset_poly,				-- polygons
	offset_norm,				-- Normals
	offset_vert,				-- Vertices (munged) - num_vertices ? ? 
	offset_uvmap,				-- UV maps. Z is junk (count - the same as vertex count)
	offset_blends,				-- Floats (num_stretchy). Blending factors. All in the range 0-1. Probably blend factors between two joints. Count - the same as num_stretchy
	offset_U9, 					-- zeros...?
	-- BIN Material chunk size per version (in bytes)
	MatChunkSize = #(40, 56)	
)

--- MC and MI files:
struct TrackMappingStruct (
	TrackType, 
	JointNumber, 
	TrackNumber
	)

struct FlagStruct (
	FrameNumber, 
	FlagType
	)

struct AnimInfoStruct (
	charMan, 
	MIfileName = "newMot.mi", 
	MCfilename = "newMot_.mc", 
	name, 
	creatureType, 
	frameCount = 0, 
	frameRate = 30, 
	unknown,
	tracksNum, 
	flagsNum, 
	trackMapping, 
	Flags = #(), 
	channels = #() 
	)
	
-- Animation Track Type
struct AnimationTrackTypeEnum (
	Translational = 1,
	Rotational = 0
)
global TType = AnimationTrackTypeEnum()


-- Structure of currently built character
struct CharacterStruct (
	-- rig related
	rawName,
	name,
	type,
	orient,
	Zoffset,
	charMan,
	RootCTRL,
	jointsNumber,
	torsos = #(),
	limbs = #(),
	jointPos = #(),		-- joint positions used in rig (may be different due to adjustments)
	jointPosCAL = #(),	-- original joint positions, used for mesh calculations
	jointParent = #(),
	-- mesh related
	mesh,
	Volumes = #(),
	Mappers = #(),
	Mats,						-- AI materials
	
	fn createLGSjoints =
	(
		LM=layerManager
		DATlayer.LGS = LM.newLayerFromName (name + "_LGSrig")
		if DATlayer.LGS==undefined then DATlayer.LGS = LM.getLayerFromName "LGS rig"
		DATlayer.LGS.current = true
		charMan.lgsjoints = #()
		for i = 1 to jointPosCAL.count do
		(			
			jname = "J" + AIstructure[type].jointNames[i]
			jnt = box name:jname width:0.1 length:0.1 height:0.1
			jnt.pos = jointPosCAL[i]
			jnt.objectOffsetPos = [0,0, -(jnt.height/2)]			
			jnt.parent = RootCTRL.node
			append charMan.lgsjoints (nodeTransformMonitor node:jnt)
		)
	)
)

------------- Creature skeleton data ------------------
/* let's face it - this section is a mess - it should be all data driven (from CSV) - not half and half... */

-- 'Dark' CreatureTypes:
struct CreatureTypeEnum (
	appa = 1,
	arach = 2,
	biped = 3,
	bugbeast = 4,
	burrick = 5,
	droid = 6,
	flexbow = 7,
	playarm = 8,
	rope = 9,
	spidey = 10,
	sweel = 11,
	simple = 12,
	crayman = 13,
	constantine = 14,
	overlord = 15,
	number = 15							-- total number of creature types available
)
global DC = CreatureTypeEnum()

global creaTypeNames = #()						-- longer creature Type names

-- structure elements --
-- this is for - among others - automatic identifying the creature type on file load
struct creatureStructure (
	longName = "",
	shortName = "",
	mjoname = "",
	torsosIdx = #(),  -- this is read from .mjo file
	libsIdx = #(),    -- this is read from .mjo file
	jointNames = #(),
	jointsNo, 
	torsosNo, 
	limbsNo, 
	torsoType = #(),
	limbType = #(),
	trackOrder = #(),
	motionTracks,
	motionTracksMap = #(),
	swapSide
)

global AIstructure= #()

-- let's read the stuff from the CSV text file
CSVfile = openFile (DATconfig.DATscriptsFolder + DATconfig.CSVfileName)
creaTypeNames = getDataRowLabel &CSVfile "creaTypeNames"	true -- nice long names of creature types
CSVrow0 = getDataRowNext &CSVfile true

CSVrow1 = getDataRowLabel &CSVfile "Aistructure" true	-- number of joints per AI
CSVrow2 = getDataRowNext &CSVfile true	-- number of torsos
CSVrow3 = getDataRowNext &CSVfile true	-- number of limbs
CSVrow4 = getDataRowNext &CSVfile true	-- .mjo file names

for j = 1 to DC.number do
(
	AIstructure[j] = creatureStructure longName:(creaTypeNames[j]) shortName:(CSVrow0[j]) jointsNo:(CSVrow1[j] as integer) torsosNo:(CSVrow2[j] as integer) limbsNo:(CSVrow3[j] as integer) mjoname:(CSVrow4[j])
)

skipToString CSVfile "TorsoType"
readLine CSVfile  -- skips to next line

for i = 1 to 4 do
(
	CSVrow1 = getDataRowNext &CSVfile true	-- types of torsos
	for j = 1 to DC.number do
	(
		if CSVrow1[j] != "" then AIstructure[j].torsoType[i] = (CSVrow1[j] as name)
	)
)

skipToString CSVfile "LimbType"
readLine CSVfile  -- skips to next line

for i = 1 to 10 do
(
	CSVrow1 = getDataRowNext &CSVfile true	-- types of limbs
	for j = 1 to DC.number do
	(
		if CSVrow1[j] != "" then AIstructure[j].limbType[i] = (CSVrow1[j] as name)
	)
)

skipToString CSVfile "JointMaps"
skipToNextLine2 CSVfile
for j = 1 to DC.number do
	AIstructure[j].jointNames=#()

for i = 1 to 40 do
(
	CSVrow1 = getDataRowNext &CSVfile true	-- joint names	
	for j = 1 to DC.number do
	(
		if CSVrow1[j] != "" then AIstructure[j].jointNames[i] = CSVrow1[j]
	)
)

-- TRACK ORDER - a secret to correct loading of channels. 
-- The order of tracks in a motion file (.mc) IS NOT the order tracks/channells should be applied onto a skeleton
-- The correct order is always from the CHILD to PARENT within a limb
-- The order of limbs does not matter as much, but they have to go BEFORE torsos.
-- So the last channel to load will always be a ROTATIONAL track of ROOT joint. 
-- (Transitional track of the ROOT joint to come first seems to be OK)
skipToString CSVfile "trackOrder"
readLine CSVfile  -- skips to next line
for j = 1 to DC.number do
	AIstructure[j].trackOrder = #()

for i = 1 to 40 do
(
	CSVrow1 = getDataRowNext &CSVfile true	-- order of joints's tracks to be applied to the rig
	for j = 1 to DC.number do
	(
		if CSVrow1[j] != "" then AIstructure[j].trackOrder[i] = (CSVrow1[j] as integer)
	)
)

CSVrow1 = getDataRowLabel &CSVfile "motionTracks" true		-- number of tracks in motion file
for j = 1 to DC.number do
	AIstructure[j].motionTracks = CSVrow1[j] as integer


skipToString CSVfile "motionTracksMap"
readLine CSVfile  -- skips to next line
--skipToNextLine2 CSVfile
for j = 1 to DC.number do
	AIstructure[j].motionTracksMap = #()	

for i = 1 to 40 do
(
	CSVrow1 = getDataRowNext &CSVfile true	-- tracks mapped to joints
	for j = 1 to DC.number do
	(
		AIstructure[j].motionTracksMap[i] = (CSVrow1[j] as integer)
	)
)

-- Some of the creatures - namely spiders and overlord (psi-reaver) happen to be rotated by 180 degree
-- We need to take that into account when figuring out which side is left, which right.
-- And also as a default value for a missing joint either (0 0 0) or (180 0 0)
skipToString CSVfile "swapSides"
readLine CSVfile
CSVrow = getDataRowNext &CSVfile true
for j = 1 to DC.number do (
	AIstructure[j].swapSide = 	CSVrow[j] as integer
)


close CSVfile
---------------------------------------------------------------
-- end of .CSV file reading
---------------------------------------------------------------


-- Below is a 'dictionary' of default torsos matches. 
-- from .MI file to a creature type
-- Note there is a certain ambiguity in the values present in .mi files
global MItoCTmap = SimpleDict()	
MItoCTmap.add 536870911 DC.spidey
MItoCTmap.add 524287 DC.biped			-- this matches also apparition / burrick
MItoCTmap.add 1048575 DC.biped		-- this matches also burrick
MItoCTmap.add 4194303 DC.bugbeast   -- this matches also Constantine
MItoCTmap.add 262143 DC.droid
MItoCTmap.add 14 DC.playarm			-- this matches also flexbow
MItoCTmap.add 255 DC.arach
MItoCTmap.add 127 DC.sweel
MItoCTmap.add 2097151 DC.crayman
MItoCTmap.add 7 DC.overlord

-- the opposite match - creature type to a code in .MI file (for export)
-- Note - due to certain ambiguities, it's not a reversed match to MItoCTmap
global CTtoMImap = SimpleDict()
CTtoMImap.add DC.appa 			524287
CTtoMImap.add DC.arach 			255
CTtoMImap.add DC.biped			524287
CTtoMImap.add DC.bugbeast		4194303
CTtoMImap.add DC.burrick		524287
CTtoMImap.add DC.droid			262143
CTtoMImap.add DC.flexbow		14
CTtoMImap.add DC.playarm		14
CTtoMImap.add DC.rope			0			-- unknown / does not occur
CTtoMImap.add DC.spidey			536870911
CTtoMImap.add DC.sweel			127
CTtoMImap.add DC.simple			0			-- unknown / does not occur
CTtoMImap.add DC.crayman		2097151
CTtoMImap.add DC.constantine	4194303			
CTtoMImap.add DC.overlord		7

-- This maps creature types to the motion schemas' torso property
global CTtoTorso = SimpleDict()
CTtoTorso.add DC.appa 			"Apparition"
CTtoTorso.add DC.arach 			"Spider"
CTtoTorso.add DC.biped			"Biped"
CTtoTorso.add DC.bugbeast		"Biped"
CTtoTorso.add DC.burrick		"Burrick"
CTtoTorso.add DC.droid			"Droid"
CTtoTorso.add DC.flexbow		"PlayerBow"
CTtoTorso.add DC.playarm		"PlayerArm"
CTtoTorso.add DC.rope			""			-- does not exist
CTtoTorso.add DC.spidey			"Spider"
CTtoTorso.add DC.sweel			"Sweel"
CTtoTorso.add DC.simple			""			-- does not exist
CTtoTorso.add DC.crayman		"Biped"
CTtoTorso.add DC.constantine	"Constantine"
CTtoTorso.add DC.overlord		"Overlord"

-----------------------
--- RIG PRESETS
-----------------------

-- size multiplier for bones (to accomodate for different size creatures)
global boneSizeMult = #()
boneSizeMult[DC.appa] = 1
boneSizeMult[DC.arach] = 0.3
boneSizeMult[DC.biped] = 1
boneSizeMult[DC.bugbeast] = 1
boneSizeMult[DC.burrick] = 0.5
boneSizeMult[DC.droid] = 0.7
boneSizeMult[DC.flexbow] = 1
boneSizeMult[DC.playarm] = 1
boneSizeMult[DC.rope] = 0.8
boneSizeMult[DC.spidey] = 0.3
boneSizeMult[DC.sweel] = 0.3
boneSizeMult[DC.crayman] = 1.0
boneSizeMult[DC.constantine] = 1.0
boneSizeMult[DC.overlord] = 1.0

-- Animation controls colors
struct RigMat (
	name,	
	color,
	mat
)

struct RigColorCodesEnum (
	SPINE = 1,
	FK = 2,
	IK = 3,
	AUX = 4,
	ROOT = 5,
	IKBONE = 6
)
ColorCode = RigColorCodesEnum()

rigMats = #()
rigMats[ColorCode.SPINE] = RigMat name:"Rig_Spine" color:(color 214 189 18)
rigMats[ColorCode.FK] = RigMat name:"Rig_FK" color:(color 33 30 160)
rigMats[ColorCode.IK] = RigMat name:"Rig_IK" color:(color 159 17 17)
rigMats[ColorCode.AUX] = RigMat name:"Rig_Hip" color:(color 192 142 64)
rigMats[ColorCode.ROOT] = RigMat name:"Rig_Root" color:(color 160 14 165)
rigMats[ColorCode.IKBONE] = RigMat name:"Rig_IKbone" color:(color 108 8 136)

for i = 1 to rigMats.count do
(
	rm = Standard name:rigMats[i].name diffuse:rigMats[i].color selfIllumAmount:100
	rigMats[i].mat = rm
)

-- customizable elements


struct customHelpers (
	h2offsetX = 0.0,
	h2offsetY = 0.0,
	h3offsetX = 0.0,
	h3offsetY = 0.0,
	h4offsetX = 0.0,
	h4offsetY = 0.0,
	h4angle = 0.0,
	h5offsetX = 0.0,
	h5offsetY = 0.0,
	h5angle = 0.0
)

struct customRig (
	rootSize = 1.0,
	rootOffset = 0.0,
	torsoStartSize = 1.0,
	torsoEndSize = 0.8,
	torsoOffsetX = 0.0,
	footIKwidth = 1.0,
	footIKlength = 1.0,
	footIKoffsetX = 0.0,
	footIKoffsetY = 0.0,
	footHelpers = #(),
	legFkStartSize =1.0,
	legFkEndSize =1.0,
	handIKsize = 1.0,
	armFKStartSize = 1.0,
	armFKEndSize = 1.0,
	genFKStartSize = 1.0,
	genFKEndSize = 1.0,
	headSize = 1.0,
	headOffsetX = 0.0,
	headOffsetY = 0.0,
	headOffsetZ = 0.0,
	headStraight = false,
	ctrlThickness = 0.01,
	
	fn loadStruct rigINIfile &structName prefix =
	(		
		propNames = getPropNames structName
		for i = 1 to propNames.count do 
		(			
			propName = propNames[i]			
			propClass = classof (getProperty structName propName)
			--format "Property class: %\n" propClass
			case propClass of 
			(			
			(Point2):
				(
					keyName1 = prefix + (propName as string) + ".x"
					keyValue1 = getINIsetting rigINIfile "Settings" keyName1
					keyName2 = prefix + (propName as string) + ".y"
					keyValue2 = getINIsetting rigINIfile "Settings" keyName2
					try 
					(
						propValue = [(keyValue1 as float), (keyValue2 as float)]
						setProperty structName propName propValue
					)									
					catch (format "\\\\WARN: Cannot find property % in the % file.\n" propName rigINIfile)
				)
			(Array):
				(
					nestedArray = getProperty structName propName 
					for j = 1 to nestedArray.count do
					( 
						prefix = (propName as string) + "[" + (j as string) + "]."	
						loadStruct rigINIfile &nestedArray[j] prefix						
					)
					prefix = ""
				)
			(MAXScriptFunction):()	-- don't load in functions...
			default:
				(
					keyName = prefix + (propName as string)					
					if hasINISetting rigINIfile "Settings" keyName then (						
						keyValue = getINIsetting rigINIfile "Settings" keyName
						try 
						(
							propValue = keyValue as propClass
							--format "Setting '%' of '%' to value: %\n" propName structName propValue
							setProperty structName propName propValue							
						)									
						catch (format "\\\\WARN: Cannot find property % in the % file.\n" propName rigINIfile)
					)
				)
			)
		)		
	),
	
	fn loadPresets rigName =
	(
		result = #failed
		rigINIfile = DATconfig.Mesh() + "\\" + rigName + ".rig"
		
		if doesFileExist rigINIfile then
		(
			loadStruct rigINIfile &this ""			
			format "\\\\INFO: Loaded rig settings from file: %\n" rigINIfile
			result = #OK
		)
		else 
		(
			format "\\\\INFO: Couldn't find the file %\n" rigINIfile
			format "\\\\INFO: Using default values.\n"
		)
		result
	),
	
	fn saveStruct rigINIfile &structName prefix =
	(
		propNames = getPropNames structName
		sort propNames
		for i = 1 to propNames.count do 
		(
			propName = propNames[i]			
			propClass = classof (getProperty structName propName)
			case propClass of
			(
				(Point2):
				(
					keyValue = getProperty rig propName
					keyName1 = prefix + (propName as string) + ".x"
					keyValue1 = keyValue.x as string 
					setINIsetting rigINIfile "Settings" keyName1 keyValue1
					keyName2 = prefix + (propName as string) + ".y"
					keyValue2 = keyValue.x as string
					setINIsetting rigINIfile "Settings" keyName2 keyValue2
				)
				(Array):
				(
					for j = 1 to (getProperty structName propName).count do
					(
						prefix = (propName as string) + "[" + (j as string) + "]."						
						nestedArray = getProperty structName propName 
						saveStruct rigINIfile &nestedArray[j] prefix
					)
					prefix = ""
				)
				(MAXScriptFunction):()	-- don't save out functions...
				default:
				(
					keyName = prefix + (propName as string )
					keyValue = (getProperty structName propName) as string
					setINIsetting rigINIfile "Settings" keyName keyValue
	-- 				format "% =  %\n" keyname keyvalue
				)	
			)		
		)
	),
	
	fn savePresets rigName  =
	(
		rigINIfile = DATconfig.Mesh() + "\\" + rigName + ".rig"
		delINIsetting rigINIfile "Settings"
		
		saveStruct rigINIfile &this ""
		
		messageBox ("Rig settings saved to " + rigINIfile + " file.")
	),
	
	fn Init = for i = 1 to 2 do	footHelpers[i] = customHelpers(),
	
	on create do Init()
)
