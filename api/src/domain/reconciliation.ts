/**
 * Rapprochement de fin de service (docs/01-regles-metier.md, section 9).
 * Compare, par produit carburant, les litres sortis des pompes (index) et
 * les litres calculés pour les passages fidélité.
 */

export interface NozzleReadings {
  nozzleId: string;
  productId: string;
  /** Index du totalisateur en centilitres. */
  startCl: number;
  endCl: number;
}

export interface ReconciliationLine {
  productId: string;
  pumpedCl: number;
  loyaltyCl: number;
  /** loyalty / pumped, entre 0 et 1 (peut dépasser 1 en cas d'anomalie). 0 si rien n'a été pompé. */
  captureRate: number;
  overCaptured: boolean;
}

export class ReadingError extends Error {
  constructor(public readonly code: 'READING_LOWER_THAN_START', public readonly nozzleId: string) {
    super(`L'index de fin est inférieur à l'index de début pour le pistolet ${nozzleId}.`);
  }
}

/**
 * @param loyaltyClByProduct litres fidélité validés pendant le service, par produit (centilitres)
 * @param tolerancePct tolérance en pourcentage, ex. 0.5 pour 0,5 %
 */
export function reconcile(
  readings: NozzleReadings[],
  loyaltyClByProduct: Record<string, number>,
  tolerancePct: number,
): ReconciliationLine[] {
  const pumped: Record<string, number> = {};
  for (const r of readings) {
    if (r.endCl < r.startCl) throw new ReadingError('READING_LOWER_THAN_START', r.nozzleId);
    pumped[r.productId] = (pumped[r.productId] ?? 0) + (r.endCl - r.startCl);
  }

  const productIds = new Set([...Object.keys(pumped), ...Object.keys(loyaltyClByProduct)]);
  return [...productIds].sort().map((productId) => {
    const pumpedCl = pumped[productId] ?? 0;
    const loyaltyCl = loyaltyClByProduct[productId] ?? 0;
    const allowedCl = pumpedCl * (1 + tolerancePct / 100);
    return {
      productId,
      pumpedCl,
      loyaltyCl,
      captureRate: pumpedCl > 0 ? Math.round((loyaltyCl / pumpedCl) * 10_000) / 10_000 : 0,
      overCaptured: loyaltyCl > allowedCl,
    };
  });
}
