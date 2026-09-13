// Read-only compatibility view. Never copy values into process.env or log them.
// Explicit ONARIA values, including an empty string, take precedence.
export function brandEnv(env = {}) {
  return new Proxy(env, {
    get(target, key) {
      if (typeof key !== 'string' || !key.startsWith('ONARIA_')) return target[key];
      if (target[key] !== undefined) return target[key];
      const suffix = key.slice('ONARIA_'.length);
      return target[`SOUL_${suffix}`] ?? target[`MIND_${suffix}`];
    },
  });
}
