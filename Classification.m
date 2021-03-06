% Program to do classification of the reconstructed holographic data

% Path to holograms
% cd([pwd,'\recon'])
rules= {'pixden','ge',0.79;'dsqoverlz','le',2;'underthresh','ge',0.04;'asprat','le',1.5};
pStats = getparticlemetrics(rules,tree)  
save('pStats_v0','pStats','-v7.3')
pStats  = processhistmetrics(pStats);
save('pStats','pStats','-v7.3')

% Combining data to get a single data file
cd ..
mkdir([pwd,'\data'])
cd([pwd,'\data'])


% Removing ghost particles and 
[particledata,gpindex,numgp,dist2d,label] = findghostparticles(pStats.metrics);
particledata = removeshattering(particledata,'chopoff');
save('particledata','particledata','-v7.3')
[area2dvar,volume]=calculatevolume(particledata,label);
save('volume','volume','-v7.3')
% pd=calculatediameter(particledata);
% 
% pStats.diameter= pd;
output = data2bin(pStats,volume);
save('output','output','-v7.3')