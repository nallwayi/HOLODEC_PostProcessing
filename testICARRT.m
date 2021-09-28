%%  Code to test the ICT archivable file
% Tests:
% 1. Total concentration calculations
% 2. Missing data, upper and lower limit of detection
% 3. Liquid water content
% 4. Comparison with other probes

%  Returns tFlag which is equal to 1 if the total calculated and read 
%  concentrations are equal
%% Main function implementation

% testICARTT(ICARTTfile)
function tFlag = testICARTT(HolodecICARTTfile,FcdpICARTTfile,LwcICARTTfile)

% Reading ICT file
pStats = ICARTTreader(HolodecICARTTfile);
fcdpRead = ICARTTreader(FcdpICARTTfile);
lwcRead = ICARTTreader(LwcICARTTfile);

% Extracting info from Holodec ICT file data
concLRead = pStats.concL;
concLRead(isnan(concLRead)) = -9999;
date = textscan(pStats.header{7},'%s','Delimiter',',');
date = date{1};
% date = str2double(date{1}(1:3));



% Calculate the total concentration
concLCalc = calcConc(pStats);


% Validating concentration value from ICARTT file
% the values are round off to avoid rounding off errors

concLCalc = concLCalc';
concLCalc=round(concLCalc,1);
concLRead=round(concLRead,1);

tFlag = isequal(concLCalc,concLRead);

% Function to look at the missing values 
missingFlag= testMissingvalues(pStats);

% Function to calculate the liquid water content
lwc = calcLiquidWaterContent(pStats);

% Additonal concentration- lwc plots

additionalcomparison(pStats,fcdpRead,lwc,lwcRead,date)



% Plotting the results
figure


subplot(2,2,1)
plot(pStats.Second,concLRead)
hold on
plot(pStats.Second,concLCalc)
set(gca, 'YScale', 'log')
xlim([pStats.Second(1) pStats.Second(end)])
title('Total concentration comparison- Calc vs Read')
xlabel('Seconds after UTC 00:00 (s)')
ylabel('# Concentration (#/l)')
legend('Holodec-Read','Holodec-Calculated')

subplot(2,2,2)
plot(pStats.Second,concLRead)
hold on
plot(fcdpRead.Second,fcdpRead.concL)
set(gca, 'YScale', 'log')
xlim([pStats.Second(1) pStats.Second(end)])
title('Total concentration comparison- Holodec vs FCDP')
xlabel('Seconds after UTC 00:00 (s)')
ylabel('# Concentration (#/l)')
legend('Holodec','Fcdp')

subplot(2,2,3)

image(missingFlag,'CDataMapping','scaled')
title('Holodec- Missing data with bins')
% xlim([pStats.Second(1) pStats.Second(end)])
xlabel('Seconds after UTC 00:00 (s)')
ylabel('bin')


subplot(2,2,4)
plot(pStats.Second,lwc)
hold on
plot(lwcRead.Start_TimeUTC,lwcRead.WCM_TWCgm3)
hold on
plot(lwcRead.Start_TimeUTC,lwcRead.PVMgm3)
hold on
plot(lwcRead.Start_TimeUTC(lwcRead.CAPS_HWgm3 >=0),lwcRead.CAPS_HWgm3(lwcRead.CAPS_HWgm3 >=0))
set(gca, 'YScale', 'log')
xlim([pStats.Second(1) pStats.Second(end)])
title('Liquid Water comparison- Holodec vs Others')
xlabel('Seconds after UTC 00:00 (s)')
ylabel('Liquid Water Content (g/m^3)')
legend('Holodec','WCM','PVM','CAPS')
% lgd.FontSize = 4;

sgtitle(['Research Flight Date: ' date{2} '-' date{3} '-' date{1} ' ' pStats.header{63}])
savefig(['testResults/' date{1} date{2} date{3}])
% plottools


end

%% Function to calculate the total concentration
function concLCalc = calcConc(pStats)
fnames = fieldnames(pStats);
fnames = fnames(5:end);

% Extracting the bining information from the header file
var = textscan(pStats.header{end},'%s','Delimiter',',');
var = var{1};
var = erase(var(4:end),"C:");


binEdges = nan(length(var),2);
concMtrx = nan(length(var),length(pStats.Second));
for cnt = 1:length(var)    
    binEdges(cnt,:) = str2double(strsplit(var{cnt},{'-'}));   
    concMtrx(cnt,:) = pStats.(fnames{cnt});
end

binWidth  = binEdges(:,2)-binEdges(:,1);


concLCalc = size(pStats.Second,1);
for cnt=1:length(pStats.Second) 
    
    if sum(isnan(concMtrx(:,cnt)))==length(binWidth)
        concLCalc(cnt) = -9999;
    else
        concMtrx(isnan(concMtrx(:,cnt)),cnt) =0;
        concLCalc(cnt) = sum(concMtrx(:,cnt).*binWidth);
    end
end

end


%% Function to look at the missing values 

function missingFlag= testMissingvalues(pStats)
fnames = fieldnames(pStats);
fnames = fnames(5:end);

concMtrx = nan(length(fnames),length(pStats.Second));
for cnt = 1:length(fnames)    
    concMtrx(cnt,:) = pStats.(fnames{cnt});
end

ind = find(isnan(concMtrx));
missingFlag=zeros(size(concMtrx));
missingFlag(ind) = 1;

end

%% Function to calculate the liquid water content

function lwc = calcLiquidWaterContent(pStats)
density = 997e3 ; % g/m^3

% Getting the volume from the ICT file
tmp = strfind(pStats.header{46},'cm^3');
volume = str2double(pStats.header{46}(tmp-5:tmp-1));
volume = volume *1e-6; %Conversion to m^3


% Getting the fieldnames
fnames = fieldnames(pStats);
fnames = fnames(5:end);
% Extracting the bining information from the header file
var = textscan(pStats.header{end},'%s','Delimiter',',');
var = var{1};
var = erase(var(4:end),"C:");


binEdges = nan(length(var),2);
concMtrx = nan(length(var),length(pStats.Second));
for cnt = 1:length(var)    
    binEdges(cnt,:) = str2double(strsplit(var{cnt},{'-'}));   
    concMtrx(cnt,:) = pStats.(fnames{cnt});
end

binRadius  = 0.25*(binEdges(:,2)+binEdges(:,1)) *1e-6; %in metre

lwc = size(pStats.Second,1);
for cnt=1:length(pStats.Second) 
    
    if sum(isnan(concMtrx(:,cnt)))==length(binRadius)
        lwc(cnt) = nan;
    else
        concMtrx(isnan(concMtrx(:,cnt)),cnt) =0;
        effRadius3 = sum(binRadius.^3.*concMtrx(:,cnt)) * 1e3; 
        lwc(cnt) = density*4/3*pi*effRadius3; 
        
    end
end



end


%% Additional Comparison

function additionalcomparison(pStats,fcdpRead,lwc,lwcRead,date)

figure
yyaxis left
plot(pStats.Second,pStats.concL)
hold on
plot(fcdpRead.Second,fcdpRead.concL)
set(gca, 'YScale', 'log')
xlim([pStats.Second(1) pStats.Second(end)])
title('Total concentration comparison- Holodec vs FCDP')
xlabel('Seconds after UTC 00:00 (s)')
ylabel('# Concentration (#/l)')
% legend('Holodec','Fcdp')

yyaxis right
plot(pStats.Second,lwc)
hold on
plot(lwcRead.Start_TimeUTC,lwcRead.WCM_TWCgm3)
hold on
plot(lwcRead.Start_TimeUTC,lwcRead.PVMgm3)
hold on
plot(lwcRead.Start_TimeUTC(lwcRead.CAPS_HWgm3 >=0),lwcRead.CAPS_HWgm3(lwcRead.CAPS_HWgm3 >=0))
set(gca, 'YScale', 'log')
xlim([pStats.Second(1) pStats.Second(end)])
title('Liquid Water comparison- Holodec vs Others')
xlabel('Seconds after UTC 00:00 (s)')
ylabel('Liquid Water Content (g/m^3)')
legend('Holodec','Fcdp','Holodec','WCM','PVM','CAPS')

title(['Research Flight Date: ' date{2} '-' date{3} '-' date{1} ' ' pStats.header{63}])
savefig(['testResults/A' date{1} date{2} date{3}])

end