import { registerPlugin } from '@capacitor/core';

import type { PJAMMHealthPlugin } from './definitions';

const PJAMMHealth = registerPlugin<PJAMMHealthPlugin>('PJAMMHealth', {
  web: () => import('./web').then(m => new m.PJAMMHealthWeb()),
});

export * from './definitions';
export { PJAMMHealth };
