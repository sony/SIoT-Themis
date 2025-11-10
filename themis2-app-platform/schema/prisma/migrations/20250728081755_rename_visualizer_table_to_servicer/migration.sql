/*
  Warnings:

  - You are about to drop the column `visualizer_id` on the `subscriptions` table. All the data in the column will be lost.
  - You are about to drop the `visualizers` table. If the table is not empty, all the data it contains will be lost.
  - Added the required column `servicer_id` to the `subscriptions` table without a default value. This is not possible if the table is not empty.

*/
-- DropForeignKey
ALTER TABLE "subscriptions" DROP CONSTRAINT "subscriptions_visualizer_id_fkey";

-- AlterTable
ALTER TABLE "subscriptions" DROP COLUMN "visualizer_id",
ADD COLUMN     "servicer_id" INTEGER NOT NULL;

-- DropTable
DROP TABLE "visualizers";

-- CreateTable
CREATE TABLE "servicers" (
    "id" SERIAL NOT NULL,
    "name" VARCHAR(50) NOT NULL,
    "api_key" VARCHAR(32),
    "url" TEXT,
    "analyze" BOOLEAN NOT NULL DEFAULT false,
    "node_ids" TEXT[],
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "servicers_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "servicers_name_key" ON "servicers"("name");

-- CreateIndex
CREATE UNIQUE INDEX "servicers_api_key_key" ON "servicers"("api_key");

-- AddForeignKey
ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_servicer_id_fkey" FOREIGN KEY ("servicer_id") REFERENCES "servicers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
