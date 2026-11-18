import { reconcile, ReadingError } from './reconciliation';

describe('Rapprochement de fin de service', () => {
  const readings = [
    // Pompe 3 : un pistolet Gasoil et un pistolet Super
    { nozzleId: 'p3-gasoil', productId: 'gasoil', startCl: 128_453_340, endCl: 128_473_190 }, // 198,50 L
    { nozzleId: 'p3-super', productId: 'super', startCl: 98_000_000, endCl: 98_050_000 }, // 500,00 L
  ];

  it('calcule litres pompés, litres fidélité et taux de capture par produit', () => {
    const lines = reconcile(readings, { gasoil: 6_948, super: 17_500 }, 0.5);
    expect(lines).toEqual([
      { productId: 'gasoil', pumpedCl: 19_850, loyaltyCl: 6_948, captureRate: 0.35, overCaptured: false },
      { productId: 'super', pumpedCl: 50_000, loyaltyCl: 17_500, captureRate: 0.35, overCaptured: false },
    ]);
  });

  it('lève une alerte si les litres fidélité dépassent les litres pompés + tolérance', () => {
    // Exemple du tableau de bord : 212 L saisis pour 198,50 L pompés
    const [gasoil] = reconcile(readings.slice(0, 1), { gasoil: 21_200 }, 0.5);
    expect(gasoil.overCaptured).toBe(true);
  });

  it('tolère un petit écart dans la marge', () => {
    // 198,50 L × 1,005 = 199,49 L
    const [ok] = reconcile(readings.slice(0, 1), { gasoil: 19_949 }, 0.5);
    expect(ok.overCaptured).toBe(false);
    const [ko] = reconcile(readings.slice(0, 1), { gasoil: 19_950 }, 0.5);
    expect(ko.overCaptured).toBe(true);
  });

  it('additionne plusieurs pistolets du même produit', () => {
    const lines = reconcile(
      [
        { nozzleId: 'a', productId: 'gasoil', startCl: 0, endCl: 10_000 },
        { nozzleId: 'b', productId: 'gasoil', startCl: 500, endCl: 5_500 },
      ],
      {},
      0.5,
    );
    expect(lines[0]).toMatchObject({ pumpedCl: 15_000, loyaltyCl: 0, captureRate: 0 });
  });

  it('signale des litres fidélité sur un produit sans pompage', () => {
    const lines = reconcile([], { super: 1_000 }, 0.5);
    expect(lines[0]).toMatchObject({ productId: 'super', pumpedCl: 0, overCaptured: true });
  });

  it('refuse un index de fin inférieur à l\'index de début', () => {
    expect(() => reconcile([{ nozzleId: 'x', productId: 'super', startCl: 100, endCl: 50 }], {}, 0.5)).toThrow(ReadingError);
  });
});
