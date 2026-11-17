import os
import json
import logging
from typing import Dict, Any, Optional
import requests
from config import settings

logger = logging.getLogger("RescueLens_FirebaseSync")

class FirebaseSyncService:
    """
    Manages synchronization between the local FastAPI backend and Firebase Realtime Database.
    Supports both direct REST synchronization and Google Firebase Admin SDK.
    Gracefully handles offline / unconfigured credentials for classroom demonstrations.
    """
    def __init__(self):
        self.db_url = settings.FIREBASE_DATABASE_URL.rstrip('/') if settings.FIREBASE_DATABASE_URL else ""
        self.credentials_path = settings.FIREBASE_CREDENTIALS_PATH
        self.is_connected = False
        self.admin_initialized = False

        self._initialize_client()

    def _initialize_client(self):
        """Attempts to initialize Firebase credentials if configured."""
        if not self.db_url:
            logger.info("[FirebaseSync] No FIREBASE_DATABASE_URL defined. Operating in Local Memory Mode.")
            return

        # Check for serviceAccountKey.json
        cred_file = os.path.abspath(self.credentials_path)
        if os.path.exists(cred_file):
            try:
                import firebase_admin
                from firebase_admin import credentials, db

                if not firebase_admin._apps:
                    cred = credentials.Certificate(cred_file)
                    firebase_admin.initialize_app(cred, {'databaseURL': self.db_url})
                self.admin_initialized = True
                self.is_connected = True
                logger.info(f"[FirebaseSync] Initialized Firebase Admin SDK with {cred_file}")
                return
            except Exception as e:
                logger.warning(f"[FirebaseSync] Failed to initialize Firebase Admin SDK: {e}. Falling back to REST API.")

        # Fallback to direct REST API
        try:
            test_resp = requests.get(f"{self.db_url}/building_status.json", timeout=3.0)
            if test_resp.status_code in (200, 401, 403):
                self.is_connected = True
                logger.info(f"[FirebaseSync] Connected via Firebase REST API: {self.db_url}")
            else:
                logger.warning(f"[FirebaseSync] Firebase test endpoint returned status {test_resp.status_code}")
        except Exception as e:
            logger.info(f"[FirebaseSync] Firebase REST endpoint unreachable ({e}). Local simulation remains fully operational.")

    def sync_building_status(self, status_data: Dict[str, Any]):
        """Pushes current overall building health to /building_status."""
        if not self.db_url:
            return
        endpoint = f"{self.db_url}/building_status.json"
        try:
            requests.patch(endpoint, json=status_data, timeout=2.0)
        except Exception as e:
            logger.debug(f"[FirebaseSync] Failed to sync building status: {e}")

    def sync_room_update(self, room_id: str, room_data: Dict[str, Any]):
        """Pushes real-time room readings to /rooms/{room_id}."""
        if not self.db_url:
            return
        endpoint = f"{self.db_url}/rooms/{room_id}.json"
        try:
            requests.patch(endpoint, json=room_data, timeout=2.0)
        except Exception as e:
            logger.debug(f"[FirebaseSync] Failed to sync room {room_id}: {e}")

    def sync_alert(self, alert_id: str, alert_data: Dict[str, Any]):
        """Pushes active alert to /active_alerts/{alert_id} and historical log."""
        if not self.db_url:
            return
        try:
            # Add to active alerts
            requests.put(f"{self.db_url}/active_alerts/{alert_id}.json", json=alert_data, timeout=2.0)
            # Add to historical audit log
            requests.put(f"{self.db_url}/alert_history/{alert_id}.json", json=alert_data, timeout=2.0)
        except Exception as e:
            logger.debug(f"[FirebaseSync] Failed to sync alert {alert_id}: {e}")

    def clear_active_alerts(self):
        """Clears active alerts on demonstration reset."""
        if not self.db_url:
            return
        try:
            requests.delete(f"{self.db_url}/active_alerts.json", timeout=2.0)
        except Exception as e:
            logger.debug(f"[FirebaseSync] Failed to clear active alerts: {e}")

    def sync_evacuation_route(self, origin: str, route_data: Dict[str, Any]):
        """Pushes optimal evacuation route to /evacuation_routes/{origin}."""
        if not self.db_url:
            return
        endpoint = f"{self.db_url}/evacuation_routes/{origin}.json"
        try:
            requests.put(endpoint, json=route_data, timeout=2.0)
        except Exception as e:
            logger.debug(f"[FirebaseSync] Failed to sync route for {origin}: {e}")

# Singleton instance
firebase_sync = FirebaseSyncService()
