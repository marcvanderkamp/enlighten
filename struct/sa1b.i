MD with ibelly restraint outside 10.0 sphere
&cntrl
 ntx=5, irest=1,
 nstlim=2000, dt=0.001,
 ntpr=100, ntwx=5000,
 ntb=0, cut=10,
 ibelly=1,
 bellymask='BELLYMASK'
/ 
#
# Simple simulated annealing algorithm:
#
# from steps 0 to 1000: raise target temperature 10->300K
# from steps 1000 to 2000: leave at 300K
# from steps 2000 to 10000: re-cool to low temperatures
#
# Strength of temperature coupling:
# steps 0 to 2000: tight coupling for heating and equilibration
# steps 2000 to 8000: slow cooling phase
# IN sa1b:
#   ONLY THIS PART RUN HERE:
# steps 8000 to 9000: somewhat faster cooling
# steps 9000 to 10000: fast cooling, like a minimization
#
&wt type='TAUTP', istep1=0,istep2=1000,value1=1.0,
value2=1.0, /
&wt type='TAUTP', istep1=1001,istep2=1500,value1=0.5,
value2=0.5, /
&wt type='TAUTP', istep1=1501,istep2=2000,value1=0.05,
value2=0.05, /

