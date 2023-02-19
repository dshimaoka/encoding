function showMap(anat,map,mask,mapRange,cmap)
%inputs
% anat: background (anatomical) image of gray scale
% map: image to show
% mask: [0 1] image to show map
% mapRange: [min max] vector to specify range of the map
% cmap: colormap (default: half of hsv)

if ~exist('mapRange','var')
    mapRange = [prctile(map(mask),1),prctile(map(mask),99)];
end

if ~exist('cmap','var')
    foo = hsv(256);
    cmap = foo(1:128,:);
end

if isempty(anat)
    anat = zeros(size(map));
end




img = anat;
tmp = 128*(map-mapRange(1))/diff(mapRange);



tmp(tmp<0) = 0;
tmp(tmp>128) = 128;
img(mask) =tmp(mask)+129;



clf
image(img)
h = gca;

colormap([gray(128);cmap]);
axis equal
axis tight

pos = get(gca,'Position');

subplot('position',[pos(1)+pos(3),pos(2),.05,pos(4)]);
image(ones(1,128),linspace(mapRange(1),mapRange(2),128),(129:256)');
%set(gca,'XTick',[-inf,inf]);%this somehow does not work in my environment
set(gca,'YDir','normal');
subplot(h)
