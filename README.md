# utility functions
- getExpInfoNatMov.m: list of natural movie experiments, returning expInfo
- getDataPaths.m: retrieve paths to imageData/roiData/stimData/encoding result/played movie
- getAnalysisParam.m: parameters for analysis of a given experiment ID
- getAreaStatsParam.m: parameters for areal analysis (Fig5) dommon across experiments
- stimPix2Deg.m: convert pixels to visual field degree
- stimDeg2Pix.m: convert visual field degree to pixels on the screen
- getFoveaPix.m: pixel location corresponding to fovea. Registered for each exp
- findConnectedPixels.m: find neiboring pixels with same sign. used in statAcrossAreas.m
- getPixPerMm.m: retrieve pisel size per mm, at a given rescale factor
- addScaleBar.m: add scale bar to a given axis and a rescale factor
- addSignStar.m: add star symbols indicating significance, called in statsAcrossAreas_pop.m
- getArray.m: retrieve array numbers for a sbatch scrpt 
- getROIIdx.m: retrieve pixel index (x,y) from roi mask image
- getSFrange_stim: minimum and maximum SF included in the visual stimulus in cycles per deg

# energy model
- filterViewer.m: show kernels's spatiotemporal characters to a given gparamIdx
- relpos2deg: convert relative position on the screen [0 1] to visual field in degree
- getSFRange_mdl: min and max SF of the energy model, specified as gparamIdx
- showFiltParams.m: create a figure to show parameters of all kernels in the energy model, called in filerViewer.m

# functions/scripts for encoding modeling
- getFilterParams.m: retrieve energy model parameters to a given gparamIdx
- prepareObserved.m: returns observed signal (time x pixel) at dsRate [Hz] after preprocDownSample and preprocNormalize
- preprocAll.m: returns energy model response to movie
- ridgeSx_cv.m: ridge regression with cross-validation capability
- saveGaborBankOut.m: save output of the energy model, called in makeStimDataBase
- makeStimDataBase.m: save output of saveGaborBank across all movies
- makeDataBase.m: create timeTable data. this script uses:
analysisImaging/saveImageProcess, getOETimes
- trainAneuron.m: train an encoding model, called in trainAndSimulate
- trainAndSimulate.m: train an en encoding model then run in silico simulations, called in wrapper_encoding.m
- detectNGidx: check if a training result exists in a designated directory. called by wrapper_encoding
- wrapper_encoding.m: loads processed data by makeDataBase.m, fit one pixel with ridge regression, evaluate the fit result with in-silico simulation
- script_wrapper.sh: script to run wrapper_encoding.m in parallel w SBATCH

# scripts for characterising result of encoding modeling
- makeStimDataBase_inSilico.m: wrapper to create and save stimulus used in silico stimulations
- getInSilicoRFstim.m: obtain stimulus used for in silico simulation to obtain receptive field (same across camera pixels)
- getInSilicoDIRSFTFstim.m: obtain stimulus used for in silico simulation to obtain receptive field (same across camera pixels)
- getInSilicoRF: run in silico simulation to obtain receptive field
- showInSilicoRF: show summary figures of the result of in silico simulation (getInSilicoRF)
- getInSilicoDIRSFTF: run in silico simulation to obtain preferred direction, sf, and tf
- showInSilicoDIRSFTF: show summary figures of the result of in silico simulation (getInSilicoDIRSFTF)
- makeStimDataBase_inSilico.m
- analyzeInsilicoRF.m: analyse result of in silico simulation to obtain receptive field, called in summaryAcrossPix
- analyzeInSilicoDIRSFTF.m: analse result of in silico simulation to characterise preferred direction, sf and tf, called in summaryAcrossPix
- fitoriWrapped.m: obtain preferred direction via fitting, called in analzeInSilicoDIRSFTF
- oritune(Wrapped).m: sum of two gaussians living on a circle, for orientation tuning
- fitit.m: fit data to a given function
- filterHist.m: show images of RF (Fig 1G) and a histogram of kernel coefficients of a given pixel (Fig 1F)

# scripts on ephy-imaging (Fig 4)
- CJ231_sparsenoise_figures2.m: compute receptive fields from sparse noise stimulation
- alignEphys2Image_paper.m: run image registration to match images from ephys and imaging
- ephys_imaging_CJ231_DS05.m: create figures for preferred position from ephys and imaging

# scripts for summarizing characters of encoded model 
- showCompositeMap.m: create images of preferred alititute/azimuth/vfs/brain image
- fitByEccentricityBin.m: returns average and standard error across pixels within a bin, used in statAcrossAreas.m
- summaryAcrossPix.m: obtain preferred position, SF, TF, direction of each pixel, save as 'encoding_(date)_resizeXX_(stimSuffix)_nxv_summary.mat'
- showSummaryFig.m: create maps of preferrd posiion and field sign (fig2C,D, 3C), called in summaryAcrossPix
- showRFpanels: show transition of RF centers (fig2E), called in summaryAcrossPix
- getAreaStats.m: divide summary_adj into each area
- statAcrossAreas.m: create summary for each experiment (fig5A-G), save as '(ID)_eccentricity-sigma-sf'
- statsAcrossAreas_pop.m: create summary across experiments (fig5H-M)
- alignVFS.m: align field sign maps across experiments (fig3D)