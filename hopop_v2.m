%%
% -------------------------------------------------------------------------
%                   Holodec Post Processing Code
% -------------------------------------------------------------------------
%  
% Author: Nithin Allwayin
% Version 2, Oct 1, 2021

% This code is used to do the post processing works on the reconstructed
% hologram data (mat files). 
% It includes functions to 
%   1. Read the pd information from the mat files
%   2. Apply the "rules" and classify using a decision tree
%   3. Find and remove ghost particles
%   4. Modify the sample volume to account for shattering effects and less
%       dectectablility with increasing Z distance
%   5. Calculate the modified sample volume for DSD calculations
%   6. Convert the particle stats file to archivable format

% -------------------------------------------------------------------------

% Pre requisites
%   1. Holosuite code added to path
%   2. HOPOP code addes to path
%   3. Statistics and Machine Learning Toolbox
%   4. Parallel Computing Toolbox
%   5. Preferably over 16 GB RAM
%% 

% Inputs

pathtomatfiles = '/hulk/data/Susanne/IOP2/RF07/recon';
pathtosaveresults = '/hulk/data/Nithin/IOP2/';
dynamicRules = {'pixden','ge',0.80;'dsqoverlz','le',2;'underthresh',...
    'ge',0.04;'asprat','le',1.5};
pathtodecisionTrees = '/hulk/data/Nithin/HOPOP_Test/';
convert2ArchiveFrmt = 'yes'; % yes or no input
predictionParams.method = 'cnn';
predictionParams.model = '/home/nallwayi/SoftwareInstallations/holosuite/predict_pipeline/modelsNN/AE2_cnn_liquid_ft';

%% Execution of the Code
disp('-------------------------------')
disp('Holodec Post Processing Code ')
disp('-------------------------------')
disp('Post processing started...')


cd (pathtomatfiles)


% Prelimiary rules to remove the sure noise 
rules= {'pixden','ge',0.60;'dsqoverlz','le',10;'underthresh','ge',0.04;'asprat','le',3};
disp('Reading the mat files')
pStats = getparticlemetrics(rules); 

cd (pathtosaveresults)
mkdir([pStats.header '_HOPOP_V2_results'])
cd ([pStats.header '_HOPOP_V2_results'])
disp('Saving the level 0 processed pStats file')
save('pStats_p0','pStats','-v7.3')


% Rules from the optimization. This field can be left blanc
rules= dynamicRules;
disp('Removing noise using dynamic rules and decision trees/CNN')
if strcmp(predictionParams.method,'cnn')
    predictionParams.pred_path = [fullfile(pathtosaveresults,pStats.header)...
        '_HOPOP_V2_results/CNNFiles'];
else
    load([pathtodecisionTrees 'decisionTrees.mat'])
    predictionMethodParams.tree = tree;
end
pStats  = processhistmetrics(pStats,rules,predictionParams);
disp('Saving the level 1 processed pStats file')
save('pStats_p1','pStats','-v7.3')


% Ghost particle removal
disp('Removing Ghost Particles')
[pStats] = removeGhostParticle(pStats);


% Optimizing the sample volume
disp('Optimizing the sample volume')
pStats = trimEdges(pStats); %Trimming the edges
pStats.volume = calculatevolume(pStats); % Calculating new  volume
disp('Saving the level 2 processed pStats file')
save('pStats_p2','pStats','-v7.3')




% Conversion to the archivable format
if strcmp(convert2ArchiveFrmt,'yes')
    disp('Conversion to the archivable format')
    holodec = data2bin(pStats);
    save('holodec','holodec')
end

disp('')
disp('Post processing completed.')
disp('-------------------------------')




