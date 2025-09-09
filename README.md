# 🎮 2048 Game on AWS ECS (Fargate) with CI/CD

This project demonstrates a **production-grade deployment** of the classic **2048 Game** on **AWS ECS (Fargate)** with a **fully automated CI/CD pipeline** using **CodePipeline, CodeBuild, ECR, and ECS**.

The setup ensures that **every code commit to GitHub triggers a build, pushes a new Docker image to ECR, and deploys automatically to ECS** behind an **Application Load Balancer (ALB)**.

---

## 📌 Architecture Overview

### Workflow

1. **Developer** → Pushes code to GitHub.
2. **CodePipeline** → Detects commit and triggers build.
3. **CodeBuild** → Builds Docker image, tags with commit ID, pushes to **Amazon ECR**.
4. **ECS (Fargate)** → Pulls the new image from ECR, updates service.
5. **Application Load Balancer** → Routes external traffic to running ECS tasks.
6. **CloudWatch** → Collects logs & metrics for monitoring.

### AWS Services Used

* **Amazon ECS (Fargate)** → Runs containers serverlessly.
* **Amazon ECR** → Private Docker registry for storing container images.
* **AWS CodePipeline** → CI/CD orchestration.
* **AWS CodeBuild** → Docker build + push to ECR.
* **Application Load Balancer (ALB)** → Public access point with health checks.
* **IAM Roles & Policies** → Secure permissions (ECS task execution role, CodeBuild role).
* **CloudWatch Logs** → ECS task logging.

---

## 🚀 Features

✅ Fully automated CI/CD with rollback support
✅ Secure image storage in Amazon ECR
✅ Stateless ECS Fargate tasks (no server management)
✅ Load-balanced and highly available app
✅ IAM-based least privilege access
✅ CloudWatch logging & monitoring

---

## ⚙️ Setup Instructions

### 1. Prerequisites

* AWS Account with admin privileges
* GitHub repository containing the **2048 Game** source code & `Dockerfile`
* AWS CLI installed locally
* Docker installed locally (optional for testing before push)

---

### 2. Create ECR Repository

```bash
aws ecr create-repository --repository-name 2048-game
```

---

### 3. Build & Push Docker Image (first manual push)

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com

docker build -t 2048-game .
docker tag 2048-game:latest <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/2048-game:latest
docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/2048-game:latest
```

---

### 4. ECS Cluster & Service Setup

1. **Create ECS Cluster (Fargate)** via console.
2. **Task Definition** → use ECR image, `ecsTaskExecutionRole`.
3. **ECS Service** → Fargate, desired tasks = 1, attach **ALB**.
4. Configure **security group** → allow inbound HTTP (port 80).

---

### 5. CI/CD Setup

#### a) Create Buildspec File (`buildspec.yml`)

```yaml
version: 0.2
phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
      - REPO_URI=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/2048-game
      - IMAGE_TAG=$CODEBUILD_RESOLVED_SOURCE_VERSION
  build:
    commands:
      - echo Build started on `date`
      - docker build -t $REPO_URI:$IMAGE_TAG .
  post_build:
    commands:
      - echo Build completed on `date`
      - docker push $REPO_URI:$IMAGE_TAG
      - printf '[{"name":"2048-game","imageUri":"%s"}]' $REPO_URI:$IMAGE_TAG > imagedefinitions.json
artifacts:
  files: imagedefinitions.json
```

#### b) CodePipeline Stages

1. **Source Stage** → GitHub repo (trigger on push).
2. **Build Stage** → CodeBuild project runs `buildspec.yml`.
3. **Deploy Stage** → ECS deployment using `imagedefinitions.json`.

---

## 🌍 Deployment

After pipeline success, ECS Service updates with the **new Docker image** from ECR.

* ALB DNS (e.g. `http://ecs-alb-123456.us-east-1.elb.amazonaws.com`) serves the **2048 Game**.

---

## 🛠️ Troubleshooting

| Error                                              | Cause                                | Fix                                           |
| -------------------------------------------------- | ------------------------------------ | --------------------------------------------- |
| `AccessDeniedException: ecr:GetAuthorizationToken` | Missing permissions in ECS task role | Attach `AmazonECSTaskExecutionRolePolicy`     |
| `429 Too Many Requests (Docker Hub)`               | Rate limit on base image             | Use ECR-hosted base images OR Docker Hub auth |
| `No rollback candidate found`                      | First deploy has no previous version | Ignore for initial setup                      |
| `ResourceInitializationError`                      | ECS cannot pull from ECR             | Ensure ECS task role has ECR permissions      |
| `docker push failed`                               | Image not built successfully         | Check Dockerfile, build logs                  |

---

## 📊 Monitoring

* **CloudWatch Logs** → ECS container stdout/stderr.
* **ECS Service Metrics** → CPU, memory, task count.
* **ALB Target Group** → Health checks for containers.
* **Auto Scaling** → Can be enabled for ECS service.

---

## 🔒 IAM Roles

* **ecsTaskExecutionRole** → Required for ECS tasks to pull images/secrets.

  * Attach: `AmazonECSTaskExecutionRolePolicy`.
* **CodeBuild Service Role** → Required to build/push Docker images.

  * Attach: `AmazonEC2ContainerRegistryFullAccess`.

---

## 💰 Cost Considerations

* **ECS Fargate** → Pay per vCPU/memory used.
* **ECR** → Pay per GB/month for stored images.
* **CodePipeline/CodeBuild** → Small hourly charges.
* **ALB** → Charged hourly + per request.

💡 Tip: For demo/testing, keep only **1 running task** and delete unused images in ECR.

---

## 🏗️ Future Improvements

* Add **ECS Auto Scaling** based on CPU/memory.
* Use **Secrets Manager** for DB/API keys.
* Add **CloudFront** + HTTPS with ACM for SSL.
* Implement **Blue/Green Deployments** for zero downtime.

---

## 📜 License

This project is for **educational and demo purposes**.

---

✅ With this pipeline, your app is **fully automated from GitHub push → ECS deployment** 🎉

---

Would you like me to also add a **diagram (ASCII or generated)** of the architecture in this README to make it more visual?
