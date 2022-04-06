const path = require('path')
const HtmlWebpackPlugin = require('html-webpack-plugin')
const { CleanWebpackPlugin } = require('clean-webpack-plugin')
const CopyPlugin = require('copy-webpack-plugin')
const MiniCssExtractPlugin = require('mini-css-extract-plugin')

module.exports = {
    entry: './src/index.ts',
    mode: 'none',
    output: {
        path: path.resolve(__dirname, 'dist'),
        filename: 'bundle.js',
    },
    module: {
        rules: [
            {
                test: /\.ts$/,
                use: 'ts-loader',
                exclude: /node_modules|styles/,
            },
            {
                test: /\.(s(a|c)ss)$/,
                use: [MiniCssExtractPlugin.loader, 'css-loader', 'sass-loader'],
            },
        ],
    },
    resolve: {
        extensions: ['.ts', '.js'],
    },
    plugins: [
        new CleanWebpackPlugin(),
        new HtmlWebpackPlugin({ template: 'src/index.html' }),
        // copies necessary facemoji NPM package resources content to target dist directory
        new CopyPlugin({
            patterns: [
                {
                    from: 'models/**/*',
                    context: path.dirname(require.resolve('@0xalter/mocap4face/package.json')),
                },
                {
                    from: '*.json',
                    context: path.dirname(require.resolve('@0xalter/mocap4face/package.json')),
                },
            ],
        }),
        new MiniCssExtractPlugin(),
    ],
}
