function f = showInSilicoORSF(RF_insilico, trange)
% fig = showInSilicoRF(RF_insilico, trange)

if nargin < 2
    trange = [-inf inf];
end

oriList = RF_insilico.ORSF.oriList;
sfList = RF_insilico.ORSF.sfList;
resp = RF_insilico.ORSF.resp;
respDelay = RF_insilico.ORSF.respDelay;

tidx = find(respDelay>=trange(1) & respDelay<=trange(2));
mresp = squeeze(mean(resp(:,:,tidx),3));

crange = prctile(abs(resp(:)),[99]);
f = figure('position',[0 0 1900 1000]);
for isf = 1:size(resp,1)
    subplot(2,size(resp,1),isf);
    imagesc(respDelay, oriList, squeeze(resp(isf,:,:)));
    caxis([-crange crange]);
    if isf==1
        title(['SF (cycles/pix) ' num2str(sfList(isf))]);
    else
        title(num2str(sfList(isf)));
    end
end
xlabel('delay [s]');
ylabel('orientation [rad]');

subplot(212);
imagesc(sfList, oriList, mresp');
ylabel('orientation [rad]');
xlabel('SF (cycles/pix)');

    title('mean across delays');
    caxis([-crange crange]);
    colorbar;

% if RF_ok
%     hold on;
%     plot(RF_Cx, RF_Cy, 'ro');
% end