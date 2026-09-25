#!/bin/bash
#
# recon.sh - basic recon report generator
# Usage: recon.sh <target> [--slow]
#   <target>  domain or IP address
#   --slow    optional: run the vuln scan at -T2 with a 1s delay between probes

set -euo pipefail

TARGET=""
SLOW=false

# Loop through all arguments, since --slow could come before or after the target
for arg in "$@"; do
    if [ "$arg" == "--slow" ]; then
        SLOW=true
    else
        TARGET="$arg"
    fi
done

if [ -z "$TARGET" ]; then
    echo "Usage: $0 <target-domain-or-ip> [--slow]"
    echo "Example: $0 scanme.nmap.org --slow"
    exit 1
fi

mkdir -p /output
TIMESTAMP=$(date +%s)
OUTFILE="/output/${TARGET}-${TIMESTAMP}.txt"
XMLFILE="/output/${TARGET}-${TIMESTAMP}.xml"
VULNXML="/output/${TARGET}-${TIMESTAMP}-vuln.xml"

{
    echo "=================================================="
    echo " RECON REPORT FOR: $TARGET"
    echo " Generated: $(date)"
    echo " Mode: $([ "$SLOW" = true ] && echo "slow/polite" || echo "normal")"
    echo "=================================================="
    echo

    echo "--------------------------------------------------"
    echo " WHOIS"
    echo "--------------------------------------------------"
    whois "$TARGET" || echo "(whois lookup failed or returned no data)"
    echo

    echo "--------------------------------------------------"
    echo " DNS - A RECORDS"
    echo "--------------------------------------------------"
    dig +short A "$TARGET" || echo "(no A records found)"
    echo

    echo "--------------------------------------------------"
    echo " DNS - MX RECORDS"
    echo "--------------------------------------------------"
    dig +short MX "$TARGET" || echo "(no MX records found)"
    echo

    echo "--------------------------------------------------"
    echo " DNS - NS RECORDS"
    echo "--------------------------------------------------"
    dig +short NS "$TARGET" || echo "(no NS records found)"
    echo

    echo "--------------------------------------------------"
    echo " NMAP SCAN"
    echo "--------------------------------------------------"
    nmap -oX "$XMLFILE" -oN - "$TARGET" || echo "(nmap scan failed)"
    echo "XML report saved to: $XMLFILE"
    echo

    echo "--------------------------------------------------"
    echo " NMAP VULNERABILITY SCAN (with version detection)"
    echo " ---------- THIS MAY TAKE A MOMENT ...------------"
    echo "--------------------------------------------------"
    if [ "$SLOW" = true ]; then
        echo "(running in slow/polite mode: -T2, 1s scan delay)"
        nmap -v -sV --script vuln -T2 --scan-delay 1s --stats-every 10s -oX "$VULNXML" -oN - "$TARGET" || echo "(vuln scan failed)"
    else
        nmap -v -sV --script vuln --stats-every 10s -oX "$VULNXML" -oN - "$TARGET" || echo "(vuln scan failed)"
    fi
    echo "Vuln XML report saved to: $VULNXML"
    echo
    echo "=================================================="
    echo " END OF REPORT"
    echo "=================================================="
} | tee "$OUTFILE"
