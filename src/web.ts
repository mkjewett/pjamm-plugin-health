import { WebPlugin } from '@capacitor/core';

import type { PJAMMHealthPlugin } from './definitions';

export class PJAMMHealthWeb extends WebPlugin implements PJAMMHealthPlugin {
  async echo(options: { value: string }): Promise<{ value: string }> {
    console.log('ECHO', options);
    return options;
  }
}
