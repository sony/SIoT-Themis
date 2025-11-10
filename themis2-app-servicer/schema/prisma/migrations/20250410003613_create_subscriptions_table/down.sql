-- DropForeignKey
ALTER TABLE "conditions" DROP CONSTRAINT "conditions_type_id_fkey";

-- DropForeignKey
ALTER TABLE "subscriptions" DROP CONSTRAINT "subscriptions_type_id_fkey";

-- DropForeignKey
ALTER TABLE "types" DROP CONSTRAINT "types_customer_id_fkey";

-- DropTable
DROP TABLE "subscriptions";

-- AddForeignKey
ALTER TABLE "types" ADD CONSTRAINT "types_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "conditions" ADD CONSTRAINT "conditions_type_id_fkey" FOREIGN KEY ("type_id") REFERENCES "types"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

