/**
 * Calculs d'argent et de volumes.
 *
 * Règle OLA STATION : le pompiste saisit la SOMME donnée par le client (FCFA entiers).
 * Les litres sont calculés à partir du prix du jour, au centilitre près (2 décimales),
 * et ne servent qu'au rapprochement avec les index des pompes et aux plafonds véhicule.
 *
 * Pour éviter les erreurs d'arrondi des nombres à virgule, les litres sont manipulés
 * en CENTILITRES entiers (13,99 L = 1399 cL).
 */

export class InvalidAmountError extends Error {}

/** Vérifie qu'un montant est un nombre entier strictement positif de FCFA. */
export function assertValidAmountXof(amountXof: number): void {
  if (!Number.isInteger(amountXof) || amountXof <= 0) {
    throw new InvalidAmountError(`Montant invalide : ${amountXof}. Attendu : un entier de FCFA supérieur à 0.`);
  }
}

/**
 * Litres obtenus pour une somme donnée, en centilitres, arrondis au plus proche.
 * Exemple : 10 000 F de Gasoil à 715 F/L → 1399 cL (13,99 L).
 */
export function centilitersForAmount(amountXof: number, unitPriceXof: number): number {
  assertValidAmountXof(amountXof);
  if (!Number.isInteger(unitPriceXof) || unitPriceXof <= 0) {
    throw new InvalidAmountError(`Prix au litre invalide : ${unitPriceXof}.`);
  }
  // amount * 100 / price, arrondi au plus proche, en arithmétique entière.
  const numerator = amountXof * 100;
  const quotient = Math.floor(numerator / unitPriceXof);
  const remainder = numerator - quotient * unitPriceXof;
  return remainder * 2 >= unitPriceXof ? quotient + 1 : quotient;
}

/** Convertit des centilitres en chaîne décimale pour la base (Decimal(10,2)) : 1399 → "13.99". */
export function centilitersToDecimalString(cl: number): string {
  const sign = cl < 0 ? '-' : '';
  const abs = Math.abs(cl);
  return `${sign}${Math.floor(abs / 100)}.${String(abs % 100).padStart(2, '0')}`;
}

/** Convertit une valeur Decimal (chaîne "13.99" ou nombre) en centilitres. */
export function decimalToCentiliters(value: string | number): number {
  return Math.round(Number(value) * 100);
}

/** Affichage français : 1399 → "13,99 L". */
export function formatLiters(cl: number): string {
  return `${centilitersToDecimalString(cl).replace('.', ',')} L`;
}

/** Affichage français des montants : 10000 → "10 000 F" (espace insécable fine entre milliers). */
export function formatXof(amountXof: number): string {
  const digits = String(Math.abs(amountXof)).replace(/\B(?=(\d{3})+(?!\d))/g, ' ');
  return `${amountXof < 0 ? '-' : ''}${digits} F`;
}
