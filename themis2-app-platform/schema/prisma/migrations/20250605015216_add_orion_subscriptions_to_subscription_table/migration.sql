-- AlterTable
ALTER TABLE "subscriptions" ADD COLUMN     "orion_subscription_for_eltres" VARCHAR(24),
ADD COLUMN     "orion_subscription_for_iota" VARCHAR(24),
ALTER COLUMN "subscription_id" SET DATA TYPE VARCHAR(36);
