#!/bin/bash

set -e

REPORT_PATH="${1:-analysis-results/compliance_report.txt}"

echo "## CBOM Analysis Results" >> $GITHUB_STEP_SUMMARY
echo "Analysis completed at: $(date)" >> $GITHUB_STEP_SUMMARY
echo "### Repository Analyzed" >> $GITHUB_STEP_SUMMARY
echo "Repository: ${GITHUB_REPOSITORY}" >> $GITHUB_STEP_SUMMARY
echo "Branch: ${GITHUB_REF#refs/heads/}" >> $GITHUB_STEP_SUMMARY
echo "Commit: ${GITHUB_SHA}" >> $GITHUB_STEP_SUMMARY
echo "" >> $GITHUB_STEP_SUMMARY

if [ ! -f "$REPORT_PATH" ]; then
  echo "### Compliance report not found." >> $GITHUB_STEP_SUMMARY
  echo "No violations found." >> $GITHUB_STEP_SUMMARY
  echo "" >> $GITHUB_STEP_SUMMARY
  echo "### Full Reports" >> $GITHUB_STEP_SUMMARY
  echo "- CBOM Report (cbom.json)" >> $GITHUB_STEP_SUMMARY
  echo "- Compliance Report (compliance_report.txt)" >> $GITHUB_STEP_SUMMARY
  exit 0
fi

TOTAL_VIOLATIONS=$(grep "Found [0-9]* violation" "$REPORT_PATH" | grep -o '[0-9]*' | head -1)
[ -z "$TOTAL_VIOLATIONS" ] && TOTAL_VIOLATIONS=0

echo "### Security Violations Found" >> $GITHUB_STEP_SUMMARY
echo "**Total violations found: $TOTAL_VIOLATIONS**" >> $GITHUB_STEP_SUMMARY
echo "" >> $GITHUB_STEP_SUMMARY

if [ "$TOTAL_VIOLATIONS" -gt 0 ]; then
  awk '
    BEGIN {
      violation_count = 0; in_violation = 0;
    }
    /^- Rule ID:/ {
      in_violation = 1;
      rule_id = $0;
      gsub(/^- Rule ID:[[:space:]]*/, "", rule_id);
    }
    in_violation && /^  Description:/ {
      description = $0;
      gsub(/^  Description:[[:space:]]*/, "", description);
    }
    in_violation && /^  Location:/ {
      location = $0;
      gsub(/^  Location:[[:space:]]*/, "", location);
      split(location, loc_parts, ":");
      file = loc_parts[1]; line = loc_parts[2];
    }
    in_violation && /^  Finding:/ {
      finding = $0;
      gsub(/^  Finding:[[:space:]]*/, "", finding);
    }
    in_violation && /^$/ {
      if (rule_id && description && file && line) {
        violation_count++;
        severity = "Medium";
        if (index(description, "DES") > 0) severity = "High";
        if (index(description, "MD5") > 0) severity = "Medium";
        if (index(description, "SHA1") > 0) severity = "Medium";
        if (index(description, "RC4") > 0) severity = "High";

        print "#### Violation in `" file "` at line " line >> ENVIRON["GITHUB_STEP_SUMMARY"];
        print "**Rule**: " rule_id >> ENVIRON["GITHUB_STEP_SUMMARY"];
        print "**Severity**: " severity >> ENVIRON["GITHUB_STEP_SUMMARY"];
        print "**Description**: " description >> ENVIRON["GITHUB_STEP_SUMMARY"];
        print "" >> ENVIRON["GITHUB_STEP_SUMMARY"];
        print "**Affected Code:**" >> ENVIRON["GITHUB_STEP_SUMMARY"];
        print "```c" >> ENVIRON["GITHUB_STEP_SUMMARY"];

        start_line = line - 3; end_line = line + 3;
        if (start_line < 1) start_line = 1;
        cmd = "awk -v start=" start_line " -v end=" end_line " -v target=" line " '\''NR >= start && NR <= end { if (NR == target) { printf \\"→ %d: %s\\\\n\\", NR, $0 } else { printf \\"  %d: %s\\\\n\\", NR, $0 } }'\'' " file;
        if (system("test -f " file) == 0) {
          system(cmd " >> " ENVIRON["GITHUB_STEP_SUMMARY"]);
        } else {
          print "File not found in workspace." >> ENVIRON["GITHUB_STEP_SUMMARY"];
        }

        print "```" >> ENVIRON["GITHUB_STEP_SUMMARY"];
        print "" >> ENVIRON["GITHUB_STEP_SUMMARY"];

        if (severity == "High") high_count++;
        else if (severity == "Medium") medium_count++;
        else if (severity == "Low") low_count++;
      }
      in_violation = 0;
      rule_id = ""; description = ""; location = "";
      file = ""; line = ""; finding = "";
    }
    END {
      print "### Violation Statistics" >> ENVIRON["GITHUB_STEP_SUMMARY"];
      print "**Total violations**: " violation_count >> ENVIRON["GITHUB_STEP_SUMMARY"];
      print "" >> ENVIRON["GITHUB_STEP_SUMMARY"];
      print "**By severity:**" >> ENVIRON["GITHUB_STEP_SUMMARY"];
      if (high_count > 0) print "- High: " high_count >> ENVIRON["GITHUB_STEP_SUMMARY"];
      if (medium_count > 0) print "- Medium: " medium_count >> ENVIRON["GITHUB_STEP_SUMMARY"];
      if (low_count > 0) print "- Low: " low_count >> ENVIRON["GITHUB_STEP_SUMMARY"];
      print "" >> ENVIRON["GITHUB_STEP_SUMMARY"];
    }
  ' "$REPORT_PATH"
else
  echo "No violations found." >> $GITHUB_STEP_SUMMARY
  echo "" >> $GITHUB_STEP_SUMMARY
fi

echo "### Full Reports" >> $GITHUB_STEP_SUMMARY
echo "- CBOM Report (cbom.json)" >> $GITHUB_STEP_SUMMARY
echo "- Compliance Report (compliance_report.txt)" >> $GITHUB_STEP_SUMMARY
echo "" >> $GITHUB_STEP_SUMMARY
echo "**Job summary generated at run-time**" >> $GITHUB_STEP_SUMMARY
