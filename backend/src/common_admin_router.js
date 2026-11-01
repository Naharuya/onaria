import {ContentReleaseError} from './content_release_core.js';
import {Router} from 'express';
import {createAdminControl,AdminControlError} from './common_admin.js';
export function commonAdminRouter(options){
 const {accounts,audit}=options;
 const control=createAdminControl(options),router=Router();
 const owner=(req,res,next)=>{
  if(res.locals.admin?.role!=='owner')return res.status(403).json({code:'FORBIDDEN'});
  if(!accounts||!audit)return res.status(503).json({code:'ADMIN_ACCOUNTS_UNAVAILABLE'});
  return next();
 };
 router.get('/accounts',owner,(_req,res)=>res.json({accounts:accounts.list()}));
 router.post('/accounts',owner,async(req,res)=>{
  const actor=res.locals.admin;
  if(!req.body||Object.keys(req.body).sort().join(',')!=='password,role,username')return res.status(400).json({code:'INVALID_INPUT'});
  try{
   audit.record({actor:actor.actor,role:actor.role,action:'admin.account.create',outcome:'started'});
   const account=await accounts.create(req.body);
   audit.record({actor:actor.actor,role:actor.role,action:'admin.account.create',target:account.id,outcome:'success'});
   return res.status(201).json({account});
  }catch(error){return res.status(['INVALID_USERNAME','WEAK_PASSWORD','INVALID_ROLE'].includes(error.code)?400:error.code==='USERNAME_EXISTS'?409:503).json({code:'ADMIN_ACCOUNT_CHANGE_UNCONFIRMED'});}
 });
 router.post('/accounts/:id',owner,(req,res)=>{
  const actor=res.locals.admin;
  if(actor.accountId===req.params.id)return res.status(409).json({code:'SELF_CHANGE_FORBIDDEN'});
  if(!req.body||Object.keys(req.body).sort().join(',')!=='disabled,role'||typeof req.body.disabled!=='boolean')return res.status(400).json({code:'INVALID_INPUT'});
  if(!accounts.get(req.params.id))return res.status(404).json({code:'NOT_FOUND'});
  if(!['owner','admin','editor','reviewer','support','operator','viewer'].includes(req.body.role))return res.status(400).json({code:'INVALID_ROLE'});
  try{
   audit.record({actor:actor.actor,role:actor.role,action:'admin.account.update',target:req.params.id,outcome:'started'});
   accounts.setRole(req.params.id,req.body.role);accounts.setDisabled(req.params.id,req.body.disabled);
   audit.record({actor:actor.actor,role:actor.role,action:'admin.account.update',target:req.params.id,outcome:'success'});
   return res.json({account:accounts.get(req.params.id)});
  }catch{return res.status(503).json({code:'ADMIN_ACCOUNT_CHANGE_UNCONFIRMED'});}
 });
 router.use((req,res)=>{
  res.set('Cache-Control','no-store');
  try{const input={method:req.method,path:req.path,body:req.body,actor:res.locals.admin};return res.json(req.path.startsWith('/publications')&&options.publications?options.publications.dispatch(input):control.dispatch(input));}
  catch(error){return res.status((error instanceof AdminControlError||error instanceof ContentReleaseError)?error.status:503).json({code:(error instanceof AdminControlError||error instanceof ContentReleaseError)?error.code:'ADMIN_STORAGE_UNAVAILABLE'});}
 });
 return router;
}
