// **INFO** //
// version: 10/2025
// Saving every file in a folder as a video in the AVI format
// author: Ted (Edward) Aplin



//GUI asking for inputs
#@ String (value = "Saving every file in a folder as a video in the AVI format", visibility="MESSAGE", required=false, persist=false) hint1 // adds text, can be used inbetween inputs too
#@ String (value = "Author: Edward (Ted) Aplin", visibility="MESSAGE", required=false, persist=false) hint2 // adds text, can be used inbetween inputs too

#@ File (label = "Select folder with raw data", style="directory") input //defines folder with raw data
#@ File (label = "Select folder to export files to", style="directory") output //defines output directory for exported data

#@ Integer (label = "Frames per Second") FPS
#@ string (label = "Channels for recording", choices={"All","Single"}, style="radioButtonHorizontal") MultiChannel
#@ Integer (label = "Channel for recording (if Single)") Channel
#@ string (label = "Run maximum Z projection?", choices={"Yes","No"}, style="radioButtonHorizontal") Zproject
#@ string (label = "Run auto brightness/ contrast?", choices={"Yes","No"}, style="radioButtonHorizontal") ABC

//cleanup
setBatchMode(true);
close("*");

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

// setting up count for errors
TotalError = 0;

//the macro
for (b = 0; b < fileList.length; b++) { // for each file in the list of relevant files
	
	// get their name and filepath
	name=fileList[b];
	fname_with_path = input + File.separator + fileList[b];
	
	// open the file with Bio-formats Importer, with virtual stack on to allow for greater file sizes on less powerful hardware
	// if there is an issue, you can turn virtual stack off by reming "use_virtual_stack" from the end of the string below
	run("TIFF Virtual Stack...", "open=[" + fname_with_path + "]");
	print("Analyzing Image " + name);// notifying user
	
	error = 0;
	getDimensions(width, height, channels, slices, frames);
	
	// checking if it is a timeseries
	if (frames == 1){
		print("only 1 frame so no video made, you can make a photo using the Save as PNG macro")
		error = 1
	}
	
	// running Z projection
	if (Zproject == "Yes"){
		if (slices == 1) {
			print("no Maximum Projection processed as only 1 slice");
		}
		else {
			run("Z Project...", "projection=[Max Intensity] all");
			print("Maximum intensity projected");
		}
	}
	
	// running auto brightness and contrast
	if (ABC == "Yes"){
		run("Brightness/Contrast...");
		run("Enhance Contrast", "saturated=0.35");
		print("run auto brightness/ contrast");
	}
	
	// working with multiple channels
	if (MultiChannel == "Single"){
		
		// Checking if the channel is in range
		if (Channel == 0 || Channel > channels){
			print(" ERROR: couldn't create video as channel not present");
			print(" ERROR: entered " + Channel + " but there are only " + channels + " channels present");
			error = 1;
		}
		
		// selecting the single channel
		else if (channels > 1) {
			run("Split Channels");
			selectImage("C" + Channel + "-" + name);
			print("Channel " + Channel + " selected");
		}
	}
	
	// if everything worked then save
	if (error == 0) {
		savename = substring(name, 0 , name.length-4);
		outputname = output + File.separator + savename + ".avi";
		run("AVI... ", "compression=JPEG frame=" + FPS + " save=[" + outputname + "]");
		print("Video created");
	}
	
	// count up the error if there was a failure
	if (error == 1) {
		TotalError = 1;
	}
	close("*");
}

// error warning
if (TotalError != 0) {
	showMessage(TotalError + " errrors detected, please check the log");
}

else {
	showMessage("'save video as AVI' macro completed");
}


