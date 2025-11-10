-- AlterTable
ALTER TABLE "subscriptions" DROP COLUMN "orion_subscription_for_eltres",
DROP COLUMN "orion_subscription_for_iota",
ALTER COLUMN "subscription_id" SET DATA TYPE VARCHAR(25);

