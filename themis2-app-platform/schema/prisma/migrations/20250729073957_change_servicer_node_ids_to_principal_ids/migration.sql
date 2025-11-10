/*
  Warnings:

  - You are about to drop the column `node_ids` on the `servicers` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "servicers" DROP COLUMN "node_ids",
ADD COLUMN     "principal_ids" TEXT[];
