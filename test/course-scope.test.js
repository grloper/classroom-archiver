import test from 'node:test';
import assert from 'node:assert/strict';
import { scrapeClassroom } from '../web/src/scraper/scrapeEngine.js';

test('an unmatched explicit course selection never widens to all courses', async () => {
  const originalFetch = globalThis.fetch;
  const requests = [];
  const progress = [];
  globalThis.fetch = async url => {
    requests.push(String(url));
    assert.equal(new URL(url).pathname, '/v1/courses');
    return new Response(JSON.stringify({ courses: [{ id: 'other-course', name: 'Unselected' }] }), {
      headers: { 'Content-Type': 'application/json' }
    });
  };
  try {
    const result = await scrapeClassroom({
      session: { getToken: async () => 'fixture-only' },
      courseFilterIds: ['requested-course'],
      onProgress: event => progress.push(event)
    });
    assert.deepEqual(result.entities, { courses: [], topics: [], materials: [], attachments: [] });
    assert.equal(result.files.size, 0);
    assert.equal(requests.length, 1);
    assert.ok(progress.some(event => event.phase === 'warn' && event.message.includes('nothing will be archived')));
  } finally {
    globalThis.fetch = originalFetch;
  }
});
