GoalMaster 1.1 by R Soul

**** Introduction ****
This program simplifies the process of creating goals/objectives for the Thief games.

It blatantly rips off the user interface of Thief Objective Wizard (made by William the Taffer) but then it takes things further:
In addition to creating goals, GoalMaster lets you specify the goal text, and allows goals to be re-arranged.
Another useful feature is that you can save and load all that info so you can stop and resume work at any point.
The program will export the "goals.str" file, and a ".cmd" file which DromEd uses to generate the goal data.
    A new feature for version 1.1 allows you to import a selection of goals from any other GoalMaster file (these get added to the end of your current goal list).

It does help to be reasonably aware of the original way of creating goals. Quick summary:
    Goals in Dromed can be set up with various commands (e.g. quest_create_mis goal_visible_3, 1, quest_create_mis goal_state_3, 0 etc).   
    It can be quite tedious for a large number of goals, and it can be easy to make a mistake or miss something. Easily fixed but not always easy to see what's wrong if a goal isn't working properly.
    If you decide to change the order of goals, you have to clear some or all of them, the redo the commands.
    The text for each goal is set via "fiction_n" and "text_n" lines in "goals.str". Easy to make formatting errors, and rearranging can mean changing lots of numbers and having to take care to get them right.

GoalMaster can generate the text for "goals.str", and a ".cmd" file which you can run in DromEd to set the correct goal parameters.


**** Installation ****
Extract "GoalMaster.exe" and "Newtonsoft.Json.dll" into any folder, and it will be ready to run.
If you're overwriting an older version, you can use the same folder.

When you first run the program, go to Tools and then Settings to select the required folders for exporting (or do this whenever you want to change the values).
    If you have overwritten from version 1.0, the settings file has changed. GoalMaster will look for "dirs.txt", will import what it finds, then rename the old file so you can see it's worth deleting (it doesn't delete the file itself in case of an error that you want to review.


**** Instructions ****

On the left is the current Goal List.
Above and on the right is the mission number, which should match the value in Dromed's 'Dark Mission Description' property.

On the right, the Goal Number menu tells you which goal you're currently editing.
Fiction is the text you see while choosing your difficulty level.
Text is the text you see during the mission.
Summary is an optional field which is only used by GoalMaster.

The Goal List will try to display the summary. If that is blank, or it says (Optional), it will try to display the Text. If that's blank, it will try to display the Fiction.
If that is also blank, it will simply display 'Goal: X'.

The purpose of the summary is to allow you to add any extra details about the goal (e.g. "Steal object 1251, Hard only) without affecting the Fiction or Text values.

At first, the only available goal number is 0.

** Setting up a goal **
This is the simplest part. Choose whatever values apply to the first goal (0). The original Dromed tutorial/Komag's tutorial etc explains these values.

For the Type, select 'No Type' if the objective's state will be managed by a QuestVarTrap in Dromed.

** Buttons **
Update List adds the current goal to the Goal List. If there's already a goal with the selcted goal number, you'll be asked if you want to overwrite.

Each time you update, GoalMaster will take you to the next goal to be added. E.g. if the last goal in the list is goal 5, GM will set up an empty goal 6.

Reset Target fields resets the values of the selected Type to the default value. This can be useful if you've set a complicated loot goal with gold, gems and goods, and then change your mind and want to do something else.

Reset All Variables does exactly that - sets all values to their defaults. This will uncheck all of the 'Other' flags, reset difficulty etc.

** Updating an exisitng goal **

If a goal is in the Goal List and needs to be updated, just click on it and its values will be shown. Edit them and click on Update List.
You can also update a goal by changing the Goal Number from the menu at the top.

** Re-ordering and deleting goals **

Select a goal from the list and the Up/Down buttons can rearrange them.

When a goal is deleted, any goals that came after it will have their numbers reset. The Dark Engine does not allow goal numbers to be skipped. If you want to disable a goal, just make it invisible.

Version 1.1 note:
    There is now the option to "skip" a goal so that GoalMaster will not generate any DromEd commands for that goal number, nor any text in goals.str. A button will appear prompting you go read a warning to make sure you know what you're doing
    (in short, Thief doesn't allow goal numbers to be skipped, but you might want to prevent GoalMaster overwriting some goals you've already defined in DromEd)

**** Saving and Exporting ****
If you go to File > Save, all the goal data are saved as a plain text ".json" file, i.e. the goal list, the text values and the mission number. You can reload the file and continue making changes. This has no effect on your FM's goals or .cmd files.

File > Export gives you the option of generating the .cmd and or goals.str files. The Export window shows you what files will be created. You can change the paths by going back to the main window and going to Tools > Settings.

**** Opening or Importing ****
File > Open lets you load previously saved goals data so you can add to/edit an existing list.

File > Open Legacy lets you load goals data from the previous file format used up to GoalMaster 1.01 (saving is now in ".json" format only, so this feature is only for recovering old work).

File > Import Selection lets you bring in a selection of goals from any other GoalMaster file (you can choose from the current ".json" format or the old ".gml" format).
(these will be added to your current list of goals rather than replacing them).

**** Languages ****
The Settings window gives you the option to type in a language folder name. I have briefly tested it with some German characters and it looks okay, but futher testing is required.
(I vaguely recall some discussion about issues with characters ouside the standard Latin alphabet, but this will need further testing to see if any further work is needed to GoalMaster)

**** DromEd ****
If the export setting were correct, the objective text will already be in place.

Make sure your Editors > Mission Variables > Dark Mission Description is set up.

Run the .cmd file that GoalMaster generated, and you should then be able to see your goal.
For each goal specified, GoalMaster will have also generated the necessary commands to delete any previous parameters set for that goal (to prevent them interfering with how the current goal works).

********** If you want to delete all objective data before you run GoalMaster's .cmd file. Many packages, e.g. the Dromed Toolkit/Tafferpather, include a 'nogoals.cmd' file, or you can search for it on TTLG or Discord etc.

**** Extra thing *****
If you run GoalMaster with a single parameter, a number, the program will use that as your mission number.

**** ++++ Version changes ++++ ****

1.1
Changed format of GoalMaster's save/load file to the plain text ".json" format. A future-proofing feature to make it easier to share goals data with other applications.
    GoalMaster can still load from the original format so you can get data from the previous version.
The settings are now edited in the Settings window (instead of a text file) for easier changing. Also changed the file format to ".json" in case external editing is required.
    The old format settings will be imported if GoalMaster finds them, but this is a one-off process.
Added a setting for the default Open/Save folder.
Added the ability to import a selection of goals from another GoalMaster file.
Added the ability to "skip" a goal (i.e. do not generate commands or goals.str entry)
Tweaked the "tab" order in the UI to make it easier to use keyboard controls.
Pressing Enter will add the current goal data to the list.
Synchronised the "Goal Number" drop down menu with the main goals list selection on the left.
Choosing the last item from the menu will reset all goal data to the default values.
Tweaked some directory-searching code to make it easier for GoalMaster to find its own file on Linux using Wine.

1.01:
Removed a space that wrongly added to the T1/G special loot command.

1.0:
Set goal parameters and text, edit and re-order them, export goals.str and DromEd command list, save and load goals data to file.


Robin Collier, 2025 and counting!
