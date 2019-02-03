import gql from 'graphql-tag'
// Subs
import { withFilter } from 'graphql-subscriptions'
import channels from '../channels'
import devices from '../connectors/devices'

export const types = gql`
extend type Query {
  devices: [Device]
}

extend type Mutation {
  deviceBoot (udid: String!): Device
  deviceShutdown (udid: String!): Device
  openUrl (udid: String!, url: String!): Boolean
}

extend type Subscription {
  devicesChanged: [Device]
}

type Device {
  name: String!
  udid: String!
  state: String!
}
`

export const resolvers = {
  Query: {
    devices: async () => await devices.getDevices(),
  },
  Mutation: {
    deviceBoot: (root, { udid }, context) => devices.boot(udid, context),
    deviceShutdown: (root, { udid }, context) => devices.shutdown(udid, context),
    openUrl: (root, { udid, url }, context) => devices.openUrl(udid, url)
  },
  Subscription: {
    devicesChanged: {
      subscribe: withFilter(
        (parent, args, { pubsub }) => pubsub.asyncIterator(channels.DEVICEDS_CHANGED),
        (payload, vars) => true
      )
    }
  }
}
