function showFiltParams(gaborparams, S, showFiltIdx)
%showFiltParams(gaborparams, S, showFiltIdx)

%[gaborparams_real, gaborparams, S] = getFilterParams(gparamIdx, screenPix, screenDeg);

% showFiltIdx = 1:30; %filter idx to visualize
if nargin < 3 || isempty(showFiltIdx)
showFiltIdx = find(gaborparams(1,:)==0.5 & gaborparams(2,:)==0.5 & gaborparams(3,:)==0);
end

%% approach 1: spatial
%filtContours = squeeze(mean(abs(S),3));
filtContours = squeeze(S(:,:,round(size(S,3)/2),:));
[~,a]=images(filtContours(:,:,showFiltIdx),[],[],[],showFiltIdx);
axis(a(:),'equal','tight');


%% temporal
Stmp = reshape(S,size(S,1)*size(S,2),size(S,3),size(S,4));
filtContours_t = squeeze(mean(abs(Stmp),1));
images(filtContours_t(:,showFiltIdx),[],'individual',[],showFiltIdx);


%% approach 2: gabor parameters
figure;
paramNames = {'pos_x' 'pos_y' 'direction' 's_freq' 't_freq' 's_size' 't_size' 'phasevalue'};
for ii = 1:8
    ax(ii)=subplot(8,1,ii);
    plot(gaborparams(ii,showFiltIdx));
    ylabel(paramNames{ii});
    grid on;
    axis tight padded
end
linkaxes(ax(:),'x');
xlabel('filter number')



