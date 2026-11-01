import {createHash} from 'node:crypto';
export function sendContentCatalog(req,res,value,{cache='public, no-cache'}={}){
 const raw=JSON.stringify(value),etag='"'+createHash('sha256').update(raw).digest('hex')+'"';
 res.setHeader('Cache-Control',cache);res.setHeader('ETag',etag);res.setHeader('Content-Type','application/json; charset=utf-8');
 const candidates=String(req.headers['if-none-match']??'').split(',').map(v=>v.trim().replace(/^W\//,''));
 if(candidates.includes(etag)||candidates.includes('*')){res.statusCode=304;return res.end();}
 res.statusCode=200;return res.end(raw);
}
