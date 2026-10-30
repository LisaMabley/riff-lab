import { z } from 'zod';

// Mirrors the database's username check (coming with the profiles table). Usernames are stored
// lowercase, so uniqueness is case-insensitive. The spec doesn't define these rules yet.
export const USERNAME_PATTERN = /^[a-z0-9_.]{3,30}$/;

export const usernameSchema = z
  .string()
  .trim()
  .toLowerCase()
  .regex(USERNAME_PATTERN, '3–30 characters: letters, numbers, underscores, and periods');
