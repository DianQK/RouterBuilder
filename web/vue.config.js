module.exports = {
  pluginOptions: {
    apollo: {
      enableMocks: true,
      enableEngine: true
    }
  },
  configureWebpack: {
    resolve: {
      symlinks: false
    }
  }
}
