#!/opt/local/bin/python
import subprocess
import os
import sys
import argparse
# sander The main engine used for running molecular simulations with Amber.Originally acronym standing for
# Simulated Annealing with Nmr-Derived Energy Restraints.
# The key thing that this file needs to be abel to do is take different DYNAM profiles so that it can be set up with
# flexibility. This may be achievable with a tabbed Option that allows the construction of the profiles from sanders
# with some simple sliders


# Get the file names to run with this script, there are two types top files and rst
parser = argparse.ArgumentParser(prog='DYNAM',description='Dynamics python wrapper for sanders. '
                                                          'This program expects both the top and the rst '
                                                          'to have the same basename. You only need to '
                                                          'pass it the top file.')
parser.add_argument('molecule', metavar='Molecule',nargs=1, help='Top file for the dynamics to be run on')
args = parser.parse_args()
print(args.molecule)
top=args.molecule[0]
print("File read in as water %s" % top)

rst = "min_sa_"
rst += os.path.splitext(top)[0]
rst +=".rst"


if args == 0:
    print("No file names provided")
    print('Please provide the basename for the system (i.e without the file extension)')
    top = input("Molecule :  ")
    args[1]=top

# Check that file exists
if args != 0:
    if os.path.exists(top) == False:
        print("No file called %s found" % top)
        sys.exit()
    if os.path.exists(rst) == False:
        print("No file called %s found" % rst)
        sys.exit()

# Detect the AMBERHOME directory, or take argument from the pymol script,then check if sander is installed
amber = os.getenv('AMBERHOME')
sander='/bin/sander'

if amber is None:
    print("The AMBERPATH hasn't been set ")
    amber = input("Please enter amber path  :")
    print(("AMBERPATH set to  : %s" % amber))
    sander_full=amber+sander
    if os.path.exists(sander_full) == False:
        print("Your amberpath does not contain sander, please check your installation")
        sys.exit()
else:
    print("Amber path has been detected as %s" % amber)
    sander_full=amber+sander
    if os.path.exists(sander_full) == False:
        print("Your amberpath does not contain sander, please check your installation")
        sys.exit()





# By this point the amber path and molecular system have been found and we need to run the dynamics program
def rundynam(amber,top,res):
    # list the input files, this can eventually be embedded in this script
    heat="./heat.i"
    md="./md.i"
    min="./min.i"

    sander='/bin/sander'
    sander_full=amber+sander

    # Run the heating script using AMBER/sander this calls the heat.i, input .tp and .rst
    # $AMBERHOME/bin/sander -O -i ../../heat.i -o heat.log -p ../a137y.sp20.top -c ../min_sa_a137y.sp20.rst -ref ../min_sa_a137y.sp20.rst -r heat.rst -x heat.nc
    command = sander_full + " -O -i "+ heat + " -o heat.log -p " + top + " -c " + rst + " -ref "+rst+" -r heat.rst -x heat.nc"
    p = subprocess.Popen([command], shell=True, stderr=subprocess.PIPE)
    while True:
        out = str(p.stderr.read())
        print(out,type(out))
        if out == '' and p.poll() != None:
            break
        if out != '':
            sys.stdout.write(out)
            sys.stdout.flush()
            break
        # temp = self.pdb[:-4]
        print("Job Finished %s" %p)
    # Do Md sampling
# $AMBERHOME/bin/sander -O -i ../../md.i -o md.log -p ../a137y.sp20.top -c heat.rst -ref ../min_sa_a137y.sp20.rst -r md.rst -x md.nc
    command = sander_full + " -O -i "+ md + " -o md.log -p " + top + " -c heat.rst -ref "+rst+" -r md.rst -x md.nc"
    p = subprocess.Popen([command], shell=True, stderr=subprocess.PIPE)
# 4) brief minimization (100 steps)
    # Minimise the energy
#  $AMBERHOME/bin/sander -O -i ../../min.i -o min.log -p ../a137y.sp20.top -c md.rst -ref ../min_sa_a137y.sp20.rst -r min.rst
    command = sander_full + " -O -i "+ heat + " -o " + " heat.log -p " + top + " -c " + rst + " -ref "+rst+" -r heat.rst -x heat.nc"
    p = subprocess.Popen([command], shell=True, stderr=subprocess.PIPE)


rundynam(amber,top,rst)

#
 # def rundyynam(self):
 #     # heating command
 #     command = self.entry3.get() + "/struct.sh " + self.pdb + " " + self.entry5.get() + " " + self.entry6.get()
 #     p = subprocess.Popen([command], shell=True, stderr=subprocess.PIPE)
 #     while True:
 #         out = p.stderr.read(1)
 #         if out == '' and p.poll() != None:
 #             break
 #         if out != '':
 #             sys.stdout.write(out)
 #             sys.stdout.flush()
 #     temp = self.pdb[:-4]
 #     pymol.cmd.load("./" + temp + "/struct/min_sa_" + temp + ".sp20.rst", temp + ".sp20")
 #     print "Job Finished"

# export AMBERHOME="/users/chmwvdk/amber14"
# cd /users/chmwvdk/projects/bb_tools/nal/md_sp/a137y/sp20
# 1) run struct (sa) protocol (resulting in min_sa_a137y.sp20.rst)
# 2) md heating to 300K in 5ps
# $AMBERHOME/bin/sander -O -i ../../heat.i -o heat.log -p ../a137y.sp20.top -c ../min_sa_a137y.sp20.rst -ref ../min_sa_a137y.sp20.rst -r heat.rst -x heat.nc
# 3) md sampling at 300K for 100ps
# $AMBERHOME/bin/sander -O -i ../../md.i -o md.log -p ../a137y.sp20.top -c heat.rst -ref ../min_sa_a137y.sp20.rst -r md.rst -x md.nc
# 4) brief minimization (100 steps)
#  $AMBERHOME/bin/sander -O -i ../../min.i -o min.log -p ../a137y.sp20.top -c md.rst -ref ../min_sa_a137y.sp20.rst -r min.rst



