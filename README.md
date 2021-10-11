HOLODEC_PostProcessing- Version 2

Overview: 
HOPOP (HOLODEC Post Processing code) is a set of functions to do the post processing works on the output mat files after hologram reconstruction.
The code in general should work for all the deployments of HOLODEC and can be extended to all holographic probes that use HOLOSUITE with minor changes to the code. 

Functions of the code: 
  •	Read the hist.mat files
  •	Apply the dynamic set of rules and decision trees created
  •	Remove the ghost particles and account for the nearly empty regions (laser fluctuation issue)
  •	Adjust the volume to account for the shattering effects and the low detectability with Z distance 
  •	Calculate the optimized volume to account for the changes in previous steps
  •	Convert the data file to archive format
  
Version 2: 
The holograms are individually read and then compiled to get the primary raw file. This defines the processed version '0' of the pStats file. 
The dynamic rules are then applied to do the preliminary noise removal. Each hologram is then categorized using a cutoff to use either of the decision trees. 
The result gives the version '1' of the pStats file. Note that different set of dynamic rules and decision trees can be used on the pStats_p0 file 
to get a different pStats_p1 file. This part can also be modified in the next updates to use the neural network classification schemes instead of the decision trees.
Then ghost particles are removed, edges are trimmed and the volume optimized to give the final version of the pStats (p2) file.

Pre requisites 
  1. Holosuite code added to path
  2. HOPOP code addes to path
  3. Statistics and Machine Learning Toolbox
  4. Parallel Computing Toolbox
  5. Preferably over 16 GB RAM
  
User Inputs 
  1. pathtomatfiles: Location of the folder containing all the mat files.
  2. pathtosaveresults: Location of the folder to save the results
  3. dynamicRules: The dynamic rules to be applied while processing the hist files.
  4. pathtodecisionTrees: Location of the folder containing the decision trees. They should be saved by the name "decisionTrees".
     eg. load('decisionTrees') gives a tree.mat file containing tree.noisetree and tree.particletree.
     The sample decision tree (derived from IOP1 RF10) can be used as the default tree and can be found with this code.
  5. convert2ArchiveFrmt: yes or no input. Converts the pStats file to the archivable format if the input is yes.

Output
pStats- Particle Stats
  1. header - From the hist.mat file name
  2. noholograms - Gives the number of holograms in each second. Used for the final concentration calculation
  3. holoinfo - Contains the number,timestamp,microsecond info, second info of all holograms 
  4. rules - Dynamic rules used in the code
  5. noisetree- Decision tree used for the holograms in the regions outside the cloud
  6. particletree- Decision tree used for holograms inside the cloud
  7. metrics- Gives all the particle metrics (Includes holosecond- UTC second associated with a hologram and holonum- the chronological hologram number)
  8. GP3dStats - Stats form the 3d ghost particle removal
  9. GP2dStats - Stats form the 2d ghost particle removal
  10. trimEdges - Stats form the optimisation of the sample volume
  11. volume - The new optimized sample volume
  
  
      
