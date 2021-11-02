package co.facemoji.mocap4face

import android.content.Context
import android.os.Build
import android.util.AttributeSet
import android.view.OrientationEventListener
import android.view.Surface
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout


/**
 * A [LinearLayout] that handles screen orientation change and stacks the child views either horizontally or vertically.
 */
class OrientedLinearLayout (
    context: Context?,
    attrs: AttributeSet?,
    defStyleAttr: Int,
    defStyleRes: Int
) : LinearLayout(context, attrs, defStyleAttr, defStyleRes) {
    private val orientationListener = object: OrientationEventListener(context) {
        override fun onOrientationChanged(orientation: Int) {
            adjustOrientation(getCurrentDisplayOrientation())
        }
    }

    private val defaultOrientation = orientation
    private val childOrientations = HashMap<View, Int>()

    constructor(context: Context?) :
            this(context, null)

    constructor(context: Context?, attrs: AttributeSet?) :
            this(context, attrs, 0)

    constructor(context: Context?, attrs: AttributeSet?, defStyleAttr: Int) :
            this(context, attrs, defStyleAttr, 0)

    init {
        adjustOrientation(getCurrentDisplayOrientation())
    }

    private fun getCurrentDisplayOrientation(): Int {
        val display = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            context.display
        } else {
            val wm = context.getSystemService(Context.WINDOW_SERVICE) as? WindowManager
            @Suppress("DEPRECATION") // deprecated since Android R
            wm?.defaultDisplay
        }

        return display?.rotation ?: Surface.ROTATION_0
    }

    private fun adjustOrientation(screenOrientation: Int) {
        if (childCount == 0) {
            return
        }
        val newOrientation = when (screenOrientation) {
            Surface.ROTATION_90, Surface.ROTATION_270 -> HORIZONTAL
            Surface.ROTATION_0, Surface.ROTATION_180 -> VERTICAL
            else -> VERTICAL
        }

        if (newOrientation != orientation) {
            for (i in 0 until childCount) {
                val child = getChildAt(i)
                if (childOrientations[child] != newOrientation) {
                    transposeView(child)
                    childOrientations[child] = newOrientation
                }
            }

            orientation = newOrientation
            forceLayout()
        }
    }

    /**
     * Swaps width and height of a view to transform between vertical and horizontal orientation properly
     */
    private fun transposeView(child: View) {
        val params = child.layoutParams
        val h = params.height
        val w = params.width
        params.width = h
        params.height = w
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        orientationListener.enable()
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        orientationListener.disable()
    }

    override fun onViewAdded(child: View?) {
        super.onViewAdded(child)
        if (child != null) {
            if (orientation != defaultOrientation) {
                transposeView(child)
            }
            childOrientations[child] = orientation
        }
    }

    override fun onViewRemoved(child: View?) {
        super.onViewRemoved(child)
        if (child != null) {
            childOrientations.remove(child)
        }
    }
}