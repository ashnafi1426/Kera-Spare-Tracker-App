const fs = require('fs');
const path = require('path');

function getFiles(dir) {
  let results = [];
  for (const f of fs.readdirSync(dir)) {
    const p = path.join(dir, f);
    if (fs.statSync(p).isDirectory()) results = results.concat(getFiles(p));
    else if (p.endsWith('.dart')) results.push(p);
  }
  return results;
}

const files = getFiles('lib/features/admin');
const callsWithArgs = new Set();
for (const f of files) {
  const content = fs.readFileSync(f, 'utf8');
  const matches = content.matchAll(/l10n\.([a-zA-Z0-9_]+)\(/g);
  for (const m of matches) callsWithArgs.add(m[1]);
}

console.log('Keys called with arguments:', [...callsWithArgs]);
