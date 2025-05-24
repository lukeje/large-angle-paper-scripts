#!/bin/bash
set -e

rootdir=..

indir=$rootdir/.dcm

sub=phantom

## MPM
anat=$rootdir/sub-"$sub"/anat
mkdir -p "$anat"

dcm2niix -o "$anat" -f sub-"$sub"_acq-R1opt_echo-%e_flip-2_mt-off_MPM "$indir"/8_t1w_*_R1
dcm2niix -o "$anat" -f sub-"$sub"_acq-R1opt_echo-%e_flip-1_mt-off_MPM "$indir"/9_pdw_*_R1
dcm2niix -o "$anat" -f sub-"$sub"_acq-PDopt_echo-%e_flip-2_mt-off_MPM "$indir"/11_t1w_*_PD2
dcm2niix -o "$anat" -f sub-"$sub"_acq-PDopt_echo-%e_flip-1_mt-off_MPM "$indir"/12_pdw_*_PD

# add zero to single digit echo numbers when there are more than 10 echoes for easier sorting
for f in "$anat"/*_echo-10_*; do
	for n in {1..9}; do
		ff=${f/_echo-10/_echo-$n}
		mv "$ff" "${ff/_echo-/_echo-0}"
	done
done

# add some missing fields
tmp=$(mktemp)
for f in "$anat"/*.json; do
	jq '.MTState = false | .SpoilingState = true | .SpoilingType = "COMBINED" | with_entries(if .key == "RepetitionTime" then .key = "RepetitionTimeExcitation" else . end)' "$f" > "$tmp" && mv "$tmp" "$f"
done
rm -f "$tmp"

## B0 and B1
fmap=$rootdir/sub-"$sub"/fmap
mkdir -p "$fmap"

# AFI
dcm2niix -o "$fmap" -f sub-"$sub"_acq-tr%e_TB1AFI "$indir"/3_kp_afib1_*

# correct TR in second volume
afi2="$fmap"/sub-"$sub"_acq-tr2_TB1AFI.nii
mrconvert -force $afi2 -json_import ${afi2/.nii/.json} $afi2 \
	-set_property RepetitionTime 0.150 -json_export ${afi2/.nii/.json}

# BIDS requires RepetitionTimeExcitation instead of RepetitionTime
# mrconvert messes DeviceSerialNumber up for some reason
for f in "$fmap"/sub-"$sub"_acq-tr?_TB1AFI.json; do
	jq 'with_entries(if .key == "RepetitionTime" then .key = "RepetitionTimeExcitation" else . end) | .DeviceSerialNumber = (.DeviceSerialNumber | tostring)' "$f" > "$tmp" && mv "$tmp" "$f"
done
rm -f "$tmp"

# SESTE
dcm2niix -o "$fmap" -f sub-"$sub"_echo-%e_TB1EPI "$indir"/5_kp_seste_b1map_*
te=0.03906
tm=0.0338
fa=(115 110 105 100 95 90 85 80 75 70 65)
for n in {0..10}; do
	f="$fmap"/sub-"$sub"_echo-1_TB1EPI.nii
	mrconvert "$f" "$fmap"/sub-"$sub"_echo-1_flip-"$(printf %02d $((n+1)))"_TB1EPI.nii -coord 3 "$n" -axes 0,1,2 \
		-json_import "${f/.nii/.json}" \
		-set_property MixingTime $tm -set_property FlipAngle "${fa[$n]}" -set_property EchoTime $te \
		-set_property TotalReadoutTime 0.01296 \
		-json_export "$fmap"/sub-"$sub"_echo-1_flip-"$(printf %02d $((n+1)))"_TB1EPI.json

	f="$fmap"/sub-"$sub"_echo-2_TB1EPI.nii
	mrconvert "$f" "$fmap"/sub-"$sub"_echo-2_flip-"$(printf %02d $((n+1)))"_TB1EPI.nii -coord 3 "$n" -axes 0,1,2 \
		-json_import "${f/.nii/.json}" \
		-set_property MixingTime $tm -set_property FlipAngle "${fa[$n]}" -set_property EchoTime "$(echo $te+$tm | bc)" \
		-set_property TotalReadoutTime 0.01296 \
		-json_export "$fmap"/sub-"$sub"_echo-2_flip-"$(printf %02d $((n+1)))"_TB1EPI.json
done

rm -f "$fmap"/sub-"$sub"_echo-{1,2}_TB1EPI.{nii,json}

# mrconvert messes DeviceSerialNumber up for some reason
for f in "$fmap"/sub-"$sub"_*_TB1EPI.json; do
	jq '.DeviceSerialNumber = (.DeviceSerialNumber | tostring) | . += {"PhaseEncodingDirection":"i-"}' "$f" > "$tmp" && mv "$tmp" "$f"
done
rm -f "$tmp"

# B0 for SESTE
dcm2niix -o "$fmap" -f sub-"$sub"_magnitude%e "$indir"/6_gre_field_map_*
dcm2niix -o "$fmap" -f sub-"$sub"_phasediff "$indir"/7_gre_field_map_*

# for some reason dcm2niix adds a suffix which we don't need
mv "$fmap"/sub-"$sub"_phasediff*.nii "$fmap"/sub-"$sub"_phasediff.nii
mv "$fmap"/sub-"$sub"_phasediff*.json "$fmap"/sub-"$sub"_phasediff.json