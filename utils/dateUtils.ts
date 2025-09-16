
export const getDayKey = (date: Date): string => {
    // We need to adjust for timezone offset to prevent dates from being off by one day.
    const tzOffset = date.getTimezoneOffset() * 60000; // offset in milliseconds
    const localDate = new Date(date.getTime() - tzOffset);
    return localDate.toISOString().split('T')[0];
};
