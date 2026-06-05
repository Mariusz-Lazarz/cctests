import { Router } from 'express';
import artists from './artists.js';
import albums from './albums.js';
import tracks from './tracks.js';

const router = Router();

router.use('/artists', artists);
router.use('/albums', albums);
router.use('/tracks', tracks);

export default router;
