import { ref } from 'vue'
import { defineStore } from 'pinia'

export default defineStore('display', () => {
  // 显示模式数据选项
  const showModelData = ['显示移动平均值', '显示原始数据']

  // Y轴刻度选项
  const yAxisTicks = ['线性刻度', '对数刻度']

  // 当前选中的数据显示模式
  const currentShowModelData = ref('显示移动平均值')

  // 当前选中的Y轴刻度
  const currentYAxisTick = ref('线性刻度')

  // 设置数据显示模式
  const setShowModelData = (mode: string) => {
    currentShowModelData.value = mode
  }

  // 设置Y轴刻度
  const setYAxisTick = (tick: string) => {
    currentYAxisTick.value = tick
  }

  return {
    showModelData,
    yAxisTicks,
    currentShowModelData,
    currentYAxisTick,
    setShowModelData,
    setYAxisTick,
  }
})
