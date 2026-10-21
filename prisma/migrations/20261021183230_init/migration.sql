-- CreateEnum
CREATE TYPE "AppRole" AS ENUM ('SUPER_ADMIN', 'BROKERAGE_ADMIN', 'SALES', 'CHARTER_OPS', 'FINANCE', 'OPERATOR_USER', 'CUSTOMER');

-- CreateEnum
CREATE TYPE "LeadSource" AS ENUM ('WEBSITE', 'REFERRAL', 'SAFARI_COMPANY', 'HOTEL', 'CORPORATE_OUTREACH', 'EXECUTIVE_ASSISTANT', 'EXISTING_CUSTOMER', 'INDUSTRY_EVENT', 'PARTNER');

-- CreateEnum
CREATE TYPE "LeadStage" AS ENUM ('NEW', 'CONTACTED', 'QUALIFIED', 'OPPORTUNITY', 'CUSTOMER', 'LOST');

-- CreateEnum
CREATE TYPE "Priority" AS ENUM ('LOW', 'MEDIUM', 'HIGH');

-- CreateEnum
CREATE TYPE "PartnerType" AS ENUM ('SAFARI_COMPANY', 'TOUR_OPERATOR_DMC', 'HOTEL_LODGE', 'CORPORATE_TRAVEL_AGENCY', 'CONCIERGE_EA', 'GROUND_TRANSPORT', 'OTHER');

-- CreateEnum
CREATE TYPE "AgreementStatus" AS ENUM ('NONE', 'DRAFT', 'ACTIVE', 'SUSPENDED', 'ENDED');

-- CreateEnum
CREATE TYPE "OperatorVerification" AS ENUM ('UNVERIFIED', 'DOCUMENTS_REQUESTED', 'UNDER_REVIEW', 'VERIFIED', 'REJECTED', 'SUSPENDED', 'EXPIRED');

-- CreateEnum
CREATE TYPE "OperatorStatus" AS ENUM ('ACTIVE', 'SUSPENDED', 'ARCHIVED');

-- CreateEnum
CREATE TYPE "AircraftCategory" AS ENUM ('TURBOPROP', 'LIGHT_JET', 'MIDSIZE_JET', 'SUPER_MIDSIZE_JET', 'LARGE_CABIN_JET', 'VIP_AIRLINER', 'HELICOPTER');

-- CreateEnum
CREATE TYPE "RequestStatus" AS ENUM ('NEW', 'QUALIFYING', 'SOURCING', 'QUOTES_RECEIVED', 'PROPOSAL_SENT', 'CUSTOMER_DECISION', 'BOOKED', 'ON_HOLD', 'CANCELLED', 'DECLINED', 'CLOSED_LOST');

-- CreateEnum
CREATE TYPE "TripType" AS ENUM ('ONE_WAY', 'RETURN', 'MULTI_LEG');

-- CreateEnum
CREATE TYPE "RfqStatus" AS ENUM ('DRAFT', 'READY_TO_SEND', 'SENT', 'RESPONSE_RECEIVED', 'NO_RESPONSE', 'DECLINED', 'EXPIRED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "QuoteState" AS ENUM ('DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'SHORTLISTED', 'REJECTED', 'EXPIRED', 'ACCEPTED_FOR_PROPOSAL');

-- CreateEnum
CREATE TYPE "ProposalStatus" AS ENUM ('DRAFT', 'INTERNAL_REVIEW', 'APPROVED', 'SENT_TO_CUSTOMER', 'VIEWED', 'ACCEPTED', 'DECLINED', 'EXPIRED', 'WITHDRAWN');

-- CreateEnum
CREATE TYPE "BookingStatus" AS ENUM ('PENDING_OPERATOR_CONFIRMATION', 'PENDING_PAYMENT', 'CONFIRMED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'DISRUPTED');

-- CreateEnum
CREATE TYPE "InvoiceStatus" AS ENUM ('ISSUED', 'PARTIALLY_PAID', 'PAID', 'CANCELLED');

-- CreateEnum
CREATE TYPE "PaymentState" AS ENUM ('EXPECTED', 'PENDING', 'RECEIVED_UNVERIFIED', 'RECONCILED', 'FAILED', 'REFUNDED', 'PARTIALLY_REFUNDED');

-- CreateEnum
CREATE TYPE "DocVerification" AS ENUM ('PENDING', 'VERIFIED', 'REJECTED');

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "role" "AppRole" NOT NULL DEFAULT 'CUSTOMER',
    "customerId" TEXT,
    "operatorId" TEXT,
    "emailVerifiedAt" TIMESTAMP(3),
    "resetToken" TEXT,
    "resetExpiresAt" TIMESTAMP(3),
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Session" (
    "id" TEXT NOT NULL,
    "tokenHash" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "ip" TEXT,
    "userAgent" TEXT,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "revokedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Session_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CompanySettings" (
    "id" INTEGER NOT NULL DEFAULT 1,
    "name" TEXT NOT NULL DEFAULT 'PRIVATE AVIATION',
    "tagline" TEXT NOT NULL DEFAULT '',
    "colorPrimary" TEXT NOT NULL DEFAULT '#0b1f3a',
    "colorAccent" TEXT NOT NULL DEFAULT '#9a7b4f',
    "phone" TEXT NOT NULL DEFAULT '',
    "whatsapp" TEXT NOT NULL DEFAULT '',
    "email" TEXT NOT NULL DEFAULT '',
    "address" TEXT NOT NULL DEFAULT '',
    "website" TEXT NOT NULL DEFAULT '',
    "defaultCurrency" TEXT NOT NULL DEFAULT 'USD',
    "timezone" TEXT NOT NULL DEFAULT 'Africa/Nairobi',
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CompanySettings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "IntegrationSetting" (
    "id" TEXT NOT NULL,
    "key" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'NOT_CONFIGURED',
    "config" JSONB NOT NULL DEFAULT '{}',
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "IntegrationSetting_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Lead" (
    "id" TEXT NOT NULL,
    "companyName" TEXT NOT NULL,
    "contactName" TEXT NOT NULL,
    "contactTitle" TEXT,
    "email" TEXT,
    "phone" TEXT,
    "segment" TEXT,
    "source" "LeadSource" NOT NULL DEFAULT 'WEBSITE',
    "partnerId" TEXT,
    "assignedTo" TEXT,
    "preferredRoutes" TEXT,
    "travelFrequency" TEXT,
    "estimatedBudget" DECIMAL(14,2),
    "budgetCurrency" TEXT NOT NULL DEFAULT 'USD',
    "stage" "LeadStage" NOT NULL DEFAULT 'NEW',
    "priority" "Priority" NOT NULL DEFAULT 'MEDIUM',
    "lastContactAt" TIMESTAMP(3),
    "nextFollowUp" TIMESTAMP(3),
    "notes" TEXT,
    "customerId" TEXT,
    "archived" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Lead_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "LeadActivity" (
    "id" TEXT NOT NULL,
    "leadId" TEXT NOT NULL,
    "userId" TEXT,
    "kind" TEXT NOT NULL,
    "detail" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "LeadActivity_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Customer" (
    "id" TEXT NOT NULL,
    "companyName" TEXT NOT NULL,
    "contactName" TEXT NOT NULL,
    "contactTitle" TEXT,
    "email" TEXT,
    "phone" TEXT,
    "segment" TEXT,
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Customer_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Partner" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "type" "PartnerType" NOT NULL DEFAULT 'OTHER',
    "contactName" TEXT,
    "email" TEXT,
    "phone" TEXT,
    "arrangement" TEXT NOT NULL DEFAULT 'REFERRAL',
    "agreementStatus" "AgreementStatus" NOT NULL DEFAULT 'NONE',
    "referralTerms" TEXT,
    "feePercent" DECIMAL(5,2),
    "feeCurrency" TEXT NOT NULL DEFAULT 'USD',
    "followUpDate" TIMESTAMP(3),
    "notes" TEXT,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Partner_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Operator" (
    "id" TEXT NOT NULL,
    "legalName" TEXT NOT NULL,
    "tradingName" TEXT,
    "country" TEXT NOT NULL,
    "city" TEXT,
    "website" TEXT,
    "commercialContact" TEXT,
    "commercialEmail" TEXT,
    "commercialPhone" TEXT,
    "opsContact" TEXT,
    "opsEmail" TEXT,
    "opsPhone" TEXT,
    "aocHolder" BOOLEAN NOT NULL DEFAULT false,
    "authority" TEXT,
    "aocNumber" TEXT,
    "verificationStatus" "OperatorVerification" NOT NULL DEFAULT 'UNVERIFIED',
    "verifiedBy" TEXT,
    "verifiedAt" TIMESTAMP(3),
    "verificationNotes" TEXT,
    "insuranceInsurer" TEXT,
    "insuranceExpiry" TIMESTAMP(3),
    "operatingRegions" TEXT,
    "agreementStatus" "AgreementStatus" NOT NULL DEFAULT 'NONE',
    "rateTerms" TEXT,
    "paymentTerms" TEXT,
    "cancellationTerms" TEXT,
    "reliabilityNotes" TEXT,
    "lastContactAt" TIMESTAMP(3),
    "nextFollowUp" TIMESTAMP(3),
    "status" "OperatorStatus" NOT NULL DEFAULT 'ACTIVE',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Operator_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OperatorContact" (
    "id" TEXT NOT NULL,
    "operatorId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "role" TEXT,
    "email" TEXT,
    "phone" TEXT,

    CONSTRAINT "OperatorContact_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Aircraft" (
    "id" TEXT NOT NULL,
    "operatorId" TEXT NOT NULL,
    "manufacturer" TEXT NOT NULL,
    "model" TEXT NOT NULL,
    "registration" TEXT NOT NULL,
    "category" "AircraftCategory" NOT NULL,
    "seats" INTEGER NOT NULL,
    "baggageKg" INTEGER,
    "rangeKm" INTEGER,
    "baseAirport" TEXT,
    "cabinConfig" TEXT,
    "restrictions" TEXT,
    "notes" TEXT,
    "imageUrl" TEXT,
    "lastVerifiedAt" TIMESTAMP(3),
    "active" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Aircraft_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AvailabilityObservation" (
    "id" TEXT NOT NULL,
    "aircraftId" TEXT NOT NULL,
    "route" TEXT,
    "date" TIMESTAMP(3) NOT NULL,
    "source" TEXT NOT NULL,
    "confirmedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expiresAt" TIMESTAMP(3),
    "note" TEXT,

    CONSTRAINT "AvailabilityObservation_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CharterRequest" (
    "id" TEXT NOT NULL,
    "reference" TEXT NOT NULL,
    "customerId" TEXT,
    "publicName" TEXT,
    "publicEmail" TEXT,
    "publicPhone" TEXT,
    "publicCompany" TEXT,
    "assignedTo" TEXT,
    "origin" TEXT NOT NULL,
    "originCode" TEXT,
    "destination" TEXT NOT NULL,
    "destCode" TEXT,
    "tripType" "TripType" NOT NULL DEFAULT 'ONE_WAY',
    "departureAt" TIMESTAMP(3) NOT NULL,
    "returnAt" TIMESTAMP(3),
    "pax" INTEGER NOT NULL,
    "baggage" TEXT,
    "aircraftPref" "AircraftCategory",
    "domestic" BOOLEAN NOT NULL DEFAULT true,
    "flexible" BOOLEAN NOT NULL DEFAULT false,
    "groundTransport" TEXT,
    "catering" TEXT,
    "notes" TEXT,
    "contactMethod" TEXT NOT NULL DEFAULT 'EMAIL',
    "consent" BOOLEAN NOT NULL DEFAULT false,
    "source" TEXT NOT NULL DEFAULT 'WEBSITE',
    "priority" "Priority" NOT NULL DEFAULT 'MEDIUM',
    "status" "RequestStatus" NOT NULL DEFAULT 'NEW',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CharterRequest_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "FlightLeg" (
    "id" TEXT NOT NULL,
    "requestId" TEXT,
    "bookingId" TEXT,
    "seq" INTEGER NOT NULL,
    "fromName" TEXT NOT NULL,
    "fromCode" TEXT,
    "toName" TEXT NOT NULL,
    "toCode" TEXT,
    "departAt" TIMESTAMP(3),
    "arriveAt" TIMESTAMP(3),
    "note" TEXT,

    CONSTRAINT "FlightLeg_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Rfq" (
    "id" TEXT NOT NULL,
    "reference" TEXT NOT NULL,
    "requestId" TEXT NOT NULL,
    "operatorId" TEXT NOT NULL,
    "message" TEXT,
    "requireResponseBy" TIMESTAMP(3),
    "status" "RfqStatus" NOT NULL DEFAULT 'DRAFT',
    "sentAt" TIMESTAMP(3),
    "sentVia" TEXT,
    "sentTo" TEXT,
    "emailLogId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Rfq_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "OperatorQuote" (
    "id" TEXT NOT NULL,
    "rfqId" TEXT NOT NULL,
    "aircraftId" TEXT,
    "registration" TEXT,
    "pax" INTEGER,
    "availability" TEXT,
    "confirmedAt" TIMESTAMP(3),
    "price" DECIMAL(14,2) NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'USD',
    "positioning" DECIMAL(14,2),
    "handling" DECIMAL(14,2),
    "permits" DECIMAL(14,2),
    "catering" DECIMAL(14,2),
    "groundTransp" DECIMAL(14,2),
    "otherCharges" DECIMAL(14,2),
    "inclusions" TEXT,
    "exclusions" TEXT,
    "expiresAt" TIMESTAMP(3),
    "depositPct" DECIMAL(5,2),
    "paymentTerms" TEXT,
    "cancelTerms" TEXT,
    "source" TEXT,
    "receivedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "state" "QuoteState" NOT NULL DEFAULT 'DRAFT',

    CONSTRAINT "OperatorQuote_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Proposal" (
    "id" TEXT NOT NULL,
    "reference" TEXT NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "requestId" TEXT NOT NULL,
    "customerId" TEXT,
    "quoteId" TEXT,
    "aircraftId" TEXT,
    "operatorId" TEXT,
    "discloseOperator" BOOLEAN NOT NULL DEFAULT false,
    "pax" INTEGER NOT NULL,
    "itinerary" JSONB NOT NULL DEFAULT '[]',
    "price" DECIMAL(14,2) NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'USD',
    "taxes" DECIMAL(14,2),
    "inclusions" TEXT,
    "exclusions" TEXT,
    "paymentSchedule" TEXT,
    "cancellationTerms" TEXT,
    "validUntil" TIMESTAMP(3),
    "operatorCost" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "directCost" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "totalCost" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "grossSpread" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "grossMarginPct" DECIMAL(7,4) NOT NULL DEFAULT 0,
    "fxRate" DECIMAL(12,6),
    "fxSource" TEXT,
    "status" "ProposalStatus" NOT NULL DEFAULT 'DRAFT',
    "sentAt" TIMESTAMP(3),
    "decidedAt" TIMESTAMP(3),
    "decidedOutcome" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Proposal_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ProposalItem" (
    "id" TEXT NOT NULL,
    "proposalId" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "label" TEXT NOT NULL,
    "amount" DECIMAL(14,2) NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'USD',

    CONSTRAINT "ProposalItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Booking" (
    "id" TEXT NOT NULL,
    "reference" TEXT NOT NULL,
    "requestId" TEXT NOT NULL,
    "proposalId" TEXT,
    "customerId" TEXT,
    "operatorId" TEXT NOT NULL,
    "aircraftId" TEXT,
    "operatorConfirmedAt" TIMESTAMP(3),
    "operatorConfirmedBy" TEXT,
    "operatorCost" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "sellingPrice" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "currency" TEXT NOT NULL DEFAULT 'USD',
    "depositAmount" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "amountReceived" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "paymentDueAt" TIMESTAMP(3),
    "confirmationRef" TEXT,
    "opsOwner" TEXT,
    "status" "BookingStatus" NOT NULL DEFAULT 'PENDING_OPERATOR_CONFIRMATION',
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Booking_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TripActivity" (
    "id" TEXT NOT NULL,
    "bookingId" TEXT NOT NULL,
    "userId" TEXT,
    "kind" TEXT NOT NULL,
    "note" TEXT NOT NULL,
    "at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TripActivity_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Invoice" (
    "id" TEXT NOT NULL,
    "number" TEXT NOT NULL,
    "bookingId" TEXT NOT NULL,
    "amount" DECIMAL(14,2) NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'USD',
    "issuedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "dueAt" TIMESTAMP(3),
    "status" "InvoiceStatus" NOT NULL DEFAULT 'ISSUED',

    CONSTRAINT "Invoice_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Payment" (
    "id" TEXT NOT NULL,
    "bookingId" TEXT,
    "invoiceId" TEXT,
    "amount" DECIMAL(14,2) NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'USD',
    "method" TEXT NOT NULL DEFAULT 'TRANSFER',
    "txnRef" TEXT,
    "initiatedAt" TIMESTAMP(3),
    "receivedAt" TIMESTAMP(3),
    "state" "PaymentState" NOT NULL DEFAULT 'EXPECTED',
    "evidenceRef" TEXT,
    "recordedBy" TEXT,
    "verifiedBy" TEXT,
    "fxRate" DECIMAL(12,6),
    "fxSource" TEXT,
    "fxDate" TIMESTAMP(3),
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Payment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "FinancialAdjustment" (
    "id" TEXT NOT NULL,
    "paymentId" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "amount" DECIMAL(14,2) NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'USD',
    "note" TEXT,
    "byUserId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "FinancialAdjustment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Commission" (
    "id" TEXT NOT NULL,
    "bookingId" TEXT,
    "kind" TEXT NOT NULL,
    "counterpartyId" TEXT,
    "counterparty" TEXT,
    "amount" DECIMAL(14,2) NOT NULL,
    "currency" TEXT NOT NULL DEFAULT 'USD',
    "dueAt" TIMESTAMP(3),
    "paidAt" TIMESTAMP(3),
    "notes" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Commission_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Task" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "ownerId" TEXT,
    "dueAt" TIMESTAMP(3),
    "priority" "Priority" NOT NULL DEFAULT 'MEDIUM',
    "status" TEXT NOT NULL DEFAULT 'OPEN',
    "notes" TEXT,
    "leadId" TEXT,
    "customerId" TEXT,
    "operatorId" TEXT,
    "requestId" TEXT,
    "bookingId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "completedAt" TIMESTAMP(3),

    CONSTRAINT "Task_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Document" (
    "id" TEXT NOT NULL,
    "entityType" TEXT NOT NULL,
    "entityId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "fileName" TEXT NOT NULL,
    "storageKey" TEXT,
    "mimeType" TEXT,
    "sizeBytes" INTEGER,
    "expiresAt" TIMESTAMP(3),
    "verificationState" "DocVerification" NOT NULL DEFAULT 'PENDING',
    "verifiedBy" TEXT,
    "verifiedAt" TIMESTAMP(3),
    "uploadedBy" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Document_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Notification" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "body" TEXT,
    "link" TEXT,
    "readAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Notification_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "EmailLog" (
    "id" TEXT NOT NULL,
    "toAddress" TEXT NOT NULL,
    "subject" TEXT NOT NULL,
    "template" TEXT,
    "status" TEXT NOT NULL DEFAULT 'QUEUED',
    "provider" TEXT NOT NULL DEFAULT 'log',
    "error" TEXT,
    "sentAt" TIMESTAMP(3),
    "meta" JSONB NOT NULL DEFAULT '{}',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "EmailLog_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AuditLog" (
    "id" TEXT NOT NULL,
    "at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "userId" TEXT,
    "action" TEXT NOT NULL,
    "entity" TEXT,
    "entityId" TEXT,
    "detail" JSONB NOT NULL DEFAULT '{}',

    CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE INDEX "User_role_idx" ON "User"("role");

-- CreateIndex
CREATE UNIQUE INDEX "Session_tokenHash_key" ON "Session"("tokenHash");

-- CreateIndex
CREATE INDEX "Session_userId_idx" ON "Session"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "IntegrationSetting_key_key" ON "IntegrationSetting"("key");

-- CreateIndex
CREATE INDEX "Lead_stage_idx" ON "Lead"("stage");

-- CreateIndex
CREATE INDEX "Lead_assignedTo_idx" ON "Lead"("assignedTo");

-- CreateIndex
CREATE INDEX "Lead_nextFollowUp_idx" ON "Lead"("nextFollowUp");

-- CreateIndex
CREATE INDEX "LeadActivity_leadId_idx" ON "LeadActivity"("leadId");

-- CreateIndex
CREATE INDEX "Operator_verificationStatus_idx" ON "Operator"("verificationStatus");

-- CreateIndex
CREATE INDEX "Operator_status_idx" ON "Operator"("status");

-- CreateIndex
CREATE UNIQUE INDEX "Aircraft_registration_key" ON "Aircraft"("registration");

-- CreateIndex
CREATE INDEX "Aircraft_operatorId_idx" ON "Aircraft"("operatorId");

-- CreateIndex
CREATE INDEX "Aircraft_category_idx" ON "Aircraft"("category");

-- CreateIndex
CREATE UNIQUE INDEX "CharterRequest_reference_key" ON "CharterRequest"("reference");

-- CreateIndex
CREATE INDEX "CharterRequest_status_idx" ON "CharterRequest"("status");

-- CreateIndex
CREATE INDEX "CharterRequest_customerId_idx" ON "CharterRequest"("customerId");

-- CreateIndex
CREATE INDEX "CharterRequest_assignedTo_idx" ON "CharterRequest"("assignedTo");

-- CreateIndex
CREATE UNIQUE INDEX "Rfq_reference_key" ON "Rfq"("reference");

-- CreateIndex
CREATE INDEX "Rfq_requestId_idx" ON "Rfq"("requestId");

-- CreateIndex
CREATE INDEX "Rfq_operatorId_idx" ON "Rfq"("operatorId");

-- CreateIndex
CREATE INDEX "Rfq_status_idx" ON "Rfq"("status");

-- CreateIndex
CREATE INDEX "OperatorQuote_rfqId_idx" ON "OperatorQuote"("rfqId");

-- CreateIndex
CREATE UNIQUE INDEX "Proposal_reference_key" ON "Proposal"("reference");

-- CreateIndex
CREATE UNIQUE INDEX "Proposal_quoteId_key" ON "Proposal"("quoteId");

-- CreateIndex
CREATE INDEX "Proposal_requestId_idx" ON "Proposal"("requestId");

-- CreateIndex
CREATE INDEX "Proposal_customerId_idx" ON "Proposal"("customerId");

-- CreateIndex
CREATE UNIQUE INDEX "Booking_reference_key" ON "Booking"("reference");

-- CreateIndex
CREATE INDEX "Booking_status_idx" ON "Booking"("status");

-- CreateIndex
CREATE INDEX "Booking_customerId_idx" ON "Booking"("customerId");

-- CreateIndex
CREATE INDEX "TripActivity_bookingId_idx" ON "TripActivity"("bookingId");

-- CreateIndex
CREATE UNIQUE INDEX "Invoice_number_key" ON "Invoice"("number");

-- CreateIndex
CREATE INDEX "Invoice_bookingId_idx" ON "Invoice"("bookingId");

-- CreateIndex
CREATE INDEX "Payment_bookingId_idx" ON "Payment"("bookingId");

-- CreateIndex
CREATE INDEX "Payment_state_idx" ON "Payment"("state");

-- CreateIndex
CREATE INDEX "Task_status_idx" ON "Task"("status");

-- CreateIndex
CREATE INDEX "Task_dueAt_idx" ON "Task"("dueAt");

-- CreateIndex
CREATE INDEX "Document_entityType_entityId_idx" ON "Document"("entityType", "entityId");

-- CreateIndex
CREATE INDEX "Document_expiresAt_idx" ON "Document"("expiresAt");

-- CreateIndex
CREATE INDEX "Notification_userId_readAt_idx" ON "Notification"("userId", "readAt");

-- CreateIndex
CREATE INDEX "AuditLog_at_idx" ON "AuditLog"("at");

-- CreateIndex
CREATE INDEX "AuditLog_userId_idx" ON "AuditLog"("userId");

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "Customer"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_operatorId_fkey" FOREIGN KEY ("operatorId") REFERENCES "Operator"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Session" ADD CONSTRAINT "Session_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "LeadActivity" ADD CONSTRAINT "LeadActivity_leadId_fkey" FOREIGN KEY ("leadId") REFERENCES "Lead"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OperatorContact" ADD CONSTRAINT "OperatorContact_operatorId_fkey" FOREIGN KEY ("operatorId") REFERENCES "Operator"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Aircraft" ADD CONSTRAINT "Aircraft_operatorId_fkey" FOREIGN KEY ("operatorId") REFERENCES "Operator"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AvailabilityObservation" ADD CONSTRAINT "AvailabilityObservation_aircraftId_fkey" FOREIGN KEY ("aircraftId") REFERENCES "Aircraft"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CharterRequest" ADD CONSTRAINT "CharterRequest_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "Customer"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CharterRequest" ADD CONSTRAINT "CharterRequest_assignedTo_fkey" FOREIGN KEY ("assignedTo") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "FlightLeg" ADD CONSTRAINT "FlightLeg_requestId_fkey" FOREIGN KEY ("requestId") REFERENCES "CharterRequest"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "FlightLeg" ADD CONSTRAINT "FlightLeg_bookingId_fkey" FOREIGN KEY ("bookingId") REFERENCES "Booking"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Rfq" ADD CONSTRAINT "Rfq_requestId_fkey" FOREIGN KEY ("requestId") REFERENCES "CharterRequest"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Rfq" ADD CONSTRAINT "Rfq_operatorId_fkey" FOREIGN KEY ("operatorId") REFERENCES "Operator"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OperatorQuote" ADD CONSTRAINT "OperatorQuote_rfqId_fkey" FOREIGN KEY ("rfqId") REFERENCES "Rfq"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OperatorQuote" ADD CONSTRAINT "OperatorQuote_aircraftId_fkey" FOREIGN KEY ("aircraftId") REFERENCES "Aircraft"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Proposal" ADD CONSTRAINT "Proposal_requestId_fkey" FOREIGN KEY ("requestId") REFERENCES "CharterRequest"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Proposal" ADD CONSTRAINT "Proposal_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "Customer"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Proposal" ADD CONSTRAINT "Proposal_aircraftId_fkey" FOREIGN KEY ("aircraftId") REFERENCES "Aircraft"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProposalItem" ADD CONSTRAINT "ProposalItem_proposalId_fkey" FOREIGN KEY ("proposalId") REFERENCES "Proposal"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_requestId_fkey" FOREIGN KEY ("requestId") REFERENCES "CharterRequest"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_proposalId_fkey" FOREIGN KEY ("proposalId") REFERENCES "Proposal"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "Customer"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_operatorId_fkey" FOREIGN KEY ("operatorId") REFERENCES "Operator"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Booking" ADD CONSTRAINT "Booking_aircraftId_fkey" FOREIGN KEY ("aircraftId") REFERENCES "Aircraft"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TripActivity" ADD CONSTRAINT "TripActivity_bookingId_fkey" FOREIGN KEY ("bookingId") REFERENCES "Booking"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Invoice" ADD CONSTRAINT "Invoice_bookingId_fkey" FOREIGN KEY ("bookingId") REFERENCES "Booking"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_bookingId_fkey" FOREIGN KEY ("bookingId") REFERENCES "Booking"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_invoiceId_fkey" FOREIGN KEY ("invoiceId") REFERENCES "Invoice"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_recordedBy_fkey" FOREIGN KEY ("recordedBy") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Payment" ADD CONSTRAINT "Payment_verifiedBy_fkey" FOREIGN KEY ("verifiedBy") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "FinancialAdjustment" ADD CONSTRAINT "FinancialAdjustment_paymentId_fkey" FOREIGN KEY ("paymentId") REFERENCES "Payment"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Task" ADD CONSTRAINT "Task_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AuditLog" ADD CONSTRAINT "AuditLog_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;
