# Spring Boot Kubernetes Deployment

This project demonstrates a GitOps workflow for deploying a Spring Boot application to Google Kubernetes Engine (GKE) using GitHub Actions.

## Prerequisites

- GitHub account
- Google Cloud Platform (GCP) account
- DockerHub account
- GKE cluster running in GCP

## Required GitHub Environment Variables

Create a GitHub environment named `non-prod` and add the following variables:

### GCP Configuration
- `PROJECT_ID`: Your GCP project ID
- `GKE_CLUSTER`: Your GKE cluster name
- `WORKLOAD_IDENTITY_PROVIDER`: GCP Workload Identity Provider URL
  - Format: `projects/PROJECT_NUMBER/locations/global/workloadIdentityPools/POOL_ID/providers/PROVIDER_ID`

### Docker Configuration
- `DOCKER_USER`: Your DockerHub username
- `DOCKER_PASSWORD`: Your DockerHub access token (not your account password)

## GCP Setup

1. Create a GKE cluster in the `us-central1` region
2. Create a service account for GitHub Actions:
   ```bash
   gcloud iam service-accounts create github-actions-sa \
     --display-name="GitHub Actions Service Account"
   ```

3. Grant necessary IAM roles to the service account:
   ```bash
   gcloud projects add-iam-policy-binding $PROJECT_ID \
     --member="serviceAccount:github-actions-sa@$PROJECT_ID.iam.gserviceaccount.com" \
     --role="roles/container.developer"

   gcloud projects add-iam-policy-binding $PROJECT_ID \
     --member="serviceAccount:github-actions-sa@$PROJECT_ID.iam.gserviceaccount.com" \
     --role="roles/artifactregistry.admin"

   gcloud projects add-iam-policy-binding $PROJECT_ID \
     --member="serviceAccount:github-actions-sa@$PROJECT_ID.iam.gserviceaccount.com" \
     --role="roles/iam.serviceAccountTokenCreator"
   ```

4. Create a Workload Identity Pool and Provider:
   ```bash
   gcloud iam workload-identity-pools create "github-actions-pool" \
     --location="global" \
     --display-name="GitHub Actions Pool"

   gcloud iam workload-identity-pools providers create-oidc "github-actions-provider" \
     --location="global" \
     --workload-identity-pool="github-actions-pool" \
     --display-name="GitHub Actions Provider" \
     --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
     --issuer-uri="https://token.actions.githubusercontent.com"
   ```

## Project Structure

```
.
├── .github/
│   └── workflows/
│       └── gke-deploy.yml    # GitHub Actions workflow
├── k8s/
│   ├── base/
│   │   ├── deployment.yaml   # Base Kubernetes deployment
│   │   ├── service.yaml      # Base Kubernetes service
│   │   └── kustomization.yaml # Base kustomization
│   └── overlays/
│       └── non-prod/
│           └── kustomization.yaml # Non-prod environment config
├── src/                      # Spring Boot application source
├── Dockerfile               # Multi-stage Docker build
└── pom.xml                  # Maven configuration
```

## Kustomize Configuration

### Base Configuration
The `k8s/base` directory contains the base Kubernetes manifests:
- `deployment.yaml`: Defines the base deployment configuration
- `service.yaml`: Defines the base service configuration
- `kustomization.yaml`: References the base resources and sets common labels

### Environment Overlays
The `k8s/overlays` directory contains environment-specific configurations:

#### Non-Prod Environment
Located in `k8s/overlays/non-prod/`:
- `kustomization.yaml`: 
  - References the base configuration
  - Adds `non-prod-` prefix to all resources
  - Patches the deployment with non-prod specific settings:
    - Sets replicas to 1
    - Configures resource limits (512Mi memory, 500m CPU)

To apply the non-prod configuration:
```bash
kustomize build k8s/overlays/non-prod | kubectl apply -f -
```

### Adding New Environments
To add a new environment (e.g., prod):
1. Create a new directory: `k8s/overlays/prod/`
2. Create a `kustomization.yaml` with environment-specific settings
3. Add the environment to the GitHub Actions workflow

## Deployment Process

1. The workflow is triggered on:
   - Push to the `master` branch
   - Manual trigger via GitHub Actions UI

2. The workflow:
   - Authenticates to GCP using Workload Identity
   - Authenticates to DockerHub
   - Builds and pushes the Docker image
   - Deploys to GKE using kustomize

## Local Development

1. Build the application:
   ```bash
   ./mvnw clean package
   ```

2. Build the Docker image:
   ```bash
   docker build -t vinaybalamuru/boot-k8s-sample-deploy:local .
   ```

3. Run locally:
   ```bash
   docker run -p 8080:8080 vinaybalamuru/boot-k8s-sample-deploy:local
   ```

## Troubleshooting

1. If the workflow fails to authenticate to GCP:
   - Verify the Workload Identity Provider URL
   - Check service account permissions
   - Ensure the GKE cluster exists in the specified region

2. If the Docker build fails:
   - Verify DockerHub credentials
   - Check Docker image name and tags

3. If the deployment fails:
   - Check GKE cluster access
   - Verify kustomize configuration
   - Check deployment logs: `kubectl logs -l app=boot-k8s-sample-deploy`

## Security Notes

- Never commit sensitive credentials to the repository
- Use GitHub Secrets for sensitive values
- Use Workload Identity Federation for GCP authentication
- Use DockerHub access tokens instead of passwords
- Follow the principle of least privilege for service account permissions 