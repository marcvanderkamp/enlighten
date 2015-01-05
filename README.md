enzlig_tools
============

Protocols and tools to run (automated) atomistic simulations of enzyme-ligand systems

Minimal software requirements:
- AmberTools14 (see www.ambermd.org - Amber14.pdf manual has instructions for installation)

Several utitilies/programs from AmberTools14 are used.
Currently, the protocols are only available as bash-scripts (for Linux or Mac OS X).
All bash-scripts require awk & sed.
NOTE: current bash-scripts are NOT fully POSIX compliant.

Tested with:
- GNU Awk 3.1.7 (Linux)
- GNU sed version 4.2.1 (Linux)
- awk version 20070501 (Mac OS)


## Available scripts
### prep.sh
Takes enzyme-ligand pdb file and generates ligand parameters, adds hydrogens, adds solvent (sphere), generates Amber topology/coordinate files.
  Usage:  
  prep.sh \<pdb file\> \<ligand name\> \<net ligand charge\> [\<non-standard residue name; if multiple, put in "quotes"\>]
- The pdb file should contain 1 (non-protein) ligand, WITH all hydrogens added!
- Uses the following AmberTools14 programs: antechamber (& sqm), prmchk2, pdb4amber, reduce, tleap 
- Ideally requires installation of propka31 (and put in \$PATH)
- Extensive comments in prep.sh provide more in-depth explanation of the steps in the protocol, etc.

