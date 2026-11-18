import {
  centilitersForAmount,
  centilitersToDecimalString,
  decimalToCentiliters,
  formatLiters,
  formatXof,
  InvalidAmountError,
} from './money';

describe('Litres calculés à partir de la somme', () => {
  it.each([
    // [somme, prix au litre, centilitres attendus, affichage]
    [10_000, 715, 1399, '13,99 L'], // Gasoil 10 000 → 13,986 → 13,99
    [5_000, 875, 571, '5,71 L'], // Super 5 000 → 5,714 → 5,71
    [2_500, 715, 350, '3,50 L'], // Gasoil 2 500 → 3,4965 → 3,50
    [875, 875, 100, '1,00 L'],
    [100, 875, 11, '0,11 L'], // 0,1143 → 0,11
  ])('%i F à %i F/L → %i cL (%s)', (amount, price, cl, label) => {
    expect(centilitersForAmount(amount, price)).toBe(cl);
    expect(formatLiters(cl)).toBe(label);
  });

  it('arrondit au plus proche, la moitié vers le haut', () => {
    // 1 F à 200 F/L = 0,005 L → 0,01 L
    expect(centilitersForAmount(1, 200)).toBe(1);
    // 1 F à 201 F/L = 0,00497 L → 0,00 L
    expect(centilitersForAmount(1, 201)).toBe(0);
  });

  it('refuse une somme nulle, négative ou à virgule', () => {
    expect(() => centilitersForAmount(0, 715)).toThrow(InvalidAmountError);
    expect(() => centilitersForAmount(-500, 715)).toThrow(InvalidAmountError);
    expect(() => centilitersForAmount(2500.5, 715)).toThrow(InvalidAmountError);
  });

  it('refuse un prix absent ou nul', () => {
    expect(() => centilitersForAmount(10_000, 0)).toThrow(InvalidAmountError);
  });
});

describe('Conversions décimales', () => {
  it('centilitres ↔ chaîne décimale pour la base', () => {
    expect(centilitersToDecimalString(1399)).toBe('13.99');
    expect(centilitersToDecimalString(350)).toBe('3.50');
    expect(centilitersToDecimalString(7)).toBe('0.07');
    expect(decimalToCentiliters('13.99')).toBe(1399);
    expect(decimalToCentiliters(0.07)).toBe(7);
  });
});

describe('Affichage des montants', () => {
  it('sépare les milliers', () => {
    expect(formatXof(10_000)).toBe('10 000 F');
    expect(formatXof(2_500)).toBe('2 500 F');
    expect(formatXof(500)).toBe('500 F');
    expect(formatXof(1_250_000)).toBe('1 250 000 F');
  });
});
