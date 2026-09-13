// K-Stock mock verification must fail before standard Node transports reach external hosts.
const net = require('node:net');
const tls = require('node:tls');
const http = require('node:http');
const https = require('node:https');
const dns = require('node:dns');
const blocked = () => { throw new Error('ARI_EXTERNAL_REQUEST_BLOCKED'); };
function assertLocal(host) {
  if (!['localhost','127.0.0.1','::1','[::1]'].includes(String(host))) blocked();
}
function hostOf(value) {
  if (typeof value === 'string' || value instanceof URL) return new URL(value).hostname;
  return value?.hostname ?? value?.host ?? 'localhost';
}
for (const module of [http,https]) {
  for (const method of ['request','get']) {
    const original = module[method];
    module[method] = function (...args) { assertLocal(hostOf(args[0])); return original.apply(this,args); };
  }
}
for (const module of [net,tls]) {
  for (const method of ['connect',...(module === net ? ['createConnection'] : [])]) {
    const original = module[method];
    module[method] = function (...args) {
      if (typeof args[0] === 'object' && args[0].path) blocked();
      const host = typeof args[0] === 'object' ? args[0].host ?? 'localhost' : typeof args[1] === 'string' ? args[1] : 'localhost';
      assertLocal(host); return original.apply(this,args);
    };
  }
}
const fetch = globalThis.fetch;
if (fetch) globalThis.fetch = async function (input,...args) { assertLocal(new URL(typeof input === 'string' || input instanceof URL ? input : input.url).hostname); return fetch(input,...args); };
for (const name of ['lookup','resolve','resolve4','resolve6']) {
 const original=dns[name];dns[name]=function(host,...args){assertLocal(host);return original.call(this,host,...args);};
}
