// The club operates on Asia/Dubai time (UTC+4, no DST). Lesson times entered
// by admins are wall-clock times in that timezone. Constructing them with
// ambient-local Date methods (e.g. setHours) would silently shift every
// lesson time depending on whatever timezone the server process or a
// user's browser happens to run in — dev/uat/prod could easily differ — so
// both client and server use this single, explicit offset instead.
export const CLUB_UTC_OFFSET_HOURS = 4;
export const CLUB_UTC_OFFSET_ISO = "+04:00";
