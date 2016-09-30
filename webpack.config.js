const webpack = require('webpack');

module.exports = {
  entry: './client_modules/js/app.js',
  output: {
    path: './webpack_dist',
    filename: 'app.bundle.js'
  },
  // resolve: {
  //   extensions: ['', '.js', '.jsx']
  // },
  // module: {
  //   loaders: [
  //     {
  //       test: /\.jsx?$/,
  //       include: './client_modules/',
  //       loader: 'babel-loader',
  //       query: {
  //         presets: ['react', 'es2015']
  //       }
  //     }
  //   ]
  // },
  plugins: [
    new webpack.ProvidePlugin({
      $: "jquery",
      jQuery: "jquery",
      "window.jQuery": "jquery",
      d3: 'd3'
    })
    // new webpack.optimize.UglifyJsPlugin({
    //     compress: {
    //         warnings: false,
    //     },
    //     output: {
    //         comments: false,
    //     },
    // })
  ]
};