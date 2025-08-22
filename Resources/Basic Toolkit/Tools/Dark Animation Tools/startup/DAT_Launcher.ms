/* -------------------------------------------------------
/* 			Dark Animation Tools
/*					Main
/* -------------------------------------------------------
/* author: Juliusz Kaczmarek
/* ver. 0.01
/* Nov. 2012, 2013
/* ver. 0.9
/* June 2015
/*
/* tools for importing and exporting
/* rigged characters and their motions
/* from and to dark engine games. 
/*
/* this script was possible thanks to the knowledge and experience 
/* of Volca, Shadowspawn, Weyoun, Telliamed
/* ------------------------------------------------------
*/
-- global DMT_PATH = getDir #startupScripts + "\\DarkMaxTools\\"
-- global FILEIN_PATH = getDir #startupScripts + "\\DarkMaxTools\\(filein)\\"
-- global INCLUDE_PATH = getDir #startupScripts + "\\DarkMaxTools\\(include)\\"

format "Launching Dark Max Tools\n"

fn SetCurrentDir subfolder:"" = 
(
    if subfolder != "" then subfolder = "\\" + subfolder
    local DMTfolderName = "\\DarkMaxTools\\"
    local devPath = systemTools.getEnvVariable "DAT_DEV_PATH"    
    if devPath == undefined then (        
        sysInfo.currentDir = GetDir #userScripts + DMTfolderName + subfolder
    ) else (        
        sysInfo.currentDir = devPath + subfolder
    )
    format ("Sourcing scripts from: " + sysInfo.currentDir + "\n")
)

-- SetCurrentDir subfolder:"Lib"
-- fileIn "XMLStruct_v1.2.ms"                  -- XML dotNet wrapper 

SetCurrentDir()

global DATMain
global DATImport
global DATRig

fileIn "DarkAnimTools_CommonFunc.ms"		-- some useful common functions
fileIn "DAT_UIManager.ms"                   -- some functions to manage UI elements in rollouts
fileIn "DarkAnimTools_h.ms"				    -- main structs and declarations

global CAL = CALStruct()					-- struct holding the current CAL file data
global BIN = BINfileStruct()				-- struct holding the current BIN file data
global currentAnimInfo = AnimInfoStruct()	-- struct holding the curent motion data - MI and MC files
global AI 									-- struct holding currently built character's data

-- pre-declaring Custom Attributes
global CharManCA                            
global AIRootCA
global FootCA
global ArmCA
global SpiderFootCA
global GenericCA
global TorsoCA

fileIn "DarkAnimTools_DAT.ms"				-- main functions of Dark Animation Tools
fileIn "DAT_MotionTester.ms"

global ImportMotion                         -- Import Motion Dialog

fileIn "DAT_MotionDatabase.ms"              -- Motion Database
fileIn "DarkAnimTools_MotSch.ms"			-- Motion Schema Browser 
fileIn "DAT_MoSchEditor.ms"				    -- Motion Schema Editor
fileIn "DarkAnimTools_CA.ms"				-- custom attributes definitions
fileIn "DarkAnimTools_Rollouts.ms"			-- main rollouts definitions
fileIn "DarkMaxTools_Menu.ms"				-- menu registration

--*/

-------------------------------------------------------------------------------------------
--------------------------------  Some Global Settings     -----------------------------
-------------------------------------------------------------------------------------------

units.SystemScale = 1
units.SystemType = #Feet
animationRange = (interval 1 animationRange.end)





