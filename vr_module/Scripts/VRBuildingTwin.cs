using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Networking;
using TMPro;

namespace RescueLens.XR.VR
{
    /// <summary>
    /// RescueLens XR - 3D Digital Twin & Incident Commander VR Viewer
    /// Fetches live building health and dynamic evacuation routing from the backend,
    /// rendering a full 3D volumetric model of the building floor with real-time
    /// color-coded hazard zones and glowing safe evacuation corridors.
    /// </summary>
    public class VRBuildingTwin : MonoBehaviour
    {
        [Header("API Endpoints")]
        public string backendStatusUrl = "http://192.168.1.150:8000/api/v1/building/status";
        public string backendRouteUrl = "http://192.168.1.150:8000/api/v1/evacuation/route?origin=ROOM_1";
        public float refreshIntervalSeconds = 2.0f;

        [Header("3D Sector GameObjects")]
        public GameObject room1Object;
        public GameObject room2Object;
        public GameObject room3Object;
        public GameObject corridorWestObject;
        public GameObject corridorCentralObject;
        public GameObject corridorEastObject;
        public GameObject mainExitObject;
        public GameObject emergencyExitObject;

        [Header("Shaders & Materials")]
        public Material safeNeutralMaterial;
        public Material warningAmberMaterial;
        public Material criticalFireMaterial;
        public Material evacuationPathMaterial;

        [Header("Path Renderer")]
        public LineRenderer routeLineRenderer;

        // Sector mapping dictionary
        private Dictionary<string, GameObject> sectorObjects = new Dictionary<string, GameObject>();

        // Node 3D positions for the LineRenderer
        private readonly Dictionary<string, Vector3> nodePositions = new Dictionary<string, Vector3>()
        {
            { "ROOM_1", new Vector3(-8f, 0.5f, 5f) },
            { "ROOM_2", new Vector3(0f, 0.5f, 5f) },
            { "ROOM_3", new Vector3(8f, 0.5f, 5f) },
            { "CORRIDOR_WEST", new Vector3(-8f, 0.5f, 0f) },
            { "CORRIDOR_CENTRAL", new Vector3(0f, 0.5f, 0f) },
            { "CORRIDOR_EAST", new Vector3(8f, 0.5f, 0f) },
            { "MAIN_EXIT", new Vector3(14f, 0.5f, 0f) },
            { "EMERGENCY_EXIT", new Vector3(-14f, 0.5f, 0f) }
        };

        [System.Serializable]
        public class RoomStatusDto
        {
            public string room_id;
            public string hazard_level;
            public double temperature;
            public double smoke_ppm;
            public bool flame_detected;
            public bool is_passable;
        }

        [System.Serializable]
        public class BuildingStatusDto
        {
            public string overall_status;
            public int critical_rooms;
            public int active_alerts_count;
        }

        [System.Serializable]
        public class RouteDto
        {
            public string status;
            public List<string> path;
            public string destination;
            public float path_distance;
        }

        private void Awake()
        {
            // Bind inspector objects into sector dictionary
            if (room1Object != null) sectorObjects["ROOM_1"] = room1Object;
            if (room2Object != null) sectorObjects["ROOM_2"] = room2Object;
            if (room3Object != null) sectorObjects["ROOM_3"] = room3Object;
            if (corridorWestObject != null) sectorObjects["CORRIDOR_WEST"] = corridorWestObject;
            if (corridorCentralObject != null) sectorObjects["CORRIDOR_CENTRAL"] = corridorCentralObject;
            if (corridorEastObject != null) sectorObjects["CORRIDOR_EAST"] = corridorEastObject;
            if (mainExitObject != null) sectorObjects["MAIN_EXIT"] = mainExitObject;
            if (emergencyExitObject != null) sectorObjects["EMERGENCY_EXIT"] = emergencyExitObject;

            // Generate procedural primitives if no 3D models assigned
            if (sectorObjects.Count == 0)
            {
                CreateProceduralBuildingModel();
            }

            if (routeLineRenderer == null)
            {
                GameObject lineObj = new GameObject("VR_Route_Line");
                lineObj.transform.SetParent(transform);
                routeLineRenderer = lineObj.AddComponent<LineRenderer>();
                routeLineRenderer.startWidth = 0.4f;
                routeLineRenderer.endWidth = 0.4f;
                routeLineRenderer.material = evacuationPathMaterial != null ? evacuationPathMaterial : safeNeutralMaterial;
            }
        }

        private void Start()
        {
            StartCoroutine(SyncLoopRoutine());
        }

        private IEnumerator SyncLoopRoutine()
        {
            while (true)
            {
                yield return FetchBuildingAndRoute();
                yield return new WaitForSeconds(refreshIntervalSeconds);
            }
        }

        private IEnumerator FetchBuildingAndRoute()
        {
            // 1. Fetch Route
            using (UnityWebRequest routeReq = UnityWebRequest.Get(backendRouteUrl))
            {
                routeReq.timeout = 3;
                yield return routeReq.SendWebRequest();
                if (routeReq.result == UnityWebRequest.Result.Success)
                {
                    RouteDto route = JsonUtility.FromJson<RouteDto>(routeReq.downloadHandler.text);
                    UpdateEvacuationPath(route);
                }
            }

            // 2. Fetch Rooms
            string roomsUrl = backendStatusUrl.Replace("/status", "/rooms");
            using (UnityWebRequest roomsReq = UnityWebRequest.Get(roomsUrl))
            {
                roomsReq.timeout = 3;
                yield return roomsReq.SendWebRequest();
                if (roomsReq.result == UnityWebRequest.Result.Success)
                {
                    // Update room colors
                    UpdateRoomMaterials(roomsReq.downloadHandler.text);
                }
            }
        }

        private void UpdateEvacuationPath(RouteDto route)
        {
            if (route == null || route.path == null || route.path.Count < 2 || route.status == "TRAPPED_NO_SAFE_ROUTE")
            {
                routeLineRenderer.positionCount = 0;
                return;
            }

            routeLineRenderer.positionCount = route.path.Count;
            for (int i = 0; i < route.path.Count; i++)
            {
                string node = route.path[i];
                if (nodePositions.ContainsKey(node))
                {
                    routeLineRenderer.SetPosition(i, nodePositions[node]);
                }
            }
        }

        private void UpdateRoomMaterials(string jsonArray)
        {
            // Simple string inspection for demonstration
            foreach (var kvp in sectorObjects)
            {
                string rId = kvp.Key;
                GameObject obj = kvp.Value;
                Renderer rend = obj.GetComponent<Renderer>();
                if (rend == null) continue;

                if (jsonArray.Contains($"\"{rId}\"") && jsonArray.Contains("\"CRITICAL\""))
                {
                    // Sector is in critical fire hazard
                    rend.material = criticalFireMaterial != null ? criticalFireMaterial : rend.material;
                }
                else
                {
                    // Sector is secure
                    rend.material = safeNeutralMaterial != null ? safeNeutralMaterial : rend.material;
                }
            }
        }

        private void CreateProceduralBuildingModel()
        {
            // Procedurally builds demonstration floor plan
            foreach (var kvp in nodePositions)
            {
                string id = kvp.Key;
                Vector3 pos = kvp.Value;

                GameObject box = GameObject.CreatePrimitive(PrimitiveType.Cube);
                box.name = id;
                box.transform.position = pos;
                box.transform.localScale = id.Contains("ROOM") ? new Vector3(6f, 3f, 5f) : (id.Contains("EXIT") ? new Vector3(3f, 4f, 2f) : new Vector3(6f, 0.2f, 3f));
                box.transform.SetParent(transform);

                sectorObjects[id] = box;
            }
        }
    }
}
