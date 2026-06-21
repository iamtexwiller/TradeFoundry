# Backend local — o projeto original usava Azure Storage Account para o state remoto.
# Na versão local, mantemos o state versionado no próprio repositório Git (terraform.tfstate
# é incluído no .gitignore por segurança — pode conter dados sensíveis dos provedores).
#
# Trade-off consciente: em um cenário de equipe real, o ideal seria um backend remoto
# (mesmo que gratuito, como um bucket S3 free tier ou Terraform Cloud free tier).
# Para um projeto individual de portfólio, backend local é suficiente e mantém custo zero.

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
