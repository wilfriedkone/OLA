import { ControlInput, ControlSettings, countsAsVisit, isLateSync, runBlockingControls } from './controls';

const settings: ControlSettings = {
  vehicleLiterCaps: { MOTO: 15, CAR: 80, TAXI: 80, MINIBUS: 150, TRUCK: 600, OTHER: 100 },
  dailyLiterCapPerCustomer: 300,
  minVisitAmountXof: 2000,
  minHoursBetweenVisits: 4,
  lateSyncMinutes: 30,
};

const base: ControlInput = {
  customerStatus: 'ACTIVE',
  customerPhone: '+2250708451212',
  attendantBlockedPhones: ['+2250102030405'],
  isFuel: true,
  unitPriceXof: 715,
  centiliters: 1399, // 10 000 F de Gasoil
  centilitersToday: 0,
  vehicleType: 'TAXI',
};

describe('Contrôles bloquants', () => {
  it('accepte un passage normal', () => {
    expect(runBlockingControls(base, settings)).toEqual({ ok: true });
  });

  it('refuse un client bloqué ou supprimé', () => {
    expect(runBlockingControls({ ...base, customerStatus: 'BLOCKED' }, settings)).toMatchObject({ code: 'CUSTOMER_INACTIVE' });
    expect(runBlockingControls({ ...base, customerStatus: 'DELETED' }, settings)).toMatchObject({ code: 'CUSTOMER_INACTIVE' });
  });

  it('refuse qu\'un pompiste crédite un numéro interdit (le sien ou un proche)', () => {
    const input = { ...base, customerPhone: '+2250102030405' };
    expect(runBlockingControls(input, settings)).toMatchObject({ ok: false, code: 'SELF_CREDIT_FORBIDDEN' });
  });

  it('refuse le carburant sans prix du jour', () => {
    expect(runBlockingControls({ ...base, unitPriceXof: null, centiliters: null }, settings)).toMatchObject({ code: 'PRICE_MISSING' });
  });

  it('refuse une moto au-delà de 15 L, accepte exactement 15 L', () => {
    const moto = { ...base, vehicleType: 'MOTO' as const };
    expect(runBlockingControls({ ...moto, centiliters: 1500 }, settings)).toEqual({ ok: true });
    expect(runBlockingControls({ ...moto, centiliters: 1501 }, settings)).toMatchObject({ code: 'VEHICLE_CAP_EXCEEDED' });
  });

  it('applique le plafond OTHER quand le véhicule est inconnu', () => {
    expect(runBlockingControls({ ...base, vehicleType: null, centiliters: 10_001 }, settings)).toMatchObject({
      code: 'VEHICLE_CAP_EXCEEDED',
      details: { vehicleType: 'OTHER' },
    });
  });

  it('refuse au-delà du plafond journalier', () => {
    const input = { ...base, vehicleType: 'TRUCK' as const, centilitersToday: 29_000, centiliters: 1_001 };
    expect(runBlockingControls(input, settings)).toMatchObject({ code: 'DAILY_CAP_EXCEEDED' });
  });

  it('la boutique n\'a ni prix au litre ni plafond de litres', () => {
    const shop = { ...base, isFuel: false, unitPriceXof: null, centiliters: null };
    expect(runBlockingControls(shop, settings)).toEqual({ ok: true });
  });

  it('le contrôle du numéro interdit s\'applique aussi à la boutique', () => {
    const shop = { ...base, isFuel: false, centiliters: null, customerPhone: '+2250102030405' };
    expect(runBlockingControls(shop, settings)).toMatchObject({ code: 'SELF_CREDIT_FORBIDDEN' });
  });
});

describe('Visite comptée', () => {
  const t = new Date('2026-11-18T10:00:00Z');
  const hoursAgo = (h: number) => new Date(t.getTime() - h * 3_600_000);

  it('première visite au-dessus du minimum', () => {
    expect(countsAsVisit(2000, null, t, settings)).toBe(true);
  });

  it('pas de visite sous 2 000 F', () => {
    expect(countsAsVisit(1999, null, t, settings)).toBe(false);
  });

  it('pas de nouvelle visite moins de 4 h après la précédente', () => {
    expect(countsAsVisit(10_000, hoursAgo(3.9), t, settings)).toBe(false);
    expect(countsAsVisit(10_000, hoursAgo(4), t, settings)).toBe(true);
  });
});

describe('Synchronisation tardive', () => {
  it('signale un passage reçu plus de 30 min après sa saisie', () => {
    const occurred = new Date('2026-11-18T10:00:00Z');
    expect(isLateSync(occurred, new Date('2026-11-18T10:30:00Z'), 30)).toBe(false);
    expect(isLateSync(occurred, new Date('2026-11-18T10:31:00Z'), 30)).toBe(true);
  });
});
