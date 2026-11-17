using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Networking;
using TMPro;

namespace RescueLens.XR.AR
{
    /// <summary>
    /// RescueLens XR - Augmented Reality Evacuation Guidance Controller
    /// Connects to the FastAPI backend, retrieves the dynamic Dijkstra evacuation route,
    /// and renders animated 3D directional chevron arrows and emergency HUD banners
    /// in the user's real-world camera space via AR Foundation.
    /// </summary>
    public class ARRouteNavigator : MonoBehaviour
    {
        [Header("Backend API Configuration")]
        [Tooltip("Backend endpoint URL for Dijkstra route calculation")]
        public string backendRouteUrl = "http://192.168.1.150:8000/api/v1/evacuation/route?origin=ROOM_1";
        public float routePollIntervalSeconds = 3.0f;

        [Header("AR Prefabs & Assets")]
        [Tooltip("3D Chevron Arrow Prefab indicating evacuation direction")]
        public GameObject chevronArrowPrefab;
        [Tooltip("World-space canvas for emergency warnings & exit distance")]
        public GameObject emergencyBillboardPrefab;

        [Header("Visual Materials")]
        public Material safeGreenMaterial;
        public Material warningAmberMaterial;
        public Material hazardRedMaterial;

        [Header("Floor Node 3D Coordinates (Relative to Building Anchor)")]
        // World coordinates (in meters) representing building demonstration layout
        private readonly Dictionary<string, Vector3> nodeCoordinates = new Dictionary<string, Vector3>()
        {
            { "ROOM_1", new Vector3(0f, 0f, 0f) },
            { "ROOM_2", new Vector3(10f, 0f, 0f) },
            { "ROOM_3", new Vector3(20f, 0f, 0f) },
            { "CORRIDOR_WEST", new Vector3(0f, 0f, 5f) },
            { "CORRIDOR_CENTRAL", new Vector3(10f, 0f, 5f) },
            { "CORRIDOR_EAST", new Vector3(20f, 0f, 5f) },
            { "MAIN_EXIT", new Vector3(26f, 0f, 5f) },
            { "EMERGENCY_EXIT", new Vector3(-6f, 0f, 5f) }
        };

        private List<GameObject> activeSpawnedArrows = new List<GameObject>();
        private GameObject activeBillboardInstance;
        private Coroutine pollingCoroutine;

        // Data Models
        [System.Serializable]
        public class RoutePayload
        {
            public string status;
            public string origin;
            public string destination;
            public List<string> path;
            public float path_distance;
            public List<string> hazard_nodes_blocked;
            public string warning_message;
        }

        private void Start()
        {
            pollingCoroutine = StartCoroutine(PollEvacuationRouteRoutine());
        }

        private void OnDestroy()
        {
            if (pollingCoroutine != null)
            {
                StopCoroutine(pollingCoroutine);
            }
        }

        private IEnumerator PollEvacuationRouteRoutine()
        {
            while (true)
            {
                yield return FetchDynamicRoute();
                yield return new WaitForSeconds(routePollIntervalSeconds);
            }
        }

        private IEnumerator FetchDynamicRoute()
        {
            using (UnityWebRequest request = UnityWebRequest.Get(backendRouteUrl))
            {
                request.timeout = 4;
                yield return request.SendWebRequest();

                if (request.result == UnityWebRequest.Result.Success)
                {
                    string json = request.downloadHandler.text;
                    RoutePayload payload = JsonUtility.FromJson<RoutePayload>(json);
                    UpdateARVisuals(payload);
                }
                else
                {
                    Debug.LogWarning($"[ARRouteNavigator] Failed to fetch route: {request.error}");
                }
            }
        }

        private void UpdateARVisuals(RoutePayload route)
        {
            // 1. Clear previous arrows
            foreach (GameObject arrow in activeSpawnedArrows)
            {
                Destroy(arrow);
            }
            activeSpawnedArrows.Clear();

            // 2. Trapped Condition Check
            if (route.status == "TRAPPED_NO_SAFE_ROUTE")
            {
                ShowTrappedWarningBillboard(route.warning_message);
                return;
            }

            // 3. Spawn Directional Chevrons along route nodes
            if (route.path != null && route.path.Count > 1)
            {
                for (int i = 0; i < route.path.Count - 1; i++)
                {
                    string currentNode = route.path[i];
                    string nextNode = route.path[i + 1];

                    if (nodeCoordinates.ContainsKey(currentNode) && nodeCoordinates.ContainsKey(nextNode))
                    {
                        Vector3 startPos = nodeCoordinates[currentNode];
                        Vector3 endPos = nodeCoordinates[nextNode];

                        SpawnChevronWaypoints(startPos, endPos, i);
                    }
                }

                // 4. Update Exit Guidance Billboard at suggested exit
                if (nodeCoordinates.ContainsKey(route.destination))
                {
                    Vector3 exitPos = nodeCoordinates[route.destination];
                    ShowExitBillboard(route.destination, route.path_distance, exitPos);
                }
            }
        }

        private void SpawnChevronWaypoints(Vector3 start, Vector3 end, int segmentIndex)
        {
            float distance = Vector3.Distance(start, end);
            Vector3 direction = (end - start).normalized;
            Quaternion rotation = Quaternion.LookRotation(direction, Vector3.up);

            // Spawn arrows every 1.5 meters along the segment
            int arrowCount = Mathf.Max(1, Mathf.FloorToInt(distance / 1.5f));
            for (int j = 0; j < arrowCount; j++)
            {
                float t = (float)(j + 0.5f) / arrowCount;
                Vector3 spawnPos = Vector3.Lerp(start, end, t) + Vector3.up * 0.2f; // Slight elevation above floor

                GameObject arrow;
                if (chevronArrowPrefab != null)
                {
                    arrow = Instantiate(chevronArrowPrefab, spawnPos, rotation, transform);
                }
                else
                {
                    // Fallback procedural prism arrow if no prefab assigned
                    arrow = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
                    arrow.transform.position = spawnPos;
                    arrow.transform.rotation = rotation * Quaternion.Euler(90f, 0f, 0f);
                    arrow.transform.localScale = new Vector3(0.2f, 0.4f, 0.2f);
                    arrow.transform.SetParent(transform);
                }

                // Apply Safe Green Material
                Renderer rend = arrow.GetComponent<Renderer>();
                if (rend != null && safeGreenMaterial != null)
                {
                    rend.material = safeGreenMaterial;
                }

                // Attach forward motion animation component
                arrow.AddComponent<ChevronPulser>();

                activeSpawnedArrows.Add(arrow);
            }
        }

        private void ShowExitBillboard(string exitName, float distance, Vector3 position)
        {
            if (activeBillboardInstance == null && emergencyBillboardPrefab != null)
            {
                activeBillboardInstance = Instantiate(emergencyBillboardPrefab, position + Vector3.up * 2.0f, Quaternion.identity);
            }

            if (activeBillboardInstance != null)
            {
                activeBillboardInstance.transform.position = position + Vector3.up * 2.0f;
                // Face active camera
                if (Camera.main != null)
                {
                    activeBillboardInstance.transform.LookAt(Camera.main.transform);
                    activeBillboardInstance.transform.Rotate(0, 180, 0); // Correct billboard text flip
                }

                TextMeshPro textComp = activeBillboardInstance.GetComponentInChildren<TextMeshPro>();
                if (textComp != null)
                {
                    textComp.text = $"<color=#00FF66><b>SAFE EXIT: {exitName}</b></color>\nDistance: {distance:F1} m\nFollow Green Chevrons";
                }
            }
        }

        private void ShowTrappedWarningBillboard(string warning)
        {
            if (activeBillboardInstance == null && emergencyBillboardPrefab != null)
            {
                Vector3 centerPos = nodeCoordinates["CORRIDOR_CENTRAL"] + Vector3.up * 2.0f;
                activeBillboardInstance = Instantiate(emergencyBillboardPrefab, centerPos, Quaternion.identity);
            }

            if (activeBillboardInstance != null)
            {
                TextMeshPro textComp = activeBillboardInstance.GetComponentInChildren<TextMeshPro>();
                if (textComp != null)
                {
                    textComp.text = $"<color=#FF0000><b>CRITICAL DANGER: TRAPPED</b></color>\n{warning}\nSeek Nearest Shelter!";
                }
            }
        }
    }

    /// <summary>
    /// Creates a pulsing luminous wave effect on directional chevron arrows.
    /// </summary>
    public class ChevronPulser : MonoBehaviour
    {
        private Vector3 initialScale;
        private float animationSpeed = 4.0f;

        private void Start()
        {
            initialScale = transform.localScale;
        }

        private void Update()
        {
            float scaleMultiplier = 1.0f + 0.15f * Mathf.Sin(Time.time * animationSpeed);
            transform.localScale = initialScale * scaleMultiplier;
        }
    }
}
