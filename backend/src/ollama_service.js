// Private loopback transport only. Never redirect user text to another host.
export function createOllamaService({ model = 'qwen3:8b', baseUrl = 'http://127.0.0.1:11434', fetchImpl = fetch } = {}) {
  const url = new URL(baseUrl);
  if (url.protocol !== 'http:' || !['127.0.0.1', '[::1]'].includes(url.hostname)
      || url.username || url.password || url.search || url.hash || url.pathname !== '/') {
    throw new Error('Ollama requires a private loopback endpoint.');
  }
  if (!/^[a-zA-Z0-9][a-zA-Z0-9_.:-]{0,79}$/.test(model) || /cloud/i.test(model)) {
    throw new Error('A local Ollama model is required.');
  }
  return {
    async runStructured(task, { signal, onUsage } = {}) {
      signal?.throwIfAborted();
      const response = await fetchImpl(new URL('/api/chat', url), {
        method: 'POST', redirect: 'error', signal,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ model, stream: false, think: false,
          messages: [{ role: 'system', content: task.instructions },
            { role: 'user', content: typeof task.input === 'string' ? task.input : JSON.stringify(task.input) }],
          format: task.jsonSchema, options: { temperature: 0, num_predict: task.maxOutputTokens ?? 900 },
        }),
      });
      if (!response.ok) throw Object.assign(new Error('Local provider unavailable.'), { status: response.status });
      const output = await response.json();
      if (output.done !== true || output.done_reason === 'length' || !output.message?.content) {
        throw Object.assign(new Error('Local response incomplete.'), { code: 'PROVIDER_INCOMPLETE' });
      }
      onUsage?.({ inputTokens: output.prompt_eval_count, outputTokens: output.eval_count });
      return task.schema.parse(JSON.parse(output.message.content));
    },
  };
}
