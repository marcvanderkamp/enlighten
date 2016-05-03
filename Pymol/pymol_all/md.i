100ps MD with only ibelly restraint on atoms outside 20 Ang
&cntrl
 imin=0, irest=1, ntx=5, 
 nstlim=50, dt=0.002,
 ntpr=250, ntwx=250, ioutfm=1, ntwr=-12500,
 ntf = 2, ntc = 2, tol = 0.0000005,
 ntb=0, cut=10,
 ibelly=1,
 bellymask=':MN9@C<:20.0',
 ntt=1, tautp=4.0, temp0=300.0,
/ 
