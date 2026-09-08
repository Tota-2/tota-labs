const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const output = path.join(root, 'public');
// Publish only the website, never adjacent game source or planning documents.
const files = [
  'index.html', 'robots.txt', 'sitemap.xml', 'app-ads.txt', 'latest-update.json',
  'logo.png', 'og-image.png', 'cicho.png', 'ozaio.png', 'neural-blitz.png',
  'simitci-rush.png', 'tota-finance.png', 'fornow.png', 'perihelix.svg'
];
fs.rmSync(output, { recursive: true, force: true });
fs.mkdirSync(output, { recursive: true });
for (const file of files) fs.copyFileSync(path.join(root, file), path.join(output, file));
console.log(`Published ${files.length} website files.`);
