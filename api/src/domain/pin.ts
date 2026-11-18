/**
 * Règles sur le code PIN client (4 chiffres).
 * Le hachage et la vérification sont faits par le service d'authentification (argon2).
 */

export type PinProblem = 'FORMAT' | 'REPEATED' | 'SEQUENCE' | 'PHONE_SUFFIX';

/** Retourne la raison pour laquelle un PIN est refusé, ou null s'il est acceptable. */
export function pinProblem(pin: string, phoneE164?: string): PinProblem | null {
  if (!/^\d{4}$/.test(pin)) return 'FORMAT';
  if (/^(\d)\1{3}$/.test(pin)) return 'REPEATED'; // 0000, 1111…

  const d = pin.split('').map(Number);
  const ascending = d.every((v, i) => i === 0 || v === (d[i - 1] + 1) % 10);
  const descending = d.every((v, i) => i === 0 || v === (d[i - 1] + 9) % 10);
  if (ascending || descending) return 'SEQUENCE'; // 1234, 6789, 9876, 8901…

  if (phoneE164 && phoneE164.endsWith(pin)) return 'PHONE_SUFFIX';
  return null;
}

export interface PinLockState {
  failedCount: number;
  lockedUntil: Date | null;
}

/** Le compte est-il verrouillé à cet instant ? */
export function isPinLocked(state: PinLockState, now: Date): boolean {
  return state.lockedUntil !== null && state.lockedUntil > now;
}

/** Nouvel état après une tentative de PIN. */
export function nextPinState(
  state: PinLockState,
  success: boolean,
  now: Date,
  settings: { pinMaxAttempts: number; pinLockMinutes: number },
): PinLockState & { justLocked: boolean } {
  if (success) return { failedCount: 0, lockedUntil: null, justLocked: false };
  const failedCount = state.failedCount + 1;
  if (failedCount >= settings.pinMaxAttempts) {
    return {
      failedCount: 0,
      lockedUntil: new Date(now.getTime() + settings.pinLockMinutes * 60_000),
      justLocked: true,
    };
  }
  return { failedCount, lockedUntil: state.lockedUntil, justLocked: false };
}
