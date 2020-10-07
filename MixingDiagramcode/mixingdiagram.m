
function mixingdiagram(particledata,volume,alt,starttime,endtime)
% 
% starttime = 34283;
% endtime = 34945.7;
% alt     = 600; 

sod = unique(particledata.holotimes);
ind = sod > starttime & sod< endtime;
sod = sod(ind);

tic

meandiam = length(sod);
reldisp  = length(sod);
conc     = length(sod);
% figure(3)
top=0;
for i= 1:length(sod)
    ind = find(particledata.holotimes == sod(i) );% particledata.majsiz<100e-6);
    diameter = particledata.majsiz(ind);
%     semilogy(diameter)
%     hold on
    if max(diameter)>top
        top = max(diameter);
    end
    meandiam(i) = mean(diameter);
    reldisp(i) = std(diameter./2)/mean(diameter./2);
    conc(i)    = numel(ind)/volume;
end


[mconc,ind]=(max(conc));



% Relative Dispersion vs n
figure(1)
scatter(conc,reldisp)
title(['Relative dispersion vs n(cm^{-3}): Altitude- ' num2str(alt)  ...
'Time : ' num2str(starttime) '-' num2str(endtime)])
xlabel('n (cm^{-3})')
ylabel('\sigma r^{-1}')
grid on
saveas(gcf,['RelativeDispersion_A' num2str(alt)  ...
'_T' num2str(starttime) '-' num2str(endtime) '.png'])

figure(2)
scatter(conc/mconc,meandiam.^3/meandiam(ind)^3,[],reldisp)
colorbar
axis([0 1 0 4])
title(['Mixing diagram: Altitude- ' num2str(alt) ' Time : ' num2str(starttime)...
    '-' num2str(endtime)])
xlabel('n/n_{0} ')
ylabel('d^{3}/d_{0}^{3}')
grid on
saveas(gcf,['MixingDiagram_A' num2str(alt)  ...
'_T' num2str(starttime) '-' num2str(endtime) '.png'])

end


