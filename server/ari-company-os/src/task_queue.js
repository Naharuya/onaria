import fs from 'node:fs';
import path from 'node:path';

export class TaskQueue {
  constructor(filePath) {
    this.filePath = filePath;
    fs.mkdirSync(path.dirname(filePath), { recursive: true });
    if (!fs.existsSync(filePath)) fs.writeFileSync(filePath, '[]\n');
  }

  #read() {
    return JSON.parse(fs.readFileSync(this.filePath, 'utf8'));
  }

  #write(tasks) {
    const tmp = `${this.filePath}.tmp`;
    fs.writeFileSync(tmp, `${JSON.stringify(tasks, null, 2)}\n`);
    fs.renameSync(tmp, this.filePath);
  }

  list() { return this.#read(); }

  enqueue(task) {
    const tasks = this.#read();
    const now = new Date().toISOString();
    const record = {
      id: task.id ?? `task-${Date.now()}-${Math.random().toString(16).slice(2, 8)}`,
      status: 'PENDING',
      createdAt: now,
      updatedAt: now,
      attempts: 0,
      dependencies: [],
      ...task,
    };
    tasks.push(record);
    this.#write(tasks);
    return record;
  }

  nextReady() {
    const tasks = this.#read();
    const completed = new Set(tasks.filter(t => t.status === 'COMPLETED').map(t => t.id));
    return tasks.find(t => t.status === 'PENDING' && (t.dependencies ?? []).every(d => completed.has(d))) ?? null;
  }

  update(id, patch) {
    const tasks = this.#read();
    const index = tasks.findIndex(t => t.id === id);
    if (index < 0) throw new Error(`Unknown task ${id}`);
    tasks[index] = { ...tasks[index], ...patch, updatedAt: new Date().toISOString() };
    this.#write(tasks);
    return tasks[index];
  }
}
