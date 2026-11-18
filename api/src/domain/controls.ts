/**
 * Contrôles automatiques d'un passage (docs/01-regles-metier.md, section 3.3).
 * Fonctions pures : elles reçoivent toutes les données utiles et renvoient une décision.
 * La vérification du PIN (hachage) est faite à part, par le service d'authentification.
 */

export type VehicleType = 'MOTO' | 'CAR' | 'TAXI' | 'MINIBUS' | 'TRUCK' | 'OTHER';

export type BlockingCode =
  | 'CUSTOMER_INACTIVE'
  | 'SELF_CREDIT_FORBIDDEN'
  | 'PRICE_MISSING'
  | 'VEHICLE_CAP_EXCEEDED'
  | 'DAILY_CAP_EXCEEDED';

export interface ControlSettings {
  /** Plafond en litres par passage, par type de véhicule. */
  vehicleLiterCaps: Partial<Record<VehicleType, number>>;
  dailyLiterCapPerCustomer: number;
  minVisitAmountXof: number;
  minHoursBetweenVisits: number;
  lateSyncMinutes: number;
}

export interface ControlInput {
  customerStatus: 'ACTIVE' | 'BLOCKED' | 'DELETED';
  customerPhone: string;
  /** Numéros que le pompiste n'a pas le droit de créditer (le sien inclus). */
  attendantBlockedPhones: string[];
  isFuel: boolean;
  /** Prix au litre du jour ; null si aucun prix n'est configuré (carburant uniquement). */
  unitPriceXof: number | null;
  /** Litres calculés pour ce passage, en centilitres (carburant uniquement). */
  centiliters: number | null;
  /** Litres déjà validés aujourd'hui pour ce client, en centilitres. */
  centilitersToday: number;
  vehicleType: VehicleType | null;
}

export type ControlResult =
  | { ok: true }
  | { ok: false; code: BlockingCode; details?: Record<string, unknown> };

/** Applique les contrôles bloquants dans l'ordre défini par les règles métier. */
export function runBlockingControls(input: ControlInput, settings: ControlSettings): ControlResult {
  if (input.customerStatus !== 'ACTIVE') {
    return { ok: false, code: 'CUSTOMER_INACTIVE' };
  }
  if (input.attendantBlockedPhones.includes(input.customerPhone)) {
    return { ok: false, code: 'SELF_CREDIT_FORBIDDEN' };
  }
  if (!input.isFuel) {
    return { ok: true };
  }
  if (input.unitPriceXof === null || input.centiliters === null) {
    return { ok: false, code: 'PRICE_MISSING' };
  }
  const vehicle = input.vehicleType ?? 'OTHER';
  const capLiters = settings.vehicleLiterCaps[vehicle];
  if (capLiters !== undefined && input.centiliters > capLiters * 100) {
    return {
      ok: false,
      code: 'VEHICLE_CAP_EXCEEDED',
      details: { vehicleType: vehicle, capLiters, centiliters: input.centiliters },
    };
  }
  if (input.centilitersToday + input.centiliters > settings.dailyLiterCapPerCustomer * 100) {
    return {
      ok: false,
      code: 'DAILY_CAP_EXCEEDED',
      details: { capLiters: settings.dailyLiterCapPerCustomer, centilitersToday: input.centilitersToday },
    };
  }
  return { ok: true };
}

/**
 * Un passage compte comme « visite » si la somme atteint le minimum ET si la dernière
 * visite comptée remonte à plus de N heures. Les points, eux, sont toujours attribués.
 */
export function countsAsVisit(
  amountXof: number,
  lastCountedVisitAt: Date | null,
  occurredAt: Date,
  settings: Pick<ControlSettings, 'minVisitAmountXof' | 'minHoursBetweenVisits'>,
): boolean {
  if (amountXof < settings.minVisitAmountXof) return false;
  if (!lastCountedVisitAt) return true;
  const hours = (occurredAt.getTime() - lastCountedVisitAt.getTime()) / 3_600_000;
  return hours >= settings.minHoursBetweenVisits;
}

/** Passage reçu par le serveur longtemps après avoir été saisi (mode hors ligne). */
export function isLateSync(occurredAt: Date, receivedAt: Date, lateSyncMinutes: number): boolean {
  return receivedAt.getTime() - occurredAt.getTime() > lateSyncMinutes * 60_000;
}
