#!/bin/bash
#### prep.sh is for running the following:
#### - ligand parameterisation (with antechamber/prmchk2)
#### - pdb protonation (apart from ligands, they need to be protonated already!)
#### - tleap to solvate and write starting parm7/rst7 (top/rst)
####
#### prep.sh is meant to be followed by struct.sh
# TO DO: let user select the centre of the system (for solvation and restraints)
#        (currently, the first ligand atom in the pdb is used)
# TO DO: Add options to specify solvation (box or sphere, radius of sphere, water model)

# Rudimentary usage (to be replaced by usage with input flags etc.)
Usage="Usage: prep.sh <pdb file> <ligand name> <net ligand charge> [<non-standard residue name; if multiple, put in \"quotes\">]"


#### Read user input
# TO DO: Replace this with proper input parsing (&checking + usage printing, probably use flags)
#        Potentially useful example: http://stackoverflow.com/questions/1682214/pass-list-of-variables-to-bash-script

# Rudimentary input checking and variable assignment
if [ $# -ne 3 -a $# -ne 4 ]; then
   echo $Usage
   exit
elif [ $# -eq 4 ]; then
   alt_res_lst=$4
   # Convert to array
   declare -a alt_res=($alt_res_lst)
else
   # initialize $alt_res as empty variable. Needed?
   alt_res=
fi
pdb=$1         # pdb WITH hydrogens on ligand!
pdb_name=`echo $pdb | sed -e 's,\.pdb,,' -e 's,\.PDB,,'`
lig_name=$2    #
lig_charge=$3
ph=7.0         # Could be set by user (as advanced option)
ph_offset=0.7  # The default offset - will be an option that can be set by user
               #   ph_offset is used because it is better to (de)protonate residues ONLY if this is very clear from predicted pKa
prot_pka=`echo "$ph + $ph_offset" | bc`    # predicted pKa above which ASP & GLU will be protonated 
deprot_pka=`echo "$ph - $ph_offset" | bc`  # predicted pKa below which CYS,LYS will be deprotonated

#### Check for presence of input pdb and for lig_name residue(s) in pdb
if [ ! -f $pdb ]; then
   echo "$pdb is not present. Please check and try again. Exiting..."
   exit
fi
# check if there are more than 1 atoms in the ligand, exit if not
lig_atno=`gawk -v lig=$lig_name '{if (substr($0,18,3)==lig && (substr($0,0,4)=="ATOM" || substr($0,0,6)=="HETATM" )) print}' $pdb | grep -c $lig_name`
# Less elegant alternative, based on grep & expr
#lig_atom1=`grep -c "^ATOM.*$lig_name" $pdb`
#lig_atom2=`grep -c "^HETATM.*$lig_name" $pdb`
#lig_atno=`expr ${lig_atom1} + ${lig_atom2}`
if [ $lig_atno -lt 2 ]; then
  echo " Ligand $lig_name contains 1 or less atoms. Please check your command."
  echo $Usage
  echo "Exiting..."
  exit
fi
# Count number of ligands by using residue number
lig_num=`gawk -v lig=$lig_name '{if (substr($0,18,3)==lig && (substr($0,0,4)=="ATOM" || substr($0,0,6)=="HETATM" )) print substr($0,23,4)}' $pdb | uniq | wc -l`
# Define lig_resn as the first ligand residue occuring (needed in case there are multiple copies of ligand in pdb)
lig_resn=`gawk -v lig=$lig_name '{if (substr($0,18,3)==lig && (substr($0,0,4)=="ATOM" || substr($0,0,6)=="HETATM" )) print substr($0,23,4)}' $pdb | head -n 1`
# Update lig_atno
lig_atno=`gawk -v lig=$lig_name -v lig_resid="$lig_resn" '{if (substr($0,18,3)==lig && substr($0,23,4)==lig_resid && (substr($0,0,4)=="ATOM" || substr($0,0,6)=="HETATM" )) print}' $pdb | grep -c $lig_name`
#lig_resn=`$lig_resn | xargs`
# Report
if [ $lig_num -gt 1 ]; then
  echo "Multiple $lig_name residues in $pdb. Using residue number $lig_resn for parameterisation."
fi
echo "Ligand $lig_name contains $lig_atno atoms in $pdb."


#### Check for required software ($AMBERHOME)
if [ -z $AMBERHOME ]; then
   echo "Please set \$AMBERHOME and try again. Exiting..."
   exit
elif [ ! -f $AMBERHOME/bin/pdb4amber ]; then
   echo "Cannot find pdb4amber in $AMBERHOME/bin/. Cannot continue without. Exiting..."
   exit
elif [ ! -f $AMBERHOME/bin/reduce ]; then
   echo "Cannot find reduce in $AMBERHOME/bin/. Cannot continue without. Exiting..."
   exit
elif [ ! -f $AMBERHOME/bin/tleap ]; then
   echo "Cannot find tleap in $AMBERHOME/bin/. Cannot continue without. Exiting..."
   exit
else
# Possibly not an ideal way to do this... (Will be done better in python scripts)
   export PATH="$PATH:$AMBERHOME/bin"
fi
# NB Specific checks for antechamber/sqm follow later, only when lig/$lig_name.prepc .frcmod are not present.
# Check for propka31 - if not available, print warning and skip propka31 step (by setting skip_propka31=1)
skip_propka31=0
command -v propka31 >/dev/null 2>&1 || { printf >&2 "propka31 cannot be found in \$PATH.\n WARNING: all ASP/GLU will be treated as unprotonated.\n" ; skip_propka31=1; }


echo "Starting PREP protocol in $pdb_name/"

#### Ligand parameterisation
#### Take single lig from pdb and run antechamber/parmchk2 (will be done in subdir lig/)
# NB: Currently expects ONE single ligand to be present!
# TO DO: check for multiple ligs in pdb and take one by getting unique resnum & chain_id?
# TO DO: Proper check for errors in antechamber run (eg sqm convergence) and resubmit with different convergenc criteria (or exit)
# TO DO: additional checks for $lig_name.prepc?
# TO DO: if lig.prepc already exists, prompt user to overwrite or not?
# TO DO: check for parameters in frcmod from parmchk2 that have ATTN (and prompt user?)
# to do: write appropriate remark in prepc & frcmod headers
if [ ! -d "lig" ]; then 
  mkdir lig
fi
#  Checks for presence of $lig_name.prepc (in Python scripts, replace by more efficient way to check in multiple locations in order)
if [ -e lig/$lig_name.prepc ]; then
   lig_prep="lig/$lig_name.prepc"
   echo "Found lig/$lig_name.prepc and will use this. (If this is NOT what you want, rename $lig_name.prepc or ligand in pdb.)"
elif [ -e include/$lig_name.prepc ]; then
   lig_prep=include/$lig_name.prepc
   echo "Found include/$lig_name.prepc and will use this. (If this is NOT what you want, rename $lig_name.prepc or ligand in pdb.)"
else
   echo "Preparing parameters for $lig_name: lig/$lig_name.prepc"
   # print only the ATOM/HETATM fields for the ligand with lig_resid
   gawk -v lig=$lig_name -v lig_resid="$lig_resn" '{if (substr($0,18,3)==lig && substr($0,23,4)==lig_resid && (substr($0,0,4)=="ATOM" || substr($0,0,6)=="HETATM" )) print}' $pdb > lig/$lig_name.pdb
   cd lig
   antechamber -i  $lig_name.pdb -fi pdb -o $lig_name.prepc -fo prepc -rn $lig_name -c bcc -nc $lig_charge
# Check here if antechamber/sqm have run successfully
# Very rudemintary check - just see if $lig_name.prepc is generated
   if [ ! -e $lig_name.prepc ]; then
      echo "Antechamber failed to generate $lig_name.prepc."
      echo "Cannot continue; Exiting..."
      exit
   fi
# Remove antechamber files (once run successfully)
   rm ANTECHAMBER* ATOMTYPE.INF NEWPDB.PDB PREP.INF
   lig_prep="lig/$lig_name.prepc"
   cd ..
fi
if [ -e lig/$lig_name.frcmod ]; then
   lig_frcmod="lig/$lig_name.frcmod"
   echo "Found lig/$lig_name.frcmod and will use this. (If this is NOT what you want, rename $lig_name.frcmod or ligand in pdb.)"
elif [ -f include/$lig_name.frcmod ]; then
   lig_frcmod=include/$lig_name.frcmod
   echo "Found include/$lig_name.frcmod and will use this. (If this is NOT what you want, rename $lig_name.frcmod or ligand in pdb.)"
else 
   echo "Preparing parameters for $lig_name: lig/$lig_name.frcmod"
   cd lig
# Run parmchk2
   parmchk2 -i $lig_name.prepc -f prepc -o $lig_name.frcmod
# Check here for ATTN warnings?
   lig_frcmod="lig/$lig_name.frcmod"
   cd ..
fi


#### Protein prep: renumbering, adding hydrogens (incl. check for flips, assign HIS tautomers), check ASP/GLU protonation
#### Run pdb4amber, reduce & propka31 on pdb, then change HIS and ASP/GLU as needed
# Do this all in $pdb_name/ 
# TO DO: check in ${pdb_name}_1_nonprot.pdb for residues that are not $lig_name or $alt_res
if [ ! -d "$pdb_name" ]; then
  echo "Preparing pdb (addition of hydrogens etc.)"
  mkdir $pdb_name
else 
 echo "It appears you've already (attempted to) run prep.sh with $pdb. Delete folder $pdb_name or rename pdb if you want to run it again."
 exit
fi
cd $pdb_name
# Change ligand chain ID (to L)
gawk -v lig=$lig_name '{if (substr($0,18,3)==lig || $4==lig) {printf("%sL%s\n",substr($0,0,21),substr($0,23,70))} else print}' ../$pdb > ${pdb_name}_0.pdb
# Run pdb4amber and reduce
pdb4amber -i ${pdb_name}_0.pdb -o ${pdb_name}_1.pdb  --nohyd --dry &> pdb4amber.log
reduce -build -nuclear ${pdb_name}_1.pdb &> ${pdb_name}_2.pdb
# HIS tautomers selected, but not renamed in ${pdb_name}_2.pdb. 
#  Detect which protons are present and rename to HIE/HID/HIP based on that.
#  (Generate sed-script to run later to create ${pdb_name}_3.pdb)
gawk '{if (substr($0,0,9)=="USER  MOD" && substr($0,26,3)=="HIS") {if (substr($0,40,6)=="no HE2") {res="HID"} else if (substr($0,40,6)=="no HD1") {res="HIE"}  else if (substr($0,40,6)=="bothHN") {res="HIP"}; printf("s,HIS %s,%s %s,g \n",substr($0,20,5),res,substr($0,20,5))}}' ${pdb_name}_2.pdb > rename.sed
# Reduce doesn't check pKa's and leaves all Asp/Glu (Lys etc.) in their standard states. Check Asp/Glu with propka31 (if available)
# Run propka31 (if available in $PATH)
if [ $skip_propka31 -ne 1 ]; then
  propka31 ${pdb_name}_2.pdb &> propka31.log
# Check for ASP/GLU pKa's above prot_pka and if so, print out and put in prot_res_lst
  prot_res_lst=`gawk -v pka=$prot_pka '{if (NF==5 && (substr($0,0,6)=="   ASP" || substr($0,0,6)=="   GLU") && $4>=pka) {print $2}}' ${pdb_name}_2.pka`
  if [ -n "$prot_res_lst" ]; then
    echo "The following ASP/GLU residues have predicted pKa's above $prot_pka and will be protonated (on OD2/OE2):"
    echo "   (predicted pKa is indicated)"
# Print the original residue name+number of ASP/GLU's being protonated (with predicted pKa?):
    for res in $prot_res_lst; do
      gawk -v resid=$res '{if ($4==resid) printf("%s    ",substr($0,1,9))}' ${pdb_name}_1_renum.txt
  # need to compare res with residue number in the .pka file. See also next comments. 
  #  (Not sure what propka does with >999 resid - still in columns 7-10 ?)
      gawk -v resid=$res '{if (substr($0,1,3)=="   " && ($2==resid || substr($0,7,4)==resid)) print substr($0,17,5)}' ${pdb_name}_2.pka
  # need to compare res with the residue number in the pdb file (columns 23-26), regardless of how many characters it is (1-4).
  # Currently, rely on resid being $6 (true if there is a chain ID and resid is 1-3 chars) OR $5 (true if there's no chain ID and resid is 1-3 chars) OR substr($0,23,4) (true if resid is 4 chars)
  #  This will cause problems when res is 1-9 and there is a numerical chain ID (a very unusual situation)
  #  (This will be easier to do properly when ${pdb_name}_2.pdb is parsed in a python-script)
      gawk -v resid=$res '{if ($3=="CA" && ($substr($0,23,4)==resid || $6==resid || $5==resid)) {if (substr($0,18,3)=="ASP") {resn="ASH"}; if (substr($0,18,3)=="GLU") {resn="GLH"} ; printf("s,%s %s,%s %s,g \n",substr($0,18,3),substr($0,22,6),resn,substr($0,22,6))}}'  ${pdb_name}_2.pdb >> rename.sed
    done
  fi
# Check for CYS/LYS pKa's below deprot_pka and if so, print out and put in deprot_res_lst
#  (Essentially the same as above for protonation of ASP/GLU)
  deprot_res_lst=`gawk -v pka=$deprot_pka '{if (NF==5 && (substr($0,0,6)=="   CYS" || substr($0,0,6)=="   LYS") && $4<=pka) {print $2}}' ${pdb_name}_2.pka`
  if [ -n "$deprot_res_lst" ]; then
    echo "The following CYS/LYS residues have predicted pKa's below $deprot_pka and will be deprotonated:"
    echo "   (predicted pKa is indicated)"
    for res in $deprot_res_lst; do
      gawk -v resid=$res '{if ($4==resid) printf("%s    ",substr($0,1,9))}' ${pdb_name}_1_renum.txt
      gawk -v resid=$res '{if (substr($0,1,3)=="   " && ($2==resid || substr($0,7,4)==resid)) print substr($0,17,5)}' ${pdb_name}_2.pka
      gawk -v resid=$res '{if ($3=="CA" && ($substr($0,23,4)==resid || $6==resid || $5==resid)) {if (substr($0,18,3)=="CYS") {resn="CYM"}; if (substr($0,18,3)=="LYS") {resn="LYN"} ; printf("s,%s %s,%s %s,g \n",substr($0,18,3),substr($0,22,6),resn,substr($0,22,6))}}'  ${pdb_name}_2.pdb >> rename.sed
    done
  fi
fi
# Run sed-scripts to rename HIS and residues to (de)protonate, AND remove hydrogens on HETATMs added by reduce
sed -f rename.sed ${pdb_name}_2.pdb | gawk '{if (substr($0,0,6)!="HETATM" || substr($0,78,7)!="H   new") print}' > ${pdb_name}_3.pdb
# NB: also need to remove hydrogens added by reduce on deprotonated residues - else top-file creation will fail.    
if [ -n "$deprot_res_lst" ]; then
  gawk '{if ((substr($0,18,3)!="LYN" && substr($0,18,3)!="CYM") || substr($0,78,7)!="H   new") print}' ${pdb_name}_3.pdb > tmp.pdb
  mv tmp.pdb ${pdb_name}_3.pdb
fi
cd ..


#### Check alternative residue parameters
# Check for parameters of 'non-standard' parameters in ${pdb_name}_1_nonprot.pdb
#  Currently only in main dir and lig/
# TO DO: check multiple locations for non-standard res .lib, .off, .frcmod files
#       (frcmod may not be required, but complicated to check)
#  0. initialize a list of files to be read in by tleap later
res_loadoff=""
res_loadfrcmod=""
#  1a. check for residue names in ${pdb_name}_1_nonprot.pdb different from $lig_name, put them in list and declare an array
nonprot_res_lst=`gawk -v lig=$lig_name '{if (substr($0,18,3)!=lig) print substr($0,18,3)}' ${pdb_name}/${pdb_name}_1_nonprot.pdb | uniq`
declare -a nonprot_res=($nonprot_res_lst)
#  1b. start loop over the residues in the array
for val in "${nonprot_res[@]}" ; do
   echo "Found non-standard residue $val."
#  2a. check if these residues are in the user-supplied list $alt_res
#     uses a 'hacky' check ( if [[ "${alt_res[@]}" =~ "${val} "  etc.) instead of the contains() function
   if [[ "${alt_res[@]}" =~ "${val} " || "${alt_res[${#alt_res[@]}-1]}" == "${val}" ]]; then
      echo "Residue $val was given in user-supplied list."
   else 
      echo "Residue $val was NOT given in user-supplied list."
   fi
#  2b. check if .off (OR .prepc) and .frcmod exist, and put them in list to load for tleap
   if [ -e $val.off -a -e $val.frcmod ]; then
      echo "Using user-supplied $val.off & $val.frcmod."
      res_loadoff="$res_loadoff $val.off"
      res_loadfrcmod="$res_loadfrcmod $val.frcmod"
   elif [ -e lig/$val.off -a -e lig/$val.frcmod ]; then
      echo "Using user-supplied lig/$val.off & lig/$val.frcmod."
      res_loadoff="$res_loadoff lig/$val.off"
      res_loadfrcmod="$res_loadfrcmod lig/$val.frcmod"
   elif [ -e $val.prepc -a -e $val.frcmod ]; then
      echo "Using user-supplied $val.prepc & $val.frcmod."
      res_loadprepc="$res_loadprepc $val.prepc"
      res_loadfrcmod="$res_loadfrcmod $val.frcmod"
   elif [ -e lig/$val.prepc -a -e lig/$val.frcmod ]; then
      echo "Using user-supplied lig/$val.prepc & lig/$val.frcmod."
      res_loadprepc="$res_loadprepc lig/$val.prepc"
      res_loadfrcmod="$res_loadfrcmod lig/$val.frcmod"
#  TO DO Check if these residues are in include/ .off files
#        Best also to support *searching through* .off AND .lib files
   else
      echo "Cannot find $val.off/.prepc and/or $val.frcmod for non-standard residue $val. Exiting."
      exit
   fi 
# 3. Reduce adds hydrogens to alternative residues if they are labelled "ATOM" (which is the PyMOL default)
# This will cause problems with (user-supplied) parameter files. So, delete added hydrogens from alternative residues here.
   gawk -v res=$val '{if (substr($0,18,3)!=res || substr($0,78,7)!="H   new") print}' ${pdb_name}/${pdb_name}_3.pdb > ${pdb_name}/tmp.pdb
   mv ${pdb_name}/tmp.pdb ${pdb_name}/${pdb_name}_3.pdb 
done   



#### Solvation of system in TIP3P solvent sphere
#### Run tleap with ${pdb_name}_3.pdb for protein & $lig_name.prepc/frcmod
# TO DO: advanced options for sphere size or box as alternative, closeness, ..
# Get tleap input (incl. checking for presence of files):
# Center selection - Best to take center that is used later
# Curently just the first atom of the ligand in the pdb (but needs changing to let user select!?)
#  Simple way: extract first ligand resid & atname from ${pdb_name}_1.pdb 
#   resid (echo cuts preceeding spaces from variable; necessary wheno printing all 4 (resid) or 5(atname) fields; be aware of this for python-script!)
cen_resid=`grep $lig_name ${pdb_name}/${pdb_name}_1.pdb | head -n 1 | gawk '{print substr($0,23,4)}'`
cen_atname=`grep $lig_name ${pdb_name}/${pdb_name}_1.pdb | head -n 1 | gawk '{print substr($0,13,5)}'`
cen_resid=`echo $cen_resid | xargs`
cen_atname=`echo $cen_atname | xargs`
# formatted for tleap:
pos=$cen_resid.$cen_atname
# other parameters:
rad=20.0
rad_short=`printf "%.0f\n" $rad`
close=0.75
# check for presence of both prepc & frcmod for ligand; exit if not
# TO DO: more checks? (e.g. check in include/ - but do in if loop, so that lig/ is used if present; print message which are used)
if [ ! -e lig/$lig_name.frcmod -o ! -e lig/$lig_name.prepc ]; then
  echo "Cannot find topology (lig/$lig_name.prepc) and/or parameters (lig/$lig_name.frcmod) for ligand $lig_name. Exiting..."
  exit
elif [ ! -e $pdb_name/${pdb_name}_3.pdb ]; then
  echo "Cannot find the pdb with hydrogens added ($pdb_name/${pdb_name}_3.pdb). Exiting..."
else
  echo "Preparing pdb for simulation (solvation, amber topology & coordinates)"
fi
cd $pdb_name
# Write tleap input
#  Initial part
printf "# read in standard protein/DNA parameters and GAFF
source leaprc.ff14SB
source oldff/leaprc.ff14SB
source leaprc.water.tip3p
source leaprc.gaff
# read in ligand parameters
loadamberprep ../$lig_prep
loadamberparams ../$lig_frcmod
" > tleap_sp$rad_short.in
#  Part for reading in required non-standard residues
#   Currently quite rudimentary - only .off files, not .lib files
for off in $res_loadoff ; do
   echo "loadoff ../$off" >>  tleap_sp$rad_short.in
done
for frc in $res_loadfrcmod ; do 
   echo "loadamberparams ../$frc" >>  tleap_sp$rad_short.in
done
#  Part for loading and solvating the pdb, saving top & rst, pdb
printf "# load the water model (& ions)
#loadamberparams frcmod.ionsjc_tip3p
# load the prepared pdb (sslinks should be automatically recognised through CYX & CONECT records in pdb)
mol = loadpdb ${pdb_name}_3.pdb
# save parm & crd of unsolvated system with PyMOL compatible extensions
saveamberparm mol ${pdb_name}.dry.top ${pdb_name}.dry.rst
savepdb mol ${pdb_name}.dry.pdb
# load the crystal waters
xwat = loadpdb ${pdb_name}_1_water.pdb
mol_xwat = combine {mol xwat}
##### Up to here, tleap.in is the same (independent of using box or
# solvate with a sphere of TIP3P
solvatecap mol_xwat TIP3PBOX mol_xwat.$pos $rad $close
# save parm & crd, with PyMOL compatible extensions
saveamberparm mol_xwat ${pdb_name}.sp$rad_short.top ${pdb_name}.sp$rad_short.rst
savepdb mol_xwat ${pdb_name}.sp$rad_short.pdb
quit
" >> tleap_sp$rad_short.in
# Actually run tleap
tleap -f tleap_sp$rad_short.in &> tleap_sp$rad_short.log

# Check for empty .top files and print warning (and exit)
#  Put in extra checks, more informative messages?
if [ -s ${pdb_name}.sp$rad_short.top -o -s ${pdb_name}.sp$rad_short.rst ]; then
  echo "Generated topology (prmtop) file $pdb_name/${pdb_name}.sp$rad_short.top"
  echo "Generated coordinate (inpcrd) file $pdb_name/${pdb_name}.sp$rad_short.rst"
  echo "Finished PREP protocol."
else
  echo "Something went wrong, check $pdb_name/tleap_sp$rad_short.log ."
fi

