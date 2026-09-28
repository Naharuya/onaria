import { createCore } from './core.js';

// Only the pack selected at composition time can be routed. No text inference.
export function createReligionRouter(pack, options = {}) {
  return createCore({ ...options, pack });
}
