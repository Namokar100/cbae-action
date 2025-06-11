# CBOM Vulnerability Analysis GitHub Action

This GitHub Action performs a comprehensive **CBOM (Cryptographic Bill of Materials)** vulnerability analysis on your repository using a CLI-based tool. It inspects your codebase for weak or disallowed cryptographic primitives and generates both a detailed JSON report and a human-readable compliance summary.

---

## Features

-  **Automated CBOM Analysis:** Runs a full scan of your repository for cryptographic vulnerabilities.
-  **Customizable Setup:** Supports custom dependency installation and build commands.
-  **Detailed Reporting:** Outputs both machine-readable (JSON) and human-readable compliance reports.
-  **CI Enforcement:** Fails CI jobs on policy violations or detected vulnerabilities.
-  **Workflow Summary:** Provides an easy-to-read summary in the workflow output.

---

## Usage

### Basic Example

Add the following to your workflow file (e.g., `.github/workflows/cbom-analysis.yml`):

```yaml
name: Run CBOM Analysis

on:
  push:
    branches: [main]
  pull_request:

jobs:
  cbom-analysis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: Namokar100/cbae-action@v1.0.8
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
```

---

### Example with Custom Dependency Installation and Build Command

If your project requires specific libraries, tools, or a custom build process, you can provide the necessary shell commands using `commands-to-install-build-tools` and `build-command`:

```yaml
name: Run CBOM Analysis with Custom Setup

on:
  push:
    branches: [main]
  pull_request:

jobs:
  cbom-analysis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: Namokar100/cbae-action@v1.0.8
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          commands-to-install-build-tools: |
            #Example
            sudo apt-get update
            sudo apt-get install -y libssl-dev libxml2-dev
          build-command: |
            #Example
            mkdir build
            cd build
            cmake ..
            make -j$(nproc)
```

---

## Inputs

| Name                           | Description                                                                 | Required |
|---------------------------------|-----------------------------------------------------------------------------|----------|
| `token`                        | GitHub token for API access.                                                | Yes      |     
| `commands-to-install-build-tools` | Shell commands to install dependencies before analysis.                    | No       |    
| `build-command`                | Shell command to build your project before analysis.                        | No       |     

---

## Outputs

- **JSON Report:** Detailed vulnerability and compliance findings.
- **Summary:** Human-readable compliance summary in the workflow output.

---

## Compliance & Failure

- The action will **fail the workflow** if any disallowed or weak cryptographic primitives are detected, ensuring your codebase remains compliant.

---

## Support

For questions or issues, please open an [issue](https://github.com/Namokar100/cbae-action/issues) on GitHub.
