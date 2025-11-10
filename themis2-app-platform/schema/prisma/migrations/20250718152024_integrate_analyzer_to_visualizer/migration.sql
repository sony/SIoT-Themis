-- Step 1: Update visualizers with URLs from matching analyzers
UPDATE "visualizers" 
SET 
    "url" = "analyzers"."url",
    "analyze" = "analyzers"."url" IS NOT NULL
FROM "analyzers"
WHERE "analyzers"."url" IS NOT NULL 
AND EXISTS (
    SELECT 1 
    FROM unnest("analyzers"."node_ids") AS analyzer_node_id
    WHERE analyzer_node_id = ANY("visualizers"."node_ids")
);

-- Step 2: Insert analyzers that don't overlap with existing visualizers
INSERT INTO "visualizers" ("name", "api_key", "url", "node_ids", "analyze", "created_at", "updated_at")
SELECT 
    "analyzers"."name",
    "analyzers"."api_key",
    "analyzers"."url",
    "analyzers"."node_ids",
    "analyzers"."url" IS NOT NULL,
    "analyzers"."created_at",
    "analyzers"."updated_at"
FROM "analyzers"
WHERE NOT EXISTS (
    SELECT 1 
    FROM "visualizers"
    WHERE EXISTS (
        SELECT 1 
        FROM unnest("analyzers"."node_ids") AS analyzer_node_id
        WHERE analyzer_node_id = ANY("visualizers"."node_ids")
    )
);
