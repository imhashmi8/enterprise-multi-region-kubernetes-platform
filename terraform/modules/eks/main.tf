data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# ── KMS key — envelope encryption for Kubernetes secrets ─────────────────────
resource "aws_kms_key" "eks" {
  description             = "EKS secrets encryption key — ${var.cluster_name}"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = merge(var.tags, { Name = "${var.cluster_name}-secrets-key" })
}

resource "aws_kms_alias" "eks" {
  name          = "alias/${var.cluster_name}-secrets"
  target_key_id = aws_kms_key.eks.key_id
}

# ── CloudWatch log group for control plane logs ───────────────────────────────
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 90
  tags              = var.tags
}

# ── Cluster IAM role ──────────────────────────────────────────────────────────
resource "aws_iam_role" "cluster" {
  name = "${var.name_prefix}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_eks_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "cluster_vpc_resource_controller" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

# ── Cluster security group ────────────────────────────────────────────────────
resource "aws_security_group" "cluster" {
  name        = "${var.cluster_name}-cluster-sg"
  description = "EKS control plane security group."
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound."
  }

  tags = merge(var.tags, { Name = "${var.cluster_name}-cluster-sg" })
}

# ── EKS Cluster ───────────────────────────────────────────────────────────────
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = var.cluster_endpoint_public_access
    public_access_cidrs     = var.cluster_endpoint_public_access_cidrs
    security_group_ids      = [aws_security_group.cluster.id]
  }

  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.eks.arn
    }
  }

  enabled_cluster_log_types = var.enable_cluster_log_types

  # API_AND_CONFIG_MAP supports both Access Entries and legacy aws-auth
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = merge(var.tags, { Name = var.cluster_name })

  depends_on = [
    aws_iam_role_policy_attachment.cluster_eks_policy,
    aws_iam_role_policy_attachment.cluster_vpc_resource_controller,
    aws_cloudwatch_log_group.eks,
  ]
}

# ── OIDC provider — enables IRSA for all service accounts ────────────────────
data "tls_certificate" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]

  tags = merge(var.tags, { Name = "${var.cluster_name}-oidc-provider" })
}

locals {
  oidc_issuer_url = replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
}

# ── Node IAM role ─────────────────────────────────────────────────────────────
resource "aws_iam_role" "node" {
  name = "${var.name_prefix}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "node_worker_policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_ecr_readonly" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "node_cni_policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# SSM Session Manager access — avoids needing SSH keys on nodes
resource "aws_iam_role_policy_attachment" "node_ssm" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ── Node security group ───────────────────────────────────────────────────────
resource "aws_security_group" "node" {
  name        = "${var.cluster_name}-node-sg"
  description = "EKS worker node security group."
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound."
  }

  tags = merge(var.tags, {
    Name                                        = "${var.cluster_name}-node-sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  })
}

resource "aws_security_group_rule" "node_ingress_self" {
  security_group_id        = aws_security_group.node.id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
  source_security_group_id = aws_security_group.node.id
  description              = "Node-to-node communication."
}

resource "aws_security_group_rule" "node_ingress_from_cluster" {
  security_group_id        = aws_security_group.node.id
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cluster.id
  description              = "Control plane to nodes (webhooks, metrics)."
}

resource "aws_security_group_rule" "cluster_ingress_from_nodes" {
  security_group_id        = aws_security_group.cluster.id
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.node.id
  description              = "Nodes to API server."
}

# ── Launch template — system node group ──────────────────────────────────────
resource "aws_launch_template" "system" {
  name_prefix = "${var.cluster_name}-system-"
  description = "System node group — platform add-ons."

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.system_node_group_config.disk_size_gb
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = aws_kms_key.eks.arn
      delete_on_termination = true
    }
  }

  # IMDSv2 enforced — prevents SSRF-based credential theft from pods
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring { enabled = true }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { NodeGroup = "system" })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(var.tags, { NodeGroup = "system" })
  }

  lifecycle { create_before_destroy = true }
  tags = var.tags
}

# ── Launch template — application node group ──────────────────────────────────
resource "aws_launch_template" "application" {
  name_prefix = "${var.cluster_name}-application-"
  description = "Application node group — workloads."

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.application_node_group_config.disk_size_gb
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = aws_kms_key.eks.arn
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring { enabled = true }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { NodeGroup = "application" })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(var.tags, { NodeGroup = "application" })
  }

  lifecycle { create_before_destroy = true }
  tags = var.tags
}

# ── Managed node group — system ───────────────────────────────────────────────
resource "aws_eks_node_group" "system" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-system"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.system.id
    version = aws_launch_template.system.latest_version
  }

  scaling_config {
    min_size     = var.system_node_group_config.min_size
    max_size     = var.system_node_group_config.max_size
    desired_size = var.system_node_group_config.desired_size
  }

  instance_types = var.system_node_group_config.instance_types
  capacity_type  = "ON_DEMAND"

  update_config { max_unavailable = 1 }

  # Prevents general workloads from landing on system nodes
  taint {
    key    = "CriticalAddonsOnly"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  labels = {
    role                            = "system"
    "node.kubernetes.io/node-group" = "system"
  }

  tags = merge(var.tags, { NodeGroup = "system" })

  depends_on = [
    aws_iam_role_policy_attachment.node_worker_policy,
    aws_iam_role_policy_attachment.node_ecr_readonly,
    aws_iam_role_policy_attachment.node_cni_policy,
  ]

  # Karpenter / cluster-autoscaler manage desired_size at runtime
  lifecycle { ignore_changes = [scaling_config[0].desired_size] }
}

# ── Managed node group — application ─────────────────────────────────────────
resource "aws_eks_node_group" "application" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.cluster_name}-application"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids

  launch_template {
    id      = aws_launch_template.application.id
    version = aws_launch_template.application.latest_version
  }

  scaling_config {
    min_size     = var.application_node_group_config.min_size
    max_size     = var.application_node_group_config.max_size
    desired_size = var.application_node_group_config.desired_size
  }

  instance_types = var.application_node_group_config.instance_types
  capacity_type  = "ON_DEMAND"

  update_config { max_unavailable = 1 }

  labels = {
    role                            = "application"
    "node.kubernetes.io/node-group" = "application"
  }

  tags = merge(var.tags, { NodeGroup = "application" })

  depends_on = [
    aws_iam_role_policy_attachment.node_worker_policy,
    aws_iam_role_policy_attachment.node_ecr_readonly,
    aws_iam_role_policy_attachment.node_cni_policy,
  ]

  lifecycle { ignore_changes = [scaling_config[0].desired_size] }
}

# ── IRSA — VPC CNI ────────────────────────────────────────────────────────────
data "aws_iam_policy_document" "vpc_cni_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_url}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "vpc_cni" {
  name               = "${var.name_prefix}-vpc-cni-irsa"
  assume_role_policy = data.aws_iam_policy_document.vpc_cni_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "vpc_cni" {
  role       = aws_iam_role.vpc_cni.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# ── IRSA — EBS CSI Driver ─────────────────────────────────────────────────────
data "aws_iam_policy_document" "ebs_csi_assume" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_url}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_url}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi" {
  name               = "${var.name_prefix}-ebs-csi-irsa"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# ── EKS managed add-ons ───────────────────────────────────────────────────────
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = aws_iam_role.vpc_cni.arn
  tags                        = var.tags

  depends_on = [aws_eks_node_group.system]
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "coredns"
  resolve_conflicts_on_update = "OVERWRITE"
  tags                        = var.tags

  depends_on = [aws_eks_node_group.system]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_update = "OVERWRITE"
  tags                        = var.tags

  depends_on = [aws_eks_node_group.system]
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "aws-ebs-csi-driver"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = aws_iam_role.ebs_csi.arn
  tags                        = var.tags

  depends_on = [aws_eks_node_group.system]
}

# ── Admin access entries ──────────────────────────────────────────────────────
resource "aws_eks_access_entry" "admin" {
  for_each = toset(var.admin_iam_roles)

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value
  type          = "STANDARD"
  tags          = var.tags
}

resource "aws_eks_access_policy_association" "admin" {
  for_each = toset(var.admin_iam_roles)

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope { type = "cluster" }

  depends_on = [aws_eks_access_entry.admin]
}
