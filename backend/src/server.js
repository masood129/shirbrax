import 'dotenv/config';
import app from './app.js';
import { initDatabase } from './config/database.js';
import { seedDatabase } from './services/seedService.js';

const PORT = process.env.PORT || 3000;

async function startServer() {
  try {
    // 1. Initialize DB and Seed
    console.log('📦 Initializing SQLite Database...');
    await initDatabase();
    await seedDatabase();

    // 2. Start Express server
    app.listen(PORT, () => {
      console.log(`\n======================================================`);
      console.log(`🚀 ShirBrax Backend Server is RUNNING on port ${PORT}`);
      console.log(`🌐 Base URL: http://localhost:${PORT}/api/v1`);
      console.log(`🩺 Health Check: http://localhost:${PORT}/api/v1/health`);
      console.log(`======================================================`);
      console.log(`🔑 Demo Accounts:`);
      console.log(`   - Admin: admin@shirbrax.ir / admin123456`);
      console.log(`   - User 1: ali@example.com / 123456`);
      console.log(`   - User 2: sara@example.com / 123456`);
      console.log(`======================================================\n`);
    });
  } catch (error) {
    console.error('❌ Failed to start ShirBrax server:', error);
    process.exit(1);
  }
}

startServer();
