% CompileData.m
% Step 1 in the 3 step process of analyzing and visualizing mouse
% retinotopy data.
%
% This step spatially subsamples and temporally interpolates the stimulus
% movies in 'visualStim.mat' to match the temporal sampling rate of the
% experimental data.  The result is the matrix 'S' which is a nt x  npixel
% matrix.  The resampled spatial positions are defined by the vectors phi
% (x) and theta (y), and the time is defined by the vector t.
%
% The unwrapped images in S are binary - 1's where there was a checkerboard
% stimulus and 0 otherwise.
%
% This script also generates the matrix R which contains the imaging data,
% spatially unwrapped and concatenated across stimuli.  The size of R is an
% nt x npixel matrix where the temporal sampling is defined by the same
% vector t as in the stimulus matrix S. Each column of R is an unrapped
% nRows x nCols optical image.

function [S, R, t, phi, theta, nRows, nCols] = ...
    CompileData(saveDir, dnSamp, Exps, dataSuffix, StackName)

%input
% visualStim, phi, theta, time ... loaded internally

%output

%takes a minute on zombie


AnimalDir   = fullfile( saveDir, [Exps.animal '_ratio']); % 13.10.18 DS
SeriesDir   = fullfile(AnimalDir, sprintf('%03d', Exps.iseries));
ExpDir      = fullfile(SeriesDir, sprintf('%03d', Exps.iexp));

visualStimName = fullfile(ExpDir, [Exps.animal '_' num2str(Exps.iseries) '_' ...
    num2str(Exps.iexp) 'stimInfo']);
load(visualStimName, 'visualStim','phi','theta','time');

%%
% Load in the visual stimulus
%
%load visualStim
[ny,nx,nt,ns] = size(visualStim);

% pick a stimulus and frame to show for demonstration - these do not
% affect the saved result.
frameShow  =10;
stimShow = 1;


% Spatial downsample factor.  pRF methods do not require a high-resolution
% model of the stimulus, and downsampling speeds up the fitting process dra
%dnSamp = 25;  %needs to divide into the size of the original stimulus

%%
% unwrap x and y dimensions into columns
stim = reshape(visualStim,[ny*nx,nt,ns]);

figure(1)
showUnwrappedImg(phi,theta,stim(:,frameShow,stimShow));

%%
% Get rid of black (unstimulated) regions ouside projector range

for stimNum = 1:ns
    meanImg = squeeze(mean(stim(:,:,stimNum),2));
    id = meanImg == 0;
    for frameNum=1:nt
        stim(id,frameNum,stimNum) = 129;
    end
end

figure(2)
showUnwrappedImg(phi,theta,stim(:,frameShow,stimShow));

%%
% Find black images at the end of each sequence and set them to gray

for stimNum=1:ns
    meanT = squeeze(mean(stim(:,:,stimNum),1));
    blankFrames = meanT==min(meanT);
    stim(:,blankFrames,stimNum) = 129;
end

%%
% Make mask by turning checkerboard to 1 and background to zero
stim(stim==255) = 1;
stim(stim==0) = 1;
stim(stim==129) = 0;

figure(3)
showUnwrappedImg(phi,theta,stim(:,frameShow,stimShow)*255);


%%
% Spatial downsample


dnphi = phi(floor(dnSamp/2):dnSamp:end);
dntheta= theta(floor(dnSamp/2):dnSamp:end);
dnnx = length(dnphi);
dnny = length(dntheta);

dnStim = zeros(dnny,dnnx,size(visualStim,3),size(visualStim,4));

stim = reshape(stim,[ny,nx,nt,ns]);

for i=1:dnSamp
    for j=1:dnSamp
        yy = i:dnSamp:ny;
        xx = j:dnSamp:nx;
        dnStim = dnStim + double(stim(yy,xx,:,:));
    end
end
dnStim = dnStim/dnSamp^2;

dnStim = reshape(dnStim,[dnny*dnnx,nt,ns]); %space x time x condition

figure(4)
clf


showUnwrappedImg(dnphi,dntheta,dnStim(:,frameShow,stimShow)*255);

% This will show the whole movie
% showUnwrappedImg(dnphi,dntheta,dnStim(:,:,2)*255,time);

%%
% Load and concatenate data, and interpolate the stimulus to match the
% temporal sampling of the data.
p = ProtocolLoadDS(Exps);
   
R = [];
t = [];
S = [];

for iStim = 1:ns
    
    %tmpStim = dnStim(:,:,iStim);
    %load(sprintf('data/%d_avg_detrend',iStim));
    StackDir = tools.getDirectory( saveDir, p, Exps.ResizeFac, ...
        iStim, 1, Exps.Cam, dataSuffix);
    %FileName = 'nanMean_detrend';
    MyStack = tools.LoadMyStacks(StackDir, StackName);
    
    if ~exist('TimeVec_align','var')
        TimeVec_align = MyStack.TimeVec;
        if size(TimeVec_align,1) > size(TimeVec_align,2)
            TimeVec_align = TimeVec_align';
        end
    end
    
    [MyStack.Values, idx_align] = ...
        tools.alignTimeStamp(MyStack.Values, MyStack.TimeVec, TimeVec_align);
    MyStack.nFrames = length(TimeVec_align);
                
    %MyStack = MyStack.Trim([beginTime endTime]);%this is done in
    %saveStack_stimCorrectedKalatsky2
    
    %[nry,nrx,nrt] = size(MyStack.Values);
    
    tmpValues = reshape(MyStack.Values,[MyStack.nRows*MyStack.nCols],MyStack.nFrames);
    
    R = [R;tmpValues'];
    
    tmpS = zeros(MyStack.nFrames,size(dnSamp,1));
    
    MyStack.TimeVec(TimeVec_align>max(time)) = max(time);
    MyStack.TimeVec(TimeVec_align<min(time)) = min(time);
    
    
    %This automatically select period of trimmed stackset
    for i=1:size(dnStim,1);
        tmpS(:,i) = interp1(time,dnStim(i,:,iStim),TimeVec_align)';
    end
    S = [S;tmpS];
    if iStim == 1
        t = TimeVec_align';
    else
        t = [t;(TimeVec_align'+t(end))];
    end
    
end

phi = dnphi;
theta =dntheta;
nRows = MyStack.nRows;
nCols = MyStack.nCols;

%%
% Save the results for the next step
%save CompiledData S R t phi theta nRows nCols



