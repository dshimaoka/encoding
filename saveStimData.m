function [S_fin, TimeVec_stim_cat] = saveStimData(moviePath, c, stimInfo, ...
    dsRate, gaborBankParamIdx, uploadResult)
% S_fin = saveStimData(moviePath, c, dsRate)
% returns output of gabor-wavelet bank

S_fin = [];TimeVec_stim_cat=[];
% cparams = preprocColorSpace_GetMetaParams(1);
for itr = 1:c.nrTrials
    %% correct dropped frames
    [~, frameIdx_final, timeVec_stim_NG, frames_reconstruct] = c.movie.reconstructStimulus(...
        'moviePath',moviePath,'trial',itr);
    
    disp(['trialTimeby cic: ' num2str(numel(frameIdx_final)/c.screen.frameRate) '[s]']);
    %disp(['trialTime by OEphys: ' num2str(OETimes.stimOffTimes(itr)-OETimes.stimOnTimes(itr)) '[s]']);
    
    
    %% preprocess movies ... SUPER SLOW!!!
    frames_reconstruct  = single(frames_reconstruct)/255;%is this necessary?
    
    [frames_fin, TimeVec_stim] = preprocAll(gaborBankParamIdx, frames_reconstruct, c.screen.frameRate, ...
        dsRate);
    
    theseFrames = 1:round(dsRate*stimInfo.duration);
    S_fin = cat(1,S_fin, frames_fin(theseFrames,:));
    
    if itr==1
        TimeVec_stim_cat = TimeVec_stim;
    else
        TimeVec_stim_cat = cat(1, TimeVec_stim_cat, TimeVec_stim_cat(end) + 1/dsRate + TimeVec_stim);
    end
end

if uploadResult
    dirPref = getpref('nsAnalysis','dirPref');
    oeOriServer = dirPref.oeOriServer; %direct ethernet connection
    saveDir = fullfile(oeOriDir, fullOEName);

    % save gabor filter output as .mat
    % stimSaveName = fullfile(saveDirBase,expDate,...
    %     ['stimData_' regexprep(expDate, '\','_') '_' expName '.mat']);
    % save( stimSaveName, 'TimeVec_stim_cat', 'S_fin', 'energyModelParams');
end