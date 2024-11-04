#!/bin/bash
set -e

# Set the workspace output directory
OUTPUT_DIR="/workspace"
ERROR_LOG="${OUTPUT_DIR}/error.log"

# Clear the error log at the start of each run
> "$ERROR_LOG"

# Required input validation
if [[ -z "$KICAD_SCH" ]] && [[ -z "$KICAD_PCB" ]]; then
  echo "Error: At least one of KICAD_SCH or KICAD_PCB must be provided." | tee -a "$ERROR_LOG"
  exit 1
fi

# Determine the output file extension based on report format
get_report_extension() {
  if [[ "$REPORT_FORMAT" == "json" ]]; then
    echo "json"
  else
    echo "rpt"
  fi
}

# Run ERC on schematic if requested
if [[ "$SCH_ERC" == "true" && -n "$KICAD_SCH" ]]; then
  erc_output_file="${OUTPUT_DIR}/${SCH_ERC_FILE:-erc}.$(get_report_extension)"
  kicad_cli sch export erc "$KICAD_SCH" --output "$erc_output_file" --format "$REPORT_FORMAT" || {
    echo "ERC failed." | tee -a "$ERROR_LOG"
    exit 1
  }
  echo "ERC succeeded. Output: $erc_output_file"
fi

# Generate PDF from schematic if requested
if [[ "$SCH_PDF" == "true" && -n "$KICAD_SCH" ]]; then
  pdf_output_file="${OUTPUT_DIR}/${SCH_PDF_FILE:-sch.pdf}"
  kicad_cli sch export pdf "$KICAD_SCH" --output "$pdf_output_file" || {
    echo "PDF generation failed." | tee -a "$ERROR_LOG"
    exit 1
  }
  echo "PDF generation succeeded. Output: $pdf_output_file"
fi

# Generate BOM from schematic if requested
if [[ "$SCH_BOM" == "true" && -n "$KICAD_SCH" ]]; then
  bom_output_file="${OUTPUT_DIR}/${SCH_BOM_FILE:-bom.csv}"
  bom_preset_flag=()
  if [[ -n "$SCH_BOM_PRESET" ]]; then
    bom_preset_flag=(--preset "$SCH_BOM_PRESET")
  fi
  kicad_cli sch export bom "$KICAD_SCH" --output "$bom_output_file" "${bom_preset_flag[@]}" || {
    echo "BOM generation failed." | tee -a "$ERROR_LOG"
    exit 1
  }
  echo "BOM generation succeeded. Output: $bom_output_file"
fi

# Run DRC on PCB if requested
if [[ "$PCB_DRC" == "true" && -n "$KICAD_PCB" ]]; then
  drc_output_file="${OUTPUT_DIR}/${PCB_DRC_FILE:-drc}.$(get_report_extension)"
  kicad_cli pcb export drc "$KICAD_PCB" --output "$drc_output_file" --format "$REPORT_FORMAT" || {
    echo "DRC failed." | tee -a "$ERROR_LOG"
    exit 1
  }
  echo "DRC succeeded. Output: $drc_output_file"
fi

# Generate Gerbers from PCB if requested
if [[ "$PCB_GERBERS" == "true" && -n "$KICAD_PCB" ]]; then
  gerbers_output_file="${OUTPUT_DIR}/${PCB_GERBERS_FILE:-gbr.zip}"
  kicad_cli pcb export gerbers "$KICAD_PCB" --output "$gerbers_output_file" || {
    echo "Gerbers generation failed." | tee -a "$ERROR_LOG"
    exit 1
  }
  echo "Gerbers generation succeeded. Output: $gerbers_output_file"
fi

# If we reach here, all commands were successful
echo "All requested operations completed successfully."
