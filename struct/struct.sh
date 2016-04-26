#!/bin/bash
#### struct.sh is for running the following:
#### - Simulated annealing protocol for optimizing enzyme-ligand structure
#### - Finishes with brief minimisation 
####
#### struct.sh MUST be preceded by prep.sh
#### struct.sh could be followed by dynam.sh and/or qm.sh 
####
#### Currently assumes spherical system from prep.sh
#### Currently, ONLY sander is supported
####
# TO DO: build in option to determine which MD software to run (sander or NAMD)
# TO DO? check for and add $AMBERHOME/bin to $PATH (already checked in prep.sh)
# TO DO? Add in comments of what is being run

### Rudimentary usage (to be replaced by usage with input flags etc.)
Usage="Usage: struct.sh <pdb file> <ligand name> [<net ligand charge>]"


#### Read user input / set defaults
# TO DO: Replace this with proper input parsing (&checking + usage printing) 
if [ $# -lt 2 ]; then
   echo $Usage
   exit
fi
# From prep.sh:
pdb=$1         # pdb WITH hydrogens on ligand!
pdb_name=`echo $pdb | sed -e 's,\.pdb,,' -e 's,\.PDB,,'`
lig_name=$2    #  
#lig_charge=$3  # Not actually used in struct.sh!

md_code=sander
rad_short=20
# Currently, only support the solvent sphere ones
sys=${pdb_name}.sp$rad_short



#### Initial checks and setup
# check for the presence of the appropriate prmtop (.top) and rst7 (.rst) files, exit if not
if [ ! -d $pdb_name ]; then
  echo "Directory $pdb_name is not found. Please run prep.sh first."
  echo "If you HAVE run prep.sh, please run struct.sh from the same directory as prep.sh."
  echo "Exiting..."
  exit
fi

cd $pdb_name

if [ ! -e $sys.top -o ! -e $sys.rst ]; then
  echo "Topology ($sys.top) and/or coordinate files ($sys.rst) are not present. Run prep.sh first. Exiting..."
  exit
fi

## Generate bellymask
# Use a single atom, not a whole residue (in case things close to edge of water-sphere are allowed to move)
# TO DO: check if user specified central atom and if so, use that to generate bellymask
# TO DO? check if $sys.pdb is present?
# Get atom-id from first ligand atom encountered in user-supplied pdb file (crude way to select center)
#  (Consistent with prep.sh)
#  Simple way: extract first ligand resid & atname from ${pdb_name}_1.pdb
#   resid (echo cuts preceeding spaces from variable; necessary wheno printing all 4 (resid) or 5(atname) fields; be aware of this for python-script!)
if [ ! -e ${pdb_name}_1.pdb ]; then
  echo "Cannot find ${pdb_name}_1.pdb required to set central atom for system."
  echo "Exiting..."
  exit
fi
cen_resid=`grep $lig_name ${pdb_name}_1.pdb | head -n 1 | awk '{print substr($0,23,4)}'`
cen_atname=`grep $lig_name ${pdb_name}_1.pdb | head -n 1 | awk '{print substr($0,13,5)}'`
cen_resid=`echo $cen_resid | xargs`
cen_atname=`echo $cen_atname | xargs`
# bellymask: all residues with any atom within 10 Ang from cen_atname in cen_resid
rad_belly=10.0
bellymask=":"$cen_resid"@"$cen_atname"<:$rad_belly"

## Check ENLIGHTEN environment variable to copy required input files
# TO DO: prompt user to enter the directory and use that for ENLIGHTEN
if [ -z "$ENLIGHTEN" ]; then
  echo "Need to set environment variable ENLIGHTEN to location of your enlighten directory (git clone)."
  echo "  Example in bash: "
  echo "  export ENLIGHTEN=\"/my/path/to/enlighten\" "
  echo "Exiting..."
  exit 
elif [ ! -d $ENLIGHTEN/struct ]; then
  echo "Cannot find the $ENLIGHTEN/struct directory that contains required files. "
  echo "Exiting..."
  exit 
fi


#### Setup and run simulations
# Currently only support for sander !
## Write min_ibelly, md_ibelly_ntr, md_ibelly_rst inputs, based on standard input from ../include
# TO DO: check for md_code, and write input accordingly
# TO DO: check if md_code has run correctly and exit with message if not!
# only change the BELLYMASK in the standard inputs (from ../include/), and write to struct/
if [ ! -d ../include ]; then
  mkdir ../include
fi
if [ ! -d struct ]; then
  mkdir struct
fi
for name in minh min_ibelly sa1a sa1b; do
   rsync -a $ENLIGHTEN/struct/$name.i ../include/
   if [ ! -f ../include/$name.i ]; then
      echo "Can't find $name.i in include/. Cannot continue. Exiting..."
      exit
   fi
   sed -e "s/BELLYMASK/$bellymask/" ../include/$name.i > struct/$name.i
done
## Run default SA protocol in sander (with ibelly)
echo "Starting STRUCT protocol in $pdb_name/struct/ using $md_code."
cd struct
## Check for presence of sander, exit if not
if [ -z $AMBERHOME ]; then
   echo "Please set \$AMBERHOME and try again. Exiting..."
   exit
elif [ ! -f $AMBERHOME/bin/sander ]; then
   echo "Cannot find sander in $AMBERHOME/bin/. Cannot continue without it. Exiting..."
   exit
fi
# OPTIONAL: minimize hydrogens only in sphere (25+25 steps)  
#sander -O -i minh_ibelly.i -p ../$sys.top -c ../$sys.rst -o minh_$sys.log -r minh_$sys.rst -ref ../$sys.rst
# Minimize ALL hydrogens (mostly good for water outside sphere) 
#  Mostly for visualisation purposes, it is nicer to include all hydrogens..
#   ...although this will cost more time!
#   ...and it may lead to (unneccesary) problems
$AMBERHOME/bin/sander -O -i minh.i -p ../$sys.top -c ../$sys.rst -o minh_$sys.log -r minh_$sys.rst -ref ../$sys.rst
# Minimize for 100 steps first
#sander -O -i min_ibelly.i -p ../$sys.top -c ../$sys.rst -o min_$sys.log -r min_$sys.rst
$AMBERHOME/bin/sander -O -i min_ibelly.i -p ../$sys.top -c minh_$sys.rst -o min_$sys.log -r min_$sys.rst
# Then run SA MD, in two stages
# stage 1a (8000 steps, with restraint on CA position):
$AMBERHOME/bin/sander -O -i sa1a.i -p ../$sys.top -c min_$sys.rst -o sa1a_$sys.log -r sa1a_$sys.rst -ref min_$sys.rst
# stage 1b (2000 steps of cooling, without restraint on CAs):
$AMBERHOME/bin/sander -O -i sa1b.i -p ../$sys.top -c sa1a_$sys.rst -o sa1b_$sys.log -r sa1b_$sys.rst
# End with another brief minimization (100 steps)
$AMBERHOME/bin/sander -O -i min_ibelly.i -p ../$sys.top -c sa1b_$sys.rst -o min_sa_$sys.log -r min_sa_$sys.rst
echo "Finished STRUCT protocol."



#### OPTIONAL
#### Make traj file with the results (end-points of the different stages), and measure rmsd?
echo "parm ../$sys.top" > make_trj.in
echo "trajin ../$sys.rst" >> make_trj.in
for file in minh_$sys.rst min_$sys.rst sa1a_$sys.rst sa1b_$sys.rst min_sa_$sys.rst; do echo "trajin $file"; done >> make_trj.in
#for file in min_$sys.rst sa1a_$sys.rst sa1b_$sys.rst min_sa_$sys.rst; do echo "trajin $file"; done >> make_trj.in
# Use .trj extension (compatible with PyMOL?)
echo "trajout sa_$sys.trj" >> make_trj.in
cpptraj < make_trj.in > make_trj.log

# Go back to starting dir
cd ../..

#### OPTIONAL
#### Make load script for PyMOL (with just final structures from prep & struct)
#echo "load $pdb_name/${pdb_name}.sp$rad_short.top, ${pdb_name}.sp$rad_short" > load_${pdb_name}_struct.pml
#echo "load $pdb_name/${pdb_name}.sp$rad_short.rst, ${pdb_name}.sp$rad_short, 1" >> load_${pdb_name}_struct.pml
#echo "load $pdb_name/struct/min_sa_${pdb_name}.sp$rad_short.rst, ${pdb_name}.sp$rad_short, 2" >> load_${pdb_name}_struct.pml

