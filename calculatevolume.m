
function volume = calculatevolume(pStats)
voxRmd3dInd = pStats.GP3dStats.voxRmd3dInd ;
pixRmd2dInd = pStats.GP2dStats.pixRmd2dInd ;
trmdEdgeVoxInd = pStats.trimEdges.trmdEdgeVoxInd ;
hlsRmd2dInd = pStats.GP2dStats.hlsRmd2dInd;

binsize = 100e-6;
volPerVox = binsize^3*10;

z_llim = trmdEdgeVoxInd(1,5);
z_ulim = trmdEdgeVoxInd(end,5)+ binsize*10;
zbin    = z_llim:binsize*10:z_ulim;
zsize   = length(zbin)-1;


% Removing all ghost particle indices outside the Z limts
if ~isempty(voxRmd3dInd)
    voxRmd3dInd((voxRmd3dInd(:,3)< z_llim | voxRmd3dInd(:,3)> z_ulim),:)...
        =[];
end

rmvGPVoxInd = [];
rmvHolesInd = [];
for cnt=1:length(trmdEdgeVoxInd)
    x_llim = trmdEdgeVoxInd(cnt,1);
    x_ulim = trmdEdgeVoxInd(cnt,2);
    y_llim = trmdEdgeVoxInd(cnt,3);
    y_ulim = trmdEdgeVoxInd(cnt,4);
    
    xbin    = x_llim:binsize:x_ulim ;
    ybin    = y_llim:binsize:y_ulim ;


    xsize   = length(xbin)-1;
    ysize   = length(ybin)-1;

%     Total number of voxels per Z bin
    TotVoxperZbin = xsize * ysize;
    
    
    if ~isempty(voxRmd3dInd)
        rmvInd3d = find(voxRmd3dInd(:,1) >= x_llim & ...
            voxRmd3dInd(:,1) < x_ulim & ...
            voxRmd3dInd(:,2) >= y_llim & ...
            voxRmd3dInd(:,2) < y_ulim & ...
            voxRmd3dInd(:,3) >= zbin(cnt) & ...
            voxRmd3dInd(:,3) < zbin(cnt+1));
    end
    
    if ~isempty(pixRmd2dInd)
        rmvInd2d = find(pixRmd2dInd(:,1) >= x_llim & ...
            pixRmd2dInd(:,1) < x_ulim & ...
            pixRmd2dInd(:,2) >= y_llim & ...
            pixRmd2dInd(:,2) < y_ulim );
    end
    
    if ~isempty(hlsRmd2dInd)
        rmvIndhls = find(hlsRmd2dInd(:,1) >= x_llim & ...
            hlsRmd2dInd(:,1) < x_ulim & ...
            hlsRmd2dInd(:,2) >= y_llim & ...
            hlsRmd2dInd(:,2) < y_ulim );
    end    
    
    if exist('rmvInd2d','var') && exist('rmvInd3d','var')
        vox2Rmv = union(voxRmd3dInd(rmvInd3d,1:2),...
            pixRmd2dInd(rmvInd2d,1:2),'rows');
        vox2Rmv(:,3) = zbin(cnt); 
    elseif exist('rmvInd2d','var')
        vox2Rmv = pixRmd2dInd(rmvInd2d,1:2);
        vox2Rmv(:,3) = zbin(cnt); 
    elseif exist('rmvInd3d','var')
        vox2Rmv = voxRmd3dInd(rmvInd3d,1:2);
        vox2Rmv(:,3) = zbin(cnt); 
    else
        vox2Rmv = [];
    end
    
	rmvGPVoxInd = [rmvGPVoxInd;vox2Rmv]; 
    
    if exist('rmvIndhls','var')
        vox2Rmv = union(vox2Rmv(:,1:2),hlsRmd2dInd(rmvIndhls,:),'rows');
        hlsRmdZbin = hlsRmd2dInd(rmvIndhls,:);
        hlsRmdZbin(:,3) = zbin(cnt); 
    end
	rmvHolesInd = [rmvHolesInd;hlsRmdZbin];    
    
    nVox2Rmv = size(vox2Rmv,1);

    noVoxperZbin(cnt) = TotVoxperZbin - nVox2Rmv;
%     noVoxperZbin(cnt) = TotVoxperZbin;

end



noVoxForVolume = sum(noVoxperZbin);
volume = (noVoxForVolume)*volPerVox *1e6 ; % cm^3
plotRmdVlmElmts(pStats.header,trmdEdgeVoxInd,rmvGPVoxInd,rmvHolesInd)

pStats.volume = volume;
end


function plotRmdVlmElmts(header,trmdEdgeVoxInd,rmvVoxInd,rmvHolesInd)

% Conversion to mm
trmdEdgeVoxInd = trmdEdgeVoxInd *1e3;
rmvVoxInd = rmvVoxInd*1e3;
rmvHolesInd = rmvHolesInd *1e3;

f= figure('Name','RmdVxls','units','normalized','outerposition',[0 0 1 1]);

scatter3(rmvHolesInd(:,1),rmvHolesInd(:,2),rmvHolesInd(:,3),'gs','filled')
hold on
scatter3(rmvVoxInd(:,1),rmvVoxInd(:,2),rmvVoxInd(:,3),'rs','filled')
hold on
scatter3(trmdEdgeVoxInd(:,1),trmdEdgeVoxInd(:,3),trmdEdgeVoxInd(:,5),...
    'k','filled','LineWidth',0.5)
hold on
scatter3(trmdEdgeVoxInd(:,1),trmdEdgeVoxInd(:,4),trmdEdgeVoxInd(:,5),...
    'k','filled','LineWidth',0.5)
hold on
scatter3(trmdEdgeVoxInd(:,2),trmdEdgeVoxInd(:,3),trmdEdgeVoxInd(:,5),...
    'k','filled','LineWidth',0.5)
hold on
scatter3(trmdEdgeVoxInd(:,2),trmdEdgeVoxInd(:,4),trmdEdgeVoxInd(:,5),...
    'k','filled','LineWidth',0.5)
hold off
title('Optimized sample volume')
xlabel('x (mm)')
ylabel('y (mm)')
zlabel('z (mm)')
legend('Voxels removed- below LT','Voxels removed- GP')
savefig([header '_optimizedVolume.fig'])
close(f)
end