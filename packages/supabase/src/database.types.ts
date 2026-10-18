// Placeholder. Run `pnpm db:types` with local Supabase running to replace this file with the
// generated types for the current schema.
export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[];

export type Database = Record<string, never>;
