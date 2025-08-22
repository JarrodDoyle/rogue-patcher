/* ------------------------------------------------------
/* 				  Dark Max Tools
/*				Menu Registration
/* 			
/* ------------------------------------------------------
/* author: Juliusz Kaczmarek
/* ver. 1.9
/* August. 2020
/*
/* ------------------------------------------------------
*/

-----------------------------------
-- Menu Items
-----------------------------------

format " - Loading... Menus\n"

macroscript DAT_ImportAI 	category:"DarkMaxTools" 	
(	
	PosX = getINISetting DATconfig.darkINIfile "ImportRollout" "PosX"
	PosY = getINISetting DATconfig.darkINIfile "ImportRollout" "PosY"
	if PosX!="" and PosY!="" then
	(	
		pos = [(PosX as integer), (PosY as integer)]	
		if DATImport.isDisplayed == false then createDialog DATImport width:240  pos:pos	
	)
	else
		if DATImport.isDisplayed == false then createDialog DATImport width:240 
)

macroscript DAT_ImportMotion category:"DarkMaxTools" 	
(
	currentAnimInfo = AnimInfoStruct()
	importMotionDialog = createDialog importMotion lockwidth:true lockheight:false style:#(#style_titlebar, #style_border, #style_sysmenu, #style_resizing)
)

macroscript DAT_MotionSchemaEditor category:"DarkMaxTools" 	
(
	currentAnimInfo = AnimInfoStruct()
	MotionSchemaEditor.mode = #edit
	createDialog MotionSchemaEditor lockwidth:false lockheight:false style:#(#style_titlebar, #style_border, #style_sysmenu, #style_resizing)
	
)


macroScript DAT_About category:"DarkMaxTools"
(	
	createDialog DATabout modal:true width:350
)

macroScript DAT_Configuration category:"DarkMaxTools"
(
	createDialog DATPathConfiguration style:#(#style_toolwindow, #style_sysmenu) --width:500 
)

macroScript DAT_Reload category:"DarkMaxTools"
(	
	fileIn (GetDir #userstartupScripts + "\DAT_Launcher.ms")
)

macroScript DAT_Uninstall category:"DarkMaxTools"
(
	message = "This will remove the DarkMaxTools, including menu, all the associated scripts and macro scripts.\n"
	message += "\nDo you want to continue?"
	answer = queryBox message title:"Uninstall DarkMaxTools?" beep:true

	if answer != true then return ()

	-- remove DarkMaxTools folder
	userScriptsFolder = GetDir #userScripts 
	dmtFolder = userScriptsFolder + "\\DarkMaxTools"
	launcherFile = userScriptsFolder + "\\startup\\DAT_Launcher.ms"
	try (
		HiddenDOSCommand ("del /F/Q/S " + "DarkMaxTools\\*.*") startpath:userScriptsFolder
		HiddenDOSCommand ("rmdir /Q/S DarkMaxTools") startpath:userScriptsFolder
	)
	catch (
		format "\\\\ERROR: Error deleting DarkMaxTools folder at %" userScriptsFolder
	)
	
	-- Remove Launcher file
	try (
		HiddenDOSCommand ("del /F/Q/S " + "startup\\DAT_Launcher.ms") startpath:userScriptsFolder
	)
	catch (
		format "\\\\ERROR: Error deleting %" launcherFile
	)

	-- remove MacroScripts
	userMacrosFolder = GetDir #userMacros
	try (
		HiddenDOSCommand ("del /F/Q/S " + "DarkMaxTools*.mcr") startpath:userMacrosFolder
	)
	catch (
		format "\\\\ERROR: Error deleting DarkMaxTools macroscripts at %" userMacrosFolder
	)

	-- remove menu
	removeMenu()
)

fn removeMenu =
(
	mainMenuBar = menuMan.getMainMenuBar()
	for i = mainMenuBar.numItems() to 1 by -1 do
	(
		mnuItem = (mainMenuBar.getItem i)
		if (mnuItem.getTitle()) == "DarkMaxTools" then
		mainMenuBar.removeItem mnuItem
		)
		
	menuMan.updateMenuBar()
)

---------------------------
-- Menu registration
---------------------------

(
	mainMenuBar = menuMan.getMainMenuBar()
	
	-- delete existing DarkMaxTools menu
	removeMenu()

	-- create a new DarkMaxTools menu
	DATmenu = menuMan.createMenu "DarkMaxTools"  
	
	newItem = menuMan.createActionItem "DAT_ImportAI" "DarkMaxTools"
	newItem.setTitle "Import AI..."
	newItem.setUseCustomTitle True
	DATmenu.addItem newItem -1

	newItem = menuMan.createActionItem "DAT_ImportMotion" "DarkMaxTools"
	newItem.setTitle "Import Motion..."
	newItem.setUseCustomTitle True
	DATmenu.addItem newItem -1

	newItem = menuMan.createActionItem "DAT_MotionSchemaEditor" "DarkMaxTools"
	newItem.setTitle "Motion Schemas Editor..."
	newItem.setUseCustomTitle True
	DATmenu.addItem newItem -1
	
	sepItem = menuMan.createSeparatorItem()
	DATmenu.addItem sepItem -1
	
	itemConfig = menuMan.createActionItem "DAT_Configuration" "DarkMaxTools"
	itemConfig.setTitle "Configuration..."
	itemConfig.setUseCustomTitle True
	DATmenu.addItem itemConfig -1
	
	sepItem = menuMan.createSeparatorItem()
	DATmenu.addItem sepItem -1
	
	itemReload = menuMan.createActionItem "DAT_Reload" "DarkMaxTools"
	itemReload.setTitle "Reload"
	itemReload.setUseCustomTitle True
	DATmenu.addItem itemReload -1

	itemReload = menuMan.createActionItem "DAT_Uninstall" "DarkMaxTools"
	itemReload.setTitle "Uninstall..."
	itemReload.setUseCustomTitle True
	DATmenu.addItem itemReload -1

	sepItem = menuMan.createSeparatorItem()
	DATmenu.addItem sepItem -1

	aboutItem = menuMan.createActionItem "DAT_About" "DarkMaxTools"
	aboutItem.setTitle "About..."
	aboutItem.setUseCustomTitle True
	DATmenu.addItem aboutItem -1
	
	DATmenuSubmenu = menuMan.createSubMenuItem "DarkMaxTools" DATmenu
	DATmenuIndex = mainMenuBar.numItems() 
	mainMenuBar.addItem DATmenuSubmenu DATmenuIndex 
-- redraw the menu bar with the new item
	menuMan.updateMenuBar()
)
-- else print "menu already registered"