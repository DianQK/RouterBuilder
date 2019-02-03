<template>
  <div>
    <div class="form" v-for="appRoute in appRoutes" :key="appRoute.viewControllerClassName">
      <VueButton>{{ appRoute.viewControllerClassName }}</VueButton>
      <VueFormField
        v-for="parameter in appRoute.initializerFunctionParameterList"
        title=""
        :subtitle="parameter.errorMessage"
        :key="parameter.name"
        status-icon
      >
        <VueInput
          v-model="parameter.value"
          :placeholder="`${parameter.name} ${parameter.type}${parameter.required ? ' required' : ''}`"
          :status="parameter.errorMessage ? 'danger' : ''"
        />
      </VueFormField>
      <ApolloQuery :query="require('@/graphql/devices.gql')">
        <template slot-scope="{ result: { loading, error, data } }">
          <VueSelect v-if="data" v-model="appRoute.device">
            <VueSelectButton v-for="device in data.devices.filter(device => device.state === 'Booted')" :value="device.udid" :label="device.name" :key="device.udid"/>
          </VueSelect>
        </template>
      </ApolloQuery>
      <VueButton
        label="Open"
        icon-left="flash_on"
        :disabled="!appRoute.device || !!appRoute.initializerFunctionParameterList.find(p => p.required && !p.value)"
        @click="openAppRoute(appRoute)"
        class="primary"
      />
    </div>
  </div>
</template>

<script>
import OPEN_URL from '@/graphql/openUrl.gql'

export default {
  data () {
    return {
      appRoutes: [...require('@/appRoutes.json')].map(route => ({ ...route, device: '', initializerFunctionParameterList: [...route.initializerFunctionParameterList.map(p => ({ ...p, errorMessage: '' }))] }))
    }
  },
  methods: {
    openAppRoute (appRoute) {
      let urlBuildSuccess = appRoute.initializerFunctionParameterList.reduce((success, item) => {
        if (item.required || !!item.value) {
          if (['Int', 'Float', 'Double'].includes(item.type)) {
            let number = Number(item.value)
            if (!number) {
              item.errorMessage = 'type error'
              return false
            }
            if (item.type === 'Int' && !Number.isInteger(number)) {
              item.errorMessage = 'type error'
              return false
            }
            return true
          } else {
            item.errorMessage = ''
            return success
          }
        } else {
          return success
        }
      }, true)
      let query = appRoute.initializerFunctionParameterList.map(p => [p.name, encodeURIComponent(p.value)].join('=')).join('&')
      let url = `routerbuilder://${appRoute.viewControllerClassName}?${query}`
      if (urlBuildSuccess) {
        this.$apollo.mutate({
          mutation: OPEN_URL,
          variables: {
            udid: appRoute.device,
            url
          }
        })
      }
    }
  }
}
</script>

<style lang="stylus" scoped>
.form
  > *
    margin 5px
</style>
