const BASE_URL = 'http://localhost:3000/api/v1';

async function runTests() {
  console.log('🧪 Starting API Verification Suite...\n');
  let passed = 0;
  let failed = 0;

  async function test(name, fn) {
    try {
      await fn();
      console.log(`✅ [PASS] ${name}`);
      passed++;
    } catch (err) {
      console.error(`❌ [FAIL] ${name}: ${err.message}`);
      failed++;
    }
  }

  // 1. Health
  await test('GET /health', async () => {
    const res = await fetch(`${BASE_URL}/health`);
    if (res.status !== 200) throw new Error(`Status ${res.status}`);
    const data = await res.json();
    if (data.status !== 'ok') throw new Error(`Invalid status: ${data.status}`);
  });

  // 2. Auth Login
  let userToken = '';
  let adminToken = '';
  let userId = '';

  await test('POST /auth/login (User)', async () => {
    const res = await fetch(`${BASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'ali@example.com', password: '123456' }),
    });
    if (res.status !== 200) throw new Error(`Status ${res.status}`);
    const data = await res.json();
    if (!data.token) throw new Error('No token returned');
    userToken = data.token;
    userId = data.user.id;
  });

  await test('POST /auth/login (Admin)', async () => {
    const res = await fetch(`${BASE_URL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: 'admin@shirbrax.ir', password: 'admin123456' }),
    });
    if (res.status !== 200) throw new Error(`Status ${res.status}`);
    const data = await res.json();
    if (!data.token || data.user.role !== 'admin') throw new Error('Invalid admin login');
    adminToken = data.token;
  });

  // 3. Auth Me
  await test('GET /auth/me', async () => {
    const res = await fetch(`${BASE_URL}/auth/me`, {
      headers: { Authorization: `Bearer ${userToken}` },
    });
    if (res.status !== 200) throw new Error(`Status ${res.status}`);
    const data = await res.json();
    if (data.email !== 'ali@example.com') throw new Error('User mismatch');
  });

  // 4. Posts Feed
  let samplePostId = '';
  await test('GET /posts (Feed)', async () => {
    const res = await fetch(`${BASE_URL}/posts?page=1&per_page=5`, {
      headers: { Authorization: `Bearer ${userToken}` },
    });
    if (res.status !== 200) throw new Error(`Status ${res.status}`);
    const data = await res.json();
    if (!Array.isArray(data.data) || data.data.length === 0) throw new Error('Empty feed');
    samplePostId = data.data[0].id;
  });

  // 5. Post by ID
  await test('GET /posts/:id', async () => {
    const res = await fetch(`${BASE_URL}/posts/${samplePostId}`, {
      headers: { Authorization: `Bearer ${userToken}` },
    });
    if (res.status !== 200) throw new Error(`Status ${res.status}`);
    const data = await res.json();
    if (data.id !== samplePostId) throw new Error('Post ID mismatch');
  });

  // 6. Post Like
  await test('POST /posts/:id/like', async () => {
    const res = await fetch(`${BASE_URL}/posts/${samplePostId}/like`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${userToken}` },
    });
    if (res.status !== 200) throw new Error(`Status ${res.status}`);
    const data = await res.json();
    if (typeof data.is_liked !== 'boolean') throw new Error('Invalid like response');
  });

  // 7. Comments
  let commentId = '';
  await test('POST /posts/:id/comments', async () => {
    const res = await fetch(`${BASE_URL}/posts/${samplePostId}/comments`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${userToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ text: 'تست عالی بود!' }),
    });
    if (res.status !== 201) throw new Error(`Status ${res.status}`);
    const data = await res.json();
    if (!data.id) throw new Error('Invalid comment response');
    commentId = data.id;
  });

  await test('GET /posts/:id/comments', async () => {
    const res = await fetch(`${BASE_URL}/posts/${samplePostId}/comments`);
    if (res.status !== 200) throw new Error(`Status ${res.status}`);
    const data = await res.json();
    if (!Array.isArray(data.data)) throw new Error('Invalid comments list');
  });

  // 8. Explore
  await test('GET /posts/explore', async () => {
    const res = await fetch(`${BASE_URL}/posts/explore`);
    if (res.status !== 200) throw new Error(`Status ${res.status}`);
    const data = await res.json();
    if (!Array.isArray(data.data)) throw new Error('Invalid explore response');
  });

  // 9. Users
  await test('GET /users (List & Search)', async () => {
    const res = await fetch(`${BASE_URL}/users?search=سارا`);
    if (res.status !== 200) throw new Error(`Status ${res.status}`);
    const data = await res.json();
    if (!Array.isArray(data.data)) throw new Error('Invalid users response');
  });

  await test('GET /users/:id', async () => {
    const res = await fetch(`${BASE_URL}/users/${userId}`);
    if (res.status !== 200) throw new Error(`Status ${res.status}`);
    const data = await res.json();
    if (data.id !== userId) throw new Error('User ID mismatch');
  });

  await test('GET /users/:id/posts', async () => {
    const res = await fetch(`${BASE_URL}/users/${userId}/posts`);
    if (res.status !== 200) throw new Error(`Status ${res.status}`);
    const data = await res.json();
    if (!Array.isArray(data.data)) throw new Error('Invalid user posts response');
  });

  await test('POST /users/:id/follow', async () => {
    const res = await fetch(`${BASE_URL}/users/3/follow`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${userToken}` },
    });
    if (res.status !== 200) throw new Error(`Status ${res.status}`);
    const data = await res.json();
    if (typeof data.is_following !== 'boolean') throw new Error('Invalid follow response');
  });

  // 10. Notifications
  let notifId = '';
  await test('GET /notifications', async () => {
    const res = await fetch(`${BASE_URL}/notifications`, {
      headers: { Authorization: `Bearer ${userToken}` },
    });
    if (res.status !== 200) throw new Error(`Status ${res.status}`);
    const data = await res.json();
    if (!Array.isArray(data.data)) throw new Error('Invalid notifications response');
    if (data.data.length > 0) notifId = data.data[0].id;
  });

  if (notifId) {
    await test('PATCH /notifications/:id/read', async () => {
      const res = await fetch(`${BASE_URL}/notifications/${notifId}/read`, {
        method: 'PATCH',
        headers: { Authorization: `Bearer ${userToken}` },
      });
      if (res.status !== 200) throw new Error(`Status ${res.status}`);
    });
  }

  // 11. Admin APIs
  await test('GET /admin/stats', async () => {
    const res = await fetch(`${BASE_URL}/admin/stats`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    if (res.status !== 200) throw new Error(`Status ${res.status}`);
    const data = await res.json();
    if (typeof data.users_count !== 'number') throw new Error('Invalid admin stats');
  });

  await test('GET /admin/users', async () => {
    const res = await fetch(`${BASE_URL}/admin/users`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    if (res.status !== 200) throw new Error(`Status ${res.status}`);
    const data = await res.json();
    if (!Array.isArray(data.data)) throw new Error('Invalid admin users response');
  });

  await test('GET /admin/posts', async () => {
    const res = await fetch(`${BASE_URL}/admin/posts`, {
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    if (res.status !== 200) throw new Error(`Status ${res.status}`);
    const data = await res.json();
    if (!Array.isArray(data.data)) throw new Error('Invalid admin posts response');
  });

  await test('POST /admin/users/:id/ban', async () => {
    const res = await fetch(`${BASE_URL}/admin/users/4/ban`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${adminToken}` },
    });
    if (res.status !== 200) throw new Error(`Status ${res.status}`);
    const data = await res.json();
    if (typeof data.is_banned !== 'boolean') throw new Error('Invalid ban response');
  });

  console.log(`\n📊 Verification Summary: ${passed} Passed, ${failed} Failed`);
}

runTests();
