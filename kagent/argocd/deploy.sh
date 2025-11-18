#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== kagent ArgoCD Deployment ===${NC}\n"

# Check if OPENAI_API_KEY is set
if [ -z "$OPENAI_API_KEY" ]; then
    echo -e "${RED}Error: OPENAI_API_KEY environment variable is not set${NC}"
    echo "Please set it with: export OPENAI_API_KEY='your-api-key'"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl is not installed${NC}"
    exit 1
fi

# Create namespace if it doesn't exist
echo -e "${YELLOW}Creating kagent namespace...${NC}"
kubectl create namespace kagent --dry-run=client -o yaml | kubectl apply -f -

# Create the OpenAI API key secret
echo -e "${YELLOW}Creating OpenAI API key secret...${NC}"
kubectl create secret generic kagent-openai \
    --namespace kagent \
    --from-literal=OPENAI_API_KEY="$OPENAI_API_KEY" \
    --dry-run=client -o yaml | kubectl apply -f -

echo -e "${GREEN}✓ Secret created${NC}\n"

# Apply ArgoCD applications
echo -e "${YELLOW}Applying ArgoCD application for kagent-crds...${NC}"
kubectl apply -f "$(dirname "$0")/kagent-crds.yaml"

echo -e "${GREEN}✓ kagent-crds application created${NC}\n"

echo -e "${YELLOW}Waiting for CRDs to sync...${NC}"
TIMEOUT=300
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    SYNC_STATUS=$(kubectl get application kagent-crds -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "Unknown")
    if [ "$SYNC_STATUS" = "Synced" ]; then
        echo -e "${GREEN}✓ CRDs synced${NC}"
        break
    fi
    echo -n "."
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo -e "\n${RED}Warning: Timeout waiting for CRDs to sync. Continuing anyway...${NC}"
fi
echo ""

echo -e "${YELLOW}Applying ArgoCD application for kagent...${NC}"
kubectl apply -f "$(dirname "$0")/kagent.yaml"

echo -e "${GREEN}✓ kagent application created${NC}\n"

echo -e "${GREEN}=== Deployment Complete ===${NC}\n"
echo "To monitor the deployment:"
echo "  kubectl get applications -n argocd"
echo "  kubectl get pods -n kagent -w"
echo ""
echo "To access the ArgoCD UI:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "  Then visit: https://localhost:8080"
