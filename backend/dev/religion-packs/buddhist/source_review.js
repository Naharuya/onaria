import { readFileSync } from 'node:fs';

// Deliberately separate from ScriptureProvider. Never a quotation/search corpus.
const file = new URL('../../religion-data/buddhist/metadata/source_candidates.json', import.meta.url);
const hosts = new Set(['kabc.dongguk.edu','abchome.dongguk.edu','suttacentral.net','github.com','cbeta.org','www.bdrc.io']);
const fields = ['id','name','source_url','evidence_url','license_url','verification_note','rights_note','copyright_status','ingest_allowed'];
export function sourceReviewCatalog() {
  const catalog = JSON.parse(readFileSync(file, 'utf8'));
  if (catalog.mode !== 'SOURCE_REVIEW_ONLY' || !Array.isArray(catalog.candidates)) throw Error('INVALID_REVIEW_CATALOG');
  const ids = new Set();
  for (const row of catalog.candidates) {
    if (Object.keys(row).length !== fields.length || fields.some(key => !(key in row)) ||
        !/^review-[a-z]+$/.test(row.id) || ids.has(row.id) ||
        row.copyright_status !== 'BLOCKED_EXTERNAL_REVIEW' || row.ingest_allowed !== false ||
        ['name','verification_note','rights_note'].some(key => typeof row[key] !== 'string' || !row[key].trim())) throw Error('INVALID_REVIEW_CANDIDATE');
    ids.add(row.id);
    for (const key of ['source_url','evidence_url','license_url']) {
      if (key === 'license_url' && row[key] === null) continue;
      const url = new URL(row[key]);
      if (url.protocol !== 'https:' || !hosts.has(url.hostname) || url.username || url.password || url.port) throw Error('INVALID_REVIEW_LINK');
    }
  }
  return catalog;
}
