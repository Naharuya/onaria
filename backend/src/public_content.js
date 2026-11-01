import {sendContentCatalog} from './content_release_http.js';
import {readFileSync} from 'node:fs';
const original=JSON.parse(readFileSync(new URL('./public_verses.json',import.meta.url),'utf8'));
export function publicContent(req,res,{publications}={}){
 return sendContentCatalog(req,res,publications?publications.catalog():original);
}
