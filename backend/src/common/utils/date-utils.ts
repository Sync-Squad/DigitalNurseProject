/**
 * Returns a new Date object.
 * Previously this added a manual +5 hour offset, but since the database session
 * is set to 'Asia/Karachi', we now use standard Date handling to avoid double offsets.
 */
export function getPKTDate(date?: Date | string | number): Date {
  return date ? new Date(date) : new Date();
}

/**
 * Passthrough for compatibility.
 */
export function fromPKTDate(date: Date): Date {
  return date;
}
