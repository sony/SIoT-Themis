/*
  Warnings:

  - You are about to drop the `analyzers` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "analyzers" DROP CONSTRAINT "analyzers_account_id_fkey";

-- DropTable
DROP TABLE "analyzers";
