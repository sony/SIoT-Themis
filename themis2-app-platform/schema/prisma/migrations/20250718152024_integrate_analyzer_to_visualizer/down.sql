-- Down migration: No schema changes to revert since analyzers table was preserved
-- Data migration is irreversible and no rollback is needed

-- Note: This migration only performed data integration from analyzers to visualizers
-- The analyzers table remains unchanged and no schema modifications were made 