export interface PJAMMHealthPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
