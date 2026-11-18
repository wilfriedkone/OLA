import { formatPhone, InvalidPhoneError, maskPhone, normalizeCiPhone } from './phone';
import { isPinLocked, nextPinState, pinProblem } from './pin';

describe('Numéros ivoiriens', () => {
  it.each(['07 08 45 12 12', '0708451212', '+225 07 08 45 12 12', '00225 07-08-45-12-12', '+2250708451212'])(
    'normalise « %s »',
    (raw) => {
      expect(normalizeCiPhone(raw)).toBe('+2250708451212');
    },
  );

  it.each(['708451212', '07084512123', '07 08 45 12 1a', ''])('refuse « %s »', (raw) => {
    expect(() => normalizeCiPhone(raw)).toThrow(InvalidPhoneError);
  });

  it('masque le numéro pour le pompiste', () => {
    expect(maskPhone('+2250708451212')).toBe('07 08 •• •• 12');
  });

  it('affiche le numéro complet', () => {
    expect(formatPhone('+2250708451212')).toBe('07 08 45 12 12');
  });
});

describe('PIN client', () => {
  it('accepte un PIN correct', () => {
    expect(pinProblem('4827', '+2250708451212')).toBeNull();
  });

  it.each([
    ['12a4', 'FORMAT'],
    ['123', 'FORMAT'],
    ['0000', 'REPEATED'],
    ['7777', 'REPEATED'],
    ['1234', 'SEQUENCE'],
    ['6789', 'SEQUENCE'],
    ['9876', 'SEQUENCE'],
    ['8901', 'SEQUENCE'],
    ['1212', 'PHONE_SUFFIX'],
  ])('refuse %s (%s)', (pin, problem) => {
    expect(pinProblem(pin, '+2250708451212')).toBe(problem);
  });

  const lockSettings = { pinMaxAttempts: 3, pinLockMinutes: 15 };
  const now = new Date('2026-11-18T10:00:00Z');

  it('verrouille après 3 erreurs, pendant 15 minutes', () => {
    let state = { failedCount: 0, lockedUntil: null as Date | null };
    state = nextPinState(state, false, now, lockSettings);
    state = nextPinState(state, false, now, lockSettings);
    expect(isPinLocked(state, now)).toBe(false);
    const third = nextPinState(state, false, now, lockSettings);
    expect(third.justLocked).toBe(true);
    expect(isPinLocked(third, now)).toBe(true);
    expect(isPinLocked(third, new Date(now.getTime() + 15 * 60_000))).toBe(false);
  });

  it('remet le compteur à zéro après un PIN correct', () => {
    const state = nextPinState({ failedCount: 2, lockedUntil: null }, true, now, lockSettings);
    expect(state).toEqual({ failedCount: 0, lockedUntil: null, justLocked: false });
  });
});
