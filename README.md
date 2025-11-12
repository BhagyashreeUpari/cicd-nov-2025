# cicd-nov-2025

End-to-end CI/CD demo:
- Python Flask app
- Unit test (pytest)
- Dockerfile
- Jenkins pipeline (Jenkinsfile)
- Image vulnerability scan (Trivy)
- Helm chart to deploy to Kubernetes (Kind or other cluster)

## Quick local flow (before Jenkins)
1. Build and run locally (optional)
   ```bash
   cd cicd-nov-2025
   python3 -m venv .venv
   source .venv/bin/activate
   pip install -r app/requirements.txt
   python app/app.py
   # open http://127.0.0.1:5000

