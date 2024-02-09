function     addSignStar(ax, c)
pth = 0.05;
pairs = c(:,1:2);
pvalues = c(:,6);

theseIdx = find(pvalues<pth);
thesePairs = pairs(theseIdx,:);

for ii = 1:numel(theseIdx)
    yy=get(ax,'ylim');
    line(ax,thesePairs(ii,:),[yy(2) yy(2)],'color','k');hold on;
    if pvalues(theseIdx(ii))<0.01
        thisSymbol = '**';
    elseif pvalues(theseIdx(ii))<0.05
        thisSymbol = '*';
    end
    text(ax,mean(thesePairs(ii,:)),1.02*yy(2),thisSymbol, 'color','k');
    drawnow;
    set(ax,'ylim',[yy(1) 1.1*yy(2)]);
end