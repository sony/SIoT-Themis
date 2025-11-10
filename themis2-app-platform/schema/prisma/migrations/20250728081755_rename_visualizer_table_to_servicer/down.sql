-- DropForeignKey
ALTER TABLE "subscriptions" DROP CONSTRAINT "subscriptions_servicer_id_fkey";

-- AlterTable
ALTER TABLE "subscriptions" DROP COLUMN "servicer_id",
ADD COLUMN     "visualizer_id" INTEGER NOT NULL;

-- DropTable
DROP TABLE "servicers";

-- CreateTable
CREATE TABLE "visualizers" (
    "id" SERIAL NOT NULL,
    "name" VARCHAR(50) NOT NULL,
    "api_key" VARCHAR(32),
    "url" TEXT,
    "analyze" BOOLEAN NOT NULL DEFAULT false,
    "node_ids" TEXT[],
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "visualizers_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "visualizers_name_key" ON "visualizers"("name");

-- CreateIndex
CREATE UNIQUE INDEX "visualizers_api_key_key" ON "visualizers"("api_key");

-- AddForeignKey
ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_visualizer_id_fkey" FOREIGN KEY ("visualizer_id") REFERENCES "visualizers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

