/**
 * Numéros de téléphone ivoiriens.
 * Depuis 2021, les numéros comptent 10 chiffres (ex. 07 08 45 12 12).
 * Format stocké : E.164, ex. +2250708451212.
 */

export class InvalidPhoneError extends Error {}

/**
 * Normalise une saisie libre en E.164 ivoirien.
 * Accepte : "07 08 45 12 12", "0708451212", "+225 07 08 45 12 12", "00225 0708451212".
 */
export function normalizeCiPhone(raw: string): string {
  let digits = raw.replace(/[\s.\-()]/g, '');
  if (digits.startsWith('+')) digits = digits.slice(1);
  else if (digits.startsWith('00')) digits = digits.slice(2);

  if (/^225\d{10}$/.test(digits)) digits = digits.slice(3);

  if (!/^\d{10}$/.test(digits)) {
    throw new InvalidPhoneError(`Numéro invalide : « ${raw} ». Attendu : 10 chiffres, ex. 07 08 45 12 12.`);
  }
  return `+225${digits}`;
}

/** Numéro masqué pour l'écran du pompiste : +2250708451212 → "07 08 •• •• 12". */
export function maskPhone(e164: string): string {
  const local = e164.replace(/^\+225/, '');
  if (local.length !== 10) return '•• •• •• •• ••';
  return `${local.slice(0, 2)} ${local.slice(2, 4)} •• •• ${local.slice(8, 10)}`;
}

/** Affichage complet : +2250708451212 → "07 08 45 12 12". */
export function formatPhone(e164: string): string {
  const local = e164.replace(/^\+225/, '');
  return local.replace(/(\d{2})(?=\d)/g, '$1 ');
}
