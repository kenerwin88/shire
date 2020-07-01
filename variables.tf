variable "name" {
  type    = string
  default = "shire"
}

variable "namespaces" {
  type = list
  default = [
    "dev",
    "stage",
    "prod"
  ]
}

variable "sshPublicKey" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDi5dpkbHEjBCRsG2ZqGATXZps+VZxzhleFygMnScwAhWwk742Bvg3T6mmUNKDIOTZQ6KgKDzY81RZ5QpxSahI6yql6QHDThvDjHXsiGmTKsLVJ1IVesJf/dT9gTys53ZScwCr2QS2gJYY2bqYBQwUxDjzM1KYggEVrz4BjtxTuxgAcC0cAvl3e+9tDfOSJGNHMsAKvIzDusJRodo6pxuzaGDcuzR+YgTJo0Jt8ktnqY+d5MAUeWWZycwfEdIwJexTjaYUh1Hm7qwDVUhUnFgTKZRJe3Q2nj+6JI0a2TJlXBHUlTv2i4GwRLIsn0SOooitxchlASMWPvx50mqjysZhlGeo7rgA5w3hMY7f7InIx5vo8zK8K1LCuVxThay+1FyYiT3pwP2MZq9D0WuHvSq+NbSIKGGaxTGc+G70vHhCvjW1FpT5Wv19WO8AGOYUDrmqrfb+jh3pW4yoBy0FbhUoMS35+4g/O/aPxLzHpnaYbhPAtNDdBqYcG/WBlTJMaK+8= kendog15@tanooki"
}

variable "private_key" {
  type    = string
  default = "~/.ssh/shire"
}

variable "terraform_s3_bucket" {
  type    = string
}

variable "logs_s3_bucket" {
  type    = string
}
