// **INFO** //
// version: 10/2025
// Template Macro for completing tasks on all relevant files in a folder
// author: Edward (Ted) Aplin



//GUI asking for inputs
#@ String (value = "Explanation for Macro", visibility="MESSAGE", required=false, persist=false) hint1 // adds text, can be used inbetween inputs too
#@ String (value = "Author: Edward (Ted) Aplin", visibility="MESSAGE", required=false, persist=false) hint2 // adds text, can be used inbetween inputs too

#@ File (label = "Select folder with raw data", style="directory") input //defines folder with raw data
#@ File (label = "Select folder to export files to", style="directory") output //defines output directory for exported data

#@ String (value = "Choose which channel for stabilisation, best to use a channel with consistent recognisable structures e.g. (cell membranes)", visibility="MESSAGE", required=false, persist=false) hint3 // adds text, can be used inbetween inputs too
#@ int (label = "Channel:") Channel //defines channel for stabilisation
#@ String (value = "Max pixel shift is how many pixels the image can move between each frame, I recommend starting at 1 and moving up if the stabilisation is too subtle", visibility="MESSAGE", required=false, persist=false) hint4 // adds text, can be used inbetween inputs too
#@ int (label = "max pixel shift:") Shift

//cleanup
setBatchMode(true);
close("*");
Error = 0

//creates a list of only specific fileformat files

list = getFileList(input);
fileList = newArray(0);

// if all is selected then it lists all files with a relevant filetype from the folder
for (l = 0; l < list.length; l++) {
   	if (endsWith(list[l], ".tif"))
   	fileList = Array.concat(fileList, list[l]);
}

// stopping if no relevant files
if (fileList.length == 0) {
	exit("no relevant files in input directory");
}

//the macro
for (b = 0; b < fileList.length; b++) { // for each file in the list of relevant files
	
	// get their name and filepath
	name=fileList[b];
	fname_with_path = input + File.separator + fileList[b];
	
	// open the file with with virtual stack on to allow for greater file sizes on less powerful hardware
	// if there is an issue, you can turn virtual stack off by reming "use_virtual_stack" from the end of the string below
	run("TIFF Virtual Stack...", "open=[" + fname_with_path + "]");
	print("Analyzing Image " + name);// notifying user
	FileSize = File.length(fname_with_path);
	getDimensions(width, height, channels, slices, frames);
		
	// Warning if the file size is too large
	if (FileSize > 3990000000) { 
		print(" ERROR: file too large for stabilisation, please use the 'Compress Files.ijm' macro first");
		Error = Error + 1;
	}
	
	// Warning if the channel is out of range
	else if (Channel == 0 || Channel > channels) {
		print(" ERROR: Channel " + Channel + " not present, there are " + channels + " channels present in this file");
		Error = Error + 1;
	}
	
	// if all suitable then run the program and save the new file
	else{
		setBatchMode(true);
		run("Correct 3D drift", "channel=" + Channel + " multi_time_scale sub_pixel edge_enhance only=0 lowest=1 highest=" + slices + " max_shift_x=" + Shift + " max_shift_y=" + Shift + " max_shift_z=1.000");
		print("Successfully stabilised Image " + name);
		selectImage("registered time points");
		
		//renaming title
		title = getTitle();
		name = substring(title, 0 , title.length-4);
		saveName = name + "_stabilised";
		
		// saving the output as a Tiff
		saveAs("Tiff",  output + File.separator + saveName +".tif");
	}

		
	// updating the User
	print("File processed.");
	// closing anything open
	close("*");
}

// telling the user it is complete
if (Error == 0) {
	showMessage("'TIFF stabilisation' macro completed successfully");
}
else {
	showMessage(" WARNING: " + Error + " Files were not able to be stabilised, please check the log");
}
