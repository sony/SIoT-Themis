-- AlterTable
ALTER TABLE "visualizers" ADD COLUMN     "node_ids" INTEGER[];
UPDATE "visualizers" SET "node_ids" = '{}';
ALTER TABLE "visualizers" ALTER COLUMN "node_ids" SET NOT NULL;