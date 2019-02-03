import { PubSub } from 'graphql-subscriptions'

const pubsub = new PubSub()
pubsub.ee.setMaxListeners(0)

export default pubsub
