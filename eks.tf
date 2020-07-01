module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  version      = "12.1.0"
  cluster_name = "${var.name}-cluster"
  vpc_id       = module.vpc.vpc_id
  subnets      = concat(module.vpc.private_subnets, module.vpc.public_subnets)
  workers_group_defaults = {
    subnets = module.vpc.private_subnets
  }
  worker_groups = [
    {
      instance_type = "m5a.large"
      asg_max_size  = 1
    }
  ]
  map_users = [
    {
      userarn = aws_iam_role.eksAdminRole.arn
      username = "eksAdmin"
      groups = ["system:masters"]
    }
  ]
}
