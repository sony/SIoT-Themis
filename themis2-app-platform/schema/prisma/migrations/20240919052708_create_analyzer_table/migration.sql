-- CreateTable
CREATE TABLE "analyzers" (
    "id" SERIAL NOT NULL,
    "account_id" INTEGER NOT NULL,
    "name" VARCHAR(50) NOT NULL,
    "type" VARCHAR(8) NOT NULL,
    "api_key" VARCHAR(32) NOT NULL,
    "url" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "analyzers_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "analyzers_name_key" ON "analyzers"("name");

-- CreateIndex
CREATE UNIQUE INDEX "analyzers_api_key_key" ON "analyzers"("api_key");

-- AddForeignKey
ALTER TABLE "analyzers" ADD CONSTRAINT "analyzers_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "accounts"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
