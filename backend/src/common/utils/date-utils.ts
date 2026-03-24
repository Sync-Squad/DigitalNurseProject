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
/**
 * Returns a proper UTC Date object by interpreting a date and time string in Asia/Karachi timezone.
 * Example: getUTCFromPKT(new Date("2024-03-17"), "09:00") -> 2024-03-17T04:00:00.000Z
 */
export function getUTCFromPKT(date: Date, timeStr: string): Date {
  const d = new Date(date);
  const [hours, minutes] = timeStr.split(':').map(Number);
  
  // Use UTC methods to ensure we use components of the specific point-in-time
  // regardless of the server's local timezone.
  const year = d.getUTCFullYear();
  const month = String(d.getUTCMonth() + 1).padStart(2, '0');
  const day = String(d.getUTCDate()).padStart(2, '0');
  const isoStr = `${year}-${month}-${day}T${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:00`;
  
  // Create a localized string with offset for parsing
  // Karachi is always UTC+5, no DST
  return new Date(`${isoStr}+05:00`);
}
