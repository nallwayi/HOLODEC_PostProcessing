function plotconcentrations(fcdp,holodec,output,twods)

figure(1)
fcdp_plot = (fcdp.C015+fcdp.C153+fcdp.C345+fcdp.C456)*1.5e-6+(fcdp.C68+fcdp.C810)*2e-6;
plot(output.Second,output.C010*10e-6,holodec.Second,holodec.C010*10e-6,fcdp.Second(:),fcdp_plot(:))
legend('holodec','holodec susanne','fcdp','twods')
title('Concentration:0-10 um')
xlabel('Second of day')
ylabel('concentration/litre')
set(gca,'yscale','log')
saveas(gcf,'Concentration:0-10um.png')

figure(2)
plot(output.Second,(output.C10125+output.C10125)*2.5e-6,holodec.Second,(holodec.C10125+holodec.C12515)*2.5e-6,...
    fcdp.Second(:),(fcdp.C1012(:)+fcdp.C1214(:)+fcdp.C1416(:))*2e-6)
legend('holodec','holodec susanne','fcdp','twods')
title('Concentration:10-16 um')
xlabel('Second of day')
ylabel('concentration/litre')
set(gca,'yscale','log')
saveas(gcf,'Concentration:10-16um.png')

figure(3)
plot(output.Second,(output.C15175+output.C17520)*2.5e-6,holodec.Second,(holodec.C15175+holodec.C17520)*2.5e-6,...
    fcdp.Second(:),fcdp.C1618(:)*2e-6+fcdp.C1821(:)*3e-6)
legend('holodec','holodec susanne','fcdp','twods')
title('Concentration:16-20 um')
xlabel('Second of day')
ylabel('concentration/litre')
set(gca,'yscale','log')
saveas(gcf,'Concentration:16-20um.png')

figure(4)
plot(output.Second,(output.C20225+output.C22525)*2.5e-6,holodec.Second,(holodec.C20225+holodec.C22525)*2.5e-6,...
    fcdp.Second(:),fcdp.C2124(:)*3e-6)
legend('holodec','holodec susanne','fcdp','twods')
title('Concentration:20-25 um')
xlabel('Second of day')
ylabel('concentration/litre')
set(gca,'yscale','log')
saveas(gcf,'Concentration:20-25um.png')

figure(5)
plot(output.Second,(output.C2530)*5e-6,holodec.Second,(holodec.C2530)*5e-6,...
    fcdp.Second(:),fcdp.C2427(:)*3e-6+fcdp.C2730(:)*3e-6)
legend('holodec','holodec susanne','fcdp','twods')
title('Concentration:25-30 um')
xlabel('Second of day')
ylabel('concentration/litre')
set(gca,'yscale','log')
saveas(gcf,'Concentration:25-30um.png')

figure(6)
 plot(output.Second,(output.C3035)*5e-6,holodec.Second,(holodec.C3035)*5e-6,...
    fcdp.Second(:),fcdp.C3033(:)*3e-6+fcdp.C3336(:)*3e-6)
legend('holodec','holodec susanne','fcdp','twods')
title('Concentration:30-35 um')
xlabel('Second of day')
ylabel('concentration/litre')
set(gca,'yscale','log')
saveas(gcf,'Concentration:30-35um.png')

figure(7)
plot(output.Second,(output.C3540+output.C4045)*5e-6,holodec.Second,(holodec.C3540+holodec.C4045)*5e-6,...
    fcdp.Second(:),fcdp.C3639(:)*3e-6+fcdp.C3942(:)*3e-6+fcdp.C4246(:)*3e-6...
    ,twods.Second(:),twods.C3545(:)*10e-6)
legend('holodec','holodec susanne','fcdp','twods')
title('Concentration:35-45 um')
xlabel('Second of day')
ylabel('concentration/litre')
set(gca,'yscale','log')
saveas(gcf,'Concentration:35-45um.png')

figure(8)
plot(output.Second,(output.C4550*5e-6+output.C5060*10e-6),...
holodec.Second,(holodec.C4550*5e-6+holodec.C5060*10e-6),...
    twods.Second(:),twods.C4555(:)*10e-6)
legend('holodec','holodec susanne','twods(45-55 um)')
title('Concentration:45-60 um')
xlabel('Second of day')
ylabel('concentration/litre')
set(gca,'yscale','log')
saveas(gcf,'Concentration:45-60 um.png')

figure(9)
time='33000-38000';
hold off
[avgrad_twods,pdf_twods,concL,dr,variance] = pdfgenerator(twods,time,'1-100');
sum(concL)
[avgrad_holodec_susanne,pdf_holodec_susanne,concL,dr,variance] = pdfgenerator(holodec,time,'1-100');
[avgrad_holodec,pdf_holodec,concL,dr,variance] = pdfgenerator(output,time,'1-100');
[avgrad_fcdp,pdf_fcdp,concL,dr,variance] = pdfgenerator(fcdp,time,'1-100');
plot(avgrad_fcdp,pdf_fcdp,'b')
hold on
plot(avgrad_holodec,pdf_holodec,'r')
hold on
plot(avgrad_holodec_susanne,pdf_holodec_susanne,'g')
hold on 
plot(avgrad_twods,pdf_twods,'c')
xlabel('Average radius (um)')
ylabel('Fractional Concentration/ (l.um)')
legend('fcdp','holodec','holodec\_susanne','twods')
set(gca,'yscale','log')
set(gca,'xscale','log')
grid on
saveas(gcf,'Fractionalconcentration.png')

plottools

end