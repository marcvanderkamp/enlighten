100ps MD with only ibelly restraint on atoms outside sphere
&cntrl
 imin=0, irest=1, ntx=5, 
 nstlim=50000, dt=0.002,
 ntpr=500, ntwx=500, ioutfm=0, ntwr=-12500,
 ntf = 2, ntc = 2, tol = 0.0000005,
 ntb=0, cut=10,
 ibelly=1,
 bellymask='BELLYMASK',
 ntt=1, tautp=4.0, temp0=300.0,
/ 
