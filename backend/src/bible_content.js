import fs from 'node:fs';

const biblePath = new URL('../data/content/bible_verses_ko.json', import.meta.url);
let cached;

export function getBibleContent() {
  if (cached) return cached;
  const parsed = JSON.parse(fs.readFileSync(biblePath, 'utf8'));
  if (!parsed || !Array.isArray(parsed.verses)) throw new Error('Invalid bible content');
  cached = parsed;
  return cached;
}
