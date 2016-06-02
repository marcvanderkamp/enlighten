parm ../PARMFILE
loadcrd md_SYS.trj
# Generate average structure PDB, @CA only
crdaction md_SYS.trj average avg_ca1.pdb @CA
# Load average structure PDB as reference
parm avg_ca1.pdb
reference avg_ca1.pdb parm avg_ca1.pdb
# RMS-fit to average structure PDB
crdaction md_SYS.trj rms reference @CA
# Calculate atomic fluctuations for @CA only
crdaction md_SYS.trj atomicfluct out rmsf_ca.dat bfactor @CA byres
# Calculate atomic fluctuations for all protein atoms (without further rms-fit)
crdaction md_SYS.trj atomicfluct out rmsf_all.dat bfactor !:WAT,LIG_NAME
