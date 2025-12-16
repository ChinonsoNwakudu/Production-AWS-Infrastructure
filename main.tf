module "vpc" {
  source       = "./modules/vpc"
  project_tags = var.project_tags
}

module "security" {
  source            = "./modules/security"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  project_tags      = var.project_tags
}

module "compute" {
  source             = "./modules/compute"
  web_sg_id          = module.security.web_sg_id
  db_sg_id           = module.security.db_sg_id
  private_subnet_ids = module.vpc.private_subnet_ids
  project_tags       = var.project_tags
  ec2_instance_profile_name = module.security.ec2_instance_profile_name
  depends_on         = [module.security]  # Ensure security first
}