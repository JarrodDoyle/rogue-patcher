/* Motion Database structs 
/*
/* API for editing Shadowspawn's .MOS files, forming a textual representation
/* of MotionDatabase. 
/* 


Hierarchy:
	- MotionDatabase:
		- mosFiles		[MDMMOSFile]	- list of the MOS files
		- schemas		[MDBSchemas]	- list of all the schemas
		- Mtags			[MDBTag]		- global list of tags	(customizable)
		- Mtorsos		[string]		- global list of torsos
		- Mtypes		[string]		- global list of motion types

	- MDBMOSFile:
		- fullPath		string
		- globalTorso	string
		- globalTag		SCHTag
		- schemas		[MDBSchemas]

	- MDBSchema:
		- mosfile		MDBMOSFile		- file it belongs to
		- tags			[SCHTags]
		- type			string			- MotionType
		- timeScale		float				
		- XYZScale		float
		- motionList	[MDBMotion]

	- MDBMotion:
		- name			string
		- flags			int
		- blendTime		int  (short)

	- SCHTag:
		- name			string			- matches one of the MDBTag names
		- value			int

	- MDBTag:
		- name			string
		- param1		int
		- param2		float
*/

format " - Loading... MotionDatabase\n"

global MOTDB					--  motion schemas struct

fn getDirtyString dirtyValue = (
    if dirtyValue==true then 
        return " *  "
    else
        return "     "
)

fn getDeletedString deletedState = (
	if deletedState == true then
		return "(DELETED) "
	else
		return ""
)

/* Motion Tags as found in Tags.moc file */
struct MDBTag (
	name,	
	param1,
	param2,
	dirty = false,
	deleted = false,

	fn str = (		
		spaces = substring "                    " 1 (1 + 20 - name.count)		-- 20 blank spaces, all right? This is how we do padding in max script... :D
		stringFormat "motionTag %  % %  %{f:1}\n" v1:name v2:spaces v3:param1 v4:param2
	),

	fn listName =
    (        
		return (getDirtyString dirty) + (getDeletedString deleted) + (this.name)        
	)	
)

/* A pair of values - tag and its value, as found in motion schemas names */
struct SCHTag (
	name,
	value,

	fn str = (		
		stringFormat "% %" v1:name v2:(value as string)
	)
	
)


/* Struct describing one motion.  */
struct MDBMotion (
	name = "",
	flags = 0,		-- 1 - neck_is_fixed, 2 - is_turn, 4 - in_place
	blendTime = 500,

	fn str = (
		stringFormat "\nmotion %     %  %" v1:name v2:(flags as string) v3:blendTime
	)
)

/* ------------------------------------------------------------------------------------------------------------------------*/
/* 								MOTION SCHEMA
/* ------------------------------------------------------------------------------------------------------------------------*/

struct MDBSchema (
	mosfile,
	tags = #(),
	_torso = undefined,
	type = "GroundAction",
	timeScale = 0.0,
	XYZScale = 0.0,
    motionList = #(),
    dirty = false,    
    deleted = false,    -- marked to be deleted, when you save your changes in the editor
	
	fn allTags =
	(
		allTagsList = #()
		if mosFile.globalTag != undefined then (
			append allTagsList mosFile.globalTag
		)
		allTagsList = allTagsList + tags
	),

    fn name fullName:True = 
    (
		local schemaName = ""		
		local allTagsList
		if fullName==true then 
			allTagsList = allTags()
		else 
			allTagsList = this.tags

        for i=1 to allTagsList.count do
        (
            tag = allTagsList[i]
            if i<allTagsList.count then delimeter = ", " else delimeter = ""
            schemaName = schemaName + tag.str() + delimeter
        )
        return schemaName
    ),

    fn listName =
    (
        if deleted==false then
            return (getDirtyString dirty) + this.name()
        else
            return (getDirtyString dirty) + "(DELETED) " + (this.name())
	),
	
	fn torso = (
		if this._torso != undefined then
			return this._torso
		else
			return mosFile.globalTorso
	),

	fn setTorso value = (
		this._torso = value
	),

	fn str = (
		schemaString = "\n\nschema " + this.name fullName:false
		schemaString += "\nMType  " + this.type
		schemaString += "\nTimeScale " + (this.timeScale as integer) as string
		schemaString += "\nXYZScale  " + (this.XYZScale as integer) as string
		for motion in this.motionList do (
			schemaString += motion.str()
		)
		return schemaString
	),

	fn MarkAsDirty = (
		this.dirty = True
		this.mosFile.MarkAsDirty()
	),

	fn MarkAsDeleted state = (
		if state != this.deleted then (
			this.deleted = state
			this.MarkAsDirty()			
		)
	),
	
	/* Creates a copy of schema. Only a reference to the MOS file stays the same */
	fn CopySchema schema = (
		-- let's copy schema and then its compound values except for reference to mosFile
		newSchema = copy schema	 -- shallow copy of a struct
		newSchema.tags = deepcopy schema.tags
		newSchema.motionList = deepcopy schema.motionList							
		newSchema.this = newSchema
		newSchema	-- return value
	),

	fn RenameTag nameBefore nameAfter = (
		local renamed = false
		for tag in this.tags do (
			if tag.name == nameBefore then (
				tag.name = nameAfter
				this.dirty = true
				renamed = true
			)
		)
		renamed
	),

	fn IsTagUsed tagName = (
		isUsed = false
		for i = 1 to this.tags.count do (
			if this.tags[i].name == tagName then (
				return true			
			)
		)
		isUsed
	)

)

/* ------------------------------------------------------------------------------------------------------------------------*/
/* 								MOS FILE
/* ------------------------------------------------------------------------------------------------------------------------*/

/* Represents a MOS file - a list of motion schemas organized by a torso */
struct MDBMOSFile (
    fullPath = "",
    schemas = #(),		-- a list of schemas defined in this MOS file
    globalTorso = "",			-- common torso for all the schemas within this file
	globalTag = undefined,		-- optional globalTag, shared by all the schemas in this file
	deleted = false,	-- a flag for MOS files marked to be deleted
    dirty = false,		-- a dirty flag set means we've done some changes in the editor, that need to be saved

    fn FileName = (
        return (filenameFromPath fullPath)
    ),

    fn ListName = (
		if this.deleted == false then
			return (getDirtyString dirty) + fileName()		-- this includes the dirty status info.
		else
			return (getDirtyString dirty) + "(DELETED) " + fileName()		-- this includes the 'dirty' status and 'deleted' status.
	),
	
	/* Reads a .MOS file from the disk */
	fn Read mosFilename = (
		this.fullPath = mosFilename
		level = #global -- can be #global or #schema
		globalTag = undefined
		globalTorso = ""
		currSchema = undefined

		mos = openFile mosFilename
		while (eof mos)==false do
		(
			mosLine = ReadLine mos
			mosLine = trimLeft mosLine
			mosLine = trimRight mosLine
			-- ignore empty lines and comments
			if mosLine != "" and (substring mosLine 1 2) != "//" then
			(
				filtered = filterString mosLine ", "
				token = toLower filtered[1]	-- all tokens below are to be in lower case				

				case token of (
					"global":
					(
						this.globalTag = SCHTag name:filtered[2] value:(filtered[3] as integer)
						--appendIfUnique MOTDB.Mtags (this.globalTag.name)				-- Tags will be loaded from MOC file
					)
					"torso":
					(
						TorsoName = filtered[2]
						TorsoName = case (toUpper TorsoName) of (
							"T0":"Biped"
							"T1":"PlayerArm"
							"T2":"PlayerBow"
							"T3":"Burrick"
							"T4":"Spider"
							"T5":"Constantine"
							"T6":"Sweel"
							"T7":"Available1"
							"T8":"Apparition"
							"T9":"Droid"
							default:TorsoName
						)
						case level of (
							#global:(
								this.globalTorso = TorsoName								
							)
							#schema:(
								currSchema.setTorso TorsoName
								--print (currSchema.name()) +" - Torso: " + TorsoName
							)
						)
						appendIfUnique MOTDB.Mtorsos TorsoName	-- should be read from the Torso.moc, no?
					)
					"schema":
					(
						level = #schema
						currSchema = MDBSchema mosfile:this	-- new schema
						append this.schemas currSchema
						append MOTDB.schemas currSchema 																		
						
						tagsNo = (filtered.count-1) / 2
						for i = 1 to tagsNo do
						(
							currtag = SCHTag name:(filtered[i*2]) value:(filtered[i*2+1] as integer)
							append currSchema.tags currtag
							--appendIfUnique MOTDB.Mtags (currtag.name)
						)
					)
					"mtype":
					(
						currType = filtered[2]
						currSchema.type = currType
						appendIfUnique MOTDB.Mtypes currType
					)
					"timescale":currSchema.timescale = (filtered[2] as float)
					"scale2":currSchema.xyzscale = (filtered[2] as float)
					"xyzscale":currSchema.xyzscale = (filtered[2] as float)
					"motion":							
					(
						currMotion = MDBMotion name:(filtered[2]) flags:(filtered[3] as integer) blendTime:(filtered[4])
						append currSchema.motionList currMotion
					)
					default:format "\\ERROR: Can't understand the line:%\n in file:%\n" mosLine mosFilename
				)
			)
		)
		close mos	
	),

	/* outputs a string representing a mos file, in a format that can be saved back to disk */
	fn str = (
		mosString = "\n"
		if this.globalTag != undefined then
			mosString += "\nglobal " + this.globalTag.str()
		mosString += "\ntorso  " + this.globalTorso
		for schema in this.schemas do (
			if schema.deleted == false then
				mosString += schema.str()
		)
		mosString
	),

	/* Saves content of the mos file to disk */
	fn Save = (
		mos = undefined
		if doesFileExist this.fullPath then (
			mos = openfile this.fullPath mode:"wt"
		) else (
			mos = createfile this.fullPath
		)

		if mos != undefined then (
			format "%" (this.str()) to:mos
			close mos			
			this.dirty = false
			for schema in schemas do (
				schema.dirty = false
			)			
		)
	),

	fn Delete = (
		if doesFileExist this.fullPath then (
			deleteFile this.fullPath
		) else (
			format "\\\\WARN: File '%' does not exist - cannot delete.\n" this.fullPath
		)
	),

	fn MarkAsDirty = (		
		this.dirty = True
		MOTDB.dirty = True
	),

	fn markAsDeleted state = (
		if state != this.deleted then (
			this.deleted = state
			this.MarkAsDirty()			
		)
	),

	fn AddSchema schema = (
		append this.schemas schema
		append MOTDB.schemas schema
		this.MarkAsDirty()		
	),

	fn RenameTag nameBefore nameAfter = (
		local renamed = false
		local schemaRenamed = false 
		if this.globalTag != undefined then (
			if this.globalTag.name == nameBefore then (
				this.globalTag.name = nameAfter
				renamed = true
				/* CONTINUE HERE */

			)
		)		
		for schema in this.schemas do (			
			schemaRenamed = schema.RenameTag nameBefore nameAfter
			if schemaRenamed == true then (
				renamed = true
			)
		)

		if renamed == true then (
			this.dirty = true
		)
		renamed
	),

	fn IsTagUsed tagName = (
		local isUsed = false
		if this.globalTag != undefined then (
			if this.globalTag.name == tagName then (
				isUsed = true
			)
		)		
		for schema in this.schemas do (			
			isUsedInSchema = schema.IsTagUsed tagName
			if isUsedInSchema == true then (
				isUsed = true
			)
		)
		isUsed
	)
)

/* ------------------------------------------------------------------------------------------------------------------------*/
/* 								MOTION DATABASE
/* ------------------------------------------------------------------------------------------------------------------------*/

struct MotionDatabase (		
	/*  Main class managing the motion database
		It can load motion database from .mos and .moc files
		It can add new motion tags and .mos files.
		It can save motion database back to files.
		Finally - it can build new motiondb.bin file.
	*/
    mosFiles = #(),
	schemas = #(),	
	Mtags = #(),
	Mtorsos = #(),
	Mtypes = #(),	
	dirty = false,
	
	fn readTagsFromFile = (
		tagMocFiles = getFiles (DATconfig.MSchema() + "\\Tags.moc")
		if tagMocFiles.count > 0 then (
			tagMocFile = tagMocFiles[1]
			moc = openFile tagMocFile 
			while (eof moc)==false do
			(
				mocLine = ReadLine moc
				mocLine = trimLeft mocLine
				mocLine = trimRight mocLine
				if mocLine =="" then
					continue
				
				filtered = filterString mocLine " "
				if filtered.count != 4 then
					continue

				token = toLower filtered[1]	-- all tokens below are to be in lower case
				case token of (
					"motiontag":
					(
						local newTag = MDBTag name:filtered[2] param1:filtered[3] param2:filtered[4]
						append MOTDB.Mtags newTag
					)
				)				
			)
			close moc
		) else (
			print "\\\\ERROR: Can't find 'Tags.MOC file.\n Check your Configuration paths for the Motion Schemas path."
		)
	),

	-- read schemas from the .mos files
	fn readSchemas = 
	(		
		local mos
		local mosLine
		local token
		local globalTag, globalTorso
		local currSchema		
    
        mosFiles = #()
		schemas = #()
		Mtags = #()
		Mtorsos = #()
		Mtypes = #()
		
		-- read tags from the Tags.moc file
		readTagsFromFile()

		-- read schemas from .mos files
        mosFilenames = getFiles (DATconfig.MSchema() + "\\*.mos")        
		if mosFilenames.count > 0 then
		(
			for mosFilename in mosFilenames do
			(
				mosFile = MDBMOSFile() 
				mosFile.Read mosFilename
                append mosFiles mosFile							
			)
		)
		else messagebox "No schemas found."

		this.dirty = false
    ),
    
    fn getMOSfilenames = (
        fileNames = #()
        for file in mosFiles do (
            append fileNames (file.listName())
        )
        return fileNames
	),	

	fn getTagNames full:true alphabetical:false = (
		tagNames = #()
        for tag in Mtags do (
			if full==true then
				append tagNames (tag.listName())
			else 
				append tagNames (tag.name)
		)
		if alphabetical == true then (
			tagNames = sort tagNames
		)
        return tagNames
	),
	
	fn MSNames = (
		list = #()
		for schema in schemas do (
			append list (schema.listName())
		)
		return list
	),


	fn findTagByName tagName alphabetical:false = (
		tagNames = getTagNames full:false alphabetical:alphabetical
		index = findItem tagNames tagName
		index
	),

	fn findTorsoByName torsoName = (
		index = findItem MTorsos torsoName
		index
	),

	fn addNewTag tagName param1 param2 = (
		for tag in Mtags do (
			if tag.name == tagName do (
				format "\\\\WARN: Tag % already exists. Ignoring addition.\n" tag.str()
				result = false
				return result
			)
		)		
		newTag = MDBTag name:tagName param1:param1 param2:param2
		newTag.dirty = true
		append MTags newTag
		this.dirty = true
	),

	fn removeTag tagName = (
		index = findTagByName tagName
		
		if index > 0 then (
			deleteItem this.Mtags index
			this.dirty = true
		)		
	),

	fn removeMOSFileByIndex index = (
		mosFile = this.mosFiles[index]
		format "\\\\INFO: Removing MOS file '%' from the MotionDatabase." (mosFile.FileName())
		deleteItem this.mosFiles index
		this.dirty = true
	),

	fn getMOSFileByName mosFileName = (
		for mosFile in this.mosFiles do (
			if mosFile.FileName() == mosFileName then (
				return mosFile
			)
		)
	),

	fn removeMOSFileByName mosFileName = (
		index = 0
		for i = 1 to this.mosFiles.count do (
			mosFile = this.mosFiles[i]
			if mosFile.FileName() == mosFileName then (
				index = i
				break
			)
		)
		if index > 0 then (
			removeMOSFileByIndex index
		)		
	),

	fn removeMOSFile mosFile = (
		index = findItem this.mosFiles mosFile
		if index > 0 then (
			removeMOSFileByIndex index
		)
	),
	
	fn CreateMOSFile mosFileName torso globalTag:undefined = (
		fullPath = DATconfig.MSchema() + "\\" + mosFileName + ".mos"		
		if (doesFileExist fullPath) == false then (
			mosFile = MDBMOSFile fullPath:fullPath globalTorso:torso globalTag:globalTag
			mosFile.MarkAsDirty
			append this.mosFiles mosFile
		)
		mosFile
	),

	fn AddMOSFile mosFile = (
		append this.mosFiles mosFile
		this.dirty = true
	),

	fn SaveTagsToFile = (
		tagMocFileName = DATconfig.MSchema() + "\\Tags.moc"
		tagsFile = undefined
		if doesFileExist tagMocFileName then (
			tagsFile = openFile tagMocFileName mode:"wt"
		) 
		else (
			tagsFile = createfile tagMocFileName
			format "\\\\INFO: Tags.moc file not found - creating a new one"
		)

		try (
			if tagsFile != undefined then (
				for i = this.MTags.count to 1 by -1 do (
					if this.MTags[i].deleted == true then (
						deleteItem this.MTags i
					)
				)
				-- original Shadowspawn comment:
				preamble  = "//  Tags. Any tag used in the motion hierarchy must be defined here\n" 
				preamble += "//  I have no idea what the two numbers are. If you are adding a new\n"
				preamble += "//  tag, pick numbers which are similar to similar tags, or just experiment.\n"
				preamble += "//  Good luck. If you figure out what they are used for, email Shadowspawn.\n\n"
				format preamble to:tagsFile
				for mtag in this.MTags do (
					format "%" (mtag.str()) to:tagsFile
				)
				close tagsFile					
			)
		)
		catch(
			close tagsFile
		)
	),

	/*  Saves entire Motion Database to disk
		That is the Tags.moc file and all .mos files.
		Deletes .mos files marked as deleted. */
	fn SaveAll = (		
		modified = 0
		created = 0
		deleted = 0
		if this.dirty == true then (	
			format "\\\\INFO: Saving Motion Database...\n"
			-- Tags
			SaveTagsToFile()
			-- Schemas
			for i = MOTDB.mosFiles.count to 1 by -1 do (
				mosFile = MOTDB.mosFiles[i]
				if mosFile.deleted == true then (
					mosFile.Delete()
					removeMOSFileByIndex i
					deleted += 1
				)
				else (
					if mosFile.dirty == true then (
						if doesFileExist mosFile.fullPath then (
							modified += 1
						) else (
							created += 1
						)
						mosFile.Save()
					)
				)
			)						
			this.dirty = false
			
			format "\\\\INFO: MOS files modified: %\n" modified
			format "\\\\INFO: MOS files created:  %\n" created
			format "\\\\INFO: MOS files deleted:  %\n" deleted
		) else (
			format "\\\\INFO: No changes in Motion Database - not saving.\n"
		)
		return #(modified, created, deleted)
	),

	fn RenameTagInMOSFiles nameBefore nameAfter = (
		format "Renaming tag % to %...\n" nameBefore nameAfter
		for mosFile in this.mosFiles do (
			mosFileRenamed = mosFile.RenameTag nameBefore nameAfter
			if mosFileRenamed then (
				this.dirty = true
			)
		)
	),

	fn IsTagUsed tagName = (
		/* Checks whether a particular tag is used in database */
		local isUsed = false
		for mosFile in this.mosFiles do (
			isUsedInMOSFile = mosFile.IsTagUsed tagName
			if isUsedInMOSFile then (
				isUsed = true
			)
		)
		isUsed
	),

	fn BackupMDB = (
		-- Creates a backup of existing motiondb.bin file in a DAT_backup folder in game's root folder
		-- The backup file receives a time stamp: motiondb_[Year]-[Month]-[Day]_[Hour]-[Minute].bin
		-- so, only 1 backup file per minute allowed! Sorry... ;)
		result = ""
		bTime = getLocalTime()
		backupFolder = (DATConfig.Root()) + "\\DAT_backup\\"
		sourceFile = (DATConfig.Root()) + "\\motiondb.bin"
		try (
			makeDir backupFolder
			backupFileName = stringFormat "motiondb_%-%-%_%-%.bin" v1:bTime[1] v2:bTime[2] v3:bTime[4] v4:bTime[5] v5:bTime[6]
			targetFile = backupFolder + backupFileName
			if doesFileExist targetFile then (
				messageBox "WARN: Backup file already exist. Wait one minute for the time stamp to change and try again." title:"Backup MDB"
				return ""
			)
			copyResult = copyFile sourceFile targetFile
			if copyResult == True then (
				format "INFO: Created a backup of motion database: %\n" targetFile
				result = targetFile				
			) 
		)
		catch (
			format "ERROR: Error during creating a backup of motion database: % --> %\n" sourceFile targetFile
			print getCurrentException()			
		)
		result
	),

	fn MakeMDB export:false = (
		-- Build Motion Database file and optinally export it to the game folder
		-- Check conditions first:
		-- 1) Makmdb.exe needs to exist in working folder
		-- 2) motions folder need to exist in working folder
		-- 3) MSchemas need to exist in working folder
		workingFolder = DATConfig.Working() + "\\"
		if doesFileExist ( workingFolder + "Makmdb.exe") == False then (
			messageBox "Makmdb.exe file does not exist in the working folder!\n" title:"Motion DB Export Error"
			return()
		)
		-- TODO: add other conditions later
		try (
			command = "\"" + workingFolder + "Makmdb.exe\" \"dat_motiondb.bin\""
			print command
			sysInfo.currentdir = DATConfig.Working()
			HiddenDOSCommand ("\"" + command + "\"") doNotWait:false ExitCode:&errorCode
			if errorCode == 0 then (
				if export == false then return()
				--
				print "Exporting to game engine"
				createdFile = workingFolder + "dat_motiondb.bin"
				destFile = (DATConfig.Root()) + "\\motiondb.bin"
				autoBackupMdb = DATConfig.autoBackupMdb
				--autoBackupMdb = DATConfig.GetUserPrefInt "Configuration" "autoBackupMdb" 2
				--askForBackup = DATConfig.GetUserPrefBool "Configuration" "askForMDBBackup" True
				okToGo = true -- don't export, if backup failed
				if autoBackupMdb == 3 then (
					okToGo = (BackupMDB()) != ""
				) else if autoBackupMdb == 2 then (
					doBackup = queryBox "Do you want to create a backup of existing motiondb.bin file?" title:"Backup MDB"
					if doBackup == True then (
						okToGo = (BackupMDB()) != ""
					)
				)
				if okToGo == false then (
					msg = "Could not create a backup of motion database. Aborting export of new database.\n"
					return()
				)
				if doesFileExist destFile then (
					deleteFile destFile
				)
				
				result = copyFile createdFile destFile   -- <----- exporting to the game
				if result == true then (
					format "INFO: Exported motion database as %\n" destFile
				)
			) else (
				format "ERROR: Error (code %) occured while creating new database.\n" errorCode
			)
		)
		catch (
			format "ERROR: Error occured during exporting new motion database.\n"
			print (getCurrentException())
		)
	)
)

----------------------------------------------------------------------------------------------------------------------
global MOTDB = MotionDatabase()