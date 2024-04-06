%% load original data
expID = 3;%
rescaleFac = 0.1;

expInfo = getExpInfoNatMov(expID);
aparam = getAnalysisParam(expID);
dataPaths = getDataPaths(expInfo, rescaleFac, '', aparam.stimSuffix);

load(dataPaths.imageSaveName,...
    'imageProc','nanMask','theseIdx');
dsRate = 1;%[Hz] %sampling rate of hemodynamic coupling function

%% down sampling if necessary
[observed, TimeVec_ds_c] = prepareObserved(imageProc, dsRate);
mov = reshape(single(observed'), size(imageProc.nanMask,1), size(imageProc.nanMask,2),[]);
%observed = single(observed(:,theseIdx)'); %space x time
avg_im = squeeze(mean(mov,3));

%% convert to SVD
% svdOps.yrange = ; % subselection/ROI of image to use
% svdOps.xrange = ;
% svdOps.RegFile = ops.vids(v).thisDatPath;
% svdOps.Nframes = results(v).nFrames; % number of frames in whole movie
% svdOps.iplane
% svdOps.mimg
% svdOps.NavgFramesSVD
% svdOps.RegFile
% svdOps.ResultsSavePath
% svdOps.mouse_name
% svdOps.date
svdOps.nSVD = 2000;
svdOps.useGPU = 0;
svdOps.roi = ~isnan(imageProc.nanMask);%something is wrong with masking
%[U, Sv, V, totalVar] = get_svdcomps(svdOps);
% [U, Sv, V] = svdCore(imageData.imstack, svdOps);
[U, Sv, V] = svdCore(mov, svdOps);
U = reshape(U, size(imageProc.nanMask,1),size(imageProc.nanMask,2),svdOps.nSVD);
V = V';
svdViewer(U, Sv, V, dsRate);

%% compute dF/F
%[Udf,Vdf] = dffFromSVD(U,V,avg_im);

%% filteirng V
cutoffFreq=[];
lpFreq = 0.3;
fV = filtV(V, dsRate, cutoffFreq, lpFreq);

%% pick seed pixel
pixelCorrelationViewerSVD(U,fV);
%pixelCorrelationViewerSVD(Udf,Vdf);

%% seed-pixel correlation map