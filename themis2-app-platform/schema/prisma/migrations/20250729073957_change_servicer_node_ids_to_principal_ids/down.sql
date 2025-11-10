-- AlterTable
ALTER TABLE "servicers" DROP COLUMN "principal_ids",
ADD COLUMN     "node_ids" TEXT[];

