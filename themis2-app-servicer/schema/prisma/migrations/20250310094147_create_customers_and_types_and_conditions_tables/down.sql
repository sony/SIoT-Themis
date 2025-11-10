-- DropForeignKey
ALTER TABLE "conditions" DROP CONSTRAINT "conditions_type_id_fkey";

-- DropForeignKey
ALTER TABLE "types" DROP CONSTRAINT "types_customer_id_fkey";

-- DropTable
DROP TABLE "conditions";

-- DropTable
DROP TABLE "customers";

-- DropTable
DROP TABLE "types";

