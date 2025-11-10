-- Add url and analyze columns to visualizers table
ALTER TABLE "visualizers" ADD COLUMN "url" TEXT;
ALTER TABLE "visualizers" ADD COLUMN "analyze" BOOLEAN NOT NULL DEFAULT false; 