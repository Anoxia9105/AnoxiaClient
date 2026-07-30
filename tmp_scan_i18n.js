const fs = require('fs');
const path = require('path');

const root = 'd:/GIT/AnoxiaServer/AnoxiaAdmin/src';
const localeFiles = [
  'd:/GIT/AnoxiaServer/AnoxiaAdmin/src/locales/zh-CN.ts',
  'd:/GIT/AnoxiaServer/AnoxiaAdmin/src/locales/en.ts',
  'd:/GIT/AnoxiaServer/AnoxiaAdmin/src/locales/ja.ts',
];

function walk(dir, out = []) {
  for (const name of fs.readdirSync(dir)) {
    const p = path.join(dir, name);
    const st = fs.statSync(p);
    if (st.isDirectory()) {
      walk(p, out);
    } else if (/\.(vue|ts|js)$/.test(name)) {
      out.push(p);
    }
  }
  return out;
}

function keyExists(content, key) {
  const parts = key.split('.');
  let from = 0;
  for (let i = 0; i < parts.length; i++) {
    const p = parts[i].replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const re = i < parts.length - 1
      ? new RegExp('\\b' + p + '\\s*:\\s*\\{', 'm')
      : new RegExp('\\b' + p + '\\s*:', 'm');
    const sliced = content.slice(from);
    const m = re.exec(sliced);
    if (!m) return false;
    from += m.index + m[0].length;
  }
  return true;
}

const files = walk(root);
const keyRe = /(?:\$t|\bt)\(\s*(['\"])([^'\"]+)\1/g;
const keys = new Set();

for (const f of files) {
  const c = fs.readFileSync(f, 'utf8');
  let m;
  while ((m = keyRe.exec(c)) !== null) {
    keys.add(m[2]);
  }
}

const localeContents = Object.fromEntries(
  localeFiles.map((f) => [path.basename(f), fs.readFileSync(f, 'utf8')])
);

const missing = [];
for (const k of keys) {
  for (const [locale, content] of Object.entries(localeContents)) {
    if (!keyExists(content, k)) {
      missing.push({ key: k, locale });
    }
  }
}

missing.sort((a, b) => a.key.localeCompare(b.key) || a.locale.localeCompare(b.locale));

const report = [
  `TOTAL_KEYS=${keys.size}`,
  `MISSING_COUNT=${missing.length}`,
  '',
  ...missing.map((x) => `${x.key}\t${x.locale}`),
].join('\n');

const reportPath = 'd:/GIT/AnoxiaClient/tmp_i18n_missing_report.txt';
fs.writeFileSync(reportPath, report, 'utf8');
console.log(`REPORT=${reportPath}`);
console.log(`TOTAL_KEYS=${keys.size}`);
console.log(`MISSING_COUNT=${missing.length}`);
