/*
  Warnings:

  - A unique constraint covering the columns `[customer_id,type]` on the table `types` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateIndex
CREATE UNIQUE INDEX "types_customer_id_type_key" ON "types"("customer_id", "type");
