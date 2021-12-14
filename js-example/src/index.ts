import {
    ApplicationContext,
    FacemojiAPI,
    FaceTracker,
    FPS,
    Logger,
    LogLevel,
    Quaternion,
    ResourceFileSystem,
    Vec2,
} from '@facemoji/mocap4face';
import './styles/main.scss';

Logger.logLevel = LogLevel.Info; // Set LogLevel.Debug to increase logging verbosity when debugging
const videoElement = document.getElementById('videoSource') as HTMLVideoElement;
const webcamButton = document.getElementById('webcam')!;
const webcamOverlay = webcamButton.parentElement!;
const contentElement = document.getElementById('blendshapes')!;
const statusElement = document.getElementById('status')!;
const fpsElement = document.getElementById('fps');
const fallbackVideo = videoElement.currentSrc;

function startTracking() {
    const faceRectangleElement = document.getElementById('rectangle');
    const blendshapeSliders = new Map<String, HTMLElement>();
    const context = new ApplicationContext(window.location.href); // Set a different URL here if you host application resources elsewhere
    const fs = new ResourceFileSystem(context);
    const fps = new FPS(1);

    // Initialize the API and activate API key
    // Note that without an API key the SDK works only for a short period of time
    FacemojiAPI.initialize('<YOUR KEY HERE>', context).then((activated) => {
        if (activated) {
            console.info('API successfully activated');
        } else {
            console.info('API could not be activated');
        }
    });

    const webcamAvailable = checkWebcamAvailable();

    // Initialize
    const asyncTracker = FaceTracker.createVideoTracker(fs)
        .then((tracker) => {
            console.log('Started tracking');

            // Collect all blendshape names and prepare UI
            const blendshapeNames = tracker.blendshapeNames
                .toArray()
                .concat(faceRotationToBlendshapes(Quaternion.createWithFloat(0, 0, 0, 1)).map((e) => e[0]))
                .sort();

            hideLoading();
            contentElement.replaceChildren(); // remove dummy loading elements
            for (const blendshape of blendshapeNames) {
                const [li, div] = createBlendshapeElement(blendshape);
                contentElement.appendChild(li);
                blendshapeSliders.set(blendshape, div);
            }

            requestAnimationFrame(track);
            return tracker;
        })
        .logError('Could not start tracking');

    // Show webcam button after tracker loads and when webcam is available
    Promise.all([webcamAvailable, asyncTracker.promise()]).then(() => {
        webcamOverlay.classList.remove('hidden');
    });

    /**
     * Shows or hides rectangle around the detected face
     * @param show whether to show the face rectangle
     */
    function setFaceRectangleVisible(show: boolean) {
        if (faceRectangleElement !== null) {
            faceRectangleElement.style.display = show ? 'block' : 'none';
        }
    }

    /**
     * Performs face tracking, called every animation frame.
     */
    function track() {
        requestAnimationFrame(track);
        const tracker = asyncTracker.currentValue;

        // Track only when everything is fully loaded and video is running
        if (!tracker || videoElement === null || contentElement === null) {
            setFaceRectangleVisible(false);
            return;
        }

        if (videoElement.paused || document.hidden) {
            statusElement.hidden = false;
            return;
        }

        statusElement.hidden = true;

        // Face tracking
        const lastResult = tracker.track(videoElement);
        if (lastResult == null) {
            setFaceRectangleVisible(false);
            return; // No face found or video frame could not be processed
        }

        // Update UI
        for (const [name, value] of lastResult.blendshapes) {
            updateBlendshapeValue(name, value);
        }

        const rotationBlendshapes = faceRotationToBlendshapes(lastResult.rotationQuaternion);
        for (const [name, value] of rotationBlendshapes) {
            updateBlendshapeValue(name, value);
        }

        videoElement.className = videoResolutionClass(lastResult.inputImageSize);

        // Update face reactangle overlay
        if (faceRectangleElement !== null) {
            // Align overlay parent size with video size
            const parent = faceRectangleElement.parentElement;
            if (parent !== null) {
                parent.style.left = videoElement.offsetLeft + 'px';
                parent.style.top = videoElement.offsetTop + 'px';
                parent.style.width = videoElement.clientWidth + 'px';
                parent.style.height = videoElement.clientHeight + 'px';
            }

            // Convert face rectangle from tracker coordinates to HTML coordinates
            const rect = lastResult.faceRectangle
                .flipY(lastResult.inputImageSize.y)
                .normalizeBy(lastResult.inputImageSize)
                .scale(videoElement.clientWidth, videoElement.clientHeight)
                .scaleAroundCenter(0.8, 0.8); // mocap4face uses a wider rect for better detection, a smaller one is more pleasing to the eye though
            faceRectangleElement.style.position = 'relative';
            faceRectangleElement.style.left = rect.x.toString() + 'px';
            faceRectangleElement.style.top = rect.y.toString() + 'px';
            faceRectangleElement.style.width = rect.width.toString() + 'px';
            faceRectangleElement.style.height = rect.height.toString() + 'px';

            // At this point the tracker always detected some face but it might be a low confidence one.
            // hasFace() checks whether the tracker is confident enough about the detection.
            // You can also read the confidence value itself by checking lastResult.confidence
            setFaceRectangleVisible(lastResult.hasFace());
        }

        // Update FPS counter
        fps.tick((currentFps) => {
            if (fpsElement !== null) {
                fpsElement.parentElement!.className = '';
                fpsElement.innerText = currentFps.toFixed(0);
            }
        });
    }

    /**
     * Creates a progressbar-like component for a blendshape key
     * @param blendshape blendshape name
     * @returns label and progressbar elements
     */
    function createBlendshapeElement(blendshape: string): [HTMLElement, HTMLElement] {
        const li = document.createElement('li');
        const span = document.createElement('code');
        span.innerHTML = blendshape;
        li.appendChild(span);
        const div = document.createElement('div');
        div.classList.add('value');
        li.appendChild(div);
        return [li, div];
    }

    /**
     * Update UI for the given blendshape
     * @param blendShape blendshape name
     * @param value new value
     */
    function updateBlendshapeValue(blendShape: string, value: number) {
        const div = blendshapeSliders.get(blendShape);
        if (div) {
            div.style.width = `${(value * 100).toFixed(0)}%`;
        }
    }

    /**
     * Converts head rotation to blendshape-like values so that we can show it in the UI as well.
     * @param rotation rotation from the tracker
     * @returns rotation represented as 6 blendshapes
     */
    function faceRotationToBlendshapes(rotation: Quaternion): Array<[string, number]> {
        let euler = rotation.toEuler();
        let halfPi = Math.PI * 0.5;
        return [
            ['headLeft', Math.max(0, euler.y) / halfPi],
            ['headRight', -Math.min(0, euler.y) / halfPi],
            ['headUp', -Math.min(0, euler.x) / halfPi],
            ['headDown', Math.max(0, euler.x) / halfPi],
            ['headRollLeft', -Math.min(0, euler.z) / halfPi],
            ['headRollRight', Math.max(0, euler.z) / halfPi],
        ];
    }
}

/**
 * Checks whether there are any webcameras available on this device
 * @returns true if at least one camera is available
 */
function checkWebcamAvailable(): Promise<boolean> {
    const supportsWebcam = navigator.mediaDevices !== undefined && navigator.mediaDevices.getUserMedia !== undefined;
    if (supportsWebcam) {
        return navigator.mediaDevices.enumerateDevices().then(
            (devices) => {
                if (devices.some((device) => device.kind === 'videoinput')) {
                    return true;
                } else {
                    console.warn('No webcamera available');
                    return false;
                }
            },
            (error) => {
                console.warn('Error enumerating devices ' + error);
                return false;
            },
        );
    } else {
        return Promise.resolve(false);
    }
}

/**
 * Gets CSS class for the given video resolution, used only for UI tweaks
 * @param resolution video resolution
 * @returns css class
 */
function videoResolutionClass(resolution: Vec2): string {
    const knownRatios: Array<[string, number]> = [
        ['1_1', 1],
        ['16_9', 16 / 9],
        ['4_3', 4 / 3],
        ['9_16', 9 / 16],
        ['3_4', 3 / 4],
    ];
    const currentRatio = resolution.x / resolution.y;
    for (const clsAndRatio of knownRatios) {
        if (Math.abs(clsAndRatio[1] - currentRatio) <= 0.01) {
            return 'ratio_' + clsAndRatio[0];
        }
    }
    return 'ratio_unknown';
}

/**
 * Hide loading status in the UI
 */
function hideLoading() {
    statusElement.classList.remove('loading');
    contentElement.classList.remove('loading');
    webcamButton.classList.remove('loading');
    videoElement.classList.remove('hidden', 'loading');
    videoElement.parentElement?.classList?.remove('loading');
}

// Handle webcam button
webcamButton.addEventListener('click', () => {
    if (videoElement.currentSrc === fallbackVideo) {
        navigator.mediaDevices
            .getUserMedia({ video: true })
            .then((stream) => {
                videoElement.srcObject = stream;
                videoElement.autoplay = true;
                videoElement.parentElement?.classList.remove('video');
                videoElement.parentElement?.classList.add('webcam');
                webcamButton.title = 'Disable webcam';
                webcamButton.classList.remove('webcam_error');
                webcamButton.classList.add('disable_webcam');
                return;
            })
            // fallback to test video if user blocked the camera or it is not available for some reason
            .catch((err) => {
                webcamButton.classList.add('webcam_error');
                webcamButton.title = 'Error enabling webcam: ' + err.message;
                console.warn(err);
            });
    } else {
        webcamButton.title = 'Enable webcam';
        webcamButton.classList.remove('disable_webcam');
        if (videoElement.srcObject !== null) {
            (videoElement.srcObject as MediaStream)?.getTracks().forEach((t) => t.stop());
            videoElement.srcObject = null;
        }
        videoElement.setAttribute('src', fallbackVideo);
        videoElement.parentElement?.classList.remove('webcam');
        videoElement.parentElement?.classList.add('video');
    }
});

// Do not eat resources when our tab is in the background
window.onfocus = () => {
    videoElement.play();
};
window.onblur = () => {
    videoElement.pause();
};

// Start tracking
startTracking();
