/**
 * Calcul des points de fidélité.
 *
 * Règle OLA STATION : les points se calculent TOUJOURS sur la somme en FCFA,
 * jamais sur les litres. points = floor(montant / tranche) × points par tranche.
 */

export type ProductCategory = 'FUEL' | 'SHOP' | 'SERVICE' | 'GAS';

export interface LoyaltyRuleLike {
  id: string;
  stationId: string | null;
  productId: string | null;
  category: ProductCategory | null;
  points: number;
  /** Tranche en FCFA, ex. 1000 → 1 point par tranche de 1 000 F. */
  per: number;
  validFrom: Date;
  validTo: Date | null;
  active: boolean;
}

export interface RuleContext {
  stationId: string;
  productId: string;
  category: ProductCategory;
  at: Date;
}

/**
 * Score de précision d'une règle : produit > catégorie > générale, puis station > enseigne.
 * Retourne -1 si la règle ne s'applique pas.
 */
function specificity(rule: LoyaltyRuleLike, ctx: RuleContext): number {
  if (!rule.active) return -1;
  if (rule.validFrom > ctx.at) return -1;
  if (rule.validTo && rule.validTo <= ctx.at) return -1;
  if (rule.stationId && rule.stationId !== ctx.stationId) return -1;
  if (rule.productId && rule.productId !== ctx.productId) return -1;
  if (rule.category && rule.category !== ctx.category) return -1;

  let score = 0;
  if (rule.productId) score += 4;
  else if (rule.category) score += 2;
  if (rule.stationId) score += 1;
  return score;
}

/** Choisit la règle la plus précise. En cas d'égalité, la plus récente (validFrom) gagne. */
export function selectRule<R extends LoyaltyRuleLike>(rules: R[], ctx: RuleContext): R | null {
  let best: R | null = null;
  let bestScore = -1;
  for (const rule of rules) {
    const score = specificity(rule, ctx);
    if (score < 0) continue;
    if (score > bestScore || (score === bestScore && best && rule.validFrom > best.validFrom)) {
      best = rule;
      bestScore = score;
    }
  }
  return best;
}

/** Points gagnés pour une somme, selon une règle. Aucune règle → 0 point. */
export function pointsForAmount(amountXof: number, rule: Pick<LoyaltyRuleLike, 'points' | 'per'> | null): number {
  if (!rule) return 0;
  if (!Number.isInteger(rule.per) || rule.per <= 0) return 0;
  if (amountXof <= 0) return 0;
  return Math.floor(amountXof / rule.per) * rule.points;
}
