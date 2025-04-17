#!/bin/bash

# Check for dependencies
command -v trivy >/dev/null 2>&1 || { echo "Trivy is required but not installed."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq is required but not installed."; exit 1; }

# Default output file
OUTPUT_FILE="vulnerabilities_report.csv"
IMAGES_FILE="images.txt"
IMAGES=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --images-file)
            IMAGES_FILE="$2"
            shift 2
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        *)
            IMAGES+=("$1")
            shift
            ;;
    esac
done

# If no CLI images provided, read from file
if [ ${#IMAGES[@]} -eq 0 ]; then
    if [ ! -f "$IMAGES_FILE" ]; then
        echo "No images provided and $IMAGES_FILE not found."
        exit 1
    fi
    mapfile -t IMAGES < "$IMAGES_FILE"
fi

# Validate that we have images to scan
if [ ${#IMAGES[@]} -eq 0 ]; then
    echo "No images to scan."
    exit 1
fi

# Initialize CSV file
echo "Package Name,Severity,Version,Fixed In Version,Description,CVE ID,Source" > "$OUTPUT_FILE"

# Temp file for consolidation
TEMP_FILE=$(mktemp)

# Scan each image
for IMAGE in "${IMAGES[@]}"; do
    echo "Scanning $IMAGE..."
    trivy image --format json "$IMAGE" > temp.json
    # Extract vulnerabilities with jq
    jq -r '.Results[]?.Vulnerabilities[]? | select(. != null) | [.PkgName, .Severity, .InstalledVersion, .FixedVersion // "N/A", .Title // "N/A", .VulnerabilityID, "'"$IMAGE"'"] | @csv' temp.json >> "$TEMP_FILE"
    rm temp.json
done

# Consolidate vulnerabilities with awk
awk -F',' 'BEGIN {OFS=","}
NR>1 {
    key=$1","$2","$3","$4","$5","$6;  # Unique key for vulnerability (excluding Source)
    if (key in sources) {
        sources[key] = sources[key]";"$7;  # Append source (image name)
    } else {
        sources[key] = $7;
        data[key] = $0;
    }
}
END {
    for (key in data) {
        split(data[key], fields, ",");
        print fields[1], fields[2], fields[3], fields[4], fields[5], fields[6], sources[key];
    }
}' "$TEMP_FILE" >> "$OUTPUT_FILE"

# Clean up
rm "$TEMP_FILE"

echo "Scan complete. Report generated at $OUTPUT_FILE"