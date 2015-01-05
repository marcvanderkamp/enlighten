MD with ibelly restraint outside 10.0 sphere AND ntr on CAs
&cntrl
 nstlim=8000, dt=0.001,
 ntpr=100, ntwx=5000,
 ntb=0, cut=10,
 ibelly=1,
 bellymask='BELLYMASK'
 ntr=1, restraint_wt=10.0,
 restraintmask='@CA'
/ 
#
# Simple simulated annealing algorithm:
#
# from steps 0 to 1000: raise target temperature 10->500K
# from steps 1000 to 6000: leave at 500K
# from steps 6000 to 10000: re-cool to low temperatures
#
&wt type='TEMP0', istep1=0,istep2=1000,value1=10.,
value2=500., /
&wt type='TEMP0', istep1=1001, istep2=6000, value1=500.,
value2=500.0, /
&wt type='TEMP0', istep1=6001, istep2=8000, value1=0.,
value2=0.0, /
#
# Strength of temperature coupling:
# steps 0 to 6000: tight coupling for heating and equilibration
# steps 6000 to 8000: slow cooling phase
# IN sa1b:
# steps 8000 to 9000: somewhat faster cooling
# steps 9000 to 10000: fast cooling, like a minimization
#
&wt type='TAUTP', istep1=0,istep2=6000,value1=0.2,
value2=0.2, /
&wt type='TAUTP', istep1=6001,istep2=8000,value1=4.0,
value2=2.0, /
#&wt type='TAUTP', istep1=8001,istep2=9000,value1=1.0,
#value2=1.0, /
#&wt type='TAUTP', istep1=9001,istep2=9500,value1=0.5,
#value2=0.5, /
#&wt type='TAUTP', istep1=9501,istep2=10000,value1=0.05,
#value2=0.05, /

