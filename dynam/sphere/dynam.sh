#!/bin/bash
#### dynam.sh is for running the following:
#### - Short MD protocol for running some enzyme-ligand dynamics
#### - Finishes with brief minimisation 
####
#### dynam.sh MUST be preceded by prep.sh AND struct.sh
####
#### Currently assumes spherical system from prep.sh
#### Currently, ONLY sander is supported
####
# TO DO: build in option to determine which MD software to run (sander or NAMD)
# TO DO: add in more optional variables, using flags (and case/esac)
# TO DO? check for and add $AMBERHOME/bin to $PATH (already checked in prep.sh)
# TO DO? Add in comments of what is being run

### Rudimentary usage (to be replaced by usage with input flags etc.)
Usage="Usage: dynam.sh <pdb file> <ligand name> [<number of ps production>]"


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
if [ $# -lt 3 ]; then
   ps=$3       # Not tested yet
else
   ps=100      # Default value of 100ps MD 
fi
steps=`expr $ps \* 500`

md_code=sander
rad_short=20
# Currently, only support the solvent sphere ones
sys=${pdb_name}.sp$rad_short



#### Initial checks and setup
# check for the presence of the appropriate prmtop (.top) and rst7 (.rst) files, exit if not
if [ ! -d $pdb_name ]; then
  echo "Directory $pdb_name is not found. Please run prep.sh first."
  echo "If you HAVE run prep.sh, please run dynam.sh from the same directory as prep.sh."
  echo "Exiting..."
  exit
fi
if [ ! -d $pdb_name/struct/ ]; then
  echo "Directory $pdb_name/struct/ is not found. Please run struct.sh first"
  echo "If you HAVE run struct.sh and prep.sh, please run dynam.sh from the same directory as prep.sh."
  echo "Exiting..."
  exit
fi

cd $pdb_name

if [ ! -e $sys.top -o ! -e $sys.rst ]; then
  echo "Topology ($sys.top) and/or coordinate files ($sys.rst) are not present. Run prep.sh first. Exiting..."
  exit
fi
if [ ! -e struct/min_sa_$sys.rst ]; then
  echo "STRUCT coordinate file (struct/min_sa_$sys.rst) is not present. Run struct.sh first. Exiting..."
  exit
fi

## Generate bellymask (from struct.sh)
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
rad_belly=20.0    # 10.0 in struct.sh. Could set rad_belly=rad_short
bellymask=":"$cen_resid"@"$cen_atname"<:$rad_belly"

## Check ENLIGHTEN environment variable to copy required input files
# TO DO: prompt user to enter the directory and use that for ENLIGHTEN
if [ -z "$ENLIGHTEN" ]; then
  echo "Need to set environment variable ENLIGHTEN to location of your enlighten directory (git clone)."
  echo "  Example in bash: "
  echo "  export ENLIGHTEN=\"/my/path/to/enlighten\" "
  echo "Exiting..."
  exit 
elif [ ! -d $ENLIGHTEN/dynam/sphere ]; then
  echo "Cannot find the $ENLIGHTEN/dynam/sphere directory that contains required files. "
  echo "Exiting..."
  exit 
fi


#### Setup and run simulations
# Currently only support for sander !
## Write heat, md, min inputs, based on standard input from ../include
# TO DO: check for md_code, and write input accordingly
# TO DO: check if md_code has run correctly and exit with message if not!
# only change the BELLYMASK in the standard inputs (from ../include/), and write to dynam/
if [ ! -d ../include ]; then
  mkdir ../include
fi
if [ ! -d dynam ]; then
  mkdir dynam
fi
for name in heat md min; do
   rsync -a $ENLIGHTEN/dynam/sphere/$name.i ../include/
   if [ ! -f ../include/$name.i ]; then
      echo "Can't find $name.i in include/. Cannot continue. Exiting..."
      exit
   fi
   sed -e "s/BELLYMASK/$bellymask/" ../include/$name.i > dynam/$name.i
done
if [ $ps ! -e 100 ]; then
  sed -i -e "s/nstlim=50000/nstlim=$steps/g" md.i
fi

## Run default MD protocol in sander (with ibelly)
echo "Starting DYNAM protocol in $pdb_name/dynam/ using $md_code."
cd dynam
## Check for presence of sander, exit if not
if [ -z $AMBERHOME ]; then
   echo "Please set \$AMBERHOME and try again. Exiting..."
   exit
elif [ ! -f $AMBERHOME/bin/sander ]; then
   echo "Cannot find sander in $AMBERHOME/bin/. Cannot continue without it. Exiting..."
   exit
fi
# Run 5ps heating
$AMBERHOME/bin/sander -O -i heat.i -p ../$sys.top -c ../struct/min_sa_$sys.rst -o heat_$sys.log -r heat_$sys.rst -x heat_$sys.trj
# Run short md production (100ps default)
$AMBERHOME/bin/sander -O -i md.i -p ../$sys.top -c heat_$sys.rst -o md_$sys.log -r md_$sys.rst -x md_$sys.trj
# End with another brief minimization (100 steps)
$AMBERHOME/bin/sander -O -i min.i -p ../$sys.top -c md_$sys.rst -o min_$sys.log -r min_$sys.rst
echo "Finished DYNAM protocol."


# Go back to starting dir
cd ../..


