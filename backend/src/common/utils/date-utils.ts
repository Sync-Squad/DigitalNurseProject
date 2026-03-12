export const PAKISTAN_OFFSET = 5 * 60 * 60 * 1000;

/**
 * Returns a new Date object adjusted to Pakistan time (UTC+5).
 * If no date is provided, it returns the current time adjusted.
 * Note: This is used to "fake" UTC as local time for database storage.
 */
export function getPKTDate(date?: Date | string | number): Date {
  const d = date ? new Date(date) : new Date();
  // If the input is a string that already has a timezone offset, 
  // new Date(d) will correctly parse it to UTC.
  // We then add 5 hours to make the UTC value match the local time digits.
  return new Date(d.getTime() + PAKISTAN_OFFSET);
}

/**
 * Adjusts a date from PKT "fake UTC" back to real UTC if needed.
 */
export function fromPKTDate(date: Date): Date {
  if (!date) return date;
  return new Date(date.getTime() - PAKISTAN_OFFSET);
}
