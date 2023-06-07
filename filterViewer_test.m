%% testing parameters based on gparamIdx = 2;
%sfmax = 5*32 > #filter = 78729 ... more tiling needed at finer sf or smaller rf sizes


gparamIdx = 2;
subSampleFac = 1;%4;
screenPix = [56 56];%[144 256]/subSampleFac; %Y-X %gaborparams is identical irrespective of the denominator
screenDeg = [15.5556   15.3125];%[40 70]/subSampleFac;%[15 27]; %[deg] = [stimInfo.height stimInfo.width]
showFiltIdx = 1:30; %filter idx to visualize
S = zeros(screenPix(1), screenPix(2), 20); %X-Y-T???

gparams = preprocWavelets_grid_GetMetaParams(gparamIdx);
gparams.show_or_preprocess = 0; %necessary to obtain gaborparams
[S, gparams] = preprocWavelets_grid(S, gparams);%filter assumes no time delay

%% approach 1: spatial
%filtContours = squeeze(mean(abs(S),3));
filtContours = squeeze(S(:,:,round(size(S,3)/2),:));
images(filtContours(:,:,showFiltIdx),[],[],[],showFiltIdx);

% figure;
% for ii=1:size(filtContours,3)%numel(showFiltIdx)
%     contour(squeeze(filtContours(:,:,ii)));hold on
% end


%% temporal
Stmp = reshape(S,size(S,1)*size(S,2),size(S,3),size(S,4));
filtContours_t = squeeze(mean(abs(Stmp),1));
images(filtContours_t(:,showFiltIdx),[],'individual');

%% approach 2: gabor parameters
gaborparams = gparams.gaborparams;
%     .gaborparams = A set of parameters for each Gabor wavelet.
%                       This is a p-by-D matrix where p is number of parameters (8)
%                       and D is the number of wavelet channels
%                       Each field in gaborparams represents:
%                       [pos_x pos_y direction s_freq t_freq s_size t_size phasevalue]
%                       pos_x,pos_y: The spatial center of the Gabor function. The axes are normalized
%                                    to 0 (lower left corner) to 1(upper right corner).
%                                    e.g., [0.5 0.5] put the Gabor at the center of the matrix.
%                       direction: The direction of the Gabor function in degree (0-360)
%                       s_size: Spatial envelope size in standard deviation 
%                       s_freq,t_freq: Spatial frequency and temporal frequency
%                                      They determine how many cycles in
%                                      XYTSIZE pixels for each dimension.
%                                      (NOT cycles per pixel)
%                       t_size: Number of frames to calculate wavelets
%                       phasevalue can be 0 to 6, where
%                         0: spectra
%                         1: linear sin transform
%                         2: linear cos transform
%                         3: half-rectified sin transform (positive values)
%                         4: half-rectified sin transform (negative values)
%                         5: half-rectified cos transform (positive values)
%                         6: half-rectified cos transform (negative values)
%                         7: dPhase/dt
%                         8: dPhase/dt (positive values)
%                         9: dPhase/dt (negative values)
%
% see also: make3dgabor_frames.m

figure;
paramNames = {'pos_x' 'pos_y' 'direction' 's_freq' 't_freq' 's_size' 't_size' 'phasevalue'};
for ii = 1:8
    ax(ii)=subplot(8,1,ii);
    plot(gaborparams(ii,:));
    ylabel(paramNames{ii});
    grid on;
    axis tight padded
end
linkaxes(ax(:),'x');
xlabel('filter number')


showFiltIdx = find(gaborparams(1,:)==0.5 & gaborparams(2,:)==0.5 & gaborparams(3,:)==0);

%% convert to real space
pix2deg = mean(screenDeg./screenPix); %[deg/pix]
gaborparams_r = gaborparams;
[gaborparams_r(1,:),gaborparams_r(2,:)] = relpos2deg(gaborparams(1,:),gaborparams(2,:), screenDeg(2),screenDeg(1));
gaborparams_r(4,:) = 1/mean(screenDeg)* gaborparams(4,:);%s_freq [cpd]
gaborparams_r(5,:) = gaborparams(5,:); %TOBE FIXED
gaborparams_r(6,:) = mean(screenDeg) * gaborparams(6,:); %s_size [deg]
gaborparams_r(7,:) = gaborparams(7,:); %TOBE FIXED


figure;
paramNames_r = {'pos_x [deg]' 'pos_y [deg]' 'direction [deg]' 's_freq [cycles/deg]' ...
    't_freq [cycles]' 's_size [deg]' 't_size [pix]' 'phasevalue [deg]'};
for ii = 1:8
    ax(ii)=subplot(8,1,ii);
    plot(gaborparams_r(ii,:));
    ylabel(paramNames_r{ii});
    grid on;
    axis tight padded
end
linkaxes(ax(:),'x');
xlabel('filter number')

