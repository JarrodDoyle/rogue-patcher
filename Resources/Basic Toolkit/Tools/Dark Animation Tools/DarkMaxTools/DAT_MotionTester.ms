/* -------------------------------------------------------
/*   			Dark Animation Tools
/*					Motion Tester
/* -------------------------------------------------------
/* author: Juliusz Kaczmarek
/* ver. 2.0
/* June 2018
/*
/* Motion Tester struct is used to do an instant motion testing in Dromed.
/* This involves:
    - creating temporary motion files by exporting animation of a selected character
    - creating a temporary motion schema, that points to the test motion
    - building a temporary motion database file (backing up an existing one)
    - building a 'startup.cmd' file for Dromed    
    - copying necessary files: motions, new motion database, test .mis file to the game folders
    - creating a dml file for DAT_Test.mis    
    - launching Dromed - it will load the testing mission automatically
/*
/*
/* this toolset was possible thanks to the knowledge and experience 
/* of Volca, Shadowspawn, Weyoun, Telliamed
/* ------------------------------------------------------
*/

format " - Loading... Motion Tester\n"

struct _MotionTester (
	charMan = undefined,    -- needs to be provided in constructor
    testAnimInfo,
    mdbBackupFile,
    dromedResourcesFolder = GetDir #userScripts + "\\DarkMaxTools\\Dromed",
    testMotionFileName = "",

    fn GetTorso = (
        CTtoTorso.get this.charMan.creaType
    ),

    fn ExportCurrentMotion motName = (
        this.testMotionFileName = motName
        local result = false
        local testAnimInfo = AnimInfoStruct name:motName
        testAnimInfo.MIFileName = DATConfig.Motions() + "\\" + motName + ".mi"
        testAnimInfo.MCFileName = DATConfig.Motions() + "\\" + motName + "_.mc"
        testAnimInfo.charMan = charMan
        local firstFrame = animationRange.start.frame
        local lastFrame = animationRange.end.frame
        format "\\\\Exporting current animation frames: % - % to a file: %\n" firstFrame lastFrame testAnimInfo.MIFileName
        exportMotion.exportMotionFile testAnimInfo firstFrame lastFrame
        if (doesFileExist testAnimInfo.MIFileName == true) and (doesFileExist testAnimInfo.MCFileName) then (
            result = true
        )
        result
    ),
    
    fn CreateTestMotionSchema motName = (
        local result = false
        -- test MOS file:        
        torso = this.GetTorso()
        testMOSfile = MOTDB.CreateMOSFile = MDBMOSFile "DAT_Test" torso        
        -- test schema:
        testSchema = MDBSchema mosfile:testMOSfile
        -- test tag:
        testTag = MOTBD.AddNewTag "DATTest" 1 0
        schemaTag = SCHTag "DATTest" 0
        append testSchema.tags schemaTag
        -- test motion:
        testMotion = MDBMotion name:motName
        append testSchema.motionList testMotion
        newMOSfile.AddSchema testSchema

        result
    ),

    fn DeleteTestMotionSchema = (
        MOTDB.removeMOSFile "DAT_Test"
        MOTDB.removeTag "DATTest"
    ),

    fn CopyTestFMFolder = (
        gameDATFolder = DATConfig.root() + "\\FMs\\DAT"
        if (doesFileExist gameDATFolder == false) then (
            sourceFolder = dromedResourcesFolder + "\\FMs\\DAT"
            destination = DATConfig.root() + "\\FMs"
            copyFolder sourceFolder destination 
        )   
    ),

    fn CopyStartUpFile = (        
        datStartUpFile = dromedResourcesFolder + "\\StartUp.cmd"
        origStartUpFile = DATConfig.root() + "\\StartUp.cmd"
        backupStartUpFile = DATConfig.root() + "\\StartUp_DAT_backup.cmd"
        if (doesFileExist origStartUpFile == true) then 
        (
            -- backup temporarily existing startup file
            if (doesFileExist backupStartUpFile == true) then 
            (
                deleteFile backupStartUpFile
            )
            renameFile origStartUpFile backupStartUpFile    
        )        
        copyFile datStartUpFile origStartUpFile
    ),

    fn RestoreStartUpFile = (        
        backupStartUpFile = DATConfig.root() + "\\StartUp_DAT_backup.cmd"
        if (doesFileExist backupStartUpFile == true) then  
        (            
            origStartUpFile = DATConfig.root() + "\\StartUp.cmd"
            delete origStartUpFile
            result = renameFile backupStartUpFile origStartUpFile
            if result == true then (
                format "INFO: Restored the StartUp.cmd file.\n"
            )
        ) else (
            format "WARNING: Backup of StartUp.cmd does not exists. Cannot restore it."
        )
    ),

    fn LaunchDromed = (
        
    ),
    
	fn TestCurrentMotion = (
        print "Testing current motion in Dromed..."        
        /* Export it first */ 
        motionName = "dat_test"       
        result = exportCurrentMotion motionName
        if result != true then (
            messageBox "Error exporting current motion!"
            return()
        )

        /* Motion Database stuff */
        result = createTestMotionSchema motionName
        if result != true then (
            messageBox "Error creating test motion schema!"
            return()
        )

        this.mdbBackupFile = MOTDB.BackupMDB()
        if this.mdbBackupFile == "" then (
            messageBox "Error creating backup of motion database!"
            return()
        )
        
        MOTDB.MakeMDB()
        
        /* Dromed setup */
        CopyTestFMFolder()
        CopyStartUpFile()        
        -- There's more stuff needed here...
        -- - Character selection
        -- - 
        LaunchDromed()
    ),
    
    fn RestoreChangesAfterTest = (
        DeleteTestMotionSchema()
        RestoreStartUpFile()
    )
)