-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "public"."StaffRole" AS ENUM ('SUPER_ADMIN', 'ORG_ADMIN', 'MANAGER', 'ATTENDANT', 'CASHIER');

-- CreateEnum
CREATE TYPE "public"."CustomerStatus" AS ENUM ('ACTIVE', 'BLOCKED', 'DELETED');

-- CreateEnum
CREATE TYPE "public"."SignupChannel" AS ENUM ('CUSTOMER_APP', 'ATTENDANT_APP', 'ADMIN');

-- CreateEnum
CREATE TYPE "public"."NotificationChannel" AS ENUM ('PUSH', 'SMS', 'WHATSAPP');

-- CreateEnum
CREATE TYPE "public"."VehicleType" AS ENUM ('MOTO', 'CAR', 'TAXI', 'MINIBUS', 'TRUCK', 'OTHER');

-- CreateEnum
CREATE TYPE "public"."OtpPurpose" AS ENUM ('REGISTER', 'LOGIN', 'PIN_RESET', 'ASSISTED_SIGNUP');

-- CreateEnum
CREATE TYPE "public"."ProductCategory" AS ENUM ('FUEL', 'SHOP', 'SERVICE', 'GAS');

-- CreateEnum
CREATE TYPE "public"."ProductUnit" AS ENUM ('LITER', 'AMOUNT');

-- CreateEnum
CREATE TYPE "public"."ShiftStatus" AS ENUM ('OPEN', 'CLOSED', 'REVIEWED');

-- CreateEnum
CREATE TYPE "public"."ReadingKind" AS ENUM ('START', 'END');

-- CreateEnum
CREATE TYPE "public"."PaymentMethod" AS ENUM ('CASH', 'MOBILE_MONEY', 'CARD', 'OTHER', 'UNKNOWN');

-- CreateEnum
CREATE TYPE "public"."TxSource" AS ENUM ('ATTENDANT_APP', 'IMPORT', 'INTEGRATION', 'ADMIN');

-- CreateEnum
CREATE TYPE "public"."TxConfirmation" AS ENUM ('CUSTOMER_PIN', 'NONE');

-- CreateEnum
CREATE TYPE "public"."TxStatus" AS ENUM ('VALIDATED', 'REJECTED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "public"."LoyaltyRuleType" AS ENUM ('POINTS_PER_AMOUNT');

-- CreateEnum
CREATE TYPE "public"."LedgerType" AS ENUM ('EARN', 'REDEEM', 'REVERSAL', 'ADJUST', 'EXPIRE', 'BONUS');

-- CreateEnum
CREATE TYPE "public"."RedemptionStatus" AS ENUM ('FULFILLED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "public"."ReviewStatus" AS ENUM ('NEW', 'IN_PROGRESS', 'RESOLVED', 'DISMISSED');

-- CreateEnum
CREATE TYPE "public"."AnnouncementKind" AS ENUM ('OFFER', 'EVENT', 'NEWS');

-- CreateEnum
CREATE TYPE "public"."AnnouncementStatus" AS ENUM ('DRAFT', 'SCHEDULED', 'PUBLISHED', 'ARCHIVED');

-- CreateEnum
CREATE TYPE "public"."NotificationStatus" AS ENUM ('QUEUED', 'SENT', 'FAILED');

-- CreateEnum
CREATE TYPE "public"."FraudAlertType" AS ENUM ('PIN_FAILED_REPEATED', 'OFFLINE_PIN_INVALID', 'SELF_CREDIT_ATTEMPT', 'VEHICLE_CAP_EXCEEDED', 'DAILY_CAP_EXCEEDED', 'LATE_SYNC', 'RECONCILIATION_GAP', 'CUSTOMER_CONCENTRATION', 'LOW_RATING');

-- CreateEnum
CREATE TYPE "public"."AlertSeverity" AS ENUM ('INFO', 'WARNING', 'CRITICAL');

-- CreateEnum
CREATE TYPE "public"."AlertStatus" AS ENUM ('OPEN', 'ACKNOWLEDGED', 'CLOSED');

-- CreateEnum
CREATE TYPE "public"."ActorType" AS ENUM ('STAFF', 'CUSTOMER', 'SYSTEM');

-- CreateTable
CREATE TABLE "public"."Organization" (
    "id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Organization_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Station" (
    "id" UUID NOT NULL,
    "organizationId" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "city" TEXT NOT NULL DEFAULT 'Abidjan',
    "address" TEXT,
    "timezone" TEXT NOT NULL DEFAULT 'Africa/Abidjan',
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Station_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Device" (
    "id" UUID NOT NULL,
    "stationId" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "lastSeenAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Device_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Pump" (
    "id" UUID NOT NULL,
    "stationId" UUID NOT NULL,
    "number" INTEGER NOT NULL,

    CONSTRAINT "Pump_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Nozzle" (
    "id" UUID NOT NULL,
    "pumpId" UUID NOT NULL,
    "productId" UUID NOT NULL,
    "label" TEXT NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "Nozzle_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."StaffUser" (
    "id" UUID NOT NULL,
    "organizationId" UUID,
    "stationId" UUID,
    "role" "public"."StaffRole" NOT NULL,
    "firstName" TEXT NOT NULL,
    "lastName" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "staffCode" TEXT NOT NULL,
    "pinHash" TEXT NOT NULL,
    "passwordHash" TEXT,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "StaffUser_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."StaffBlockedPhone" (
    "id" UUID NOT NULL,
    "staffId" UUID NOT NULL,
    "phone" TEXT NOT NULL,
    "reason" TEXT NOT NULL DEFAULT 'Numéro personnel',

    CONSTRAINT "StaffBlockedPhone_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Customer" (
    "id" UUID NOT NULL,
    "organizationId" UUID NOT NULL,
    "phone" TEXT NOT NULL,
    "firstName" TEXT NOT NULL,
    "lastName" TEXT,
    "email" TEXT,
    "qrToken" TEXT NOT NULL,
    "pinHash" TEXT NOT NULL,
    "pinFailedCount" INTEGER NOT NULL DEFAULT 0,
    "pinLockedUntil" TIMESTAMP(3),
    "phoneVerified" BOOLEAN NOT NULL DEFAULT false,
    "hasSmartphone" BOOLEAN NOT NULL DEFAULT false,
    "preferredChannel" "public"."NotificationChannel" NOT NULL DEFAULT 'SMS',
    "marketingConsent" BOOLEAN NOT NULL DEFAULT false,
    "marketingConsentAt" TIMESTAMP(3),
    "termsAcceptedAt" TIMESTAMP(3) NOT NULL,
    "status" "public"."CustomerStatus" NOT NULL DEFAULT 'ACTIVE',
    "signupChannel" "public"."SignupChannel" NOT NULL,
    "registeredById" UUID,
    "registeredAtStationId" UUID,
    "pointsBalance" INTEGER NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Customer_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Vehicle" (
    "id" UUID NOT NULL,
    "customerId" UUID NOT NULL,
    "type" "public"."VehicleType" NOT NULL,
    "plate" TEXT,
    "isDefault" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Vehicle_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."PushToken" (
    "id" UUID NOT NULL,
    "customerId" UUID NOT NULL,
    "token" TEXT NOT NULL,
    "platform" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PushToken_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."OtpChallenge" (
    "id" UUID NOT NULL,
    "phone" TEXT NOT NULL,
    "purpose" "public"."OtpPurpose" NOT NULL,
    "codeHash" TEXT NOT NULL,
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "consumedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "OtpChallenge_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Product" (
    "id" UUID NOT NULL,
    "organizationId" UUID NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "category" "public"."ProductCategory" NOT NULL,
    "unit" "public"."ProductUnit" NOT NULL,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "Product_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."ProductPrice" (
    "id" UUID NOT NULL,
    "stationId" UUID NOT NULL,
    "productId" UUID NOT NULL,
    "unitPriceXof" INTEGER NOT NULL,
    "validFrom" TIMESTAMP(3) NOT NULL,
    "setById" UUID NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ProductPrice_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Shift" (
    "id" UUID NOT NULL,
    "stationId" UUID NOT NULL,
    "attendantId" UUID NOT NULL,
    "status" "public"."ShiftStatus" NOT NULL DEFAULT 'OPEN',
    "startedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "endedAt" TIMESTAMP(3),
    "reviewedById" UUID,
    "managerNote" TEXT,

    CONSTRAINT "Shift_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."MeterReading" (
    "id" UUID NOT NULL,
    "shiftId" UUID NOT NULL,
    "nozzleId" UUID NOT NULL,
    "kind" "public"."ReadingKind" NOT NULL,
    "valueLiters" DECIMAL(14,2) NOT NULL,
    "photoUrl" TEXT,
    "recordedById" UUID NOT NULL,
    "recordedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "MeterReading_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."ReconciliationLine" (
    "id" UUID NOT NULL,
    "shiftId" UUID NOT NULL,
    "productId" UUID NOT NULL,
    "pumpedLiters" DECIMAL(12,2) NOT NULL,
    "loyaltyLiters" DECIMAL(12,2) NOT NULL,
    "captureRate" DECIMAL(5,4) NOT NULL,
    "overCaptured" BOOLEAN NOT NULL,

    CONSTRAINT "ReconciliationLine_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Transaction" (
    "id" UUID NOT NULL,
    "organizationId" UUID NOT NULL,
    "stationId" UUID NOT NULL,
    "customerId" UUID NOT NULL,
    "vehicleId" UUID,
    "attendantId" UUID NOT NULL,
    "deviceId" UUID,
    "shiftId" UUID,
    "productId" UUID NOT NULL,
    "amountXof" INTEGER NOT NULL,
    "liters" DECIMAL(10,2),
    "unitPriceXof" INTEGER,
    "paymentMethod" "public"."PaymentMethod" NOT NULL DEFAULT 'UNKNOWN',
    "receiptRef" TEXT,
    "source" "public"."TxSource" NOT NULL,
    "confirmation" "public"."TxConfirmation" NOT NULL,
    "occurredAt" TIMESTAMP(3) NOT NULL,
    "receivedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "syncedLate" BOOLEAN NOT NULL DEFAULT false,
    "status" "public"."TxStatus" NOT NULL,
    "rejectionCode" TEXT,
    "countsAsVisit" BOOLEAN NOT NULL,
    "pointsAwarded" INTEGER NOT NULL DEFAULT 0,
    "cancelledById" UUID,
    "cancelReason" TEXT,

    CONSTRAINT "Transaction_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."LoyaltySettings" (
    "organizationId" UUID NOT NULL,
    "minVisitAmountXof" INTEGER NOT NULL DEFAULT 2000,
    "minHoursBetweenVisits" INTEGER NOT NULL DEFAULT 4,
    "vehicleLiterCaps" JSONB NOT NULL,
    "dailyLiterCapPerCustomer" INTEGER NOT NULL DEFAULT 300,
    "pinMaxAttempts" INTEGER NOT NULL DEFAULT 3,
    "pinLockMinutes" INTEGER NOT NULL DEFAULT 15,
    "lateSyncMinutes" INTEGER NOT NULL DEFAULT 30,
    "reconciliationTolerancePct" DECIMAL(4,2) NOT NULL DEFAULT 0.5,
    "tierWindowMonths" INTEGER NOT NULL DEFAULT 3,
    "pointsExpiryMonths" INTEGER,
    "reviewWindowHours" INTEGER NOT NULL DEFAULT 72,
    "lowRatingAlertThreshold" INTEGER NOT NULL DEFAULT 2,
    "requireOtpOnAssistedSignup" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "LoyaltySettings_pkey" PRIMARY KEY ("organizationId")
);

-- CreateTable
CREATE TABLE "public"."LoyaltyRule" (
    "id" UUID NOT NULL,
    "organizationId" UUID NOT NULL,
    "stationId" UUID,
    "productId" UUID,
    "category" "public"."ProductCategory",
    "type" "public"."LoyaltyRuleType" NOT NULL,
    "points" INTEGER NOT NULL,
    "per" INTEGER NOT NULL,
    "validFrom" TIMESTAMP(3) NOT NULL,
    "validTo" TIMESTAMP(3),
    "active" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "LoyaltyRule_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Tier" (
    "id" UUID NOT NULL,
    "organizationId" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "rank" INTEGER NOT NULL,
    "minPoints" INTEGER NOT NULL,
    "benefits" TEXT,
    "color" TEXT,

    CONSTRAINT "Tier_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."PointsLedgerEntry" (
    "id" UUID NOT NULL,
    "organizationId" UUID NOT NULL,
    "customerId" UUID NOT NULL,
    "stationId" UUID,
    "type" "public"."LedgerType" NOT NULL,
    "delta" INTEGER NOT NULL,
    "balanceAfter" INTEGER NOT NULL,
    "transactionId" UUID,
    "redemptionId" UUID,
    "createdById" UUID,
    "reason" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PointsLedgerEntry_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Reward" (
    "id" UUID NOT NULL,
    "organizationId" UUID NOT NULL,
    "stationId" UUID,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "imageUrl" TEXT,
    "pointsCost" INTEGER NOT NULL,
    "stock" INTEGER,
    "maxPerCustomer" INTEGER,
    "minTierRank" INTEGER,
    "validFrom" TIMESTAMP(3),
    "validTo" TIMESTAMP(3),
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Reward_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Redemption" (
    "id" UUID NOT NULL,
    "rewardId" UUID NOT NULL,
    "customerId" UUID NOT NULL,
    "stationId" UUID NOT NULL,
    "staffId" UUID NOT NULL,
    "pointsSpent" INTEGER NOT NULL,
    "status" "public"."RedemptionStatus" NOT NULL DEFAULT 'FULFILLED',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Redemption_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Review" (
    "id" UUID NOT NULL,
    "organizationId" UUID NOT NULL,
    "stationId" UUID NOT NULL,
    "customerId" UUID NOT NULL,
    "transactionId" UUID NOT NULL,
    "attendantId" UUID,
    "rating" INTEGER NOT NULL,
    "tags" TEXT[],
    "comment" TEXT,
    "status" "public"."ReviewStatus" NOT NULL DEFAULT 'NEW',
    "handledById" UUID,
    "internalNote" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Review_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Announcement" (
    "id" UUID NOT NULL,
    "organizationId" UUID NOT NULL,
    "kind" "public"."AnnouncementKind" NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT NOT NULL,
    "imageUrl" TEXT,
    "startsAt" TIMESTAMP(3),
    "endsAt" TIMESTAMP(3),
    "location" TEXT,
    "conditions" TEXT,
    "contact" TEXT,
    "targetStationIds" UUID[],
    "targetTierRanks" INTEGER[],
    "hasClaimableGift" BOOLEAN NOT NULL DEFAULT false,
    "notifyOnPublish" BOOLEAN NOT NULL DEFAULT true,
    "status" "public"."AnnouncementStatus" NOT NULL DEFAULT 'DRAFT',
    "publishAt" TIMESTAMP(3),
    "createdById" UUID NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Announcement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."AnnouncementClaim" (
    "id" UUID NOT NULL,
    "announcementId" UUID NOT NULL,
    "customerId" UUID NOT NULL,
    "stationId" UUID NOT NULL,
    "staffId" UUID NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AnnouncementClaim_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."Notification" (
    "id" UUID NOT NULL,
    "customerId" UUID NOT NULL,
    "channel" "public"."NotificationChannel" NOT NULL,
    "template" TEXT NOT NULL,
    "payload" JSONB NOT NULL,
    "status" "public"."NotificationStatus" NOT NULL DEFAULT 'QUEUED',
    "costXof" INTEGER,
    "error" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "sentAt" TIMESTAMP(3),

    CONSTRAINT "Notification_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."FraudAlert" (
    "id" UUID NOT NULL,
    "organizationId" UUID NOT NULL,
    "stationId" UUID NOT NULL,
    "type" "public"."FraudAlertType" NOT NULL,
    "severity" "public"."AlertSeverity" NOT NULL,
    "status" "public"."AlertStatus" NOT NULL DEFAULT 'OPEN',
    "staffId" UUID,
    "customerId" UUID,
    "transactionId" UUID,
    "shiftId" UUID,
    "details" JSONB NOT NULL,
    "handledById" UUID,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "FraudAlert_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "public"."AuditLog" (
    "id" UUID NOT NULL,
    "organizationId" UUID,
    "actorType" "public"."ActorType" NOT NULL,
    "actorId" UUID,
    "action" TEXT NOT NULL,
    "entityType" TEXT NOT NULL,
    "entityId" TEXT,
    "before" JSONB,
    "after" JSONB,
    "deviceId" UUID,
    "ip" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Organization_slug_key" ON "public"."Organization"("slug");

-- CreateIndex
CREATE INDEX "Station_organizationId_idx" ON "public"."Station"("organizationId");

-- CreateIndex
CREATE INDEX "Device_stationId_idx" ON "public"."Device"("stationId");

-- CreateIndex
CREATE UNIQUE INDEX "Pump_stationId_number_key" ON "public"."Pump"("stationId", "number");

-- CreateIndex
CREATE INDEX "StaffUser_stationId_idx" ON "public"."StaffUser"("stationId");

-- CreateIndex
CREATE UNIQUE INDEX "StaffUser_organizationId_staffCode_key" ON "public"."StaffUser"("organizationId", "staffCode");

-- CreateIndex
CREATE INDEX "StaffBlockedPhone_phone_idx" ON "public"."StaffBlockedPhone"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "StaffBlockedPhone_staffId_phone_key" ON "public"."StaffBlockedPhone"("staffId", "phone");

-- CreateIndex
CREATE UNIQUE INDEX "Customer_qrToken_key" ON "public"."Customer"("qrToken");

-- CreateIndex
CREATE INDEX "Customer_organizationId_createdAt_idx" ON "public"."Customer"("organizationId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "Customer_organizationId_phone_key" ON "public"."Customer"("organizationId", "phone");

-- CreateIndex
CREATE UNIQUE INDEX "PushToken_token_key" ON "public"."PushToken"("token");

-- CreateIndex
CREATE INDEX "OtpChallenge_phone_createdAt_idx" ON "public"."OtpChallenge"("phone", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "Product_organizationId_code_key" ON "public"."Product"("organizationId", "code");

-- CreateIndex
CREATE INDEX "ProductPrice_stationId_productId_validFrom_idx" ON "public"."ProductPrice"("stationId", "productId", "validFrom");

-- CreateIndex
CREATE INDEX "Shift_stationId_startedAt_idx" ON "public"."Shift"("stationId", "startedAt");

-- CreateIndex
CREATE UNIQUE INDEX "MeterReading_shiftId_nozzleId_kind_key" ON "public"."MeterReading"("shiftId", "nozzleId", "kind");

-- CreateIndex
CREATE UNIQUE INDEX "ReconciliationLine_shiftId_productId_key" ON "public"."ReconciliationLine"("shiftId", "productId");

-- CreateIndex
CREATE INDEX "Transaction_organizationId_occurredAt_idx" ON "public"."Transaction"("organizationId", "occurredAt");

-- CreateIndex
CREATE INDEX "Transaction_stationId_occurredAt_idx" ON "public"."Transaction"("stationId", "occurredAt");

-- CreateIndex
CREATE INDEX "Transaction_customerId_occurredAt_idx" ON "public"."Transaction"("customerId", "occurredAt");

-- CreateIndex
CREATE INDEX "Transaction_attendantId_occurredAt_idx" ON "public"."Transaction"("attendantId", "occurredAt");

-- CreateIndex
CREATE INDEX "LoyaltyRule_organizationId_active_idx" ON "public"."LoyaltyRule"("organizationId", "active");

-- CreateIndex
CREATE UNIQUE INDEX "Tier_organizationId_rank_key" ON "public"."Tier"("organizationId", "rank");

-- CreateIndex
CREATE INDEX "PointsLedgerEntry_customerId_createdAt_idx" ON "public"."PointsLedgerEntry"("customerId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "PointsLedgerEntry_transactionId_type_key" ON "public"."PointsLedgerEntry"("transactionId", "type");

-- CreateIndex
CREATE UNIQUE INDEX "PointsLedgerEntry_redemptionId_type_key" ON "public"."PointsLedgerEntry"("redemptionId", "type");

-- CreateIndex
CREATE UNIQUE INDEX "Review_transactionId_key" ON "public"."Review"("transactionId");

-- CreateIndex
CREATE INDEX "Review_stationId_status_createdAt_idx" ON "public"."Review"("stationId", "status", "createdAt");

-- CreateIndex
CREATE INDEX "Announcement_organizationId_status_publishAt_idx" ON "public"."Announcement"("organizationId", "status", "publishAt");

-- CreateIndex
CREATE UNIQUE INDEX "AnnouncementClaim_announcementId_customerId_key" ON "public"."AnnouncementClaim"("announcementId", "customerId");

-- CreateIndex
CREATE INDEX "Notification_customerId_createdAt_idx" ON "public"."Notification"("customerId", "createdAt");

-- CreateIndex
CREATE INDEX "FraudAlert_stationId_status_createdAt_idx" ON "public"."FraudAlert"("stationId", "status", "createdAt");

-- CreateIndex
CREATE INDEX "AuditLog_organizationId_createdAt_idx" ON "public"."AuditLog"("organizationId", "createdAt");

-- CreateIndex
CREATE INDEX "AuditLog_entityType_entityId_idx" ON "public"."AuditLog"("entityType", "entityId");

-- AddForeignKey
ALTER TABLE "public"."Station" ADD CONSTRAINT "Station_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "public"."Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Device" ADD CONSTRAINT "Device_stationId_fkey" FOREIGN KEY ("stationId") REFERENCES "public"."Station"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Pump" ADD CONSTRAINT "Pump_stationId_fkey" FOREIGN KEY ("stationId") REFERENCES "public"."Station"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Nozzle" ADD CONSTRAINT "Nozzle_pumpId_fkey" FOREIGN KEY ("pumpId") REFERENCES "public"."Pump"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Nozzle" ADD CONSTRAINT "Nozzle_productId_fkey" FOREIGN KEY ("productId") REFERENCES "public"."Product"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."StaffUser" ADD CONSTRAINT "StaffUser_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "public"."Organization"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."StaffUser" ADD CONSTRAINT "StaffUser_stationId_fkey" FOREIGN KEY ("stationId") REFERENCES "public"."Station"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."StaffBlockedPhone" ADD CONSTRAINT "StaffBlockedPhone_staffId_fkey" FOREIGN KEY ("staffId") REFERENCES "public"."StaffUser"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Customer" ADD CONSTRAINT "Customer_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "public"."Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Customer" ADD CONSTRAINT "Customer_registeredById_fkey" FOREIGN KEY ("registeredById") REFERENCES "public"."StaffUser"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Vehicle" ADD CONSTRAINT "Vehicle_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "public"."Customer"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."PushToken" ADD CONSTRAINT "PushToken_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "public"."Customer"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Product" ADD CONSTRAINT "Product_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "public"."Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."ProductPrice" ADD CONSTRAINT "ProductPrice_stationId_fkey" FOREIGN KEY ("stationId") REFERENCES "public"."Station"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."ProductPrice" ADD CONSTRAINT "ProductPrice_productId_fkey" FOREIGN KEY ("productId") REFERENCES "public"."Product"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Shift" ADD CONSTRAINT "Shift_stationId_fkey" FOREIGN KEY ("stationId") REFERENCES "public"."Station"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Shift" ADD CONSTRAINT "Shift_attendantId_fkey" FOREIGN KEY ("attendantId") REFERENCES "public"."StaffUser"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."MeterReading" ADD CONSTRAINT "MeterReading_shiftId_fkey" FOREIGN KEY ("shiftId") REFERENCES "public"."Shift"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."MeterReading" ADD CONSTRAINT "MeterReading_nozzleId_fkey" FOREIGN KEY ("nozzleId") REFERENCES "public"."Nozzle"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."ReconciliationLine" ADD CONSTRAINT "ReconciliationLine_shiftId_fkey" FOREIGN KEY ("shiftId") REFERENCES "public"."Shift"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Transaction" ADD CONSTRAINT "Transaction_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "public"."Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Transaction" ADD CONSTRAINT "Transaction_stationId_fkey" FOREIGN KEY ("stationId") REFERENCES "public"."Station"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Transaction" ADD CONSTRAINT "Transaction_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "public"."Customer"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Transaction" ADD CONSTRAINT "Transaction_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES "public"."Vehicle"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Transaction" ADD CONSTRAINT "Transaction_attendantId_fkey" FOREIGN KEY ("attendantId") REFERENCES "public"."StaffUser"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Transaction" ADD CONSTRAINT "Transaction_deviceId_fkey" FOREIGN KEY ("deviceId") REFERENCES "public"."Device"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Transaction" ADD CONSTRAINT "Transaction_shiftId_fkey" FOREIGN KEY ("shiftId") REFERENCES "public"."Shift"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Transaction" ADD CONSTRAINT "Transaction_productId_fkey" FOREIGN KEY ("productId") REFERENCES "public"."Product"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."LoyaltySettings" ADD CONSTRAINT "LoyaltySettings_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "public"."Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."LoyaltyRule" ADD CONSTRAINT "LoyaltyRule_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "public"."Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."LoyaltyRule" ADD CONSTRAINT "LoyaltyRule_productId_fkey" FOREIGN KEY ("productId") REFERENCES "public"."Product"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Tier" ADD CONSTRAINT "Tier_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "public"."Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."PointsLedgerEntry" ADD CONSTRAINT "PointsLedgerEntry_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "public"."Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."PointsLedgerEntry" ADD CONSTRAINT "PointsLedgerEntry_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "public"."Customer"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."PointsLedgerEntry" ADD CONSTRAINT "PointsLedgerEntry_transactionId_fkey" FOREIGN KEY ("transactionId") REFERENCES "public"."Transaction"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."PointsLedgerEntry" ADD CONSTRAINT "PointsLedgerEntry_redemptionId_fkey" FOREIGN KEY ("redemptionId") REFERENCES "public"."Redemption"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Reward" ADD CONSTRAINT "Reward_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "public"."Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Redemption" ADD CONSTRAINT "Redemption_rewardId_fkey" FOREIGN KEY ("rewardId") REFERENCES "public"."Reward"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Redemption" ADD CONSTRAINT "Redemption_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "public"."Customer"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Review" ADD CONSTRAINT "Review_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "public"."Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Review" ADD CONSTRAINT "Review_stationId_fkey" FOREIGN KEY ("stationId") REFERENCES "public"."Station"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Review" ADD CONSTRAINT "Review_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "public"."Customer"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Review" ADD CONSTRAINT "Review_transactionId_fkey" FOREIGN KEY ("transactionId") REFERENCES "public"."Transaction"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Review" ADD CONSTRAINT "Review_attendantId_fkey" FOREIGN KEY ("attendantId") REFERENCES "public"."StaffUser"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Review" ADD CONSTRAINT "Review_handledById_fkey" FOREIGN KEY ("handledById") REFERENCES "public"."StaffUser"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Announcement" ADD CONSTRAINT "Announcement_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "public"."Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."AnnouncementClaim" ADD CONSTRAINT "AnnouncementClaim_announcementId_fkey" FOREIGN KEY ("announcementId") REFERENCES "public"."Announcement"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."AnnouncementClaim" ADD CONSTRAINT "AnnouncementClaim_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "public"."Customer"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."Notification" ADD CONSTRAINT "Notification_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "public"."Customer"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."FraudAlert" ADD CONSTRAINT "FraudAlert_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "public"."Organization"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "public"."AuditLog" ADD CONSTRAINT "AuditLog_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES "public"."Organization"("id") ON DELETE SET NULL ON UPDATE CASCADE;

