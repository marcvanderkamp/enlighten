enzlig_tools
============

Protocols and tools to run (automated) atomistic simulations of enzyme-ligand systems

Minimal software requirements:
- AmberTools14 (see www.ambermd.org - Amber14.pdf manual has instructions for installation)

Several utitilies/programs from AmberTools14 are used for the majority of (PREP protocol) tasks.

- Currently, the automation of protocols is only available through bash-scripts (for Linux or Mac OS X).
All bash-scripts require awk & sed.
NOTE: current bash-scripts are NOT fully POSIX compliant.

Tested with:
- GNU Awk 3.1.7 (Linux)
- GNU sed version 4.2.1 (Linux)
- awk version 20070501 (Mac OS)

Additional recommended software requirements:
- propka31 (see www.propka.ki.ku.dk and/or https://github.com/jensengroup/propka-3.1; Required for pKa estimation titratable residues, in presence of ligand)


###Download the repository on Linux/UNIX/Mac :   

First ensure that git is installed. Instructions are [here](http://git-scm.com/downloads). 

Command-line:

1) In the right-hand corner of this page, there is a title "HTTPS clone URL" with a URL in a field below it.
Copy this link 

2) Go to the command line on your Linux/Mac and cd to a suitable location to create the Repository
Then type:

git clone https://github.com/marcvanderkamp/enzlig_tools.git

On UNIX clusters you may need to use SSH rather than HTTPS to clone the repository.
This typically means you will also need to add your public ssh key for the cluster (~/.ssh/id_rsa.pub) to your github account here: https://github.com/settings/ssh

Once the public ssh key is added, you can run:

git clone git@github.com:marcvanderkamp/enzlig_tools.git



3) This will download the Repository enzlig_tools for use on your local computer. 

4) Some scripts (struct.sh) in the current repository require you to set the ENZLIG environment variable to indicate the location of the repository. 

In bash:

export ENZLIG=/my/path/to/enzlig_tools/

In tcsh/csh:

setenv ENZLIG /my/path/to/enzlig_tools/


## Available protocols
### PREP: prep.sh
prep.sh takes enzyme-ligand pdb file and generates ligand parameters, adds hydrogens, adds solvent (sphere), generates Amber topology/coordinate files.

  Usage:  
  prep.sh \<pdb file\> \<ligand name\> \<net ligand charge\> [\<non-standard residue name; if multiple, put in "quotes"\>]
- The pdb file should contain 1 (non-protein) ligand, WITH all hydrogens added!
- Uses the following AmberTools14 programs: antechamber (& sqm), prmchk2, pdb4amber, reduce, tleap 
- Ideally requires installation of propka31 (and put in $PATH)
- Extensive comments in prep.sh provide more in-depth explanation of the steps in the protocol, etc.

### STRUCT: struct.sh
See struct/

struct.sh takes the topology/coordinate files generated by prep.sh and performs brief simulated-annealing and minimisation protocol (to optimize structure).

  Usage:
  
  struct.sh \<pdb file\> \<ligand name\> [all other input is currently ignored]
- Requires prep.sh to be run successfully first (and directory/filenames to stay as they were when prep.sh was run)
- Should be run in the same directory where prep.sh was run
- To get the required input files from the cloned repository, set ENZLIG environment variable; see point 4) above (User will be alerted if not SET)
- Currently only possible to run the simulation protocols with sander (free with AmberTools14)


### DYNAM
See dynam/

No (bash-)script available (yet). This protocol typically takes >30 min (on a single CPU).

sander input files are available in dynam/sphere, where BELLYMASK needs to be replaced with the appropriate string.
- heat.i: Brief heating (only 5ps MD), meant to run with output from struct.sh (min_sa_*.rst) .
- md.i: 100 ps NVT MD, to follow heat.i. Writes and keeps restart files every 25ps (12500 steps).
- min.i: Brief minimization (optionally performed after md.i). 


## Test cases
Two test-cases are included (see test/).

####1) 2CHT.pdb 
 (Chorismate mutase with chorismate, simple test-case)

to run prep.sh test:
- copy 2cht_mod.pdb from test/ and optionally pre-calculated .prepc & .frcmod for CHOrismate:
  
  rsync -a /my/path/to/enzlig_tools/test/2CHT/* .
- run prep.sh as follows:
  
  /my/path/to/enzlig_tools/prep.sh 2cht_mod.pdb CHO -2
  
NB:  2cht_mod.pdb was created from 2CHT.pdb by:
- keeping ATOM/HETATM records from chains A,B,C only
- deleting TSA from chains A,C
- renaming TSA to CHO in chain B, changing coordinates a little (to separate bond not formed in chorismate)
- Move CHO O7 so that it is the first CHO atom in pdb
- adding hydrogens to CHO (in PyMOL)


####2) 4EUZ.pdb 
 (Class A beta-lactamase SFC-1 S70A complexed with Meropenem)

This is a more complicated test-case, demonstrating the use of prep.sh with a SS-bond, insertions etc. and an ASP that is best treated as protonated.

to run prep.sh test:
- copy 4euz_mod.pdb from test/ and optionally pre-calculated .prepc & .frcmod for meropenem (MEM):

  rsync -a /my/path/to/enzlig_tools/test/4EUZ/* .
- run prep.sh as follows:

  /my/path/to/enzlig_tools/prep.sh 4euz_mod.pdb MEM -1

NB: 4euz_mod.pdb was created from 4EUZ.pdb by:
- Adding hydrogens to MEM (in PyMOL)
- Deleting EDO (crystallisation agent) and NA (sodium ions)
- Changed HAR to ARG and deleted its OH1 atom (HAR is modified ARG)
- Move MEM C7 so that it is the first MEM atom (CONECT not adjusted, but CONECT records are ignored)
- Swapped OD1/OD2 labels in Asp246
