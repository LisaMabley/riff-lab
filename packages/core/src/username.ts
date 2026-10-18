import { z } from 'zod';

// Mirrors the profiles_username_format check: stored lowercase, so uniqueness is case-insensitive.
export const USERNAME_PATTERN = /^[a-z0-9_.]{3,30}$/;

export const usernameSchema = z
  .string()
  .trim()
  .toLowerCase()
  .regex(USERNAME_PATTERN, '3–30 characters: letters, numbers, underscores, and periods');
