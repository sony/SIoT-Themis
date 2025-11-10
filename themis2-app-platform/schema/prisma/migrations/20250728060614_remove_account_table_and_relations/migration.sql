/*
  Warnings:

  - You are about to drop the column `account_id` on the `visualizers` table. All the data in the column will be lost.
  - You are about to drop the `accounts` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "visualizers" DROP CONSTRAINT "visualizers_account_id_fkey";

-- AlterTable
ALTER TABLE "visualizers" DROP COLUMN "account_id";

-- DropTable
DROP TABLE "accounts";
