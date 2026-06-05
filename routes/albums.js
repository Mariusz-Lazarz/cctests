import { Router } from 'express';
import * as ctrl from '../controllers/albums.controller.js';

const router = Router();

router.get('/', ctrl.list);
router.get('/:id', ctrl.show);
router.post('/', ctrl.store);
router.put('/:id', ctrl.update);
router.delete('/:id', ctrl.destroy);

export default router;
