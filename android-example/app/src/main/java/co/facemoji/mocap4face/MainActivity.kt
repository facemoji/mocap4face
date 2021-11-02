package co.facemoji.mocap4face

import android.Manifest
import android.content.res.Configuration
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.ImageView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import co.facemoji.api.FacemojiAPI
import co.facemoji.io.ApplicationContext
import co.facemoji.logging.LogLevel
import co.facemoji.logging.Logger
import co.facemoji.logging.error
import co.facemoji.logging.info
import co.facemoji.math.Quaternion
import co.facemoji.tracker.FaceTrackerResult
import co.facemoji.tracker.OpenGLTexture
import co.facemoji.ui.CameraTextureView
import pub.devrel.easypermissions.AfterPermissionGranted
import pub.devrel.easypermissions.EasyPermissions
import kotlin.math.max
import kotlin.math.min

class MainActivity : AppCompatActivity() {
    companion object {
        const val CAMERA_REQUEST_CODE: Int = 1337
    }

    private var cameraView: CameraTextureView? = null
    private var cameraTracker: CameraTracker? = null

    private var blendshapesView: BlendshapesView? = null
    private var facemojiContainer: ViewGroup? = null
    private var timeoutLabel: TextView? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(null)
        Logger.logLevel = LogLevel.Debug

        FacemojiAPI.initialize("<YOUR KEY HERE>", ApplicationContext(applicationContext))
            .whenDone { activated ->
                if (activated) {
                    Logger.info("API activation was successful")
                } else {
                    Logger.error("API activation failed")
                }
            }

        FacemojiAPI.addDemoTimeoutCallback {
            runOnUiThread {
                resolveTimeoutLabelVisibility()
            }
        }

        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)

        setContentView(R.layout.activity_main)

        blendshapesView = findViewById(R.id.blendshapes)
        facemojiContainer = findViewById(R.id.facemojiContainer)
        timeoutLabel = findViewById(R.id.timeout)
        findViewById<ImageView>(R.id.switchCamera).setOnClickListener {
            cameraTracker?.switchCamera()
        }
        requestCameraPermission()
    }

    private fun resolveTimeoutLabelVisibility() {
        if (resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE) {
            timeoutLabel?.visibility = View.GONE
        } else {
            timeoutLabel?.visibility = if (FacemojiAPI.isDemoMode) View.GONE else View.VISIBLE
        }
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        resolveTimeoutLabelVisibility()
    }

    private fun onTracker(cameraImage: OpenGLTexture, trackerResult: FaceTrackerResult?) {
        cameraView?.showTexture(cameraImage)
        runOnUiThread {
            if (trackerResult != null) {
                val blendshapes = trackerResult.blendshapes +
                        faceRotationToSliders(trackerResult.rotationQuaternion)
                blendshapesView?.updateData(blendshapes)
            } else {
                blendshapesView?.updateData(emptyMap())
            }
        }
    }

    /**
     * Converts head rotation to blendshape-like coefficients to display in the UI
     */
    private fun faceRotationToSliders(rotation: Quaternion): Map<String, Float> {
        val euler = rotation.toEuler()
        val halfPi = Math.PI.toFloat() * 0.5f
        return mapOf(
            "headLeft" to max(0f, euler.y) / halfPi,
            "headRight" to -min(0f, euler.y) / halfPi,
            "headUp" to -min(0f, euler.x) / halfPi,
            "headDown" to max(0f, euler.x) / halfPi,
            "headRollLeft" to -min(0f, euler.z) / halfPi,
            "headRollRight" to max(0f, euler.z) / halfPi,
        )
    }

    @AfterPermissionGranted(CAMERA_REQUEST_CODE)
    @Suppress("UNUSED")
    private fun onCameraEnabled() {
        val cameraTracker = CameraTracker(this)
        cameraView = CameraTextureView(
            applicationContext,
            cameraTracker.openGLContext
        ) // must share the OpenGL context
        runOnUiThread {
            facemojiContainer?.addView(cameraView, 0)
        }
        cameraTracker.trackerDelegate = this::onTracker
        cameraTracker.blendshapeNames.whenDone { names ->
            runOnUiThread {
                val headPoseNames = faceRotationToSliders(Quaternion.identity).keys
                blendshapesView?.blendshapeNames = (names + headPoseNames).sorted()
            }
        }
        this.cameraTracker = cameraTracker
    }

    private fun requestCameraPermission() {
        EasyPermissions.requestPermissions(
            this,
            "We need camera to breathe life to the avatar",
            CAMERA_REQUEST_CODE,
            Manifest.permission.CAMERA
        )
    }

    override fun onPause() {
        super.onPause()
        cameraTracker?.stop()
    }

    override fun onResume() {
        super.onResume()
        cameraTracker?.restart()
    }

    override fun onDestroy() {
        super.onDestroy()
        cameraTracker?.stop()
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        EasyPermissions.onRequestPermissionsResult(requestCode, permissions, grantResults, this)
    }
}
