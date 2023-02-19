function [S, timeVec] = preprocPRF(S, PRFparam, frameRate, dsRate)
%[S, timeVec] = preprocAll(S, paramIdx, frameRate, dsRate)
%
%INPUT
%S: x-y-c-t
%frameRate: original sampling rage in Hz
%dsRate: desired downsampling rate in Hz (default:1)

%OUTPUT
%S_fin: (frame number) x (filter number)

%PRFparam
%hdr hemodynamic impulse response function
%phi = stimInfo.screenPix(2)?
%theta = stimInfo.screenPix(1)?
%     cf saveStimInfo_stimCorrectedKalatsky2:
%     [PHI, THETA] = box2sphere(myScreenInfo.Dist, POSX, POSY);
%nAng = 16;  %number of polar angles
%radList = linspace(.1,2,16);  %number of eccentricities

if ~isempty(PRFparam.cparamIdx)
    cparams = preprocColorSpace_GetMetaParams(PRFparam.cparamIdx);
    [S, cparams] = preprocColorSpace(S, cparams);
end

S = reshape(S,size(S,1)*size(S,2),[])'; %S must be frames x pixels
tmpS = conv2(S,PRFparam.hdr);  %S is at 120Hz
tmpS = tmpS(1:(size(S,1)),:)';

[x,y] = meshgrid(PRFparam.phi,PRFparam.theta);
nx= length(PRFparam.phi);
ny = length(PRFparam.theta);
r = sqrt(x.^2+y.^2);

[angList,radList] = meshgrid(linspace(-pi/2,pi/2,PRFparam.nAng),PRFparam.radList);
sigList = (radList+.05)/4;  %corresponding list of sigmas (RF sizes)

G  = zeros(nx*ny,length(radList));
%img = zeros(ny,nx);
clear baseRF
for i = 1:length(radList(:))
    rad= radList(i);
    ang = angList(i);
    sig = sigList(i);
    
    xc = rad*cos(ang);
    yc = rad*sin(ang);
    baseRF(i).center = [xc,yc];
    
    baseRF(i).sig = sig;
    baseRF(i).shutup = 1;
    tmp =  Gauss(baseRF(i),x,y);
    G(:,i) = tmp(:);
end

% Generate predicted responses for each possible receptive field to the
% stimulus.  This is a simple matrix multiplication:
S = tmpS*G;

% Compute log of each channel to scale down very large values
if ~isempty(PRFparam.nlparamIdx)
    nlparams = preprocNonLinearOut_GetMetaParams(PRFparam.nlparamIdx);
    [S, nlparams] = preprocNonLinearOut(S, nlparams);
end

timeVec = 1/frameRate*(0: size(S,1)-1)';

% Downsample data to the sampling rate of your fMRI data (the TR)
if ~isempty(PRFparam.dsparamIdx)
    %resample so the framerate is integer
    times_rs = (timeVec(1):1/round(frameRate): timeVec(end))';
    S = interp1(timeVec, S, times_rs);
    
    dsparams = preprocDownsample_GetMetaParams(PRFparam.dsparamIdx); % for TR=1; use (2) for TR=2
    dsparams.imHz = round(frameRate);
    dsparams.sampleSec = 1/dsRate;
    [S, dsparams] = preprocDownsample(S, dsparams);
    timeVec = preprocDownsample(times_rs,dsparams);
end

% Z-score each channel
if ~isempty(PRFparam.nrmparamIdx)
    nrmparams = preprocNormalize_GetMetaParams(PRFparam.nrmparamIdx);
    [S, nrmparams] = preprocNormalize(S, nrmparams);
end