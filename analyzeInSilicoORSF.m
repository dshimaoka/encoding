function RF_insilico = analyzeInSilicoORSF(RF_insilico, peakPolarity,trange)
if nargin < 2
    peakPolarity = -1;
end
if nargin < 3
    trange = [-inf inf];
end
tidx = find(RF_insilico.ORSF.respDelay>=trange(1) & RF_insilico.ORSF.respDelay<=trange(2));
resp = RF_insilico.ORSF.resp(:,:,tidx);


resp = peakPolarity*resp;

%option0: simply detect the minimum
[amp, idx] = max(resp(:));
[sfidx, oridx, tidx] = ind2sub(size(RF_insilico.ORSF.resp), idx);

RF_insilico.ORSF.bestSF = RF_insilico.ORSF.sfList(sfidx);
RF_insilico.ORSF.bestOR = 180/pi*RF_insilico.ORSF.oriList(oridx); %deg

%option1: 2D gaussian fitting