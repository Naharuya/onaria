export class QuietWindowDebouncer {
  constructor({ quietMs = 20 * 60 * 1000, onReady }) {
    this.quietMs = quietMs;
    this.onReady = onReady;
    this.timer = null;
    this.lastChange = null;
  }

  markChanged(meta = {}) {
    this.lastChange = { at: Date.now(), meta };
    if (this.timer) clearTimeout(this.timer);
    this.timer = setTimeout(async () => {
      this.timer = null;
      const snapshot = this.lastChange;
      await this.onReady(snapshot);
    }, this.quietMs);
  }

  cancel() {
    if (this.timer) clearTimeout(this.timer);
    this.timer = null;
  }

  state() {
    return {
      waiting: Boolean(this.timer),
      lastChange: this.lastChange,
      quietMs: this.quietMs,
    };
  }
}
