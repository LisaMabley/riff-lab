import { describe, expect, it } from 'vitest';
import { isAdult } from './age';

describe('isAdult', () => {
  it('is true on the 18th birthday', () => {
    expect(isAdult('2008-10-17', '2026-10-17')).toBe(true);
  });

  it('is false the day before the 18th birthday', () => {
    expect(isAdult('2008-10-18', '2026-10-17')).toBe(false);
  });

  it('is true well past 18 and false for future dates', () => {
    expect(isAdult('1970-01-01', '2026-10-17')).toBe(true);
    expect(isAdult('2030-01-01', '2026-10-17')).toBe(false);
  });

  it('treats Feb 29 birthdays like Postgres: adult on Mar 1 in non-leap years', () => {
    expect(isAdult('2008-02-29', '2026-02-28')).toBe(false);
    expect(isAdult('2008-02-29', '2026-03-01')).toBe(true);
  });

  it('clamps the cutoff when today is Feb 29', () => {
    // 2044-02-29 minus 18 years is 2026-02-28 in Postgres.
    expect(isAdult('2026-02-28', '2044-02-29')).toBe(true);
    expect(isAdult('2026-03-01', '2044-02-29')).toBe(false);
  });

  it.each(['10/17/2008', '2008-2-1', '2008-02-30', '2007-02-29', '2008-13-01', '2008-00-10', ''])(
    'rejects birth date %j',
    (birthDate) => {
      expect(() => isAdult(birthDate, '2026-10-17')).toThrow();
    },
  );

  it('rejects an invalid today', () => {
    expect(() => isAdult('2008-10-17', '2026-02-30')).toThrow();
  });
});
