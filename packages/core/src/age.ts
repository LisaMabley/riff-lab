export const MINIMUM_AGE = 18;

const ISO_DATE = /^(\d{4})-(\d{2})-(\d{2})$/;

function parseIsoDate(value: string): { year: number; month: number; day: number } {
  const match = ISO_DATE.exec(value);
  if (!match) throw new Error(`Expected a YYYY-MM-DD date, got "${value}"`);
  const [, year, month, day] = match;
  return { year: Number(year), month: Number(month), day: Number(day) };
}

function daysInMonth(year: number, month: number): number {
  return new Date(Date.UTC(year, month, 0)).getUTCDate();
}

function format(year: number, month: number, day: number): string {
  return `${String(year).padStart(4, '0')}-${String(month).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
}

/**
 * Whether someone born on `birthDate` is at least 18 on `today` (both YYYY-MM-DD calendar dates).
 * Matches the database rule `birth_date <= current_date - interval '18 years'`, including its
 * handling of Feb 29 (the cutoff clamps to Feb 28 in non-leap years). The birth date is only
 * compared, never stored.
 */
export function isAdult(birthDate: string, today: string): boolean {
  parseIsoDate(birthDate);
  const t = parseIsoDate(today);
  const cutoffYear = t.year - MINIMUM_AGE;
  const cutoff = format(cutoffYear, t.month, Math.min(t.day, daysInMonth(cutoffYear, t.month)));
  return birthDate <= cutoff;
}
