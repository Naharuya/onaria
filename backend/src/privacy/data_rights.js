import { Router } from 'express';
import { readFileSync } from 'node:fs';
const profile = JSON.parse(readFileSync(new URL('./data_rights_profile.json', import.meta.url), 'utf8'));
const html = readFileSync(new URL('../../public/data-rights.html', import.meta.url), 'utf8');
export function dataRightsBody() { return html.slice(html.indexOf('<main>')+6,html.lastIndexOf('</main>')); }
export function dataRightsRouter({websiteOwnsAccountDeletion=false}={}) {
  const router = Router();
  router.get(websiteOwnsAccountDeletion ? ['/data-controls'] : ['/account-deletion', '/data-controls'], (_req,res) => {
    res.set({'Cache-Control':'no-store','Referrer-Policy':'no-referrer','X-Content-Type-Options':'nosniff'});
    res.type('html').send(html);
  });
  router.get('/v1/privacy/rights', (_req,res) => {
    res.set('Cache-Control','no-store');
    res.json({version:'ari-data-rights-v1',app:profile.app,localStorage:profile.localStorage,
      serverRecords:profile.serverRecords,accountDeletionPath:'/account-deletion',dataControlsPath:'/data-controls',
      supportEmail:profile.supportEmail,privacyPath:profile.privacyPath,
      automaticCrossAppDeletion:false,automaticDeviceSync:false});
  });
  return router;
}
