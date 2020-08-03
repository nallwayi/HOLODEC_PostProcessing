function plotsamplevolume(area2dvar)
    
    binsize=100;
    x = -7250:binsize:7250;
    y = -4850:binsize:4850;
    z = 20000:10*binsize:140000;
    matrix3d = nan(length(z)-1,(length(y)-1)*(length(x)-1));
    for i=1:length(z)-1

        matrix3d(i,area2dvar{i}(1,:)) = 1;
    end
    matrix3d = reshape(matrix3d',length(y)-1,length(x)-1,length(z)-1);

%  Plotting sample volume slices
    figure
    [x,y] = meshgrid(1:145,1:97);
    for off=1:10:120   
        z = off + zeros(size(y));
        c = matrix3d(:,:,off);
        im= surf(z,x,y,c);
        set(im, 'EdgeColor', 'none');
        hold on
    end
    view(350,0)
    saveas(gcf,'Volume Slices.png')
end