import os
from pathlib import Path
from dotenv import load_dotenv

# Base Directory
BASE_DIR = Path(__file__).resolve().parent

# Load .env file from project root or backend folder
env_path_root = BASE_DIR.parent / ".env"
env_path_local = BASE_DIR / ".env"

if env_path_root.exists():
    load_dotenv(env_path_root)
elif env_path_local.exists():
    load_dotenv(env_path_local)
else:
    load_dotenv()

class Settings:
    PROJECT_NAME: str = "RescueLens XR - Emergency Detection & Evacuation Backend"
    VERSION: str = "1.0.0"
    API_V1_PREFIX: str = "/api/v1"
    
    HOST: str = os.getenv("BACKEND_HOST", "0.0.0.0")
    PORT: int = int(os.getenv("BACKEND_PORT", "8000"))
    DEBUG: bool = os.getenv("DEBUG_MODE", "True").lower() in ("true", "1", "yes")

    # Safety Evaluation Thresholds
    SMOKE_THRESHOLD_WARNING_PPM: float = float(os.getenv("SMOKE_THRESHOLD_WARNING_PPM", "250.0"))
    SMOKE_THRESHOLD_CRITICAL_PPM: float = float(os.getenv("SMOKE_THRESHOLD_CRITICAL_PPM", "450.0"))
    
    TEMP_THRESHOLD_WARNING_C: float = float(os.getenv("TEMP_THRESHOLD_WARNING_C", "40.0"))
    TEMP_THRESHOLD_CRITICAL_C: float = float(os.getenv("TEMP_THRESHOLD_CRITICAL_C", "50.0"))
    
    # Firebase settings (configured in Phase 3)
    FIREBASE_DATABASE_URL: str = os.getenv("FIREBASE_DATABASE_URL", "")
    FIREBASE_CREDENTIALS_PATH: str = os.getenv("FIREBASE_CREDENTIALS_PATH", "./firebase/serviceAccountKey.json")

    # Simulation Defaults
    SIMULATION_MODE: bool = os.getenv("SIMULATION_MODE", "True").lower() in ("true", "1", "yes")

settings = Settings()
