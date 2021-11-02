package co.facemoji.mocap4face

import android.content.Context
import android.util.AttributeSet
import android.widget.*


class BlendshapesView(
    context: Context?,
    attrs: AttributeSet?,
    defStyleAttr: Int,
    defStyleRes: Int
) : ScrollView(context, attrs, defStyleAttr, defStyleRes) {

    private val cells = ArrayList<CellView>()
    private val layout = LinearLayout(context, attrs, defStyleAttr, defStyleRes)

    constructor(context: Context?) :
        this(context, null)

    constructor(context: Context?, attrs: AttributeSet?) :
        this(context, attrs, 0)

    constructor(context: Context?, attrs: AttributeSet?, defStyleAttr: Int) :
        this(context, attrs, defStyleAttr, 0)

    init {
        layout.orientation = LinearLayout.VERTICAL
        layout.layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        addView(layout)
    }

    var blendshapeNames: List<String> = emptyList()
        set(value) {
            field = value
            layout.removeAllViews()
            cells.clear()

            for (item in value) {
                val cell = CellView(context)
                cell.label = item
                cell.value = 0f
                layout.addView(cell)
                cells.add(cell)
            }
        }

    fun updateData(input: Map<String, Float>) {
        for (cell in cells) {
            cell.value = input[cell.label] ?: 0f
        }
    }
}

private class CellView : FrameLayout {
    private lateinit var textField: TextView
    private lateinit var valueField: SeekBar

    constructor(context: Context, attrs: AttributeSet?, defStyle: Int) : super(
        context, attrs, defStyle
    ) {
        initView()
    }

    constructor(context: Context, attrs: AttributeSet?) : super(
        context, attrs
    ) {
        initView()
    }

    constructor(context: Context) : super(context) {
        initView()
    }

    private fun initView() {
        inflate(context, R.layout.item_blendshape, this)
        textField = findViewById(R.id.name)
        valueField = findViewById(R.id.progress)
    }

    var label: String
        get() { return textField.text.toString() }
        set(value) { textField.text = value }

    var value: Float
        get() { return valueField.progress / 100.0f }
        set(value) { valueField.progress = (value * 100f).toInt() }
}
