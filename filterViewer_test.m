gparamIdx = 11;%2;
screenPix = [144 256];%/4; %Y-X %gaborparams is identical irrespective of the denominator
screenDeg = [15 27]; %[deg]
showFiltIdx = 1:30; %filter idx to visualize
S = zeros(screenPix(1), screenPix(2), 20); %X-Y-T???

gparams = preprocWavelets_grid_GetMetaParams(gparamIdx);
gparams.show_or_preprocess = 0; %necessary to obtain gaborparams
[S, gparams] = preprocWavelets_grid(S, gparams);%filter assumes no time delay

%% approach 1: spatial
%filtContours = squeeze(mean(abs(S),3));
filtContours = squeeze(S(:,:,round(size(S,3)/2),:));
images(filtContours(:,:,showFiltIdx),[],[],[],showFiltIdx);


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
%                       s_size: Spatial envelope size in standard deviation 1=entire screen
%                         
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
%pix2deg = mean(screenDeg./screenPix); %[deg/pix]
gaborparams_real = gaborparams;
gaborparams_real(4,:) = 1/max(screenDeg)* gaborparams(4,:);%s_freq [cpd]
gaborparams_real(6,:) = 1/max(screenDeg) * gaborparams(6,:); %s_size [deg]

