const { merge } = require('webpack-merge')
const common = require('./webpack.config.common.js')

module.exports = merge(common, {
    mode: 'production',
    optimization: {
        minimize: true,
    },
    devtool: 'source-map',
})
