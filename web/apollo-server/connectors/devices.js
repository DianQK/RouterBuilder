import execa from 'execa'
import channels from '../channels'
const simctl = require('node-simctl')
import pubsub from '../pubsub'

const concat = (x, y) => x.concat(y)
const flatMap = (f, xs) => xs.map(f).reduce(concat, [])

async function getDevices () {
  let devices = await simctl.getDevices()
  devices = Object.values(devices)
  if (devices.length === 0) {
    console.log('无可用模拟器')
    // TODO: 增加安装模拟器过程
    return []
  }
  devices = flatMap(v => v, devices).sort(l => l.state === 'Shutdown')
  return devices
}

async function boot (udid, context) {
  await simctl.bootDevice(udid)
  execa.shellSync(`open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app`)
  // execa.shellSync(`open -n /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app --args -CurrentDeviceUDID ${udid}`)
  // try {
  //   execa.shellSync(`xcrun instruments -w ${udid}`) // workaround: 这是一个可以 100% 启动对应设备模拟器的方案
  // } catch (error) {
  // }
  // let devices = await getDevices()
  // context.pubsub.publish(channels.DEVICEDS_CHANGED, {
  //   devices
  // })
}

async function shutdown (udid, context) {
  await simctl.shutdown(udid)
}

async function openUrl (udid, url) {
  await simctl.openUrl(udid, url)
  execa.shellSync(`open /Applications/Xcode.app/Contents/Developer/Applications/Simulator.app`)
}

const timeout = ms => new Promise(res => setTimeout(res, ms))

async function loopDetectDevicesState (preDevices = undefined) {
  let devices = await getDevices()
  if (JSON.stringify(preDevices) !== JSON.stringify(devices)) {
    pubsub.publish(channels.DEVICEDS_CHANGED, {
      devicesChanged: devices
    })
  }
  await timeout(1000)
  loopDetectDevicesState(devices)
}

loopDetectDevicesState()

export default {
  boot,
  getDevices,
  shutdown,
  openUrl
}
