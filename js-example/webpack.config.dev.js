const { merge } = require('webpack-merge')
const common = require('./webpack.config.common.js')

module.exports = merge(common, {
    mode: 'development',
    optimization: {
        minimize: false,
    },
    devtool: 'eval-source-map',
})
