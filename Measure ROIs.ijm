// **INFO** //
// version: 10/2024 
// loops through multi-series files in a directory and saves each serie as a separate tif file
// author: Ted (Edward) Aplin

// Select file location
#@ File (label = "Select folder to export csv file to", style="directory") output //defines output directory for exported data

// altering settings to measure mean
run("Set Measurements...", "mean redirect=None decimal=6");

// ensures all ROIs are being measured
roiManager("Deselect");

// Measures every frame and slice
roiManager("multi-measure measure_all");

// creating name and saving
title = getTitle();
name = substring(title, 0 , title.length-4);
saveAs("Results",  output + File.separator + name +".csv");

