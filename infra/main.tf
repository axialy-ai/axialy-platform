# 1️⃣  A project to group everything
resource "digitalocean_project" "axialy" {
  name        = "Axialy"
  environment = "Production"
  purpose     = "Web Application"
  description = "Project that hosts the Axialy platform"
}

# 2️⃣  MySQL cluster (managed by DigitalOcean)
resource "digitalocean_database_cluster" "mysql" {
  name       = "axialy-db-cluster"
  engine     = "mysql"
  version    = "8"
  region     = var.region
  size       = "db-s-1vcpu-1gb"
  node_count = 1
}

# 2 a. Two databases inside the cluster
resource "digitalocean_database_db" "ui" {
  cluster_id = digitalocean_database_cluster.mysql.id
  name       = "Axialy_UI"
}

resource "digitalocean_database_db" "admin" {
  cluster_id = digitalocean_database_cluster.mysql.id
  name       = "Axialy_Admin"
}

# 3️⃣  Three droplets
resource "digitalocean_droplet" "ui" {
  name   = "ui.axialy.ai"
  region = var.region
  size   = var.droplet_size
  image  = "ubuntu-22-04-x64"
  tags   = ["axialy", "ui"]
}

resource "digitalocean_droplet" "api" {
  name   = "api.axialy.ai"
  region = var.region
  size   = var.droplet_size
  image  = "ubuntu-22-04-x64"
  tags   = ["axialy", "api"]
}

resource "digitalocean_droplet" "admin" {
  name   = "admin.axialy.ai"
  region = var.region
  size   = var.droplet_size
  image  = "ubuntu-22-04-x64"
  tags   = ["axialy", "admin"]
}

# 4️⃣  Put every resource into the project
resource "digitalocean_project_resources" "attach" {
  project = digitalocean_project.axialy.id
  resources = [
    digitalocean_droplet.ui.urn,
    digitalocean_droplet.api.urn,
    digitalocean_droplet.admin.urn,
    digitalocean_database_cluster.mysql.urn
  ]
}

