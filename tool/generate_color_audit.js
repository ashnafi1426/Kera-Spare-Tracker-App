const fs = require('fs');
const path = require('path');

const libDir = path.join(__dirname, '..', 'lib');
const docsDir = path.join(__dirname, '..', 'docs');
const testDir = path.join(__dirname, '..', 'test');

if (!fs.existsSync(docsDir)) fs.mkdirSync(docsDir, { recursive: true });
if (!fs.existsSync(testDir)) fs.mkdirSync(testDir, { recursive: true });

// Extended regex patterns according to Item 8:
// - Colors.<non-neutral>
// - Color(0x...)
// - Color.fromARGB(...)
// - Color.fromRGBO(...)
// - MaterialColor
// - Colors.primaries
// - Colors.accents
const extendedPatterns = [
  { name: 'Colors.<hue>', regex: /\bColors\.(?!white\b|black\b|transparent\b)[a-zA-Z0-9_]+/g },
  { name: 'Color(0x...)', regex: /\bColor\(0x[0-9a-fA-F]+\)/g },
  { name: 'Color.fromARGB', regex: /\bColor\.fromARGB\([^\)]+\)/g },
  { name: 'Color.fromRGBO', regex: /\bColor\.fromRGBO\([^\)]+\)/g },
  { name: 'MaterialColor', regex: /\bMaterialColor\b/g },
  { name: 'Colors.primaries', regex: /\bColors\.primaries\b/g },
  { name: 'Colors.accents', regex: /\bColors\.accents\b/g },
];

function walk(dir, fileList = []) {
  const files = fs.readdirSync(dir);
  for (const file of files) {
    const fullPath = path.join(dir, file);
    const stat = fs.statSync(fullPath);
    if (stat.isDirectory()) {
      walk(fullPath, fileList);
    } else if (file.endsWith('.dart')) {
      fileList.push(fullPath);
    }
  }
  return fileList;
}

const allFiles = walk(libDir);
const results = [];
let totalNonNeutral = 0;
let totalHex = 0;
let totalFromARGB = 0;
let totalFromRGBO = 0;
let totalMaterialColor = 0;
let totalPrimaries = 0;

for (const filePath of allFiles) {
  const relative = path.relative(path.join(__dirname, '..'), filePath).replace(/\\/g, '/');
  
  // Whitelist core token and theme files
  if (relative.startsWith('lib/core/theme/') || relative.startsWith('lib/core/design/tokens/')) {
    continue;
  }

  const content = fs.readFileSync(filePath, 'utf8');
  let fileViolations = 0;
  const counts = {};

  for (const p of extendedPatterns) {
    const matches = content.match(p.regex) || [];
    counts[p.name] = matches.length;
    fileViolations += matches.length;
  }

  if (fileViolations > 0) {
    totalNonNeutral += counts['Colors.<hue>'] || 0;
    totalHex += counts['Color(0x...)'] || 0;
    totalFromARGB += counts['Color.fromARGB'] || 0;
    totalFromRGBO += counts['Color.fromRGBO'] || 0;
    totalMaterialColor += counts['MaterialColor'] || 0;
    totalPrimaries += (counts['Colors.primaries'] || 0) + (counts['Colors.accents'] || 0);

    results.push({
      file: relative,
      nonNeutralColorsCount: counts['Colors.<hue>'] || 0,
      hexColorsCount: counts['Color(0x...)'] || 0,
      fromARGBCount: counts['Color.fromARGB'] || 0,
      fromRGBOCount: counts['Color.fromRGBO'] || 0,
      materialColorCount: counts['MaterialColor'] || 0,
      primariesCount: (counts['Colors.primaries'] || 0) + (counts['Colors.accents'] || 0),
      totalViolations: fileViolations,
      redesigned: false,
    });
  }
}

// Sort by total descending
results.sort((a, b) => b.totalViolations - a.totalViolations);

const grandTotal = totalNonNeutral + totalHex + totalFromARGB + totalFromRGBO + totalMaterialColor + totalPrimaries;

const baseline = {
  generatedAt: new Date().toISOString(),
  totalFilesWithViolations: results.length,
  totalNonNeutralColorReferences: totalNonNeutral,
  totalHardcodedHexReferences: totalHex,
  totalFromARGBReferences: totalFromARGB,
  totalFromRGBOReferences: totalFromRGBO,
  totalMaterialColorReferences: totalMaterialColor,
  totalPrimariesReferences: totalPrimaries,
  grandTotalViolations: grandTotal,
  files: results,
};

fs.writeFileSync(
  path.join(testDir, 'color_audit_baseline.json'),
  JSON.stringify(baseline, null, 2),
  'utf8'
);

let md = `# Kera Spare Tracker — Extended Color Audit Baseline Report\n\n`;
md += `**Generated Date:** ${new Date().toISOString()}\n`;
md += `**Scope:** All Dart source files under \`lib/\` (excluding \`lib/core/theme/\` and \`lib/core/design/tokens/\`)\n\n`;
md += `## Executive Summary\n\n`;
md += `| Violation Category | Count |\n`;
md += `| :--- | :---: |\n`;
md += `| **Files with Rogue Color References** | **${results.length} files** |\n`;
md += `| **Rogue \`Colors.<hue>\` References** | **${totalNonNeutral}** |\n`;
md += `| **Hardcoded \`Color(0x...)\` References** | **${totalHex}** |\n`;
md += `| **\`Color.fromARGB(...)\` References** | **${totalFromARGB}** |\n`;
md += `| **\`Color.fromRGBO(...)\` References** | **${totalFromRGBO}** |\n`;
md += `| **\`MaterialColor\` References** | **${totalMaterialColor}** |\n`;
md += `| **\`Colors.primaries\` / \`accents\`** | **${totalPrimaries}** |\n`;
md += `| **Grand Total Violations** | **${grandTotal}** |\n\n`;
md += `---\n\n`;
md += `## Detailed File-by-File Extended Audit\n\n`;
md += `| # | File Path | \`Colors.<hue>\` | \`Color(0x...)\` | \`fromARGB/fromRGBO\` | Total | Redesigned Status |\n`;
md += `| :-: | :--- | :-: | :-: | :-: | :-: | :-: |\n`;

results.forEach((r, idx) => {
  const dynamicCount = r.fromARGBCount + r.fromRGBOCount + r.materialColorCount + r.primariesCount;
  md += `| ${idx + 1} | \`${r.file}\` | ${r.nonNeutralColorsCount} | ${r.hexColorsCount} | ${dynamicCount} | **${r.totalViolations}** | ${r.redesigned ? 'Redesigned (0 expected)' : 'Pending Migration'} |\n`;
});

md += `\n---\n`;
md += `*Baseline strictly locked in \`test/color_audit_baseline.json\`. Any violation increase fails the automated CI test.*\n`;

fs.writeFileSync(path.join(docsDir, 'color-audit.md'), md, 'utf8');

console.log(`Extended audit complete: ${results.length} files with violations, grand total ${grandTotal}.`);
