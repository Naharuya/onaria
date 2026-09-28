// Explicit development server, isolated from production and existing local services.
// Does not load .env or any stored OpenAI credentials.
import { fileURLToPath } from 'node:url';
import { createApp } from '../src/app.js';
import { createConversationService } from '../src/conversation_service.js';
import { createMemberStore } from '../src/member_store.js';

const port = 8791;
const env = { ONARIA_AI_MODE: 'ollama', ONARIA_EXTERNAL_API_DISABLED: 'true',
  ONARIA_OLLAMA_MODEL: 'qwen3:8b', ONARIA_OLLAMA_BASE_URL: 'http://127.0.0.1:11434' };
const generate = createConversationService({ env });
const memberStore = createMemberStore({ filename: fileURLToPath(new URL('../data/mac-ai/members.sqlite', import.meta.url)) });
const app = createApp({ generate, memberStore, publicOrigin: `http://127.0.0.1:${port}` });
const server = app.listen(port, '127.0.0.1', () => console.log(`ONARIA Mac AI: http://127.0.0.1:${port} (${env.ONARIA_OLLAMA_MODEL}, cloud disabled)`));
server.on('close', () => memberStore.close());
for (const signal of ['SIGINT', 'SIGTERM']) process.once(signal, () => server.close());
