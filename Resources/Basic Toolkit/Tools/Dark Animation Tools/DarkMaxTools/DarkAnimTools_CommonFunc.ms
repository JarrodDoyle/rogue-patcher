/* ------------------------------------------------------
/* 			Dark Animation Tools
/* 			Common Functions
/* ------------------------------------------------------
/* author: Juliusz Kaczmarek
/* ver. 0.01
/* Nov. 2013
/*
/* tools for importing and exporting
/* rigged characters and their motions
/* from and to dark engine games. 
/*
/* this scripted toolset was possible thanks to the knowledge and experience 
/* of Volca, Shadowspawn, Weyoun, Telliamed
/* ------------------------------------------------------
*/
format " - Loading... CommonFuncs\n"

fn insertSpaces txt = 
(
	full = ""
	fragments = filterString txt "&" splitEmptyTokens:true

)

fn stringFormat txt v1:"" v2:"" v3:"" v4:"" v5:"" = (
	full = ""
	values = #(v1, v2, v3, v4, v5)			
	fragments = filterString txt "%" splitEmptyTokens:true	
	for i = 1 to fragments.count do 
	(		
		fragment = fragments[i]
		if i < fragments.count then
			nextFragment = fragments[i+1]
		else
			nextFragment = undefined
		--print (i as string + fragment)
		strValue = if values[i] == undefined then "" else values[i] as string
		if nextFragment != undefined then 
		(
			if matchPattern nextFragment pattern:"{*}*" then (
				closingBracketPos = findString nextFragment "}"
				formatToken = subString nextFragment 2 (closingBracketPos-2)
				fragments[i+1] = subString nextFragment (closingBracketPos + 1) nextFragment.count 
				filteredFormatToken = filterString formatToken ":"
				token = filteredFormatToken[1]
				tokenValue = (filteredFormatToken[2] as integer)
				case token of (
					"f":(
						--print strValue
						stringFloat = ((strValue as float) as string) + "00000000000"
						--print stringFloat
						strValue = substring stringFloat 1 ((findString stringFloat ".") + tokenValue)
					)
				)
			)
		)
		full += fragment
		full += strValue
	)	
	full
)

fn bigger x1 x2 =
(
	if x1>x2 then x1 else x2
)

fn smaller x1 x2 =
(
	if x1<x2 then x1 else x2
)

fn average a b =
(
	result = case (classof x1) of (
		#Point3:[(a.x + b.x) / 2, (a.y + b.y) / 2, (a.z + b.z) /2]
		#Point2:[(a.x + b.x) / 2, (a.y + b.y) / 2]
		default:((a + b) / 2)
	)
	result
)

fn averageArray arr =
(
	local sum = case (classof arr[1]) of (
		#Point3:[0,0,0]
		#Point2:[0,0]
		default:0
	)
	for i = 1 to arr.count do sum += arr[i]
	sum = sum / arr.count
	return sum	
)

fn reverseArray arr = (
	revArr = #()
	for i = arr.count to 1 by -1 do (
		append revArr arr[i]
	)
	revArr
)

fn clamp what mini maxi = 
(
	if what < mini then what = mini
	if what > maxi then what = maxi
	what
)

fn arraySum numArray = (
	sum = 0
	for num in numArray do (
		sum += num
	)
	sum
)

fn findItems arr keyItem colNum = (
	found = #()
	for item in arr do (
		if item[colNum] == keyItem[colNum] then 
			append found item
	)
	found
) 

-- Reads string from a binary file ---
fn ReadBString File size = 				 
(
	Fstring = ""		
	zero = false
	for j=1 to size do
	(
		charCode = (ReadByte File)
		charCode = case of
		(
		(charCode<32):0
		(charcode>127):0
		default:charCode
		)
		if ((charCode!=0) and (zero==false)) then Fstring = Fstring + (bit.intAsChar charCode)
		else zero = true
	)
	Fstring
)
	
fn WriteBString File Fstring size = 
(
	for j = 1 to size do
	(
		if j > Fstring.count then
		(
			WriteByte File 0 #unsigned
		)
		else
			WriteByte File (bit.CharAsInt Fstring[j]) #unsigned
	)
)
	
-- INI file related

-- a getINIsetting function with a default value (which is returned, if the key does not exist)
fn getDefINIsetting INIfile catString keyString defaultValue = (
	if (hasINIsetting INIfile catString keyString) == false then (
		val = defaultValue
	) else (
		val = getINIsetting INIfile catString keyString
	)
	val
)


fn getString &what key =
(	
	keyValue = getINIsetting INIfilePath sectionName key
	if keyValue != "" then what = keyValue
-- 	format "Reading from INI, %: %\n" key keyValue
)

fn getInteger &what key =
(	
	keyValue = getINIsetting INIfilePath sectionName key
	if keyValue != "" then what = (keyValue as integer)
-- 	format "Reading from INI, %: %\n" key keyValue
)

fn invertArray arr =
(
	local inverted = #()
	inverted = for i = arr.count to 1 by -1 collect arr[i]
)

--- CSV file parsing
-- similar in result to filterString, but retains empty CSV file fields as 'undefined' values in array
-- so no field is skipped.
fn filterStringCSV str chrs =
(
	arr = #()
	val = ""
	while str.count>0 do
	(
		chr = str[1]
		case chr of (
			",":
			(
				append arr val
				val = ""
			)
			"'":()	-- skip single quote
			default:append val chr
		)
		if str.count>1 then str = substring str 2 str.count
			else str = ""
	)
	append arr val
	arr
)

fn skipToNextLine2 &file =
(
	skipToNextLine file
	rememberPos = filePos file
	ln = readLine file
	if ln=="" then
		seek file (rememberPos+1)	
	else
		seek file rememberPos	
)

-- returns a row of data as an array
fn getDataRowLabel &file label skipFirst =
(
	local ln, fln
	seek file 0
	skipToString file label
	--skipToNextLine2 file
	readLine file  -- skips to next line
	ln = readLine file
	fln = filterStringCSV ln ",'\""	-- comma and single quote here!
	if skipFirst == true then deleteItem fln 1
	fln
)

fn getDataRowNext &file skipFirst =
(
	local ln, fln
	ln = readLine file
	fln = filterStringCSV ln ",'"	-- comma and single quote here!
	if skipFirst == true then deleteItem fln 1
	fln
)

fn interpolate A B num steps =
(
	result = A
	if steps > 1 then
	(
		range = B - A
		percent = 0.01 * (num - 1) * (100.0 / (steps - 1) )
		result = A + percent * range
	)
	else
	result = A
	
)

fn bool2int bool =
(
	if bool == True then return 1
		else return 0
)

fn indexSort v1 v2 valArray: = (
	local val1
	local val2
	val1 = valArray[v1]
	val2 = valArray[v2]
	if val1 < val2 then return -1
	if val1 > val2 then return 1
	if val1 == val2 then return 0
)

-- Returns active controller 
-- In case of single controllers, like Position_XYZ the function returns itself
-- In case of compound controllers like List or Layer Controllers it returns current controller/layer
fn getActiveController controller =
(
	if isProperty controller #active then (		
		controller = getActiveController controller[controller.active] 
	)	
	return controller
)
	
-- Simple dictionary-like structure
-- use 'add' to add a new or set value of an existing dictionary item

struct SimpleDict (
	private
	items = #(),
	
	public
	fn keys = for item in items collect item.v1,
	
	fn values = for item in items collect item.v2,
	
	private
	fn _index key = 	return findItem (keys()) key,
		
	public
	fn add key val =
	(	
		index = _index key
		if index == 0 then (
			append items (DataPair key val)
		) else (
			items[index] = DataPair key val
		)
	),
	
	fn get key =
	(	
		index = _index key
		if index > 0 then (
			return items[index].v2
		)
		return undefined
	),
	
	fn has key = 
	(
		index = _index key
		if index > 0 then 
			return true
		else
			return false
	),
	
	fn remove keyOrKeyArray =
	(
		if classof keyOrKeyArray != Array then
			keysToDelete = #(keyOrKeyArray)
		else
			keysToDelete = keyOrKeyArray
		
		for key in keysToDelete do (
			id = _index key
			if id > 0 then
				deleteItem items id
		)
	)		
)

fn getLastDirectory folderPath delim:"\\" = (
	dirNames = filterString folderPath delim
	dirNames[dirNames.count]
)

fn OpenFolder path = (
	command = stringFormat "explorer \"%\"" v1:path
	HiddenDOSCommand command donotwait:true
)

/* Recursive function that copies entire folder structure */
fn copyFolder sourceFolder destination = (
	destFoldername = getLastDirectory sourceFolder
	destDirname = (destination + "\\" + destFoldername)
	makeDir destDirname
	--format "Created folder % \n" destDirname

	sourceFiles = getFiles (sourceFolder + "\\*.*")
	for sFile in sourceFiles do 
	(
		fileName = filenameFromPath sFile 				
		destFile = destDirname + "\\" + fileName
		copyFile sFile destFile
		--format "Copied % to %\n" sFile destFile
	)

	sourceDirs = getDirectories (sourceFolder + "\\*")
	for sDir in sourceDirs do 
	(
		copyFolder sDir destDirname				
	)
)
		
/* 	A function that twists in place a joint/control/any-object-really around the X axis.
	It goes through all the existing keys and twists by 90 degree either clockwise or counter clockwise
	and then twists children in the opposite direction in their parent space.
	Use it to correct some twisted joints, as it happens for certain motions.
	Args:	
		joint - an object to 'untwist'. Currently it assumes X is the length axis
		direction - #cw for clockwise or #ccw for counter clockwise
*/
fn correctTwist joint twistAngle whichKeys =
(		
	twistEulerAngles = EulerAngles twistAngle 0 0 
	untwistEulerAngles = EulerAngles -twistAngle 0 0
	children = joint.children
	ctrlr = getActiveController joint.rotation.controller
	with animate on 
	(
		if whichKeys == 1 then (
			for key in ctrlr.keys do 
			(
				at time key.time
				(
					in coordsys local rotate joint twistEulerAngles
					in coordsys parent rotate children untwistEulerAngles
				)		
			)
		)
		else (
			in coordsys local rotate joint twistEulerAngles
			in coordsys parent rotate children untwistEulerAngles
		)
			
	)			
)