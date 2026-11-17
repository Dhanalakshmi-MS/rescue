using System;
using UnityEngine;
using UnityEngine.XR.ARFoundation;
using UnityEngine.XR.ARSubsystems;

namespace RescueLens.XR.AR
{
    /// <summary>
    /// Solves the fundamental limitation of Indoor Positioning where GPS fails.
    /// Uses visual fiducial markers (QR codes / printed door plates) tracked by AR Foundation
    /// to re-anchor the virtual 3D floor plan to ground truth physical room doors.
    /// </summary>
    [RequireComponent(typeof(ARTrackedImageManager))]
    public class IndoorLocalizationManager : MonoBehaviour
    {
        [Header("System References")]
        public ARRouteNavigator routeNavigator;
        public ARSession arSession;

        private ARTrackedImageManager trackedImageManager;

        private void Awake()
        {
            trackedImageManager = GetComponent<ARTrackedImageManager>();
        }

        private void OnEnable()
        {
            trackedImageManager.trackedImagesChanged += OnTrackedImagesChanged;
        }

        private void OnDisable()
        {
            trackedImageManager.trackedImagesChanged -= OnTrackedImagesChanged;
        }

        private void OnTrackedImagesChanged(ARTrackedImagesChangedEventArgs eventArgs)
        {
            // Process newly detected or updated physical image markers
            foreach (ARTrackedImage trackedImage in eventArgs.added)
            {
                LocalizeToMarker(trackedImage);
            }

            foreach (ARTrackedImage trackedImage in eventArgs.updated)
            {
                if (trackedImage.trackingState == TrackingState.Tracking)
                {
                    LocalizeToMarker(trackedImage);
                }
            }
        }

        private void LocalizeToMarker(ARTrackedImage marker)
        {
            string markerName = marker.referenceImage.name;
            Debug.Log($"[IndoorLocalization] Physical Anchor Detected: {markerName}");

            // Map physical QR marker label to building room ID
            string recognizedRoom = "ROOM_1";
            if (markerName.Contains("ROOM_2")) recognizedRoom = "ROOM_2";
            else if (markerName.Contains("ROOM_3")) recognizedRoom = "ROOM_3";
            else if (markerName.Contains("CORRIDOR")) recognizedRoom = "CORRIDOR_CENTRAL";

            // Snap the AR world coordinate space to match the detected door anchor
            if (routeNavigator != null)
            {
                // Align root transform
                routeNavigator.transform.position = marker.transform.position;
                routeNavigator.transform.rotation = marker.transform.rotation;
                
                // Update route origin endpoint dynamically
                routeNavigator.backendRouteUrl = 
                    routeNavigator.backendRouteUrl.Split('?')[0] + $"?origin={recognizedRoom}";
            }
        }
    }
}
