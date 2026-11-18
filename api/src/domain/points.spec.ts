import { LoyaltyRuleLike, pointsForAmount, selectRule } from './points';

const jan1 = new Date('2026-01-01T00:00:00Z');
const now = new Date('2026-11-18T10:00:00Z');

function rule(partial: Partial<LoyaltyRuleLike>): LoyaltyRuleLike {
  return {
    id: 'r',
    stationId: null,
    productId: null,
    category: null,
    points: 1,
    per: 1000,
    validFrom: jan1,
    validTo: null,
    active: true,
    ...partial,
  };
}

describe('Points calculés sur la somme', () => {
  const fuel = { points: 1, per: 1000 }; // provisoire : 1 pt / 1 000 F
  const shop = { points: 1, per: 500 }; // provisoire : 1 pt / 500 F

  it.each([
    [10_000, fuel, 10], // Gasoil 10 000 → 10 pts
    [5_000, fuel, 5],
    [2_500, fuel, 2], // arrondi inférieur
    [999, fuel, 0],
    [3_200, shop, 6],
  ])('%i F → %i pts', (amount, r, expected) => {
    expect(pointsForAmount(amount, r)).toBe(expected);
  });

  it('découper un passage ne rapporte pas plus de points', () => {
    const once = pointsForAmount(10_000, fuel);
    const split = 4 * pointsForAmount(2_500, fuel);
    expect(split).toBeLessThanOrEqual(once);
  });

  it('applique le nombre de points par tranche', () => {
    expect(pointsForAmount(10_000, { points: 3, per: 1000 })).toBe(30);
  });

  it('0 point sans règle ou avec une règle invalide', () => {
    expect(pointsForAmount(10_000, null)).toBe(0);
    expect(pointsForAmount(10_000, { points: 1, per: 0 })).toBe(0);
  });
});

describe('Choix de la règle applicable', () => {
  const ctx = { stationId: 'latrie', productId: 'gasoil', category: 'FUEL' as const, at: now };

  it('produit > catégorie > générale', () => {
    const rules = [
      rule({ id: 'generale' }),
      rule({ id: 'carburant', category: 'FUEL' }),
      rule({ id: 'gasoil', productId: 'gasoil' }),
    ];
    expect(selectRule(rules, ctx)?.id).toBe('gasoil');
  });

  it('à précision égale, la règle de la station gagne sur celle de l\'enseigne', () => {
    const rules = [rule({ id: 'enseigne', category: 'FUEL' }), rule({ id: 'station', category: 'FUEL', stationId: 'latrie' })];
    expect(selectRule(rules, ctx)?.id).toBe('station');
  });

  it('ignore les règles d\'une autre station, d\'un autre produit, inactives ou hors période', () => {
    const rules = [
      rule({ id: 'autre-station', stationId: 'cocody' }),
      rule({ id: 'autre-produit', productId: 'super' }),
      rule({ id: 'boutique', category: 'SHOP' }),
      rule({ id: 'inactive', active: false }),
      rule({ id: 'future', validFrom: new Date('2027-01-01T00:00:00Z') }),
      rule({ id: 'expiree', validTo: new Date('2026-06-01T00:00:00Z') }),
    ];
    expect(selectRule(rules, ctx)).toBeNull();
  });

  it('à précision égale, la règle la plus récente gagne', () => {
    const rules = [
      rule({ id: 'ancienne', category: 'FUEL', validFrom: jan1 }),
      rule({ id: 'recente', category: 'FUEL', validFrom: new Date('2026-10-01T00:00:00Z') }),
    ];
    expect(selectRule(rules, ctx)?.id).toBe('recente');
  });
});
