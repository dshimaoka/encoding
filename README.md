# utility functions
- getExpInfoNatMov.m: list of natural movie experiments, returning expInfo
- getDataPaths.m: retrieve paths to imageData/roiData/stimData/encoding result/played movie
- getAnalysisParam.m: parameters for analysis of a given experiment ID
- stimPix2Deg.m: convert pixels to visual field degree
- deg2StimPix.m: convert visual field degree to pixels on the screen
- getFoveaPix.m: pixel location corresponding to fovea. Registered for each exp
- findConnectedPixels.m: find neiboring pixels with same sign. used in statAcrossAreas.m

# functions/scripts for encoding modeling
- makeDataBase: create timeTable data. this script uses:
analysisImaging/saveImageProcess, getOETimes
- prepareObserved: 

# scripts for analysis using result of encoding modeling
- showCompositeMap.m: create images of preferred alititute/azimuth/vfs/brain image
- fitByEccentricityBin.m: 
- summaryAcrossPix.m: 
- statAcrossAreas.m: 


# scripts for figures