import * as Track from '../models/tracks.model.js';

const notFound = () => { const e = new Error('Track not found'); e.status = 404; throw e; };

export const list = (req, res) =>
  res.json(Track.findAll(req.query));

export const show = (req, res) => {
  const row = Track.findById(req.params.id);
  if (!row) notFound();
  res.json(row);
};

export const store = (req, res) => {
  const info = Track.create(req.body);
  res.status(201).json({ id: info.lastInsertRowid });
};

export const update = (req, res) => {
  const info = Track.update(req.params.id, req.body);
  if (!info.changes) notFound();
  res.json({ updated: true });
};

export const destroy = (req, res) => {
  const info = Track.remove(req.params.id);
  if (!info.changes) notFound();
  res.json({ deleted: true });
};
