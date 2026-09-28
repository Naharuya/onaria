import { createLocalConversationService } from '../../src/local_conversation_service.js';

// Opt-in adapter only. Production entrypoints and the Bible dataset are unchanged.
export function createChristianPack({ generate = createLocalConversationService(), agent = { id: 'integrated' } } = {}) {
  return Object.freeze({ id: 'christian', respond: (request) => generate(request, agent) });
}
