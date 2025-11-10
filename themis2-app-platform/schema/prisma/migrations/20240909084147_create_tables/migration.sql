-- CreateTable
CREATE TABLE "accounts" (
    "id" SERIAL NOT NULL,

    CONSTRAINT "accounts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "visualizers" (
    "id" SERIAL NOT NULL,
    "account_id" INTEGER NOT NULL,
    "name" VARCHAR(50) NOT NULL,
    "api_key" VARCHAR(32) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "visualizers_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "visualizers_name_key" ON "visualizers"("name");

-- CreateIndex
CREATE UNIQUE INDEX "visualizers_api_key_key" ON "visualizers"("api_key");

-- AddForeignKey
ALTER TABLE "visualizers" ADD CONSTRAINT "visualizers_account_id_fkey" FOREIGN KEY ("account_id") REFERENCES "accounts"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
