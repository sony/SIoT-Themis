terraform {
  backend "s3" {
    bucket = "themis2-dev-s3-tfstate"
    key    = "terraform.tfstate"
    region = "ap-northeast-1"
  }
}
