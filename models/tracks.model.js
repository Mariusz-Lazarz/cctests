import db from '../db.js';

export const findAll = ({ limit = 20, offset = 0, albumId } = {}) => {
  if (albumId) {
    return db
      .prepare('SELECT * FROM tracks WHERE AlbumId = ? LIMIT ? OFFSET ?')
      .all(albumId, Number(limit), Number(offset));
  }
  return db.prepare('SELECT * FROM tracks LIMIT ? OFFSET ?').all(Number(limit), Number(offset));
};

export const findById = (id) =>
  db.prepare('SELECT * FROM tracks WHERE TrackId = ?').get(id);

export const create = ({ name, albumId, milliseconds, unitPrice, composer, mediaTypeId, genreId }) =>
  db
    .prepare(
      'INSERT INTO tracks (Name, AlbumId, Milliseconds, UnitPrice, Composer, MediaTypeId, GenreId) VALUES (?, ?, ?, ?, ?, ?, ?)'
    )
    .run(name, albumId, milliseconds, unitPrice, composer ?? null, mediaTypeId ?? 1, genreId ?? 1);

export const update = (id, { name, albumId, milliseconds, unitPrice, composer, mediaTypeId, genreId }) =>
  db
    .prepare(
      'UPDATE tracks SET Name = ?, AlbumId = ?, Milliseconds = ?, UnitPrice = ?, Composer = ?, MediaTypeId = ?, GenreId = ? WHERE TrackId = ?'
    )
    .run(name, albumId, milliseconds, unitPrice, composer ?? null, mediaTypeId ?? 1, genreId ?? 1, id);

export const remove = (id) =>
  db.prepare('DELETE FROM tracks WHERE TrackId = ?').run(id);
