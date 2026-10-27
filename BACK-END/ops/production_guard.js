// Stops seed / reset / test scripts from writing to a non-local database by accident.
// Set ALLOW_PRODUCTION_WRITES=yes for a deliberate one-off run (e.g. sample accounts).
module.exports = function assertLocalDatabase(scriptName) {
  const host = (process.env.DB_HOST || '127.0.0.1').toLowerCase();
  const local = ['127.0.0.1', 'localhost', '::1'].includes(host);
  if (local || process.env.ALLOW_PRODUCTION_WRITES === 'yes') return;
  console.error(`❌ ${scriptName} refuses to run against ${host} (not a local database).`);
  console.error('   Set ALLOW_PRODUCTION_WRITES=yes only if you really mean to change that database.');
  process.exit(1);
};
