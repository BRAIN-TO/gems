#!/usr/bin/env bash

# Simple formatting
bold=$(tput bold)
normal=$(tput sgr0)

# Help
function Help() {
    cat <<HELP
    
${bold}$(basename $0) ${normal} 

Usage:
$(basename $0) ${bold}--epi${normal}=EPI image ${bold}--fmap${normal}=Fieldmap
--------------------------------------------------------------------------------
Required arguments:
    --epi   : EPI dataset to be unwarped    ( e.g. /path/to/source/epi.nii.gz )
    --fmap  : Fieldmap in register with EPI ( e.g. /path/to/source/fmap_reg2func.nii.gz )
Optional arguments:
    --dwell   : Effective echo-spacing      ( default: parse from .json file )
    --pedir   : PE direction x/y/z/x-/y-/z- ( default: y )    
    --out     : Output filename             ( default: suffixed with "bto_EPI_Unwarped" )
    --fmapmag   : Fieldmap magnitude image  ( e.g. /path/to/source/fmap_mag.nii.gz )
    --register  : Register fieldmap to EPI  ( requires --fmapmag )
--------------------------------------------------------------------------------
Script was created by: S Kashyap (08-2022), kashyap.sriranga@gmail.com
--------------------------------------------------------------------------------
Citable(s):
    1. Jezzard & Balaban (1995), https://doi.org/10.1002/mrm.1910340111
    2. Andersson et al. (2001), https://doi.org/10.1006/nimg.2001.0746
    3. Hutton et al. (2002), https://doi.org/10.1006/nimg.2001.1054
    4. Jenkinson (2002), https://doi.org/10.1002/mrm.10354
--------------------------------------------------------------------------------

HELP
    exit 1
}

# Check for flag
if [[ "$1" == "-h" || $# -eq 0 ]]; then
    Help >&2
fi

# Get some info
Fversion=$(cat -v ${FSLDIR}/etc/fslversion)
runDate=$(echo $(date))

# Establish some functions
get_opt1() {
    arg=$(echo $1 | sed 's/=.*//')
    echo $arg
}

get_arg1() {
    if [ X$(echo $1 | grep '=') = X ]; then
        echo "Option $1 requires an argument" 1>&2
        exit 1
    else
        arg=$(echo $1 | sed 's/.*=//')
        if [ X$arg = X ]; then
            echo "Option $1 requires an argument" 1>&2
            exit 1
        fi
        echo $arg
    fi
}

get_imarg1() {
    arg=$(get_arg1 $1)
    arg=$($FSLDIR/bin/remove_ext $arg)
    echo $arg
}

# Defaults
pedir=y
out=bto_EPI_Unwarped

# Parse input arguments
while [ $# -ge 1 ]; do
    iarg=$(get_opt1 $1)
    case "$iarg" in

    --epi) # Timeseries Image
        epi=$(get_imarg1 $1)
        shift
        ;;
    --fmap) # Fieldmap in Rads e.g., from bto_dualecho_fieldmap
        fmap=$(get_imarg1 $1)
        shift
        ;;
    --dwell) # Phase1
        dwell=$(get_imarg1 $1)
        shift
        ;;
    --pedir) # Phase2
        pedir=$(get_imarg1 $1)
        shift
        ;;
    --out) # Out
        out=$(get_imarg1 $1)
        shift
        ;;
    --fmapmag) # Phase2
        fmapmag=$(get_imarg1 $1)
        shift
        ;;
    --register) # Phase2
        reg_bool=true
        shift
        ;;
    -h)
        Help
        exit 0
        ;;
    *)
        echo "Unrecognised option $1" 1>&2
        exit 1
        ;;
    esac
done

# Ensure registration works
if [ $reg_bool = "true" ]; then
    if [ -z "$fmapmag" ]; then
        echo "--fmapmag must be specified" 1>&2
        exit 1
    else
        register=yes
        reg_status="Not in register"
    fi
else
    reg_status="Already in register"
fi

echo " "
echo "++++ ${bold}BRAIN-TO EPI Unwarping${normal} ++++"
echo " FSL version $Fversion "
echo " $runDate "
echo " "

# Parse effective echo-spacing from EPI json file
parse_json=$(cat -v ${epi}.json | grep "EffectiveEcho" | tr -dc '0-9')
dwell="${parse_json:0:1}.${parse_json:1}"

echo " ++ Inputs "
echo "  - EPI dataset   : $epi "
echo "  - Fieldmap      : $fmap "
echo "  - Dwell time    : $dwell "
echo "  - PE direction  : $pedir "
echo "  - Registration  : $reg_status "
echo " "
if [ $register = "yes" ]; then
    echo " ++ Running FSL steps "
    echo -ne " - Registering Fieldmap to EPI ...\r "
    flirt \
        --interp trilinear \
        --dof 6 \
        --ref $fmapmag \
        --in $epi \
        --omat ${epi}_reg2Fmap.MAT
    echo " - Registering Fieldmap to EPI ... Done. "
    echo -ne " - Calculating transformations ...\r "
    convert_xfm \
        -inverse ${epi}_reg2Fmap.MAT \
        -omat ${fmapmag}_reg2EPI.MAT

    rm ${epi}_reg2Fmap.MAT
    echo " - Calculating transformations ... Done. "
    
    echo -ne " - Creating brain mask ...\r "
    bet \
        $fmapmag \
        ${fmapmag}_brain \
        -m -R

    imrm \
        ${fmapmag}_brain
    echo " - Creating brain mask ... Done."
    echo -ne " - Unmasking Fieldmap ...\r "
    fslmaths \
        $fmap \
        -abs -bin \
        -mul ${fmapmag}_brain_mask \
        ${fmapmag}_brain_mask

    fugue \
        --loadfmap=${fmap} \
        --mask=${fmapmag}_brain_mask \
        --unmaskfmap \
        --savefmap=${fmap}_unmasked \
        --unwarpdir=$pedir
    echo " - Unmasking Fieldmap ... Done."

    echo -ne " - Writing registered data  ...\r "
    # flirt \
    # -applyxfm \
    # -init ${fmapmag}_reg2EPI.MAT \
    # -ref $epi \
    # -in $fmapmag \
    # -out ${fmapmag}_reg2EPI.nii.gz
    flirt \
        -applyxfm \
        -init ${fmapmag}_reg2EPI.MAT \
        -ref $epi \
        -in ${fmap}_unmasked \
        -out ${fmap}_unmasked_reg2EPI.nii.gz
    echo " - Writing registered data  ... Done. "

    echo -ne " - Executing FUGUE ...\r "
    fugue \
        --in=$epi \
        --loadfmap=${fmap}_reg2EPI.nii.gz \
        --unwarpdir=$pedir \
        --dwell=$dwell \
        --saveshift=${epi}_VDM.nii.gz \
        --unmaskshift \
        --unwarp=$out
    echo " - Executing FUGUE ... Done."
    echo " "

    echo " ++ Output "
    echo "  - Registered Fieldmap       : ${fmap}_reg2EPI "
    echo "  - Voxel displacement map    : ${epi}_VDM "
    echo "  - Unwarped EPI              : $out "
    echo " "

else
    echo -ne " - Executing FUGUE ...\r "
    fugue \
        --in=$epi \
        --loadfmap=$fmap \
        --unwarpdir=$pedir \
        --dwell=$dwell \
        --saveshift=${epi}_VDM.nii.gz \
        --unwarp=$out
    echo " - Executing FUGUE ... Done."
    echo " "

    echo " ++ Output "
    echo "  - Voxel displacement map    : ${epi}_VDM "
    echo "  - Unwarped EPI              : $out "
    echo " "
fi

echo "++++ ${bold}Processing Completed${normal} ++++"
echo " "
