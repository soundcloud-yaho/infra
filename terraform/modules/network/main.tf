# [Network] VPC, 3계층 서브넷(Public/Private/DB), NAT 1개, ELB/Karpenter 태그
# 핵심: 서브넷 태그가 없으면 ALB 자동생성과 Karpenter 노드 배치가 전부 실패한다

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true # Aurora 엔드포인트/EKS 내부 DNS 해석에 필수
  enable_dns_hostnames = true

  tags = { Name = "${var.project_name}-${var.environment}-vpc" }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.project_name}-${var.environment}-igw" }
}

# ---------- Public Subnet (ALB, NAT 배치) ----------
resource "aws_subnet" "public" {
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${var.project_name}-${var.environment}-public-${var.azs[count.index]}"
    "kubernetes.io/role/elb" = "1" # LB Controller가 인터넷용 ALB를 놓을 서브넷 식별 태그
  }
}

# ---------- Private Subnet (EKS 워커 노드) ----------
resource "aws_subnet" "private" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name                              = "${var.project_name}-${var.environment}-private-${var.azs[count.index]}"
    "kubernetes.io/role/internal-elb" = "1"              # 내부용 LB 서브넷 식별
    "karpenter.sh/discovery"          = var.cluster_name # Karpenter가 노드 띄울 서브넷 자동 발견
  }
}

# ---------- DB Subnet (Aurora 전용, 인터넷 경로 없음) ----------
resource "aws_subnet" "db" {
  count             = length(var.azs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.db_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = { Name = "${var.project_name}-${var.environment}-db-${var.azs[count.index]}" }
}

# ---------- NAT Gateway (1개 - 비용 절약. 프로덕션이면 AZ당 1개) ----------
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${var.project_name}-${var.environment}-nat-eip" }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id # 첫 번째 AZ의 퍼블릭 서브넷에 배치
  tags          = { Name = "${var.project_name}-${var.environment}-nat" }

  depends_on = [aws_internet_gateway.this]
}

# ---------- 라우팅 ----------
# Public: 인터넷으로 직행
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
  tags = { Name = "${var.project_name}-${var.environment}-rt-public" }
}

resource "aws_route_table_association" "public" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private: 아웃바운드만 NAT 경유 (동기화 CronJob의 football-data.org 호출 경로)
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }
  tags = { Name = "${var.project_name}-${var.environment}-rt-private" }
}

resource "aws_route_table_association" "private" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# DB: 인터넷 경로 자체가 없음 (VPC 내부 통신만 가능 = 가장 안쪽 금고)
resource "aws_route_table" "db" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.project_name}-${var.environment}-rt-db" }
}

resource "aws_route_table_association" "db" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db.id
}
