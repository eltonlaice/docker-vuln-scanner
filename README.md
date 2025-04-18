# Docker Vulnerability Scanner

## Overview
This project is a Bash-based tool that scans Docker images for vulnerabilities using [Trivy](https://aquasecurity.github.io/trivy/) and generates a consolidated CSV report. The tool accepts a list of Docker images, scans them for vulnerabilities, and produces a single CSV file with deduplicated entries, combining vulnerabilities found across multiple images.

Key features:
- Scans any public Docker images (e.g., `tykio/tyk-gateway`, `tykio/tyk-dashboard`).
- Outputs a CSV report with columns: Package Name, Severity, Version, Fixed In Version, Description, CVE ID, Source.
- Supports CLI arguments (`--images-file`, `--output`) for flexibility.
- Can run as a standalone script or as a Docker container.
- Includes a GitHub Actions CI/CD pipeline to automate scans and upload reports.
- Optimized for development in GitHub Codespaces with a pre-configured environment.

## Prerequisites
- **Trivy**: Vulnerability scanner for Docker images.
- **jq**: JSON processor for parsing Trivy output.
- **Docker**: Required to pull and scan images, and for containerized execution.
- **Bash**: For running the script.

## Setup Instructions

### Option 1: Run Locally
1. Install dependencies on your system (e.g., Ubuntu):
   ```bash
   sudo apt update
   sudo apt install -y jq curl
   curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -
   ```
2. Clone the repository:
   ```bash
   git clone https://github.com/eltonlaice/docker-vuln-scanner.git
   cd docker-vuln-scanner
   ```
3. Add Docker images to `images.txt` (one per line) or pass them as arguments.

### Option 2: Run in GitHub Codespaces
1. Open the repository in GitHub Codespaces via the GitHub interface.
2. The `.devcontainer/devcontainer.json` automatically installs `trivy`, `jq`, and starts the Docker daemon.
3. If the Docker daemon isn’t running, start it manually:
   ```bash
   dockerd &
   ```
4. Test the script:
   ```bash
   ./scan.sh --images-file images.txt
   ```
5. Optionally, build and run as a container:
   ```bash
   docker build -t vuln-scanner .
   docker run --rm -v $(pwd):/data vuln-scanner tykio/tyk-gateway tykio/tyk-dashboard --output /data/vulnerabilities_report.csv
   ```
6. **Troubleshooting**: If Docker commands fail, check if the daemon is running (`ps aux | grep dockerd`) or restart it (`sudo pkill -f dockerd && dockerd &`). Rebuild the Codespace if dependencies are missing (Command Palette: `Codespaces: Rebuild Container`).

### Option 3: Run as a Container
1. Build the Docker image:
   ```bash
   docker build -t vuln-scanner .
   ```
2. Run the container with arguments:
   ```bash
   docker run --rm vuln-scanner tykio/tyk-gateway tykio/tyk-dashboard
   ```
3. To save the output locally, mount a volume:
   ```bash
   docker run --rm -v $(pwd):/data vuln-scanner tykio/tyk-gateway tykio/tyk-dashboard --output /data/custom_report.csv
   ```

## Usage Examples

### Scan Images via CLI
```bash
./scan.sh tykio/tyk-gateway tykio/tyk-dashboard
```
Output: Generates `vulnerabilities_report.csv`.

### Scan Images from a File
```bash
./scan.sh --images-file images.txt
```
Example `images.txt`:
```
tykio/tyk-gateway
tykio/tyk-dashboard
```

### Specify a Custom Output File
```bash
./scan.sh --output custom_report.csv tykio/tyk-gateway
```

### Run in CI/CD
The script is designed to be non-interactive for CI/CD pipelines:
```bash
bash ./scan.sh tykio/tyk-gateway tykio/tyk-dashboard > /dev/null
```

## Output Format
The script generates a CSV file (default: `vulnerabilities_report.csv`) with the following columns:
- **Package Name**: Name of the vulnerable package.
- **Severity**: Vulnerability severity (e.g., LOW, MEDIUM, HIGH, CRITICAL).
- **Version**: Installed version of the package.
- **Fixed In Version**: Version where the vulnerability is fixed (or "N/A" if unknown).
- **Description**: Brief description of the vulnerability.
- **CVE ID**: Unique identifier for the vulnerability.
- **Source**: Semicolon-separated list of images where the vulnerability was found (e.g., `tykio/tyk-gateway;tykio/tyk-dashboard`).

A sample report is included in the repository as `sample_vulnerabilities_report.csv`.

## Development Notes
- The script consolidates vulnerabilities by deduplicating entries with the same Package Name, Severity, Version, Fixed In Version, Description, and CVE ID, listing all affected images in the Source column.
- Built and tested in GitHub Codespaces for a seamless development experience.
- The `.devcontainer/devcontainer.json` configures Codespaces with `trivy`, `jq`, and Docker-in-Docker, automatically starting the Docker daemon.

## Contributing
Feel free to open issues or submit pull requests with improvements or bug fixes.

## License
© 2025 Elton Laice. Licensed under the MIT License.