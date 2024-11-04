#!/bin/bash
set -e

# Set the workspace output directory
OUTPUT_DIR="/workspace"
ERROR_LOG="${OUTPUT_DIR}/error.log"

# Clear the error log at the start of each run
> "$ERROR_LOG"

# Debugging: Print input values
echo "DEBUG: INPUT_KICAD_SCH = $INPUT_KICAD_SCH"
echo "DEBUG: INPUT_KICAD_PCB = $INPUT_KICAD_PCB"

# Required input validation
if [[ -z "$INPUT_KICAD_SCH" ]] && [[ -z "$INPUT_KICAD_PCB" ]]; then
  echo "Error: At least one of KICAD_SCH or KICAD_PCB must be provided." | tee -a "$ERROR_LOG"
  exit 1
fi

# Determine the output file extension based on report format
get_report_extension() {
  if [[ "$INPUT_REPORT_FORMAT" == "json" ]]; then
    echo "json"
  else
    echo "rpt"
  fi
}

# Run ERC on schematic if requested
if [[ "$INPUT_SCH_ERC" == "true" && -n "$INPUT_KICAD_SCH" ]]; then
  erc_output_file="${OUTPUT_DIR}/${INPUT_SCH_ERC_FILE:-erc}.$(get_report_extension)"
  kicad_cli sch export erc "$INPUT_KICAD_SCH" --output "$erc_output_file" --format "$INPUT_REPORT_FORMAT" || {
    echo "ERC failed." | tee -a "$ERROR_LOG"
    exit 1
  }
  echo "ERC succeeded. Output: $erc_output_file"
fi

# Generate PDF from schematic if requested
if [[ "$INPUT_SCH_PDF" == "true" && -n "$INPUT_KICAD_SCH" ]]; then
  pdf_output_file="${OUTPUT_DIR}/${INPUT_SCH_PDF_FILE:-sch.pdf}"
  kicad_cli sch export pdf "$INPUT_KICAD_SCH" --output "$pdf_output_file" || {
    echo "PDF generation failed." | tee -a "$ERROR_LOG"
    exit 1
  }
  echo "PDF generation succeeded. Output: $pdf_output_file"
fi

# Generate BOM from schematic if requested
if [[ "$INPUT_SCH_BOM" == "true" && -n "$INPUT_KICAD_SCH" ]]; then
  bom_output_file="${OUTPUT_DIR}/${INPUT_SCH_BOM_FILE:-bom.csv}"
  bom_preset_flag=()
  if [[ -n "$INPUT_SCH_BOM_PRESET" ]]; then
    bom_preset_flag=(--preset "$INPUT_SCH_BOM_PRESET")
  fi
  kicad_cli sch export bom "$INPUT_KICAD_SCH" --output "$bom_output_file" "${bom_preset_flag[@]}" || {
    echo "BOM generation failed." | tee -a "$ERROR_LOG"
    exit 1
  }
  echo "BOM generation succeeded. Output: $bom_output_file"
fi

# Run DRC on PCB if requested
if [[ "$INPUT_PCB_DRC" == "true" && -n "$INPUT_KICAD_PCB" ]]; then
  drc_output_file="${OUTPUT_DIR}/${INPUT_PCB_DRC_FILE:-drc}.$(get_report_extension)"
  kicad_cli pcb export drc "$INPUT_KICAD_PCB" --output "$drc_output_file" --format "$INPUT_REPORT_FORMAT" || {
    echo "DRC failed." | tee -a "$ERROR_LOG"
    exit 1
  }
  echo "DRC succeeded. Output: $drc_output_file"
fi

# Generate Gerbers from PCB if requested
if [[ "$INPUT_PCB_GERBERS" == "true" && -n "$INPUT_KICAD_PCB" ]]; then
  gerbers_output_file="${OUTPUT_DIR}/${INPUT_PCB_GERBERS_FILE:-gbr.zip}"
  kicad_cli pcb export gerbers "$INPUT_KICAD_PCB" --output "$gerbers_output_file" || {
    echo "Gerbers generation failed." | tee -a "$ERROR_LOG"
    exit 1
  }
  echo "Gerbers generation succeeded. Output: $gerbers_output_file"
fi

# If we reach here, all commands were successful
echo "All requested operations completed successfully."
