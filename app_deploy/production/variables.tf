variable "container_count" {
  type = number
  default = 2
}

variable "container_image" {
  type = string
  default = "919545427229.dkr.ecr.ap-southeast-2.amazonaws.com/python-demo:master-17b59c901e9f9db8339558ec63c77c5728dc3c9e"
}

variable "vpc_id" {
  type = string
  default = "vpc-08de9825e44feacf0"
}

variable "ecs_production_cluster" {
  type = string
  default = "production"
}

variable "lb_tg_name" {
  type = string
  default = "ecs-prod-target-group"
}

variable "security_group_id" {
  type = string
  default = "sg-023e8c616ea55c63a"
}


variable "private_subnet_ids" {
  default = ["subnet-058d5ea183cbff557", "subnet-02d61519d9476c95b"]
}
