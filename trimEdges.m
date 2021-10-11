function pStats = trimEdges(pStats)

global xsize ysize zsize xbin ybin zbin
noPrtcls = size(pStats.metrics.timestamp,1);

% Defiing the volume limits
x_llim = -7250e-6;
x_ulim = 7250e-6;
y_llim = -4850e-6;
y_ulim = 4850e-6;
z_llim = 25000e-6;  % New Zlimits 
z_ulim = 145000e-6; % New Zlimits 


binsize = 100e-6;
xbin    = x_llim:binsize:x_ulim;
ybin    = y_llim:binsize:y_ulim;
zbin    = z_llim:binsize*10:z_ulim;

xsize   = length(xbin)-1;
ysize   = length(ybin)-1;
zsize   = length(zbin)-1;


d2nebin = (y_ulim-50e-6:-binsize:0) ;
d2nesize   = length(d2nebin)-1;


%  Removing particles outside Z-limits to remove Shattering effects
shatterInd = pStats.metrics.zpos < z_llim & ...
    pStats.metrics.zpos > z_ulim ;
fnames = fieldnames(pStats.metrics);
for cnt=1:length(fnames)
    pStats.metrics.(fnames{cnt})(shatterInd) = [];
end


% Determining the dist of d2ne with zpos
for cnt=1:zsize       
    prtclesIndxPerZbin{cnt} = find(pStats.metrics.zpos > zbin(cnt) ...
        & pStats.metrics.zpos <= zbin(cnt+1)); 
end
for cnt=1:d2nesize        
    prtclesIndxPerd2nebin{cnt}  = find(pStats.metrics.d2ne <= d2nebin(cnt) ...
        & pStats.metrics.d2ne  > d2nebin(cnt+1));
end


for cnt = 1:d2nesize
    for cnt2 = 1:zsize
        prtclesIndxPerZd2nebin = ...
            intersect(prtclesIndxPerd2nebin{cnt},prtclesIndxPerZbin{cnt2});
        prtclesCntPerZd2nebin(cnt,cnt2) = numel(prtclesIndxPerZd2nebin);
    end
    divfac = (y_ulim*4+x_ulim*4-4*d2nebin(cnt));
    %/(y_ulim*4+x_ulim*4-4*d2ne(end));%Perimeter division
    prtclesCntPerZd2nebin(cnt,:) = prtclesCntPerZd2nebin(cnt,:)/divfac;
end

normftr = max(max(prtclesCntPerZd2nebin(1:15,1:10))); % normalizind factor;
prtclesCntPerZd2nebin = prtclesCntPerZd2nebin/normftr;
   
% Determination the 60 percent cutoff
cutOff = 0.75;
d2neCutoff = nan(1,zsize);
for cnt=1:zsize
    temp =find(prtclesCntPerZd2nebin(:,cnt) > cutOff, 1, 'last' );
    if ~isempty(temp) && temp < d2nesize
        d2neCutoff(cnt) = d2nebin(temp);
    else
        d2neCutoff(cnt)=nan;
    end
end


d2neCutoffInd = find(~isnan(d2neCutoff));
d2neCutoffFit = polyfit(zbin(d2neCutoffInd),d2neCutoff(d2neCutoffInd),1);
d2neCutoffSlope = d2neCutoffFit(1);
d2neCutoffIntrcp = d2neCutoffFit(2);
d2neCutoffFitLine = d2neCutoffSlope.*(0.5*(zbin(1:end-1)+zbin(2:end)))...
    +d2neCutoffIntrcp;




% Removing the particles out of the Cutoff bound
rmEdgeInd =[];
trmdEdgeVoxCnt=1;

for cnt=1:zsize
    tmp =find(pStats.metrics.d2ne < d2neCutoffFitLine(cnt) & ...
    pStats.metrics.zpos > zbin(cnt) & pStats.metrics.zpos <= zbin(cnt+1));
    rmEdgeInd   = [tmp;rmEdgeInd];
    [~,d2neCutoffInd] = min(abs(d2neCutoffFitLine(cnt)-d2nebin));
    
%     trmdEdgeVoxInd(trmdEdgeVoxCnt:trmdEdgeVoxCnt+3,:) = ...
%         [ xbin(end)-d2neCutoffFitLine(cnt)  ...
%         ybin(end)-d2neCutoffFitLine(cnt) zbin(cnt);
%         xbin(1)+d2neCutoffFitLine(cnt)  ...
%         ybin(end)-d2neCutoffFitLine(cnt) zbin(cnt);
%         xbin(end)-d2neCutoffFitLine(cnt)  ...
%         ybin(1)+d2neCutoffFitLine(cnt) zbin(cnt);
%         xbin(1)+d2neCutoffFitLine(cnt)  ...
%         ybin(1)+d2neCutoffFitLine(cnt) zbin(cnt);];
    trmdEdgeVoxInd(trmdEdgeVoxCnt,:) =[xbin(1)+d2nebin(d2neCutoffInd)...
        xbin(end)-d2nebin(d2neCutoffInd) ...
        ybin(1)+d2nebin(d2neCutoffInd) ...
        ybin(end)-d2nebin(d2neCutoffInd) zbin(cnt);];
    trmdEdgeVoxCnt = trmdEdgeVoxCnt+1;
end
fnames = fieldnames(pStats.metrics);
for cnt=1:length(fnames)
    pStats.metrics.(fnames{cnt})(rmEdgeInd) = [];
end

% trmdEdgeVoxInd = sort(trmdEdgeVoxInd);
pStats.trimEdges.rmEdgeInd = rmEdgeInd;
pStats.trimEdges.trmdEdgeVoxInd = trmdEdgeVoxInd;

% Getting the voxel locations of trimmed regions
for cnt = 1: zsize
    
end


f=figure('Name','TrimEdges','units','normalized','outerposition',[0 0 1 1]);
Img = pcolor(0.5*(zbin(1:end-1)+zbin(2:end))*1e3,...
    0.5*(d2nebin(1:end-1)+d2nebin(2:end))*1e3,prtclesCntPerZd2nebin);
Img.EdgeColor = 'none';
set(gca,'YDir','reverse')
colormap('jet')
hold on
scatter(0.5*(zbin(1:end-1)+zbin(2:end))*1e3,d2neCutoff*1e3,15,'x',...
'MarkerFaceColor', '#FFFFFF','MarkerEdgeColor','#000000' )
hold on
plot(0.5*(zbin(1:end-1)+zbin(2:end))*1e3,d2neCutoffFitLine*1e3,'Color',...
    '#FF0000','LineWidth',1)
hold off
title('Trimming the edges to optimize volume ')
xlabel('x (mm)')
ylabel('d2ne (mm)')

savefig([pStats.header '_d2ne_z_cutoff.fig'])
close(f)
end

