MD quick heating with only ibelly restraint on atoms outside sphere
&cntrl
 imin=0, irest=0, ntx=1, ig=-1,
 nstlim=2500, dt=0.002,
 ntpr=500, ntwx=500, ioutfm=0, ntwr=2500,
 ntf = 2, ntc = 2, tol = 0.0000005,
 ntb=0, cut=10,
 ibelly=1,
 bellymask='BELLYMASK',
 ntt=1, tautp=1.0, tempi=50.0, temp0=300.0,
/ 
