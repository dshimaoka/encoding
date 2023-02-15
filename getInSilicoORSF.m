function [mresp, oriList, sfList] = getInSilicoORSF(gparamIdx, r0, rr, ...
    lagFrames, tavg, screenPix, Fs, nRepeats, nORs, sfList)
%INPUT:
%gparamIdx: parameter Idx supplied to preprocWavelets_grid_GetMetaParams
%r0: scalar
%rr: [nDelays of hemodynamic coupling x nFilters]
%screenPix: screen pixel size (assume same size of x & y )
%Fs: sampling rate of in-silico visual stim
%nRepeats: number of stimulus presentation per OR and SF
%nOR: number of ORs (equally spaced between 0-pi
%sfList: list of SFs (cycles per pixel)
%
% OUTPUT:
%mresp: resp across repeats and delays [nORs x nSFs x nNeurons]
%oriList: list of ORs (1st dim of mresp) (rad)
%sfList: list of SFs (2nd dim of mresp) (cycles per pixel)

if nargin < 9 || isempty(nORs)
    nORs = 10;
end
if nargin < 10
    sfList = linspace(1/screenPix, 1/2, 5);
%sfList = [0.05 0.1 0.15 0.2]';
end
nNeurons = size(rr,3);
nSF = length(sfList);

gparams = preprocWavelets_grid_GetMetaParams(gparamIdx);
gparams.show_or_preprocess = 0;
[gab, pp] = preprocWavelets_grid(zeros(screenPix,screenPix), gparams);
nFilters = length(gab);
if ~isequal(size(rr,2), nFilters)
    error('#filters does not match. Check 1st and 3rd inputs');
end


%%1 make sparse white noise
oriList = pi/180*linspace(0,180,nORs+1)';
oriList = oriList(1:end-1);

if size(sfList,1) < size(sfList,2)
    sfList = sfList';
end

%random varibles: spatial phase and OR and SF
oriSfStream = repmat(1:nORs*nSF, 1, nRepeats);
oriSfStream = oriSfStream(randperm(nORs*nSF*nRepeats));
[sfIdxStream, oriIdxStream] = ind2sub([nSF nORs], oriSfStream);
oriStream = oriList(oriIdxStream);
sfStream = sfList(sfIdxStream);

nOns = length(oriStream);

onFrames = gparams.tsize*(1:nOns);
timeVec = 1/Fs*(1:(onFrames(end)+gparams.tsize));


%making 2dgabor
phaseStream = 2*pi*rand(1,nOns);
%pix2deg = 1;
xdeg = (1:screenPix)-0.5*screenPix;
ydeg = xdeg;
[X,Y]=meshgrid(xdeg,ydeg);
stim_is = single(zeros(screenPix,screenPix,length(timeVec)));
for ff = 1:nOns
    XY = X*cos(oriStream(ff))+Y*sin(oriStream(ff));
    AngFreqs = 2*pi* sfStream(ff) * XY + phaseStream(ff);
    stim_is(:,:,onFrames(ff)) = sin(AngFreqs);
end
stim_is = 0.5*(stim_is+1); %[0-1]


%% 2 compute response of the filter bank
gparams = preprocWavelets_grid_GetMetaParams(gparamIdx);
[S_gab, gparams] = preprocWavelets_grid(stim_is, gparams);%<use future times
nlparams = preprocNonLinearOut_GetMetaParams(1);
[S_nl, nlparams] = preprocNonLinearOut(S_gab, nlparams);
nrmparams = preprocNormalize_GetMetaParams(1);
[S_nm, nrmparams] = preprocNormalize(S_nl, nrmparams);
S_nm = S_nm';
%impose delay so the filter uses signal only from the past
S_nm = circshift(S_nm, round(gparams.tsize/2), 2);
%< up to here nNeurons does not matter

%% 3 compute responese of the wavelet filter
lagRange = [min(lagFrames)/Fs max(lagFrames)/Fs];%lag range provided as rr
lagRange_model = [0 (gparams.tsize-1)/Fs];
mresp = zeros(nSF, nORs, nNeurons);
parfor iNeuron = 1:nNeurons
    [observed] = predictXs(timeVec, S_nm, ...
        squeeze(r0(iNeuron)), squeeze(rr(:,:,iNeuron)), lagRange, tavg);
    
    %% 4 test OR tuning
    avgPeriEventV = eventLockedAvg(observed, timeVec, timeVec(onFrames), ...
        oriSfStream, lagRange_model);
    %      avgPeriEventV: nEventTypes x nCells x nTimePoints
    mresp_tmp = squeeze(mean(avgPeriEventV,3))';
    mresp(:,:,iNeuron) = reshape(mresp_tmp, nSF, nORs);
    %sresp = squeeze(mean(periEventV,3));
    
end
