-- AlterTable
ALTER TABLE "analyzers" ADD COLUMN     "node_ids" INTEGER[];
UPDATE "analyzers" SET "node_ids" = '{}';
ALTER TABLE "analyzers" ALTER COLUMN "node_ids" SET NOT NULL;
