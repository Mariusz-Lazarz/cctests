import db from '../db.js';

export const findAll = ({ limit = 20, offset = 0, artistId } = {}) => {
  if (artistId) {
    return db
      .prepare('SELECT * FROM albums WHERE ArtistId = ? LIMIT ? OFFSET ?')
      .all(artistId, Number(limit), Number(offset));
  }
  return db.prepare('SELECT * FROM albums LIMIT ? OFFSET ?').all(Number(limit), Number(offset));
};

export const findById = (id) =>
  db.prepare('SELECT * FROM albums WHERE AlbumId = ?').get(id);

export const create = ({ title, artistId }) =>
  db.prepare('INSERT INTO albums (Title, ArtistId) VALUES (?, ?)').run(title, artistId);

export const update = (id, { title, artistId }) =>
  db
    .prepare('UPDATE albums SET Title = ?, ArtistId = ? WHERE AlbumId = ?')
    .run(title, artistId, id);

export const remove = (id) =>
  db.prepare('DELETE FROM albums WHERE AlbumId = ?').run(id);
