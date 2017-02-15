fetch 1BTL, async=0
fetch 4FH2, async=0
align 4FH2 and name CA, 1BTL and name CA
select tmp, 1BTL or (4FH2 and resname 0RN)
create 1btl_0rn, tmp
remove (1btl_0rn and resname SO4)
select HOH, (1btl_0rn and resname HOH within 2.0 of resname 0RN)
remove (1btl_0rn and HOH)
h_add (1btl_0rn and resname 0RN)
alter 0RN, chain="L"
set pdb_use_ter_records, off
