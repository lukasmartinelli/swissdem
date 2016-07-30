#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

readonly DATA_DIR="/data"
readonly OUTPUT_DIR="/output"
readonly SWITZERLAND_BOUNDARIES_SHP="$DATA_DIR/swissboundaries3d/swissBOUNDARIES3D_1_2_TLM_LANDESGEBIET.shp"
readonly NODATA_VALUE="-32767"
readonly METERS_SCALE="111120"

function merge_srtm_files() {
    local srtm1_source_dir="$1"
    local out_file="$2"
    echo "Merge all TIF files in $srtm1_source_dir into $out_file"
    gdal_merge.py -o "$out_file" $(ls $srtm1_source_dir/*.tif) -a_nodata "$NODATA_VALUE"
}

function clip_to_boundaries() {
    local clip_polygon="$1"
    local input="$2"
    local clip_output="$3"
    echo "Clip $input to boundaries Switzerland"
    gdalwarp  -cutline "$clip_polygon" "$input" "$clip_output"
}

function compress_inplace() {
    local filename="$1"
    echo "Compress $filename"
    gdal_translate -co compress=lzw "$filename" "$filename.compressed"
    rm "$filename"
    mv "$filename.compressed" "$filename"
}

function create_hillshade() {
    local dem_source="$1"
    local hillshade_tif="$2"
    gdaldem hillshade -s "$METERS_SCALE" -co compress=lzw "$dem_source" "$hillshade_tif"
}

function create_slope() {
    local dem_source="$1"
    local slope_tif="$2"
    echo "Calculate slope for $slope_tif"
    gdaldem slope -s "$METERS_SCALE" -co compress=lzw "$dem_source" "$slope_tif"
}

function create_color_relief() {
    local dem_source="$1"
    local color_ramp="$2"
    local relief_tif="$3"
    echo "Calculate color relief for $relief_tif"
    gdaldem color-relief -s "$METERS_SCALE" -co compress=lzw "$dem_source" "$color_ramp" "$relief_tif"
}

function create_slope_shade() {
    local slope_source="$1"
    local slope_color="$2"
    local slope_shade_tif="$3"
    echo "Calculate slope shade for $slope_shade_tif"
    gdaldem color-relief -s "$METERS_SCALE" -co compress=lzw "$slope_source" "$slope_color" "$slope_shade_tif"
}

function create_dem_products() {
    dem_source="$1"
    dest_dir="$2"

    mkdir -p "$dest_dir"
    echo "Processing hillshades, slope shades and relief from DEM $dem_source"

    local relief="$dest_dir/switzerland_relief.tif"
    local hillshade="$dest_dir/switzerland_hillshade.tif"
    local slope="$dest_dir/switzerland_slope.tif"
    local slopeshade="$dest_dir/switzerland_slopeshade.tif"

    #create_color_relief "$dem_source" "./color_relief.txt" "$relief"
    #create_hillshade "$dem_source" "$hillshade"
    #create_slope "$dem_source" "$slope"
    create_slope_shade "$slope" "./color_slope.txt" "$slopeshade"
}

function fill_nodata() {
    local dem="$1"
    echo "Fill up missing data in "$dem
    gdal_fillnodata.py "$dem" "$dem.repaired"
    rm "$dem"
    mv "$dem.repaired" "$dem"
}

function main {
    local dem_clipped="$OUTPUT_DIR/switzerland_dem_srtm1.tif"
    local dem_unclipped="$OUTPUT_DIR/switzerland_dem_unclipped_srtm1.tif"

    echo "Processing DEM $dem_clipped"

    #merge_srtm_files "$DATA_DIR/srtm1" "$dem_unclipped"
    #fill_nodata "$dem_unclipped"
    #compress_inplace "$dem_unclipped"

    #clip_to_boundaries "$SWITZERLAND_BOUNDARIES_SHP" "$dem_unclipped" "$dem_clipped"
    #compress_inplace "$dem_clipped"
    create_dem_products "$dem_clipped" "$OUTPUT_DIR"
}

main
