#!/usr/bin/env bash
# Hermes Enterprise Stack (HES)
# File: docs/assets/export-png.sh
# Purpose: Export Mermaid (.mmd) diagrams to PNG using mmdc if available.
#          Falls back to an informative message when mmdc is not installed.
#
# Usage:
#   ./docs/assets/export-png.sh            # export all diagrams
#   ./docs/assets/export-png.sh dark       # export with dark theme
#   ./docs/assets/export-png.sh light      # export with light theme (default)

set -Eeuo pipefail

# Resolve the directory containing this script so it works from anywhere.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Theme handling: accept "dark" or "light" as the first argument, default "light".
theme="${1:-light}"
if [[ "${theme}" != "dark" && "${theme}" != "light" ]]; then
    echo "Unknown theme '${theme}'. Use 'dark' or 'light'." >&2
    exit 1
fi

# Mermaid CLI binary name (npx provides a fallback path if installed globally).
mmdc_cmd=""
if command -v mmdc >/dev/null 2>&1; then
    mmdc_cmd="mmdc"
elif command -v npx >/dev/null 2>&1; then
    mmdc_cmd="npx -y @mermaid-js/mermaid-cli"
fi

# The diagrams to export.
diagrams=(
    "architecture-overview"
    "network-topology"
    "security-layers"
    "deployment-flow"
)

if [[ -z "${mmdc_cmd}" ]]; then
    echo "============================================================"
    echo " mmdc (Mermaid CLI) was not found on this system."
    echo "============================================================"
    echo ""
    echo " The Mermaid source files (.mmd) are ready in:"
    echo "   ${script_dir}"
    echo ""
    echo " To export them to PNG, install the Mermaid CLI:"
    echo ""
    echo "   npm install -g @mermaid-js/mermaid-cli"
    echo ""
    echo " or use npx directly:"
    echo ""
    echo "   npx -y @mermaid-js/mermaid-cli -i ${script_dir}/architecture-overview.mmd -o ${script_dir}/architecture-overview.png"
    echo ""
    echo " For dark-theme PNGs, add a background color:"
    echo "   -b transparent -t dark"
    echo ""
    echo " Diagrams available:"
    for d in "${diagrams[@]}"; do
        echo "   - ${d}.mmd"
    done
    echo "============================================================"
    exit 0
fi

# Build the theme flag set for mmdc.
theme_args=()
if [[ "${theme}" == "dark" ]]; then
    theme_args=(-t dark -b "#1e1e2e")
else
    theme_args=(-t default -b white)
fi

echo "Exporting Mermaid diagrams (${theme} theme) using: ${mmdc_cmd}"

failed=0
for d in "${diagrams[@]}"; do
    src="${script_dir}/${d}.mmd"
    out="${script_dir}/${d}.png"
    if [[ ! -f "${src}" ]]; then
        echo "  SKIP  ${d}.mmd (not found)"
        continue
    fi
    echo "  -> ${d}.png"
    if ! ${mmdc_cmd} -i "${src}" -o "${out}" "${theme_args[@]}"; then
        echo "  FAIL  ${d} (mmdc exited non-zero)" >&2
        failed=1
    fi
done

if [[ "${failed}" -eq 1 ]]; then
    echo "One or more diagrams failed to export." >&2
    exit 1
fi

echo "Done."
