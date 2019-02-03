import GraphQLJSON from 'graphql-type-json'
import shortid from 'shortid'
import merge from 'lodash.merge'
import globby from 'globby'
import path from 'path'

const resolvers = [{
  JSON: GraphQLJSON,
  DescribedEntity: {
    __resolveType (obj, context, info) {
      return null
    }
  }
}]

// Load resolvers in './schema'
const paths = globby.sync([path.join(__dirname, './schema/*.js')])
paths.forEach(file => {
  const { resolvers: r } = require(file)
  r && resolvers.push(r)
})

export default merge.apply(null, resolvers)