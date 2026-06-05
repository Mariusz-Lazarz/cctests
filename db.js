import Database from 'better-sqlite3';

const db = new Database(process.env.DB_PATH ?? './chinook.db');
db.pragma('journal_mode = WAL');

export default db;
