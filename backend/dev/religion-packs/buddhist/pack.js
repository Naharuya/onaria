import { BuddhistScriptureProvider } from './provider.js';
import { createBuddhistAgent } from './agent.js';

export function createBuddhistPack({ provider = new BuddhistScriptureProvider() } = {}) {
  const agent = createBuddhistAgent(provider);
  return Object.freeze({ id: 'buddhist', provider, respond: (request) => agent.respond(request) });
}
