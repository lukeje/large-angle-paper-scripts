#!/bin/bash
set -e

rootdir=../"$(dirname "$0")"

outfile=$rootdir/figures/voltages.txt
echo Voltage > "$outfile"
for f in "$rootdir"/invivo/dcm/sub-?/ses-?/S*_al_B1mapping_v2f_long_TM34910/; do
	dcms=("$f"/*.ima)
	grep -aE "sTXSPEC\.asNucleusInfo\[0\]\.flReferenceAmplitude = (\d*)" "${dcms[0]}" | cut -d"=" -f2 >> "$outfile"
done