<template>
  <div class="devices">
    <ApolloQuery
      :query="require('@/graphql/devices.gql')"
    >
      <ApolloSubscribeToMore
        :document="require('@/graphql/devicesChanged.gql')"
        :updateQuery="onDevicesChanged"
      />
      <template slot-scope="{ result: { loading, error, data } }">
        <div v-if="loading" class="loading apollo">Loading...</div>
        <div v-else-if="error" class="error apollo">An error occured</div>
        <div v-else-if="data" class="result apollo">
          <div v-for="device in data.devices" :key="device.udid">
            <span>{{ device.name }}</span>
            <VueButton
              style="margin: 5px;"
              :label="(device.state !== 'Shutdown' && device.state !== 'Booted') ? device.state : (device.state === 'Shutdown' ? 'Boot' : 'Shutdown')"
              :icon-left="device.state === 'Shutdown' ? 'flash_on' : 'stop'"
              :loadingSecondary="device.state !== 'Shutdown' && device.state !== 'Booted'"
              @click="changeDeviceState(device)"
              class="primary"
            />
          </div>
        </div>
        <div v-else class="no-result apollo">No result :(</div>
      </template>
    </ApolloQuery>
  </div>
</template>

<script>
import DEVICE_BOOT from '@/graphql/deviceBoot.gql'
import DEVICE_SHUTDOWN from '@/graphql/deviceShutdown.gql'

export default {
  methods: {
    changeDeviceState ({ udid, state }) {
      this.$apollo.mutate({
        mutation: state === 'Shutdown' ? DEVICE_BOOT : DEVICE_SHUTDOWN,
        variables: {
          udid
        }
      })
    },
    onDevicesChanged (previousResult, { subscriptionData }) {
      return {
        ...previousResult,
        devices: subscriptionData.data.devicesChanged
      }
    }
  }
}
</script>

<style lang="stylus" scoped>
.tool-bar
  > *
    margin 0 10px
.devices
  v-box()
  align-items stretch
.content
  flex auto 1 1
  margin 30px
  position relative
</style>

<style scoped>
.form,
.input,
.apollo,
.message {
  padding: 12px;
}

label {
  display: block;
  margin-bottom: 6px;
}

.input {
  font-family: inherit;
  font-size: inherit;
  border: solid 2px #ccc;
  border-radius: 3px;
}

.error {
  color: red;
}

.images {
  display: grid;
  grid-template-columns: repeat(auto-fill, 300px);
  grid-auto-rows: 300px;
  grid-gap: 10px;
}

.image-item {
  display: flex;
  align-items: center;
  justify-content: center;
  background: #ccc;
  border-radius: 8px;
}

.image {
  max-width: 100%;
  max-height: 100%;
}

.image-input {
  margin: 20px;
}
</style>
