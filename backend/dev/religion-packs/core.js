import { assessRequestCrisis, crisisResponse } from '../../src/crisis.js';

// The new development composition root is independent of the production app.
// Packs own religious content; Core owns safety and the fixed-build boundary.
export function createCore({ pack, psychology = () => null }) {
  if (!pack || !['christian', 'buddhist'].includes(pack.id)) throw Error('UNKNOWN_PACK');
  return Object.freeze({
    async respond(request) {
      const safety = assessRequestCrisis(request);
      if (safety.level > 0) return crisisResponse('마음', safety);
      if (request.religion !== undefined && request.religion !== pack.id) throw Error('PACK_MISMATCH');
      const reflection = await psychology(request);
      return pack.respond(request, reflection);
    },
  });
}
