function  saveGaborBankOut(dataPaths, c, ...
    dsRate, gaborBankParamIdx, yrange,xrange, theseTrials, useGPU)
% S_fin = saveGaborBankOut(moviePath, c, dsRate)
% returns output of gabor-wavelet bank
if nargin < 9
    useGPU = 0;
end
if nargin < 8
    theseTrials = 1:c.nrTrials;
end

%cparams = preprocColorSpace_GetMetaParams(1);
for itr = theseTrials
    
    %     tempData = ['preprocAll_temp_' num2str(itr)];
    [~,prefix] = fileparts(dataPaths.stimSaveName);
    tempData = [prefix '_temp_' num2str(itr) '.mat'];
    
    if exist(tempData, 'file')
        continue;
    end
    
   disp([num2str(itr) '/' num2str(c.nrTrials)]);
   
    %% correct dropped frames
    [~, frameIdx_final, timeVec_stim_NG, frames_reconstruct] = ...
        c.movie.reconstructStimulus(...
        'moviePath',dataPaths.moviePath,'trial',itr);
    
    if nargin < 6 || isempty(yrange)
        yrange = 1:size(frames_reconstruct,1);
    end
    if nargin < 7 || isempty(xrange)
        xrange = 1:size(frames_reconstruct,2);
    end
    frames_reconstruct = frames_reconstruct(yrange,xrange,:,:);
    
    disp(['trialTimeby cic: ' num2str(numel(frameIdx_final)/c.screen.frameRate) '[s]']);
    %disp(['trialTime by OEphys: ' num2str(OETimes.stimOffTimes(itr)-OETimes.stimOnTimes(itr)) '[s]']);
    
    
    %% preprocess movies ... SUPER SLOW!!!
    %frames_reconstruct  = single(frames_reconstruct)/255;%is this necessary?
    
    %useGPU = 0; %necessary for High-res movies
    
    [frames_fin, TimeVec_stim] = preprocAll(frames_reconstruct, gaborBankParamIdx, ...
        c.screen.frameRate, dsRate, useGPU);
    
    duration = get(c.movie.prms.duration,'atTrialTime',inf)/1e3;

    theseFrames = 1:round(dsRate*duration);
    frames_fin = frames_fin(theseFrames,:);
    
    
    %% save data per trial
    save(tempData,'frames_fin','TimeVec_stim');
    clear frames_fin TimeVec_stim
end
