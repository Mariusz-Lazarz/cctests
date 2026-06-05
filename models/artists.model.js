import db from '../db.js';

export const findAll = ({ limit = 20, offset = 0 } = {}) =>
  db.prepare('SELECT * FROM artists LIMIT ? OFFSET ?').all(Number(limit), Number(offset));

export const findById = (id) =>
  db.prepare('SELECT * FROM artists WHERE ArtistId = ?').get(id);

export const create = ({ name }) =>
  db.prepare('INSERT INTO artists (Name) VALUES (?)').run(name);

export const update = (id, { name }) =>
  db.prepare('UPDATE artists SET Name = ? WHERE ArtistId = ?').run(name, id);

export const remove = (id) =>
  db.prepare('DELETE FROM artists WHERE ArtistId = ?').run(id);
