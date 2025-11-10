-- AlterTable
ALTER TABLE "analyzers"
ALTER COLUMN "node_ids" TYPE INTEGER[] USING node_ids::INTEGER[];

ALTER TABLE "visualizers"
ALTER COLUMN "node_ids" TYPE INTEGER[] USING node_ids::INTEGER[];
