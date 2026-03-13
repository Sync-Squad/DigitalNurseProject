/**
 * Returns a new Date object.
 * Standard Date handling for current time or specific date.
 */
export function getPKTDate(date?: Date | string | number): Date {
  return date ? new Date(date) : new Date();
}

/**
 * Returns a Date object set to midnight (00:00:00) in Asia/Karachi timezone
 * for the given date. This is useful for @db.Date columns to ensure the
 * date doesn't shift due to UTC conversion.
 */
export function getPKTDateOnly(date?: Date | string | number): Date {
  const d = date ? new Date(date) : new Date();
  
  // Convert to Karachi time string and then back to a date at midnight UTC
  // to satisfy Prisma's Date type without shifting.
  const karachiDateStr = d.toLocaleDateString('en-CA', {
    timeZone: 'Asia/Karachi',
  }); // returns YYYY-MM-DD
  
  return new Date(karachiDateStr);
}

/**
 * Passthrough for compatibility.
 */
export function fromPKTDate(date: Date): Date {
  return date;
}
